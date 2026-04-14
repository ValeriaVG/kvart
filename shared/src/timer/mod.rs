use facet::Facet;
use serde::{Deserialize, Serialize};

#[derive(Facet, Serialize, Deserialize, Clone, Copy, Debug, Default, PartialEq, Eq)]
#[repr(C)]
pub enum Status {
    #[default]
    Idle,
    Running,
    Paused,
    Completed,
}

#[derive(Clone, Debug)]
pub struct Interval {
    pub start_ms: u64,
    pub end_ms: Option<u64>,
}

impl Interval {
    fn duration_ms(&self, now_ms: u64) -> u64 {
        self.end_ms.unwrap_or(now_ms).saturating_sub(self.start_ms)
    }
}

pub struct Model {
    pub seconds_total: u32,
    pub status: Status,
    pub intervals: Vec<Interval>,
    pub last_tick_ms: u64,
}

impl Default for Model {
    fn default() -> Self {
        Self {
            seconds_total: 15 * 60,
            status: Status::Idle,
            intervals: Vec::new(),
            last_tick_ms: 0,
        }
    }
}

#[derive(Facet, Serialize, Deserialize, Clone, Debug)]
#[repr(C)]
pub enum TimerEvent {
    SetDuration(u32),
    SetFromText(String),
    Start(u64),
    Pause(u64),
    Reset,
    Tick(u64),
}

/// Parse strings like `15m`, `60s`, `1h`, `1.5h`, `1h30m`, `15m30s` into
/// total seconds. Components must appear in `h`→`m`→`s` order, each at
/// most once. Returns `None` for anything unrecognized. Clamps to
/// [59s, 180m].
#[must_use]
#[allow(clippy::cast_possible_truncation, clippy::cast_sign_loss)]
pub fn parse_duration(text: &str) -> Option<u32> {
    let mut rest = text.trim();
    let mut total: f64 = 0.0;
    let mut last_rank: u8 = u8::MAX;
    let mut seen_any = false;
    while !rest.is_empty() {
        let num_end = rest
            .find(|c: char| !c.is_ascii_digit() && c != '.')
            .unwrap_or(0);
        if num_end == 0 {
            return None;
        }
        let value: f64 = rest[..num_end].parse().ok()?;
        rest = &rest[num_end..];
        let unit = rest.chars().next()?;
        rest = &rest[unit.len_utf8()..];
        let (mult, rank) = match unit {
            's' | 'S' => (1.0_f64, 1_u8),
            'm' | 'M' => (60.0, 2),
            'h' | 'H' => (3600.0, 3),
            _ => return None,
        };
        if rank >= last_rank {
            return None;
        }
        last_rank = rank;
        total += value * mult;
        seen_any = true;
    }
    if !seen_any {
        return None;
    }
    let seconds = total.round().max(0.0) as u64;
    let seconds: u32 = seconds.try_into().ok()?;
    Some(seconds.clamp(59, 180 * 60))
}

pub type Event = TimerEvent;

#[derive(Facet, Serialize, Deserialize, Clone, Default)]
pub struct TimerView {
    pub seconds_total: u32,
    pub seconds_elapsed: u32,
    pub status: Status,
}

impl Model {
    fn elapsed_ms(&self, now_ms: u64) -> u64 {
        self.intervals.iter().map(|i| i.duration_ms(now_ms)).sum()
    }

    /// Milliseconds left before completion given `now_ms`. Saturates at zero.
    #[must_use]
    pub fn remaining_ms(&self, now_ms: u64) -> u64 {
        let total_ms = u64::from(self.seconds_total) * 1000;
        total_ms.saturating_sub(self.elapsed_ms(now_ms))
    }

    fn close_open_interval(&mut self, now_ms: u64) {
        if let Some(last) = self.intervals.last_mut() {
            if last.end_ms.is_none() {
                last.end_ms = Some(now_ms);
            }
        }
    }
}

/// Pure update. Returns `true` when the timer has just completed, so the
/// composing app can emit a completion effect (sound, notification).
pub fn handle(model: &mut Model, event: &Event) -> bool {
    match event {
        Event::SetDuration(seconds) => {
            if model.status == Status::Running {
                return false;
            }
            model.seconds_total = *seconds;
            model.status = Status::Idle;
            model.intervals.clear();
            false
        }
        Event::SetFromText(text) => {
            if let Some(seconds) = parse_duration(text) {
                if model.status != Status::Running {
                    model.seconds_total = seconds;
                    model.status = Status::Idle;
                    model.intervals.clear();
                }
            }
            false
        }
        &Event::Start(now_ms) => {
            match model.status {
                Status::Running => return false,
                Status::Completed => {
                    model.intervals.clear();
                }
                _ => {}
            }
            model.status = Status::Running;
            model.last_tick_ms = now_ms;
            model.intervals.push(Interval {
                start_ms: now_ms,
                end_ms: None,
            });
            false
        }
        &Event::Pause(now_ms) => {
            if model.status != Status::Running {
                return false;
            }
            model.close_open_interval(now_ms);
            model.status = Status::Paused;
            model.last_tick_ms = now_ms;
            false
        }
        Event::Reset => {
            model.status = Status::Idle;
            model.intervals.clear();
            model.last_tick_ms = 0;
            false
        }
        &Event::Tick(now_ms) => {
            model.last_tick_ms = now_ms;
            if model.status != Status::Running {
                return false;
            }
            let total_ms = u64::from(model.seconds_total) * 1000;
            if model.elapsed_ms(now_ms) >= total_ms {
                model.close_open_interval(now_ms);
                model.status = Status::Completed;
                return true;
            }
            false
        }
    }
}

impl From<&Model> for TimerView {
    fn from(m: &Model) -> Self {
        let now_ms = m.last_tick_ms;
        let elapsed_ms = m.elapsed_ms(now_ms);
        let total_ms = u64::from(m.seconds_total) * 1000;
        let clamped = elapsed_ms.min(total_ms);
        let seconds_elapsed = u32::try_from(clamped / 1000).unwrap_or(u32::MAX);
        TimerView {
            seconds_total: m.seconds_total,
            seconds_elapsed,
            status: m.status,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_to_idle_15_minutes() {
        let m = Model::default();
        assert_eq!(m.status, Status::Idle);
        assert_eq!(m.seconds_total, 900);
        assert_eq!(TimerView::from(&m).seconds_elapsed, 0);
    }

    #[test]
    fn set_duration_resets_when_not_running() {
        let mut m = Model::default();
        handle(&mut m, &Event::SetDuration(60));
        assert_eq!(m.seconds_total, 60);
        assert_eq!(m.status, Status::Idle);
    }

    #[test]
    fn set_duration_ignored_while_running() {
        let mut m = Model::default();
        handle(&mut m, &Event::Start(1_000));
        handle(&mut m, &Event::SetDuration(60));
        assert_eq!(m.seconds_total, 900);
        assert_eq!(m.status, Status::Running);
    }

    #[test]
    fn start_pause_accumulate_elapsed() {
        let mut m = Model::default();
        handle(&mut m, &Event::SetDuration(10));
        handle(&mut m, &Event::Start(1_000));
        handle(&mut m, &Event::Tick(4_000));
        assert_eq!(TimerView::from(&m).seconds_elapsed, 3);
        handle(&mut m, &Event::Pause(4_000));
        handle(&mut m, &Event::Tick(10_000));
        assert_eq!(TimerView::from(&m).seconds_elapsed, 3);
        handle(&mut m, &Event::Start(10_000));
        handle(&mut m, &Event::Tick(12_000));
        assert_eq!(TimerView::from(&m).seconds_elapsed, 5);
    }

    #[test]
    fn tick_completes_and_reports() {
        let mut m = Model::default();
        handle(&mut m, &Event::SetDuration(2));
        handle(&mut m, &Event::Start(0));
        let completed = handle(&mut m, &Event::Tick(3_000));
        assert!(completed);
        assert_eq!(m.status, Status::Completed);
        assert_eq!(TimerView::from(&m).seconds_elapsed, 2);
    }

    #[test]
    fn start_after_completion_restarts() {
        let mut m = Model::default();
        handle(&mut m, &Event::SetDuration(1));
        handle(&mut m, &Event::Start(0));
        handle(&mut m, &Event::Tick(2_000));
        assert_eq!(m.status, Status::Completed);
        handle(&mut m, &Event::Start(5_000));
        assert_eq!(m.status, Status::Running);
        assert_eq!(m.intervals.len(), 1);
    }

    #[test]
    fn parses_durations() {
        assert_eq!(parse_duration("15m"), Some(900));
        assert_eq!(parse_duration("60s"), Some(60));
        assert_eq!(parse_duration("1h"), Some(3600));
        assert_eq!(parse_duration(" 2H "), Some(7200));
        assert_eq!(parse_duration("30s"), Some(59));
        assert_eq!(parse_duration("5h"), Some(10800));
        assert_eq!(parse_duration("999m"), Some(10800));
        assert_eq!(parse_duration("1.5h"), Some(5400));
        assert_eq!(parse_duration("1h30m"), Some(5400));
        assert_eq!(parse_duration("15m30s"), Some(930));
        assert_eq!(parse_duration("30s15m"), None);
        assert_eq!(parse_duration("1h1h"), None);
        assert_eq!(parse_duration("15"), None);
        assert_eq!(parse_duration(""), None);
        assert_eq!(parse_duration("xm"), None);
        assert_eq!(parse_duration("15d"), None);
    }

    #[test]
    fn set_from_text_updates_seconds() {
        let mut m = Model::default();
        handle(&mut m, &Event::SetFromText("2m".into()));
        assert_eq!(m.seconds_total, 120);
        assert_eq!(m.status, Status::Idle);
    }

    #[test]
    fn set_from_text_invalid_is_ignored() {
        let mut m = Model::default();
        handle(&mut m, &Event::SetFromText("banana".into()));
        assert_eq!(m.seconds_total, 900);
    }

    #[test]
    fn set_from_text_ignored_while_running() {
        let mut m = Model::default();
        handle(&mut m, &Event::Start(0));
        handle(&mut m, &Event::SetFromText("30s".into()));
        assert_eq!(m.seconds_total, 900);
        assert_eq!(m.status, Status::Running);
    }

    #[test]
    fn reset_clears_everything() {
        let mut m = Model::default();
        handle(&mut m, &Event::Start(1_000));
        handle(&mut m, &Event::Tick(3_000));
        handle(&mut m, &Event::Reset);
        assert_eq!(m.status, Status::Idle);
        assert!(m.intervals.is_empty());
    }
}
