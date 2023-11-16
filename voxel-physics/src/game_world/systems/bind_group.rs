use bevy::{
    prelude::*,
    render::{
        render_asset::RenderAssets, render_resource::AsBindGroup, renderer::RenderDevice,
        texture::FallbackImage,
    },
};

use crate::game_world::{GameWorldBindGroup, GameWorldData, GameWorldPipeline};

pub fn prepare_bind_group_sys(
    mut commands: Commands,
    pipeline: Res<GameWorldPipeline>,
    gpu_images: Res<RenderAssets<Image>>,
    game_world_data: Res<GameWorldData>,
    render_device: Res<RenderDevice>,
    fallback_image: Res<FallbackImage>,
) {
    let prepared = game_world_data
        .as_bind_group(
            &pipeline.world_bind_group_layout,
            &render_device,
            &gpu_images,
            &fallback_image,
        )
        .unwrap();

    commands.insert_resource(GameWorldBindGroup(prepared.bind_group));
}
