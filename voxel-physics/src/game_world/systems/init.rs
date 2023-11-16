use bevy::{
    prelude::*,
    render::{
        render_resource::{
            BufferInitDescriptor, BufferUsages, Extent3d, TextureDimension, TextureFormat,
            TextureUsages,
        },
        renderer::RenderDevice,
    },
};

use crate::{
    game_world::{CellData, GameWorldData, WORLD_SIZE},
    utils::image::ImageUtils,
};

pub fn world_init_sys(
    mut commands: Commands,
    mut images: ResMut<Assets<Image>>,
    render_device: Res<RenderDevice>,
) {
    commands.spawn(Camera2dBundle::default());

    let image = Image::new_fill(
        Extent3d {
            width: WORLD_SIZE.0,
            height: WORLD_SIZE.1,
            depth_or_array_layers: 1,
        },
        TextureDimension::D2,
        &[0, 0, 0, 255],
        TextureFormat::Rgba8Unorm,
    )
    .with_description_usage(
        TextureUsages::COPY_DST | TextureUsages::STORAGE_BINDING | TextureUsages::TEXTURE_BINDING,
    );
    let image = images.add(image);

    commands.spawn(SpriteBundle {
        sprite: Sprite {
            custom_size: Some(Vec2::new(WORLD_SIZE.0 as f32, WORLD_SIZE.1 as f32)),
            ..default()
        },
        texture: image.clone(),
        ..default()
    });

    let data = vec![CellData::default(); (WORLD_SIZE.0 * WORLD_SIZE.1) as usize];
    let data = bytemuck::cast_slice(&data);

    let data = render_device.create_buffer_with_data(&BufferInitDescriptor {
        label: None,
        contents: data,
        usage: BufferUsages::STORAGE | BufferUsages::COPY_DST,
    });

    commands.insert_resource(GameWorldData { image, data });
}
