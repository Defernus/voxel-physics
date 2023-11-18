use std::borrow::Cow;

use bevy::{
    prelude::*,
    render::{extract_resource::ExtractResource, render_resource::*, renderer::RenderDevice},
};

use crate::game_world::WORLD_SIZE;

use super::CellData;

#[derive(Clone, Debug, Resource, ExtractResource)]
pub struct GameWorldPipeline {
    pub world_bind_group_layout: BindGroupLayout,
    pub init_pipeline: CachedComputePipelineId,
    pub pre_update_pipeline: CachedComputePipelineId,
    pub update_gravity_pipeline: CachedComputePipelineId,
    pub update_impulse_pipeline: CachedComputePipelineId,
    pub update_position_pipeline: CachedComputePipelineId,
}

impl FromWorld for GameWorldPipeline {
    fn from_world(world: &mut World) -> Self {
        let data_size = CellData::get_world_data_size(WORLD_SIZE);

        let data_ty = BindingType::Buffer {
            ty: BufferBindingType::Storage { read_only: false },
            has_dynamic_offset: false,
            min_binding_size: BufferSize::new(data_size),
        };

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
                            ty: data_ty,
                            count: None,
                        },
                        BindGroupLayoutEntry {
                            binding: 2,
                            visibility: ShaderStages::COMPUTE,
                            ty: data_ty,
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
        let pre_update_pipeline =
            pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
                label: None,
                layout: vec![world_bind_group_layout.clone()],
                push_constant_ranges: Vec::new(),
                shader: shader.clone(),
                shader_defs: vec![],
                entry_point: Cow::from("pre_update"),
            });
        let update_gravity_pipeline =
            pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
                label: None,
                layout: vec![world_bind_group_layout.clone()],
                push_constant_ranges: Vec::new(),
                shader: shader.clone(),
                shader_defs: vec![],
                entry_point: Cow::from("update_gravity"),
            });
        let update_impulse_pipeline =
            pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
                label: None,
                layout: vec![world_bind_group_layout.clone()],
                push_constant_ranges: Vec::new(),
                shader: shader.clone(),
                shader_defs: vec![],
                entry_point: Cow::from("update_impulse"),
            });
        let update_position_pipeline =
            pipeline_cache.queue_compute_pipeline(ComputePipelineDescriptor {
                label: None,
                layout: vec![world_bind_group_layout.clone()],
                push_constant_ranges: Vec::new(),
                shader,
                shader_defs: vec![],
                entry_point: Cow::from("update_position"),
            });

        GameWorldPipeline {
            world_bind_group_layout,
            init_pipeline,
            pre_update_pipeline,
            update_gravity_pipeline,
            update_impulse_pipeline,
            update_position_pipeline,
        }
    }
}
