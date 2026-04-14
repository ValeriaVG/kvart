use facet::Facet;
use serde::{Deserialize, Serialize};

#[derive(Facet, Serialize, Deserialize, Clone, Copy, Debug, Default, PartialEq, Eq, Hash)]
#[repr(C)]
pub enum ThemeId {
    #[default]
    Modern,
    VintageAmber,
    Blaze,
}

impl ThemeId {
    #[must_use]
    pub fn product_id(self) -> Option<&'static str> {
        match self {
            ThemeId::Modern => None,
            ThemeId::VintageAmber => Some("theme_vintage_amber"),
            ThemeId::Blaze => Some("theme_blaze"),
        }
    }
}

pub const ALL: [ThemeId; 3] = [ThemeId::Modern, ThemeId::VintageAmber, ThemeId::Blaze];

pub struct Model {
    pub selected: ThemeId,
    pub purchased: Vec<ThemeId>,
}

impl Default for Model {
    fn default() -> Self {
        Self {
            selected: ThemeId::Modern,
            purchased: vec![ThemeId::Modern],
        }
    }
}

impl Model {
    #[must_use]
    pub fn is_locked(&self, id: ThemeId) -> bool {
        id.product_id().is_some() && !self.purchased.contains(&id)
    }
}

#[derive(Facet, Serialize, Deserialize, Clone, Debug)]
#[repr(C)]
pub enum ThemesEvent {
    Select(ThemeId),
    SetPurchased { id: ThemeId, purchased: bool },
}

pub type Event = ThemesEvent;

#[derive(Facet, Serialize, Deserialize, Clone, Default)]
pub struct ThemeCardView {
    pub id: ThemeId,
    pub product_id: Option<String>,
    pub locked: bool,
    pub selected: bool,
}

#[derive(Facet, Serialize, Deserialize, Clone, Default)]
pub struct ThemesView {
    pub selected: ThemeId,
    pub themes: Vec<ThemeCardView>,
}

pub fn handle(model: &mut Model, event: &Event) {
    match *event {
        Event::Select(id) => {
            if !model.is_locked(id) {
                model.selected = id;
            }
        }
        Event::SetPurchased { id, purchased } => {
            model.purchased.retain(|x| *x != id);
            if purchased {
                model.purchased.push(id);
            }
        }
    }
}

impl From<&Model> for ThemesView {
    fn from(m: &Model) -> Self {
        let themes = ALL
            .iter()
            .map(|&id| ThemeCardView {
                id,
                product_id: id.product_id().map(str::to_string),
                locked: m.is_locked(id),
                selected: m.selected == id,
            })
            .collect();
        ThemesView {
            selected: m.selected,
            themes,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_only_unlocked() {
        let m = Model::default();
        assert!(!m.is_locked(ThemeId::Modern));
        assert!(m.is_locked(ThemeId::Blaze));
        assert!(m.is_locked(ThemeId::VintageAmber));
    }

    #[test]
    fn select_locked_theme_is_ignored() {
        let mut m = Model::default();
        handle(&mut m, &Event::Select(ThemeId::Blaze));
        assert_eq!(m.selected, ThemeId::Modern);
    }

    #[test]
    fn purchase_unlocks_and_allows_select() {
        let mut m = Model::default();
        handle(
            &mut m,
            &Event::SetPurchased {
                id: ThemeId::Blaze,
                purchased: true,
            },
        );
        assert!(!m.is_locked(ThemeId::Blaze));
        handle(&mut m, &Event::Select(ThemeId::Blaze));
        assert_eq!(m.selected, ThemeId::Blaze);
    }

    #[test]
    fn repeated_purchase_does_not_duplicate() {
        let mut m = Model::default();
        let ev = Event::SetPurchased {
            id: ThemeId::Blaze,
            purchased: true,
        };
        handle(&mut m, &ev);
        handle(&mut m, &ev);
        assert_eq!(m.purchased.iter().filter(|&&x| x == ThemeId::Blaze).count(), 1);
    }

    #[test]
    fn revoking_purchase_relocks_and_keeps_selection_untouched() {
        let mut m = Model::default();
        handle(
            &mut m,
            &Event::SetPurchased {
                id: ThemeId::Blaze,
                purchased: true,
            },
        );
        handle(&mut m, &Event::Select(ThemeId::Blaze));
        handle(
            &mut m,
            &Event::SetPurchased {
                id: ThemeId::Blaze,
                purchased: false,
            },
        );
        assert!(m.is_locked(ThemeId::Blaze));
        assert_eq!(m.selected, ThemeId::Blaze);
        handle(&mut m, &Event::Select(ThemeId::Blaze));
        assert_eq!(m.selected, ThemeId::Blaze);
    }

    #[test]
    fn view_projection_marks_selected_and_locked() {
        let m = Model::default();
        let v = ThemesView::from(&m);
        assert_eq!(v.themes.len(), 3);
        assert!(v.themes[0].selected);
        assert!(!v.themes[0].locked);
        assert!(v.themes[1].locked);
        assert!(v.themes[2].locked);
    }
}
