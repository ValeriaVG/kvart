use crux_core::capability::Operation;
use facet::Facet;
use serde::{Deserialize, Serialize};

use crate::settings;

/// Side-effects the shell performs for alarm-related lifecycle.
///
/// - `Fire` — play the alarm sound + haptic immediately (timer completed while
///   the app was foregrounded).
/// - `Schedule` — ask the OS to fire a local notification at `at_ms` (wall
///   clock, epoch ms). Used when the app enters the background while a timer
///   is running so the alarm still lands on time.
/// - `Cancel` — drop any pending scheduled notification (timer was paused,
///   reset, or we came back to foreground in time).
#[derive(Facet, Clone, Serialize, Deserialize, Debug, PartialEq, Eq)]
#[repr(C)]
pub enum AlarmOperation {
    Fire {
        sound_asset: String,
        vibrate: bool,
    },
    Schedule {
        at_ms: u64,
        sound_asset: String,
        vibrate: bool,
    },
    Cancel,
}

impl Operation for AlarmOperation {
    type Output = ();
}

fn sound_asset(settings: &settings::Model) -> String {
    if settings.sound_enabled {
        settings.selected_sound.asset().to_string()
    } else {
        String::new()
    }
}

#[must_use]
pub fn fire(settings: &settings::Model) -> AlarmOperation {
    AlarmOperation::Fire {
        sound_asset: sound_asset(settings),
        vibrate: settings.vibration_enabled,
    }
}

#[must_use]
pub fn schedule(at_ms: u64, settings: &settings::Model) -> AlarmOperation {
    AlarmOperation::Schedule {
        at_ms,
        sound_asset: sound_asset(settings),
        vibrate: settings.vibration_enabled,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::settings::{AlarmSoundId, Model};

    #[test]
    fn fire_respects_sound_toggle() {
        let mut m = Model::default();
        m.selected_sound = AlarmSoundId::DoubleBell;
        let AlarmOperation::Fire {
            sound_asset,
            vibrate,
        } = fire(&m)
        else {
            panic!()
        };
        assert_eq!(sound_asset, AlarmSoundId::DoubleBell.asset());
        assert!(vibrate);

        m.sound_enabled = false;
        let AlarmOperation::Fire { sound_asset, .. } = fire(&m) else {
            panic!()
        };
        assert_eq!(sound_asset, "");
    }

    #[test]
    fn schedule_carries_end_time() {
        let m = Model::default();
        let AlarmOperation::Schedule { at_ms, .. } = schedule(12_345, &m) else {
            panic!()
        };
        assert_eq!(at_ms, 12_345);
    }
}
