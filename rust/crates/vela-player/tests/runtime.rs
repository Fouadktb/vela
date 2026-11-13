//! Run with `VELA_MPV_LIBRARY=/path/to/libmpv cargo test -p vela-player --test runtime -- --ignored`.
use std::{
    fs, thread,
    time::{Duration, Instant},
};
use vela_player::{Player, PlayerState};

fn until(player: &Player, predicate: impl Fn(&PlayerState) -> bool) -> PlayerState {
    let deadline = Instant::now() + Duration::from_secs(8);
    loop {
        let state = player.snapshot();
        assert!(state.error.is_none(), "Playback error: {:?}", state.error);
        if predicate(&state) {
            return state;
        }
        assert!(
            Instant::now() < deadline,
            "Timed out waiting for playback state: {state:?}"
        );
        thread::sleep(Duration::from_millis(20));
    }
}

#[test]
#[ignore = "requires the packaged libmpv shared library"]
fn libmpv_loads_audio_and_applies_controls() {
    let mut player = Player::headless().expect("Load libmpv runtime");
    let path = std::env::temp_dir().join(format!("vela-player-smoke-{}.wav", std::process::id()));
    let bytes = 48_000u32 * 2 * 3;
    let mut wav = Vec::with_capacity(bytes as usize + 44);
    wav.extend(b"RIFF");
    wav.extend((bytes + 36).to_le_bytes());
    wav.extend(b"WAVEfmt ");
    wav.extend(16u32.to_le_bytes());
    wav.extend(1u16.to_le_bytes());
    wav.extend(1u16.to_le_bytes());
    wav.extend(48_000u32.to_le_bytes());
    wav.extend(96_000u32.to_le_bytes());
    wav.extend(2u16.to_le_bytes());
    wav.extend(16u16.to_le_bytes());
    wav.extend(b"data");
    wav.extend(bytes.to_le_bytes());
    wav.resize(bytes as usize + 44, 0);
    fs::write(&path, wav).unwrap();
    player.open(path.to_str().unwrap(), &[], None).unwrap();
    player.set_paused(true).unwrap();
    player.set_volume(37.).unwrap();
    player.set_muted(true).unwrap();
    player.set_speed(1.25).unwrap();
    let state = until(&player, |s| {
        s.duration > 2.9
            && s.paused
            && (s.volume - 37.).abs() < 0.01
            && s.muted
            && (s.speed - 1.25).abs() < 0.01
            && !s.tracks.is_empty()
    });
    assert!(state.tracks.iter().any(|t| t.kind == "audio" && t.selected));
    player.seek(1.).unwrap();
    until(&player, |s| (s.position - 1.).abs() < 0.15);
    player.set_muted(false).unwrap();
    until(&player, |s| !s.muted);
    player.select_track("audio", None).unwrap();
    until(&player, |s| {
        s.tracks.iter().all(|t| t.kind != "audio" || !t.selected)
    });
    player.select_track_auto("audio").unwrap();
    until(&player, |s| {
        s.tracks.iter().any(|t| t.kind == "audio" && t.selected)
    });
    player.select_track("audio", None).unwrap();
    until(&player, |s| {
        s.tracks.iter().all(|t| t.kind != "audio" || !t.selected)
    });
    player
        .open(
            path.to_str().unwrap(),
            &[("X-Vela-Smoke".into(), "commas,remain,valid".into())],
            Some(0.5),
        )
        .unwrap();
    player.set_paused(true).unwrap();
    until(&player, |s| {
        s.duration > 2.9
            && s.position >= 0.45
            && s.paused
            && s.tracks.iter().any(|t| t.kind == "audio" && t.selected)
    });
    player.seek(2.8).unwrap();
    player.set_paused(false).unwrap();
    until(&player, |s| s.ended);
    player.seek(0.0).unwrap();
    player.set_paused(false).unwrap();
    until(&player, |s| !s.ended && s.position < 1.0);
    assert!(player.set_speed(f64::NAN).is_err());
    assert!(player.seek(-1.).is_err());
    assert!(
        player
            .open(
                "unused",
                &[("Injected\r\nHeader".into(), "bad".into())],
                None
            )
            .is_err()
    );
    player
        .open("/vela-smoke-missing-file/does-not-exist.mp4", &[], None)
        .unwrap();
    let deadline = Instant::now() + Duration::from_secs(8);
    loop {
        let state = player.snapshot();
        if state.error.is_some() {
            assert!(!state.loading);
            break;
        }
        assert!(
            Instant::now() < deadline,
            "Missing-file playback error was not reported"
        );
        thread::sleep(Duration::from_millis(20));
    }
    player.stop().unwrap();
    player.shutdown_gl();
    fs::remove_file(path).unwrap();
}
