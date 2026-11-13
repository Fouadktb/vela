use anyhow::{Result, anyhow, bail};
use reqwest::blocking::{Client, Response};
use std::{io::Read, time::Duration};
use url::Url;

pub const MAX_IMPORT_BYTES: u64 = 256 * 1024 * 1024;

#[derive(Debug)]
pub struct HttpStatusError(pub u16);
impl std::fmt::Display for HttpStatusError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Provider request failed with HTTP {}", self.0)
    }
}
impl std::error::Error for HttpStatusError {}

/// One client per worker/import reuses TLS sessions and connections. Errors never
/// contain the requested URL: provider URLs commonly contain account credentials.
pub fn client() -> Result<Client> {
    let mut headers = reqwest::header::HeaderMap::new();
    headers.insert(
        reqwest::header::ACCEPT_ENCODING,
        reqwest::header::HeaderValue::from_static("gzip"),
    );
    Client::builder()
        .default_headers(headers)
        // Read compressed bytes ourselves so the raw and expanded sizes are
        // independently bounded; automatic decoding hides the compressed size.
        .gzip(false)
        .connect_timeout(Duration::from_secs(20))
        .timeout(Duration::from_secs(120))
        .redirect(reqwest::redirect::Policy::limited(5))
        .user_agent("VLC/3.0.20 LibVLC/3.0.20")
        .build()
        .map_err(|_| anyhow!("Could not initialize provider connection"))
}

pub fn checked_url(source: &str) -> Result<Url> {
    let url = Url::parse(source.trim()).map_err(|_| anyhow!("Provider URL is invalid"))?;
    if !matches!(url.scheme(), "http" | "https") || url.host_str().is_none() {
        bail!("Provider URL must use HTTP or HTTPS");
    }
    Ok(url)
}

pub fn get(client: &Client, url: Url) -> Result<Vec<u8>> {
    let response = client
        .get(url)
        .send()
        .map_err(|_| anyhow!("Provider could not be reached or timed out"))?;
    read_response(response)
}

pub fn read_response(response: Response) -> Result<Vec<u8>> {
    let status = response.status();
    if !status.is_success() {
        return Err(HttpStatusError(status.as_u16()).into());
    }
    if response
        .content_length()
        .is_some_and(|n| n > MAX_IMPORT_BYTES)
    {
        bail!("Provider response exceeds the 256 MiB import limit");
    }
    decode_if_gzip(read_limited(response)?)
}

pub fn read_limited(reader: impl Read) -> Result<Vec<u8>> {
    read_with_limit(reader, MAX_IMPORT_BYTES)
}

fn read_with_limit(reader: impl Read, limit: u64) -> Result<Vec<u8>> {
    let mut bytes = Vec::new();
    reader
        .take(limit + 1)
        .read_to_end(&mut bytes)
        .map_err(|_| anyhow!("Provider data could not be read"))?;
    if bytes.len() as u64 > limit {
        bail!("Provider response exceeds the 256 MiB import limit");
    }
    Ok(bytes)
}

/// Handles .gz feeds without Content-Encoding as well as local compressed files.
/// Both input and expanded output must remain inside the import budget.
pub fn decode_if_gzip(bytes: Vec<u8>) -> Result<Vec<u8>> {
    if bytes.starts_with(&[0x1f, 0x8b]) {
        read_limited(flate2::read::MultiGzDecoder::new(bytes.as_slice()))
    } else {
        Ok(bytes)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn caps_unknown_length_streams_and_redacts_parse_errors() {
        assert_eq!(read_with_limit(&b"12345"[..], 5).unwrap(), b"12345");
        assert!(read_with_limit(&b"123456"[..], 5).is_err());
        let error = checked_url("file:///secret-password")
            .unwrap_err()
            .to_string();
        assert!(!error.contains("secret-password"));
        use std::io::Write;
        let mut encoder = flate2::write::GzEncoder::new(Vec::new(), flate2::Compression::default());
        encoder.write_all(b"<tv/>").unwrap();
        assert_eq!(decode_if_gzip(encoder.finish().unwrap()).unwrap(), b"<tv/>");
        assert!(decode_if_gzip(vec![0x1f, 0x8b, 0, 0]).is_err());
    }
}
