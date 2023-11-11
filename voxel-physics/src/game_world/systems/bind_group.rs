use bevy::{
    prelude::*,
    render::{
        render_asset::RenderAssets, render_resource::BindGroupEntries, renderer::RenderDevice,
    },
};

use crate::game_world::{GameWorldBindGroup, GameWorldImage, GameWorldPipeline};

pub fn prepare_bind_group_sys(
    mut commands: Commands,
    pipeline: Res<GameWorldPipeline>,
    gpu_images: Res<RenderAssets<Image>>,
    game_world_image: Res<GameWorldImage>,
    render_device: Res<RenderDevice>,
) {
    let view = gpu_images.get(&game_world_image.0).unwrap();
    let bind_group = render_device.create_bind_group(
        None,
        &pipeline.texture_bind_group_layout,
        &BindGroupEntries::single(&view.texture_view),
    );

    commands.insert_resource(GameWorldBindGroup(bind_group));
}
