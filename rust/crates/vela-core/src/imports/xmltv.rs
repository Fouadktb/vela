use crate::models::EpgProgram;
use anyhow::{Result, anyhow, bail};
use chrono::{NaiveDateTime, TimeZone, Utc};
use quick_xml::{Reader, events::Event};
use std::{
    collections::{BTreeMap, BTreeSet},
    io::BufRead,
};

const MAX_FIELD: usize = 1024 * 1024;

fn date(value: &str) -> Option<i64> {
    let mut parts = value.split_whitespace();
    let stamp = parts.next()?;
    if stamp.len() != 14 || !stamp.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    let naive = NaiveDateTime::parse_from_str(stamp, "%Y%m%d%H%M%S").ok()?;
    let offset = match parts.next() {
        None => 0,
        Some(offset) => {
            if offset.len() != 5
                || !matches!(offset.as_bytes()[0], b'+' | b'-')
                || !offset[1..].bytes().all(|b| b.is_ascii_digit())
            {
                return None;
            }
            let h: i64 = offset[1..3].parse().ok()?;
            let m: i64 = offset[3..5].parse().ok()?;
            if h > 23 || m > 59 {
                return None;
            }
            (h * 60 + m) * 60 * 1000 * if offset.starts_with('+') { 1 } else { -1 }
        }
    };
    Some(Utc.from_utc_datetime(&naive).timestamp_millis() - offset)
}

#[derive(Default)]
struct Programme {
    channel: String,
    start: Option<i64>,
    end: Option<i64>,
    title: String,
    description: String,
    category: String,
}

/// Pull parsing avoids retaining an XML DOM, even for multi-day guides.
pub fn parse(input: impl BufRead, provider_id: &str, now_ms: i64) -> Result<Vec<EpgProgram>> {
    let mut reader = Reader::from_reader(input);
    reader.config_mut().trim_text(false);
    let mut buffer = Vec::new();
    let mut channel: Option<String> = None;
    let mut programme: Option<Programme> = None;
    let mut aliases = BTreeMap::<String, BTreeSet<String>>::new();
    let mut programs = Vec::new();
    let mut field: Option<String> = None;
    let mut text = String::new();
    let from_ms = now_ms.saturating_sub(3 * 60 * 60 * 1000);
    let to_ms = now_ms.saturating_add(7 * 24 * 60 * 60 * 1000);
    loop {
        let event = reader
            .read_event_into(&mut buffer)
            .map_err(|_| anyhow!("Channel guide contains invalid XML"))?;
        match event {
            Event::DocType(_) => bail!("Channel guide document types are not supported"),
            Event::Start(ref node) => {
                let name = String::from_utf8_lossy(node.name().as_ref()).into_owned();
                if name == "channel" || name == "programme" {
                    let mut attrs = BTreeMap::new();
                    for attribute in node.attributes() {
                        let attribute = attribute
                            .map_err(|_| anyhow!("Channel guide contains invalid attributes"))?;
                        let value = attribute
                            .decode_and_unescape_value(reader.decoder())
                            .map_err(|_| anyhow!("Channel guide contains invalid attributes"))?;
                        attrs.insert(
                            String::from_utf8_lossy(attribute.key.as_ref()).into_owned(),
                            value.trim().to_owned(),
                        );
                    }
                    if name == "channel" {
                        channel = attrs.get("id").filter(|s| !s.is_empty()).cloned();
                        if let Some(id) = &channel {
                            aliases.entry(id.clone()).or_default().insert(id.clone());
                        }
                    } else {
                        programme = Some(Programme {
                            channel: attrs.get("channel").cloned().unwrap_or_default(),
                            start: attrs.get("start").and_then(|s| date(s)),
                            end: attrs.get("stop").and_then(|s| date(s)),
                            ..Default::default()
                        });
                    }
                } else if field.is_none()
                    && ((channel.is_some() && name == "display-name")
                        || (programme.is_some()
                            && matches!(name.as_str(), "title" | "desc" | "category")))
                {
                    field = Some(name);
                    text.clear();
                }
            }
            Event::Text(value) if field.is_some() => {
                let decoded = value
                    .xml_content()
                    .map_err(|_| anyhow!("Channel guide text could not be decoded"))?;
                text.push_str(&decoded);
            }
            Event::CData(value) if field.is_some() => {
                text.push_str(
                    &value
                        .decode()
                        .map_err(|_| anyhow!("Channel guide text could not be decoded"))?,
                );
            }
            Event::GeneralRef(value) if field.is_some() => {
                if let Some(ch) = value
                    .resolve_char_ref()
                    .map_err(|_| anyhow!("Channel guide contains invalid character references"))?
                {
                    text.push(ch);
                } else {
                    let name = value
                        .decode()
                        .map_err(|_| anyhow!("Channel guide text could not be decoded"))?;
                    text.push_str(match name.as_ref() {
                        "amp" => "&",
                        "lt" => "<",
                        "gt" => ">",
                        "apos" => "'",
                        "quot" => "\"",
                        _ => bail!("Channel guide contains an unknown XML entity"),
                    });
                }
            }
            Event::End(node) => {
                let name = String::from_utf8_lossy(node.name().as_ref()).into_owned();
                if field.as_deref() == Some(name.as_str()) {
                    let value = text.trim().to_owned();
                    if name == "display-name" {
                        if let Some(id) = &channel
                            && !value.is_empty()
                        {
                            let names = aliases.entry(id.clone()).or_default();
                            if names.len() >= 256 {
                                bail!("Channel guide has too many aliases for one channel");
                            }
                            names.insert(value);
                        }
                    } else if let Some(p) = &mut programme {
                        match name.as_str() {
                            "title" if p.title.is_empty() => p.title = value,
                            "desc" if p.description.is_empty() => p.description = value,
                            "category" if p.category.is_empty() => p.category = value,
                            _ => {}
                        }
                    }
                    field = None;
                    text.clear();
                }
                if name == "channel" {
                    channel = None;
                }
                if name == "programme"
                    && let Some(p) = programme.take()
                    && let (Some(start), Some(end)) = (p.start, p.end)
                    && !p.channel.is_empty()
                    && !p.title.is_empty()
                    && end > start
                    && end >= from_ms
                    && start <= to_ms
                {
                    if programs.len() >= 1_000_000 {
                        bail!("Channel guide contains too many programmes");
                    }
                    programs.push(EpgProgram {
                        provider_id: provider_id.into(),
                        channel_id: p.channel,
                        start_at: start,
                        end_at: end,
                        title: p.title,
                        description: if p.description.is_empty() {
                            None
                        } else {
                            Some(p.description)
                        },
                        category: if p.category.is_empty() {
                            None
                        } else {
                            Some(p.category)
                        },
                    });
                }
            }
            Event::Eof => break,
            _ => {}
        }
        if text.len() > MAX_FIELD {
            bail!("Channel guide text field exceeds the size limit");
        }
        buffer.clear();
    }
    let mut output = Vec::new();
    for program in programs {
        if let Some(names) = aliases.get(&program.channel_id) {
            for name in names {
                let mut alias = program.clone();
                alias.channel_id = name.clone();
                if output.len() >= 1_000_000 {
                    bail!("Expanded channel guide contains too many programmes");
                }
                output.push(alias);
            }
        } else {
            output.push(program);
        }
    }
    output.sort_by(|a, b| {
        a.channel_id
            .cmp(&b.channel_id)
            .then(a.start_at.cmp(&b.start_at))
    });
    Ok(output)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn filters_windows_decodes_entities_and_offsets() {
        let xml = r#"<tv><channel id="n"><display-name>News HD</display-name></channel><programme channel="n" start="20261113120000 +0200" stop="20261113130000 +0200"><title>News &amp; Weather</title><desc>Today&apos;s &#60;headlines&#62;</desc><category>News</category></programme><programme channel="n" start="20251113120000 +0200" stop="20251113130000 +0200"><title>Old</title></programme></tv>"#;
        let now = date("20261113100000 +0000").unwrap();
        let p = parse(xml.as_bytes(), "p", now).unwrap();
        assert_eq!(p.len(), 2);
        assert_eq!(p[0].title, "News & Weather");
        assert_eq!(p[0].description.as_deref(), Some("Today's <headlines>"));
        assert_eq!(p[0].start_at, now);
    }
    #[test]
    fn rejects_bad_dates_and_doctype() {
        assert!(date("20261399120000 +0200").is_none());
        assert!(parse("<!DOCTYPE tv><tv/>".as_bytes(), "p", 0).is_err());
    }
}
