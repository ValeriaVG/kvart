use facet::Facet;
use serde::{Deserialize, Serialize};

#[derive(Facet, Serialize, Deserialize, Clone, Copy, Debug, Default, PartialEq, Eq, Hash)]
#[repr(C)]
pub enum AlarmSoundId {
    #[default]
    GameUnlock,
    KalimbaDing,
    DoubleBell,
}

impl AlarmSoundId {
    /// Bundle resource name used by the shell to locate the asset.
    #[must_use]
    pub fn asset(self) -> &'static str {
        match self {
            AlarmSoundId::GameUnlock => "game-ui-level-unlock-om-fx-1-1-00-05",
            AlarmSoundId::KalimbaDing => "ding-kalimba-strike-tomas-herudek-1-00-05",
            AlarmSoundId::DoubleBell => "message-notification-double-bell-the-foundation-1-00-02",
        }
    }
}

pub const ALL: [AlarmSoundId; 3] = [
    AlarmSoundId::GameUnlock,
    AlarmSoundId::KalimbaDing,
    AlarmSoundId::DoubleBell,
];

#[derive(Facet, Serialize, Deserialize, Clone, Copy, Debug, Default, PartialEq, Eq, Hash)]
#[repr(C)]
pub enum Language {
    #[default]
    System,
    En,
    Sv,
    Fr,
    De,
}

pub const ALL_LANGUAGES: [Language; 5] = [
    Language::System,
    Language::En,
    Language::Sv,
    Language::Fr,
    Language::De,
];

pub struct Model {
    pub sound_enabled: bool,
    pub vibration_enabled: bool,
    pub selected_sound: AlarmSoundId,
    pub language: Language,
}

impl Default for Model {
    fn default() -> Self {
        Self {
            sound_enabled: true,
            vibration_enabled: true,
            selected_sound: AlarmSoundId::GameUnlock,
            language: Language::System,
        }
    }
}

#[derive(Facet, Serialize, Deserialize, Clone, Debug)]
#[repr(C)]
pub enum SettingsEvent {
    SetSoundEnabled(bool),
    SetVibrationEnabled(bool),
    SelectSound(AlarmSoundId),
    SetLanguage(Language),
}

pub type Event = SettingsEvent;

#[derive(Facet, Serialize, Deserialize, Clone, Default)]
pub struct AlarmSoundView {
    pub id: AlarmSoundId,
    pub asset: String,
    pub selected: bool,
}

#[derive(Facet, Serialize, Deserialize, Clone, Default)]
pub struct LanguageView {
    pub id: Language,
    pub selected: bool,
}

#[derive(Facet, Serialize, Deserialize, Clone, Default)]
pub struct SettingsView {
    pub sound_enabled: bool,
    pub vibration_enabled: bool,
    pub selected_sound: AlarmSoundId,
    pub sounds: Vec<AlarmSoundView>,
    pub language: Language,
    pub languages: Vec<LanguageView>,
}

pub fn handle(model: &mut Model, event: &Event) {
    match *event {
        Event::SetSoundEnabled(v) => model.sound_enabled = v,
        Event::SetVibrationEnabled(v) => model.vibration_enabled = v,
        Event::SelectSound(id) => model.selected_sound = id,
        Event::SetLanguage(lang) => model.language = lang,
    }
}

impl From<&Model> for SettingsView {
    fn from(m: &Model) -> Self {
        let sounds = ALL
            .iter()
            .map(|&id| AlarmSoundView {
                id,
                asset: id.asset().to_string(),
                selected: m.selected_sound == id,
            })
            .collect();
        let languages = ALL_LANGUAGES
            .iter()
            .map(|&id| LanguageView {
                id,
                selected: m.language == id,
            })
            .collect();
        SettingsView {
            sound_enabled: m.sound_enabled,
            vibration_enabled: m.vibration_enabled,
            selected_sound: m.selected_sound,
            sounds,
            language: m.language,
            languages,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults() {
        let m = Model::default();
        assert!(m.sound_enabled);
        assert!(m.vibration_enabled);
        assert_eq!(m.selected_sound, AlarmSoundId::GameUnlock);
        assert_eq!(m.language, Language::System);
    }

    #[test]
    fn toggles() {
        let mut m = Model::default();
        handle(&mut m, &Event::SetSoundEnabled(false));
        handle(&mut m, &Event::SetVibrationEnabled(false));
        assert!(!m.sound_enabled);
        assert!(!m.vibration_enabled);
    }

    #[test]
    fn select_sound() {
        let mut m = Model::default();
        handle(&mut m, &Event::SelectSound(AlarmSoundId::DoubleBell));
        assert_eq!(m.selected_sound, AlarmSoundId::DoubleBell);
    }

    #[test]
    fn set_language() {
        let mut m = Model::default();
        handle(&mut m, &Event::SetLanguage(Language::Sv));
        assert_eq!(m.language, Language::Sv);
    }

    #[test]
    fn view_marks_selected() {
        let mut m = Model::default();
        handle(&mut m, &Event::SelectSound(AlarmSoundId::KalimbaDing));
        handle(&mut m, &Event::SetLanguage(Language::Fr));
        let v = SettingsView::from(&m);
        assert_eq!(v.sounds.len(), 3);
        assert!(!v.sounds[0].selected);
        assert!(v.sounds[1].selected);
        assert!(!v.sounds[2].selected);
        assert_eq!(v.languages.len(), 5);
        assert!(v.languages.iter().find(|l| l.id == Language::Fr).unwrap().selected);
    }
}
