use bevy::prelude::*;
use bevy::render::extract_resource::ExtractResourcePlugin;
use bevy::render::render_graph::RenderGraph;
use bevy::render::Render;
use bevy::render::RenderApp;
use bevy::render::RenderSet;

use crate::utils::add_resource::AddAndRegisterRes;

pub use self::constants::*;
use self::render::GameWorldNode;
pub use self::resources::*;
use self::systems::*;

pub mod constants;
mod render;
pub mod resources;
mod systems;

#[derive(Clone, Debug, Default)]
pub struct GameWorldPlugin;

impl Plugin for GameWorldPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Startup, world_init_sys);

        // Extract the game of life image resource from the main world into the render world
        // for operation on by the compute shader and display on the sprite.
        app.add_plugins(ExtractResourcePlugin::<GameWorldHandlers>::default());
        let render_app = app.sub_app_mut(RenderApp);
        render_app.add_systems(
            Render,
            prepare_bind_group_sys.in_set(RenderSet::PrepareBindGroups),
        );

        let mut render_graph = render_app.world.resource_mut::<RenderGraph>();
        render_graph.add_node("game_world", GameWorldNode::default());
        render_graph.add_node_edge("game_world", bevy::render::main_graph::node::CAMERA_DRIVER);
    }

    fn finish(&self, app: &mut App) {
        let render_app = app.sub_app_mut(RenderApp);
        render_app.init_resource::<GameWorldPipeline>();
    }
}
