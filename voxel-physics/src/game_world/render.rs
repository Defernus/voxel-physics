use bevy::{
    prelude::*,
    render::{render_graph, render_resource::*, renderer::RenderContext},
};

use crate::utils::pipeline_state::PipelineStateUtils;

use super::{GameWorldBindGroup, GameWorldPipeline, WORKGROUP_SIZE, WORLD_SIZE};

enum GameWorldState {
    Loading,
    Init,
    UpdateGravity,
    UpdateImpulse,
    UpdatePosition,
}

pub struct GameWorldNode {
    state: GameWorldState,
}

impl Default for GameWorldNode {
    fn default() -> Self {
        Self {
            state: GameWorldState::Loading,
        }
    }
}

impl render_graph::Node for GameWorldNode {
    fn update(&mut self, world: &mut World) {
        let pipeline = world.resource::<GameWorldPipeline>();
        let pipeline_cache = world.resource::<PipelineCache>();

        // if the corresponding pipeline has loaded, transition to the next stage
        match self.state {
            GameWorldState::Loading => {
                if pipeline_cache
                    .get_compute_pipeline_state(pipeline.init_pipeline)
                    .is_ok()
                {
                    self.state = GameWorldState::Init;
                }
            }
            GameWorldState::Init => {
                if pipeline_cache
                    .get_compute_pipeline_state(pipeline.update_gravity_pipeline)
                    .is_ok()
                {
                    self.state = GameWorldState::UpdateGravity;
                }
            }
            GameWorldState::UpdateGravity => {
                if pipeline_cache
                    .get_compute_pipeline_state(pipeline.update_impulse_pipeline)
                    .is_ok()
                {
                    self.state = GameWorldState::UpdateImpulse;
                }
            }
            GameWorldState::UpdateImpulse => {
                if pipeline_cache
                    .get_compute_pipeline_state(pipeline.update_position_pipeline)
                    .is_ok()
                {
                    self.state = GameWorldState::UpdatePosition;
                }
            }
            GameWorldState::UpdatePosition => {
                if pipeline_cache
                    .get_compute_pipeline_state(pipeline.update_gravity_pipeline)
                    .is_ok()
                {
                    self.state = GameWorldState::UpdateGravity;
                }
            }
        }
    }

    fn run(
        &self,
        _graph: &mut render_graph::RenderGraphContext,
        render_context: &mut RenderContext,
        world: &World,
    ) -> Result<(), render_graph::NodeRunError> {
        let world_bind_group = world.resource::<GameWorldBindGroup>();
        let pipeline_cache = world.resource::<PipelineCache>();
        let pipeline = world.resource::<GameWorldPipeline>();

        let mut pass =
            render_context
                .command_encoder()
                .begin_compute_pass(&ComputePassDescriptor {
                    label: Some("GameWorld compute pass"),
                });

        pass.set_bind_group(0, world_bind_group, &[]);

        // select the pipeline based on the current state
        let pipeline = match self.state {
            GameWorldState::Loading => None,
            GameWorldState::Init => Some(pipeline.init_pipeline),
            GameWorldState::UpdateGravity => Some(pipeline.update_gravity_pipeline),
            GameWorldState::UpdateImpulse => Some(pipeline.update_impulse_pipeline),
            GameWorldState::UpdatePosition => Some(pipeline.update_position_pipeline),
        };

        if let Some(pipeline) = pipeline {
            let pipeline = pipeline_cache.get_compute_pipeline(pipeline).unwrap();
            pass.set_pipeline(pipeline);
            pass.dispatch_workgroups(
                WORLD_SIZE.0 / WORKGROUP_SIZE,
                WORLD_SIZE.1 / WORKGROUP_SIZE,
                1,
            );
        }

        Ok(())
    }
}
