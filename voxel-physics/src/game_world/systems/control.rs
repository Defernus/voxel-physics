use bevy::prelude::*;

use crate::game_world::{
    GameWorldSensitivity, GameWorldViewportScale, WorldSprite, MAX_SCALE, MIN_SCALE,
};

pub fn world_control_sys(
    mut sprite_q: Query<&mut Transform, With<WorldSprite>>,
    input: Res<Input<KeyCode>>,
    time: Res<Time>,
    mut scale: ResMut<GameWorldViewportScale>,
    sensitivity: Res<GameWorldSensitivity>,
) {
    let dt = time.delta_seconds();

    let mut sprite = sprite_q.single_mut();

    let mut pos_delta = Vec2::ZERO;
    if input.pressed(KeyCode::A) {
        pos_delta.x += 1.0;
    }
    if input.pressed(KeyCode::D) {
        pos_delta.x -= 1.0;
    }
    if input.pressed(KeyCode::W) {
        pos_delta.y -= 1.0;
    }
    if input.pressed(KeyCode::S) {
        pos_delta.y += 1.0;
    }

    sprite.translation += (pos_delta * sensitivity.0 * dt).extend(0.0);

    if input.pressed(KeyCode::Q) {
        scale.0 *= 1.0 + dt;
    }
    if input.pressed(KeyCode::E) {
        scale.0 *= 1.0 - dt;
    }

    scale.0 = scale.0.clamp(MIN_SCALE, MAX_SCALE);
    sprite.scale = Vec3::splat(1.0 / scale.0);
}
