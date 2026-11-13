use super::{ImportProgress, ProgressMeter};
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
    get_with_progress(client, url, "Downloading provider data", &mut |_| {})
}

pub fn get_with_progress(
    client: &Client,
    url: Url,
    stage: &str,
    progress: &mut dyn FnMut(ImportProgress),
) -> Result<Vec<u8>> {
    progress(ImportProgress {
        stage: stage.into(),
        completed: 0,
        total: None,
        unit: "bytes".into(),
    });
    let response = client
        .get(url)
        .send()
        .map_err(|_| anyhow!("Provider could not be reached or timed out"))?;
    read_response_with_progress(response, stage, progress)
}

fn read_response_with_progress(
    response: Response,
    stage: &str,
    progress: &mut dyn FnMut(ImportProgress),
) -> Result<Vec<u8>> {
    let status = response.status();
    if !status.is_success() {
        return Err(HttpStatusError(status.as_u16()).into());
    }
    // Client automatic gzip decoding is disabled. Content-Length, when present,
    // therefore measures the very same raw bytes counted below.
    let total = response.content_length();
    if total.is_some_and(|n| n > MAX_IMPORT_BYTES) {
        bail!("Provider response exceeds the 256 MiB import limit");
    }
    decode_with_progress(
        read_limited_with_progress(response, total, stage, progress)?,
        progress,
    )
}

#[cfg(test)]
fn read_with_limit(reader: impl Read, limit: u64) -> Result<Vec<u8>> {
    read_with_limit_and_progress(reader, limit, None, "Reading provider data", &mut |_| {})
}

pub fn read_limited_with_progress(
    reader: impl Read,
    total: Option<u64>,
    stage: &str,
    progress: &mut dyn FnMut(ImportProgress),
) -> Result<Vec<u8>> {
    if total.is_some_and(|n| n > MAX_IMPORT_BYTES) {
        bail!("Provider response exceeds the 256 MiB import limit");
    }
    read_with_limit_and_progress(reader, MAX_IMPORT_BYTES, total, stage, progress)
}

fn read_with_limit_and_progress(
    reader: impl Read,
    limit: u64,
    total: Option<u64>,
    stage: &str,
    progress: &mut dyn FnMut(ImportProgress),
) -> Result<Vec<u8>> {
    let mut bytes = Vec::new();
    let mut reader = reader.take(limit + 1);
    let mut buffer = [0u8; 64 * 1024];
    let mut meter = ProgressMeter::new(stage, "bytes", total, 1024 * 1024, progress);
    loop {
        let count = match reader.read(&mut buffer) {
            Err(error) if error.kind() == std::io::ErrorKind::Interrupted => continue,
            result => result.map_err(|_| anyhow!("Provider data could not be read"))?,
        };
        if count == 0 {
            break;
        }
        bytes.extend_from_slice(&buffer[..count]);
        if bytes.len() as u64 > limit {
            bail!("Provider response exceeds the 256 MiB import limit");
        }
        meter.set(bytes.len() as u64);
    }
    meter.finish(bytes.len() as u64);
    Ok(bytes)
}

/// Handles .gz feeds without Content-Encoding as well as local compressed files.
/// Both input and expanded output must remain inside the import budget.
#[cfg(test)]
fn decode_if_gzip(bytes: Vec<u8>) -> Result<Vec<u8>> {
    decode_with_progress(bytes, &mut |_| {})
}

pub fn decode_with_progress(
    bytes: Vec<u8>,
    progress: &mut dyn FnMut(ImportProgress),
) -> Result<Vec<u8>> {
    if bytes.starts_with(&[0x1f, 0x8b]) {
        read_limited_with_progress(
            flate2::read::MultiGzDecoder::new(bytes.as_slice()),
            None,
            "Decompressing provider data",
            progress,
        )
    } else {
        Ok(bytes)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn known_and_unknown_sources_report_exact_throttled_raw_counts() {
        let source = vec![b'x'; 3 * 1024 * 1024 + 17];
        for total in [None, Some(source.len() as u64)] {
            let mut events = Vec::new();
            let result = read_limited_with_progress(
                source.as_slice(),
                total,
                "Reading playlist file",
                &mut |event| events.push(event),
            )
            .unwrap();
            assert_eq!(result, source);
            assert_eq!(events[0].completed, 0);
            assert_eq!(events.last().unwrap().completed, source.len() as u64);
            assert!(
                events
                    .iter()
                    .all(|event| event.total == total && event.unit == "bytes")
            );
            assert!(
                events
                    .windows(2)
                    .all(|pair| pair[0].completed < pair[1].completed)
            );
            assert!(
                events.len() < 20,
                "byte callbacks must not fire for every read"
            );
        }
        let mut events = Vec::new();
        let result = read_with_limit_and_progress(
            &b"123456"[..],
            5,
            None,
            "Reading playlist file",
            &mut |event| events.push(event),
        );
        assert!(result.is_err());
        assert!(events.iter().all(|event| event.completed <= 5));
    }

    #[test]
    fn gzip_http_totals_are_compressed_bytes_and_chunked_totals_are_unknown() {
        use std::{
            io::{BufRead, BufReader, Write},
            net::TcpListener,
        };
        let body = vec![b'x'; 2 * 1024 * 1024 + 5];
        let mut encoder = flate2::write::GzEncoder::new(Vec::new(), flate2::Compression::default());
        encoder.write_all(&body).unwrap();
        let compressed = encoder.finish().unwrap();
        for chunked in [false, true] {
            let listener = TcpListener::bind("127.0.0.1:0").unwrap();
            let url = Url::parse(&format!(
                "http://{}/private?password=secret",
                listener.local_addr().unwrap()
            ))
            .unwrap();
            let response = compressed.clone();
            let server = std::thread::spawn(move || {
                let (mut stream, _) = listener.accept().unwrap();
                stream.set_nonblocking(false).unwrap();
                stream
                    .set_read_timeout(Some(Duration::from_secs(5)))
                    .unwrap();
                let mut reader = BufReader::new(stream.try_clone().unwrap());
                loop {
                    let mut line = String::new();
                    reader.read_line(&mut line).unwrap();
                    if line == "\r\n" || line.is_empty() {
                        break;
                    }
                }
                if chunked {
                    write!(stream, "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\nContent-Encoding: gzip\r\nConnection: close\r\n\r\n{:x}\r\n", response.len()).unwrap();
                    stream.write_all(&response).unwrap();
                    stream.write_all(b"\r\n0\r\n\r\n").unwrap();
                } else {
                    write!(stream, "HTTP/1.1 200 OK\r\nContent-Length: {}\r\nContent-Encoding: gzip\r\nConnection: close\r\n\r\n", response.len()).unwrap();
                    stream.write_all(&response).unwrap();
                }
            });
            let mut events = Vec::new();
            assert_eq!(
                get_with_progress(
                    &client().unwrap(),
                    url,
                    "Downloading playlist",
                    &mut |event| events.push(event)
                )
                .unwrap(),
                body
            );
            server.join().unwrap();
            let download = events
                .iter()
                .rev()
                .find(|event| event.stage == "Downloading playlist")
                .unwrap();
            assert_eq!(download.completed, compressed.len() as u64);
            assert_eq!(
                download.total,
                if chunked {
                    None
                } else {
                    Some(compressed.len() as u64)
                }
            );
            let expanded = events.last().unwrap();
            assert_eq!(expanded.stage, "Decompressing provider data");
            assert_eq!(expanded.completed, body.len() as u64);
            assert_eq!(expanded.total, None);
            assert!(
                events
                    .iter()
                    .all(|event| !event.stage.contains("secret") && !event.stage.contains("http"))
            );
        }
    }

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
