use bevy::prelude::*;

use crate::game_world::{DEFAULT_SCALE, DEFAULT_SENSITIVITY};

#[derive(Clone, Copy, Debug, Resource, Reflect)]
#[reflect(Resource)]
pub struct GameWorldViewportScale(pub f32);

impl Default for GameWorldViewportScale {
    fn default() -> Self {
        Self(DEFAULT_SCALE)
    }
}

#[derive(Clone, Copy, Debug, Resource, Reflect)]
#[reflect(Resource)]
pub struct GameWorldSensitivity(pub f32);

impl Default for GameWorldSensitivity {
    fn default() -> Self {
        Self(DEFAULT_SENSITIVITY)
    }
}
