use bevy::prelude::*;

pub fn random_color() -> Color {
    Color::rgb(
        rand::random::<f32>(),
        rand::random::<f32>(),
        rand::random::<f32>(),
    )
}

pub fn random_color_normalized() -> Color {
    let (r, g, b) = rand::random();

    let rgb_vec = Vec3::new(r, g, b).normalize();

    Color::rgb(rgb_vec.x, rgb_vec.y, rgb_vec.z)
}
