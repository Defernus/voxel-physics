use std::{borrow::Cow, mem::size_of};

use bevy::{
    prelude::*,
    render::{extract_resource::ExtractResource, render_resource::*, renderer::RenderDevice},
};
use bytemuck::{Pod, Zeroable};

use super::WORLD_SIZE;

#[derive(Resource, AsBindGroup, Clone, ExtractResource)]
pub struct GameWorldData {
    #[texture(0, visibility(compute), dimension = "2d")]
    pub image: Handle<Image>,
    #[storage(1, visibility(compute), buffer)]
    pub data: Buffer,
}

#[derive(Clone, Debug, Resource, ExtractResource, Deref, DerefMut)]
pub struct GameWorldBindGroup(pub BindGroup);

impl From<BindGroup> for GameWorldBindGroup {
    fn from(bind_group: BindGroup) -> Self {
        Self(bind_group)
    }
}

#[derive(Clone, Debug, Resource, ExtractResource)]
pub struct GameWorldPipeline {
    pub world_bind_group_layout: BindGroupLayout,
    pub init_pipeline: CachedComputePipelineId,
    pub update_pipeline: CachedComputePipelineId,
}

#[derive(Clone, Copy, Pod, Zeroable)]
#[repr(C)]
pub struct CellData {
    pub state: u32,
    pub prev_state: u32,
    pub transition: f32,
}

impl Default for CellData {
    fn default() -> Self {
        Self {
            state: 0,
            prev_state: 0,
            transition: 1.0,
        }
    }
}

impl FromWorld for GameWorldPipeline {
    fn from_world(world: &mut World) -> Self {
        let world_bind_group_layout =
            world
                .resource::<RenderDevice>()
                .create_bind_group_layout(&BindGroupLayoutDescriptor {
                    label: None,
                    entries: &[
                        BindGroupLayoutEntry {
                            binding: 0,
                            visibility: ShaderStages::COMPUTE,
                            ty: BindingType::StorageTexture {
                                access: StorageTextureAccess::ReadWrite,
                                format: TextureFormat::Rgba8Unorm,
                                view_dimension: TextureViewDimension::D2,
                            },
                            count: None,
                        },
                        BindGroupLayoutEntry {
                            binding: 1,
                            visibility: ShaderStages::COMPUTE,
                            ty: BindingType::Buffer {
                                ty: BufferBindingType::Storage { read_only: false },
                                has_dynamic_offset: false,
                                min_binding_size: BufferSize::new(
                                    ((WORLD_SIZE.0 * WORLD_SIZE.1) as usize * size_of::<CellData>())
                                        as u64,
                                ),
                            },
                            count: None,
                        },
                    ],
                });

        // TODO move assets loading to separate plugin
        let shader = world
            .resource::<AssetServer>()
            .load("shaders/game_world.wgsl");

        let pipeline_cache = world.resource::<PipelineCache>();

        let init_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
            label: None,
            layout: vec![world_bind_group_layout.clone()],
            push_constant_ranges: Vec::new(),
            shader: shader.clone(),
            shader_defs: vec![],
            entry_point: Cow::from("init"),
        });
        let update_pipeline = pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
            label: None,
            layout: vec![world_bind_group_layout.clone()],
            push_constant_ranges: Vec::new(),
            shader,
            shader_defs: vec![],
            entry_point: Cow::from("update"),
        });

        GameWorldPipeline {
            world_bind_group_layout,
            init_pipeline,
            update_pipeline,
        }
    }
}
