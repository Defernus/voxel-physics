use bevy::{
    prelude::*,
    render::{render_graph, render_resource::*, renderer::RenderContext},
};

use super::{GameWorldBindGroup, GameWorldPipeline, WORKGROUP_SIZE, WORLD_SIZE};

enum GameWorldState {
    Loading,
    Init,
    Update,
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
                if let CachedPipelineState::Ok(_) =
                    pipeline_cache.get_compute_pipeline_state(pipeline.init_pipeline)
                {
                    self.state = GameWorldState::Init;
                }
            }
            GameWorldState::Init => {
                if let CachedPipelineState::Ok(_) =
                    pipeline_cache.get_compute_pipeline_state(pipeline.update_pipeline)
                {
                    self.state = GameWorldState::Update;
                }
            }
            GameWorldState::Update => {}
        }
    }

    fn run(
        &self,
        _graph: &mut render_graph::RenderGraphContext,
        render_context: &mut RenderContext,
        world: &World,
    ) -> Result<(), render_graph::NodeRunError> {
        let texture_bind_group = world.resource::<GameWorldBindGroup>();
        let pipeline_cache = world.resource::<PipelineCache>();
        let pipeline = world.resource::<GameWorldPipeline>();

        let mut pass = render_context
            .command_encoder()
            .begin_compute_pass(&ComputePassDescriptor::default());

        pass.set_bind_group(0, texture_bind_group, &[]);

        // select the pipeline based on the current state
        match self.state {
            GameWorldState::Loading => {}
            GameWorldState::Init => {
                let init_pipeline = pipeline_cache
                    .get_compute_pipeline(pipeline.init_pipeline)
                    .unwrap();
                pass.set_pipeline(init_pipeline);
                pass.dispatch_workgroups(
                    WORLD_SIZE.0 / WORKGROUP_SIZE,
                    WORLD_SIZE.1 / WORKGROUP_SIZE,
                    1,
                );
            }
            GameWorldState::Update => {
                let update_pipeline = pipeline_cache
                    .get_compute_pipeline(pipeline.update_pipeline)
                    .unwrap();
                pass.set_pipeline(update_pipeline);
                pass.dispatch_workgroups(
                    WORLD_SIZE.0 / WORKGROUP_SIZE,
                    WORLD_SIZE.1 / WORKGROUP_SIZE,
                    1,
                );
            }
        }

        Ok(())
    }
}
