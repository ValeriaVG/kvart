use facet::Facet;
use serde::{Deserialize, Serialize};

/// App lifecycle transitions the shell forwards to the core. Carries wall-clock
/// `now_ms` so the core can do resume-time correction without its own clock.
#[derive(Facet, Serialize, Deserialize, Clone, Debug)]
#[repr(C)]
pub enum BackgroundEvent {
    /// App entered background / inactive state.
    Enter(u64),
    /// App returned to the foreground.
    Resume(u64),
}

pub type Event = BackgroundEvent;
