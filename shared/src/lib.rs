mod app;
pub mod background;
pub mod ffi;
pub mod notification;
pub mod persistence;
pub mod settings;
pub mod themes;
pub mod timer;

pub use app::*;
pub use crux_core::Core;

#[cfg(feature = "uniffi")]
const _: () = assert!(
    uniffi::check_compatible_version("0.29.4"),
    "please use uniffi v0.29.4"
);
#[cfg(feature = "uniffi")]
uniffi::setup_scaffolding!();
