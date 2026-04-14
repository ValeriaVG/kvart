use crux_core::{
    macros::effect,
    render::{render, RenderOperation},
    App, Command,
};
use facet::Facet;
use serde::{Deserialize, Serialize};

use crate::{
    background, notification, notification::AlarmOperation, persistence,
    persistence::PersistedState, settings, themes, timer, timer::Status,
};

#[derive(Facet, Serialize, Deserialize, Clone, Debug)]
#[repr(C)]
pub enum Event {
    Timer(timer::TimerEvent),
    Themes(themes::ThemesEvent),
    Settings(settings::SettingsEvent),
    Background(background::BackgroundEvent),
    Hydrate(PersistedState),
}

#[effect(facet_typegen)]
#[derive(Debug)]
pub enum Effect {
    Render(RenderOperation),
    Alarm(AlarmOperation),
}

#[derive(Default)]
pub struct Model {
    pub timer: timer::Model,
    pub themes: themes::Model,
    pub settings: settings::Model,
}

fn alarm(op: AlarmOperation) -> Command<Effect, Event> {
    Command::notify_shell(op).into()
}

#[derive(Facet, Serialize, Deserialize, Clone, Default)]
pub struct ViewModel {
    pub timer: timer::TimerView,
    pub themes: themes::ThemesView,
    pub settings: settings::SettingsView,
    pub persisted: PersistedState,
}

#[derive(Default)]
pub struct Kvart;

impl App for Kvart {
    type Event = Event;
    type Model = Model;
    type ViewModel = ViewModel;
    type Effect = Effect;

    fn update(&self, event: Event, model: &mut Model) -> Command<Effect, Event> {
        let mut cmds: Vec<Command<Effect, Event>> = Vec::new();
        match event {
            Event::Timer(e) => {
                if timer::handle(&mut model.timer, &e) {
                    cmds.push(alarm(notification::fire(&model.settings)));
                }
            }
            Event::Themes(e) => themes::handle(&mut model.themes, &e),
            Event::Settings(e) => settings::handle(&mut model.settings, &e),
            Event::Background(background::Event::Enter(now_ms)) => {
                if model.timer.status == Status::Running {
                    let at_ms = now_ms.saturating_add(model.timer.remaining_ms(now_ms));
                    cmds.push(alarm(notification::schedule(at_ms, &model.settings)));
                }
            }
            Event::Hydrate(state) => {
                persistence::apply(
                    &state,
                    &mut model.timer,
                    &mut model.themes,
                    &mut model.settings,
                );
            }
            Event::Background(background::Event::Resume(now_ms)) => {
                cmds.push(alarm(AlarmOperation::Cancel));
                if timer::handle(&mut model.timer, &timer::Event::Tick(now_ms)) {
                    cmds.push(alarm(notification::fire(&model.settings)));
                }
            }
        }
        cmds.push(render());
        Command::all(cmds)
    }

    fn view(&self, model: &Model) -> ViewModel {
        ViewModel {
            timer: (&model.timer).into(),
            themes: (&model.themes).into(),
            settings: (&model.settings).into(),
            persisted: PersistedState::snapshot(&model.timer, &model.themes, &model.settings),
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use crate::themes::ThemeId;
    use crate::timer::Status;

    #[test]
    fn initial_view() {
        let app = Kvart;
        let view = app.view(&Model::default());
        assert_eq!(view.timer.status, Status::Idle);
        assert_eq!(view.themes.selected, ThemeId::Modern);
        assert_eq!(view.themes.themes.len(), 3);
    }

    #[test]
    fn timer_start_tick() {
        let app = Kvart;
        let mut model = Model::default();
        let _ = app.update(Event::Timer(timer::Event::SetDuration(30)), &mut model);
        let _ = app.update(Event::Timer(timer::Event::Start(0)), &mut model);
        let mut cmd = app.update(Event::Timer(timer::Event::Tick(5_000)), &mut model);
        cmd.expect_one_effect().expect_render();
        assert_eq!(app.view(&model).timer.seconds_elapsed, 5);
    }

    #[test]
    fn timer_completion_emits_alarm_and_render() {
        let app = Kvart;
        let mut model = Model::default();
        let _ = app.update(Event::Timer(timer::Event::SetDuration(1)), &mut model);
        let _ = app.update(Event::Timer(timer::Event::Start(0)), &mut model);
        let mut cmd = app.update(Event::Timer(timer::Event::Tick(1_500)), &mut model);
        let effects: Vec<_> = cmd.effects().collect();
        assert_eq!(effects.len(), 2);
        assert!(effects.iter().any(|e| matches!(e, Effect::Render(_))));
        assert!(effects.iter().any(|e| matches!(e, Effect::Alarm(_))));
    }

    #[test]
    fn background_enter_while_running_schedules_alarm() {
        let app = Kvart;
        let mut model = Model::default();
        let _ = app.update(Event::Timer(timer::Event::SetDuration(60)), &mut model);
        let _ = app.update(Event::Timer(timer::Event::Start(1_000)), &mut model);
        let mut cmd = app.update(
            Event::Background(background::Event::Enter(2_000)),
            &mut model,
        );
        let mut effects = cmd.effects();
        let scheduled = effects
            .find_map(|e| match e {
                Effect::Alarm(r) => Some(r.operation),
                Effect::Render(_) => None,
            })
            .expect("expected a scheduled alarm");
        match scheduled {
            AlarmOperation::Schedule { at_ms, .. } => assert_eq!(at_ms, 2_000 + 59_000),
            other => panic!("unexpected alarm: {other:?}"),
        }
    }

    #[test]
    fn background_enter_when_idle_emits_no_alarm() {
        let app = Kvart;
        let mut model = Model::default();
        let mut cmd = app.update(Event::Background(background::Event::Enter(0)), &mut model);
        let count = cmd
            .effects()
            .filter(|e| matches!(e, Effect::Alarm(_)))
            .count();
        assert_eq!(count, 0);
    }

    #[test]
    fn background_resume_past_end_cancels_and_fires() {
        let app = Kvart;
        let mut model = Model::default();
        let _ = app.update(Event::Timer(timer::Event::SetDuration(2)), &mut model);
        let _ = app.update(Event::Timer(timer::Event::Start(0)), &mut model);
        let mut cmd = app.update(
            Event::Background(background::Event::Resume(10_000)),
            &mut model,
        );
        let ops: Vec<_> = cmd
            .effects()
            .filter_map(|e| match e {
                Effect::Alarm(r) => Some(r.operation),
                Effect::Render(_) => None,
            })
            .collect();
        assert!(matches!(ops.first(), Some(AlarmOperation::Cancel)));
        assert!(ops.iter().any(|o| matches!(o, AlarmOperation::Fire { .. })));
        assert_eq!(model.timer.status, Status::Completed);
    }

    #[test]
    fn select_paid_theme_requires_purchase() {
        let app = Kvart;
        let mut model = Model::default();
        let _ = app.update(
            Event::Themes(themes::Event::Select(ThemeId::Blaze)),
            &mut model,
        );
        assert_eq!(app.view(&model).themes.selected, ThemeId::Modern);
        let _ = app.update(
            Event::Themes(themes::Event::SetPurchased {
                id: ThemeId::Blaze,
                purchased: true,
            }),
            &mut model,
        );
        let _ = app.update(
            Event::Themes(themes::Event::Select(ThemeId::Blaze)),
            &mut model,
        );
        assert_eq!(app.view(&model).themes.selected, ThemeId::Blaze);
    }
}
