//! Manual GitHub release discovery. This module never downloads or installs an app.
use anyhow::{Result, anyhow, bail, ensure};
use reqwest::blocking::Client;
use semver::Version;
use serde_json::Value;
use std::{io::Read, sync::LazyLock, time::Duration};
use url::Url;

const RELEASE_API: &str = "https://api.github.com/repos/Fouadktb/vela/releases/latest";
const RELEASE_FALLBACK: &str = "https://github.com/Fouadktb/vela/releases/latest";
const MAX_RESPONSE: u64 = 1024 * 1024;

#[derive(Clone, Debug)]
pub struct ReleaseInfo {
    pub current_version: String,
    pub latest_version: String,
    pub release_url: String,
    pub has_update: bool,
}

static CLIENT: LazyLock<std::result::Result<Client, &'static str>> = LazyLock::new(|| {
    Client::builder()
        .connect_timeout(Duration::from_secs(10))
        .timeout(Duration::from_secs(10))
        // The endpoint is fixed. A redirect is reported, rather than following
        // an unexpected external service or a repository transfer silently.
        .redirect(reqwest::redirect::Policy::none())
        .user_agent(concat!("Vela/", env!("CARGO_PKG_VERSION")))
        .build()
        .map_err(|_| "Could not initialize update checks")
});

/// Run on a background worker. Only the fixed public repository is contacted.
pub fn check() -> Result<ReleaseInfo> {
    let client = CLIENT.as_ref().map_err(|message| anyhow!(*message))?;
    let response = client
        .get(RELEASE_API)
        .header(reqwest::header::ACCEPT, "application/vnd.github+json")
        .header("X-GitHub-Api-Version", "2022-11-28")
        .send()
        .map_err(|_| anyhow!("GitHub update check could not connect or timed out"))?;
    ensure!(
        response.status() == reqwest::StatusCode::OK,
        "GitHub returned HTTP {}",
        response.status().as_u16()
    );
    if response
        .content_length()
        .is_some_and(|size| size > MAX_RESPONSE)
    {
        bail!("GitHub update response exceeds the size limit");
    }
    let bytes = read_bounded(response)?;
    parse_release(&bytes, env!("CARGO_PKG_VERSION"))
}

fn read_bounded(reader: impl Read) -> Result<Vec<u8>> {
    let mut bytes = Vec::new();
    reader
        .take(MAX_RESPONSE + 1)
        .read_to_end(&mut bytes)
        .map_err(|_| anyhow!("GitHub update response could not be read"))?;
    ensure!(
        bytes.len() as u64 <= MAX_RESPONSE,
        "GitHub update response exceeds the size limit"
    );
    Ok(bytes)
}

fn version(tag: &str) -> Result<Version> {
    let tag = tag.trim();
    let normalized = tag
        .strip_prefix('v')
        .or_else(|| tag.strip_prefix('V'))
        .unwrap_or(tag);
    Version::parse(normalized).map_err(|_| anyhow!("Latest release has an invalid version tag"))
}

fn release_url(value: Option<&str>) -> String {
    let Some(mut url) = value.and_then(|text| Url::parse(text.trim()).ok()) else {
        return RELEASE_FALLBACK.into();
    };
    let segments: Vec<_> = url
        .path_segments()
        .map(Iterator::collect)
        .unwrap_or_default();
    let valid = url.scheme() == "https"
        && url.host_str() == Some("github.com")
        && url.port().is_none()
        && url.username().is_empty()
        && url.password().is_none()
        && segments.len() >= 4
        && segments[0].eq_ignore_ascii_case("Fouadktb")
        && segments[1].eq_ignore_ascii_case("vela")
        && segments[2] == "releases"
        && !segments[3].is_empty();
    if !valid {
        return RELEASE_FALLBACK.into();
    }
    url.set_query(None);
    url.set_fragment(None);
    url.into()
}

fn parse_release(bytes: &[u8], current: &str) -> Result<ReleaseInfo> {
    ensure!(
        bytes.len() as u64 <= MAX_RESPONSE,
        "GitHub update response exceeds the size limit"
    );
    let body: Value = serde_json::from_slice(bytes)
        .map_err(|_| anyhow!("GitHub returned invalid release JSON"))?;
    ensure!(
        body.is_object(),
        "GitHub returned an invalid release response"
    );
    let tag = body
        .get("tag_name")
        .and_then(Value::as_str)
        .map(str::trim)
        .filter(|tag| !tag.is_empty())
        .ok_or_else(|| anyhow!("Latest release has no version tag"))?;
    let latest = version(tag)?;
    let current_parsed =
        version(current).map_err(|_| anyhow!("Current application version is invalid"))?;
    Ok(ReleaseInfo {
        current_version: current.into(),
        latest_version: tag.into(),
        release_url: release_url(body.get("html_url").and_then(Value::as_str)),
        // SemVer build metadata does not affect precedence. Prerelease tags
        // remain valid versions and compare correctly against stable releases.
        has_update: latest.cmp_precedence(&current_parsed).is_gt(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    fn parse(tag: &str, current: &str) -> ReleaseInfo {
        parse_release(json!({"tag_name":tag,"html_url":format!("https://github.com/Fouadktb/vela/releases/tag/{tag}")}).to_string().as_bytes(),current).unwrap()
    }
    #[test]
    fn compares_releases_without_downgrades_or_build_metadata_updates() {
        assert!(parse("v0.6.0", "0.5.0").has_update);
        assert!(!parse("v0.4.8", "0.5.0").has_update);
        assert!(!parse("V0.5.0", "0.5.0").has_update);
        assert!(!parse("v0.5.0+new-build", "0.5.0+old-build").has_update);
        assert_eq!(parse(" v0.6.0 ", "0.5.0").latest_version, "v0.6.0");
    }
    #[test]
    fn handles_prerelease_precedence_correctly() {
        assert!(!parse("v0.5.0-beta.2", "0.5.0").has_update);
        assert!(parse("v0.5.0", "0.5.0-beta.2").has_update);
        assert!(parse("v0.6.0-rc.1", "0.5.0").has_update);
        assert!(parse("v0.6.0-beta.11", "0.6.0-beta.2").has_update);
    }
    #[test]
    fn rejects_bad_json_missing_and_malformed_tags_without_echoing_data() {
        for bytes in [
            b"not JSON".as_slice(),
            b"[]",
            b"{}",
            br#"{"tag_name":42}"#,
            br#"{"tag_name":"credential-secret"}"#,
            br#"{"tag_name":"v0.5"}"#,
            br#"{"tag_name":"v0.05.0"}"#,
        ] {
            let error = parse_release(bytes, "0.5.0").unwrap_err().to_string();
            assert!(!error.contains("credential-secret"));
        }
    }
    #[test]
    fn restricts_external_release_urls_to_the_repository() {
        let expected = "https://github.com/Fouadktb/vela/releases/tag/v0.6.0";
        assert_eq!(release_url(Some(expected)), expected);
        for url in [
            "http://github.com/Fouadktb/vela/releases/tag/v0.6.0",
            "https://evil.invalid/Fouadktb/vela/releases/tag/v0.6.0",
            "https://github.com.evil.invalid/Fouadktb/vela/releases/latest",
            "https://github.com/other/vela/releases/latest",
            "https://github.com/Fouadktb/other/releases/latest",
            "https://github.com/Fouadktb/vela/releases-evil/tag/x",
            "https://user@github.com/Fouadktb/vela/releases/latest",
            "https://github.com:444/Fouadktb/vela/releases/latest",
            "javascript:alert(1)",
        ] {
            assert_eq!(release_url(Some(url)), RELEASE_FALLBACK);
        }
        assert_eq!(release_url(None), RELEASE_FALLBACK);
        assert_eq!(
            release_url(Some(&format!(
                "{expected}?redirect=https://evil.invalid#fragment"
            ))),
            expected
        );
    }
    #[test]
    fn caps_response_streams_even_without_a_length_header() {
        assert!(read_bounded(std::io::repeat(b'x').take(MAX_RESPONSE + 1)).is_err());
        assert_eq!(read_bounded(b"{}".as_slice()).unwrap(), b"{}");
    }
}
