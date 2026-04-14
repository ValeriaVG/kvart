use facet::Facet;
use serde::{Deserialize, Serialize};

use crate::{
    settings::{self, AlarmSoundId, Language},
    themes::{self, ThemeId},
    timer,
};

/// Snapshot of persistable user state. The shell reads this from
/// `ViewModel.persisted` on each render and writes it to platform storage; on
/// launch it emits `Event::Hydrate(PersistedState)` to restore.
#[derive(Facet, Serialize, Deserialize, Clone, Debug, PartialEq, Eq)]
pub struct PersistedState {
    pub selected_theme: ThemeId,
    pub purchased_themes: Vec<ThemeId>,
    pub duration_seconds: u32,
    pub sound_enabled: bool,
    pub vibration_enabled: bool,
    pub selected_sound: AlarmSoundId,
    pub language: Language,
}

impl Default for PersistedState {
    fn default() -> Self {
        Self::snapshot(
            &timer::Model::default(),
            &themes::Model::default(),
            &settings::Model::default(),
        )
    }
}

impl PersistedState {
    #[must_use]
    pub fn snapshot(
        timer: &timer::Model,
        themes: &themes::Model,
        settings: &settings::Model,
    ) -> Self {
        Self {
            selected_theme: themes.selected,
            purchased_themes: themes.purchased.clone(),
            duration_seconds: timer.seconds_total,
            sound_enabled: settings.sound_enabled,
            vibration_enabled: settings.vibration_enabled,
            selected_sound: settings.selected_sound,
            language: settings.language,
        }
    }
}

/// Apply a hydrated snapshot onto the live domain models. Only applies when
/// the timer is idle — we never clobber a running timer mid-session.
pub fn apply(
    state: &PersistedState,
    timer: &mut timer::Model,
    themes: &mut themes::Model,
    settings: &mut settings::Model,
) {
    if timer.status == timer::Status::Idle {
        timer.seconds_total = state.duration_seconds;
    }

    let mut purchased = state.purchased_themes.clone();
    if !purchased.contains(&ThemeId::Modern) {
        purchased.push(ThemeId::Modern);
    }
    themes.purchased = purchased;

    themes.selected = if themes.is_locked(state.selected_theme) {
        ThemeId::Modern
    } else {
        state.selected_theme
    };

    settings.sound_enabled = state.sound_enabled;
    settings.vibration_enabled = state.vibration_enabled;
    settings.selected_sound = state.selected_sound;
    settings.language = state.language;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn snapshot_reflects_models() {
        let mut themes = themes::Model::default();
        themes.purchased.push(ThemeId::Blaze);
        themes.selected = ThemeId::Blaze;
        let mut settings = settings::Model::default();
        settings.sound_enabled = false;
        settings.selected_sound = AlarmSoundId::DoubleBell;
        let mut timer = timer::Model::default();
        timer.seconds_total = 120;

        let snap = PersistedState::snapshot(&timer, &themes, &settings);
        assert_eq!(snap.selected_theme, ThemeId::Blaze);
        assert!(snap.purchased_themes.contains(&ThemeId::Blaze));
        assert_eq!(snap.duration_seconds, 120);
        assert!(!snap.sound_enabled);
        assert_eq!(snap.selected_sound, AlarmSoundId::DoubleBell);
    }

    #[test]
    fn apply_restores_all_fields_when_idle() {
        let snap = PersistedState {
            selected_theme: ThemeId::Blaze,
            purchased_themes: vec![ThemeId::Blaze],
            duration_seconds: 300,
            sound_enabled: false,
            vibration_enabled: false,
            selected_sound: AlarmSoundId::KalimbaDing,
            language: Language::System,
        };
        let mut timer = timer::Model::default();
        let mut themes = themes::Model::default();
        let mut settings = settings::Model::default();
        apply(&snap, &mut timer, &mut themes, &mut settings);
        assert_eq!(timer.seconds_total, 300);
        assert_eq!(themes.selected, ThemeId::Blaze);
        assert!(themes.purchased.contains(&ThemeId::Modern));
        assert!(!settings.sound_enabled);
        assert_eq!(settings.selected_sound, AlarmSoundId::KalimbaDing);
    }

    #[test]
    fn apply_ignores_duration_while_running() {
        let snap = PersistedState {
            duration_seconds: 42,
            ..PersistedState::default()
        };
        let mut timer = timer::Model::default();
        timer::handle(&mut timer, &timer::Event::Start(0));
        let mut themes = themes::Model::default();
        let mut settings = settings::Model::default();
        apply(&snap, &mut timer, &mut themes, &mut settings);
        assert_eq!(timer.seconds_total, 900);
    }

    #[test]
    fn apply_falls_back_to_modern_if_selected_locked() {
        let snap = PersistedState {
            selected_theme: ThemeId::Blaze,
            purchased_themes: vec![],
            ..PersistedState::default()
        };
        let mut timer = timer::Model::default();
        let mut themes = themes::Model::default();
        let mut settings = settings::Model::default();
        apply(&snap, &mut timer, &mut themes, &mut settings);
        assert_eq!(themes.selected, ThemeId::Modern);
    }
}
