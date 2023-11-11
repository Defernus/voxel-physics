use std::{borrow::Cow, ops::Deref};

use bevy::{
    prelude::*,
    render::{extract_resource::ExtractResource, render_resource::*, renderer::RenderDevice},
};

#[derive(Clone, Debug, Resource, Reflect, Default, ExtractResource)]
#[reflect(Resource)]
pub struct GameWorldImage(pub Handle<Image>);

impl Deref for GameWorldImage {
    type Target = Handle<Image>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl From<Handle<Image>> for GameWorldImage {
    fn from(handle: Handle<Image>) -> Self {
        Self(handle)
    }
}

impl From<GameWorldImage> for Handle<Image> {
    fn from(image: GameWorldImage) -> Self {
        image.0
    }
}

#[derive(Clone, Debug, Resource, ExtractResource)]
pub struct GameWorldBindGroup(pub BindGroup);

impl Deref for GameWorldBindGroup {
    type Target = BindGroup;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl From<BindGroup> for GameWorldBindGroup {
    fn from(bind_group: BindGroup) -> Self {
        Self(bind_group)
    }
}

#[derive(Clone, Debug, Resource, ExtractResource)]
pub struct GameWorldPipeline {
    pub texture_bind_group_layout: BindGroupLayout,
    pub init_pipeline: CachedComputePipelineId,
    pub update_pipeline: CachedComputePipelineId,
}

impl FromWorld for GameWorldPipeline {
    fn from_world(world: &mut World) -> Self {
        let texture_bind_group_layout =
            world
                .resource::<RenderDevice>()
                .create_bind_group_layout(&BindGroupLayoutDescriptor {
                    label: None,
                    entries: &[BindGroupLayoutEntry {
                        binding: 0,
                        visibility: ShaderStages::COMPUTE,
                        ty: BindingType::StorageTexture {
                            access: StorageTextureAccess::ReadWrite,
                            format: TextureFormat::Rgba8Unorm,
                            view_dimension: TextureViewDimension::D2,
                        },
                        count: None,
                    }],
                });

        // TODO move assets loading to separate plugin
        let shader = world
            .resource::<AssetServer>()
            .load("shaders/game_world.wgsl");

        let pipeline_cache = world.resource::<PipelineCache>();

        let init_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
            label: None,
            layout: vec![texture_bind_group_layout.clone()],
            push_constant_ranges: Vec::new(),
            shader: shader.clone(),
            shader_defs: vec![],
            entry_point: Cow::from("init"),
        });
        let update_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
            label: None,
            layout: vec![texture_bind_group_layout.clone()],
            push_constant_ranges: Vec::new(),
            shader,
            shader_defs: vec![],
            entry_point: Cow::from("update"),
        });

        GameWorldPipeline {
            texture_bind_group_layout,
            init_pipeline,
            update_pipeline,
        }
    }
}
