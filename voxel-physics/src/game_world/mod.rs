use bevy::prelude::*;
use bevy::render::extract_resource::ExtractResourcePlugin;
use bevy::render::main_graph::node::CAMERA_DRIVER;
use bevy::render::render_graph::RenderGraph;
use bevy::render::Render;
use bevy::render::RenderApp;
use bevy::render::RenderSet;

pub use components::*;
pub use constants::*;
use render::GameWorldNode;
pub use resources::*;
use systems::*;

use crate::utils::add_resource::AddAndRegisterRes;

pub mod components;
pub mod constants;
mod render;
mod resources;
mod systems;

#[derive(Clone, Debug, Default)]
pub struct GameWorldPlugin;

impl Plugin for GameWorldPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Startup, world_init_sys);
        app.add_systems(Update, world_control_sys);

        app.register_type::<WorldSprite>();

        app.init_and_register_res::<GameWorldViewportScale>()
            .init_and_register_res::<GameWorldSensitivity>();

        // Extract world resource from the main world into the render world
        // for operation on by the compute shader and display on the sprite.
        app.add_plugins(ExtractResourcePlugin::<GameWorldData>::default());
        let render_app = app.sub_app_mut(RenderApp);
        render_app.add_systems(
            Render,
            prepare_bind_group_sys.in_set(RenderSet::PrepareBindGroups),
        );

        let mut render_graph = render_app.world.resource_mut::<RenderGraph>();
        render_graph.add_node("game_world", GameWorldNode::default());
        render_graph.add_node_edge("game_world", CAMERA_DRIVER);
    }

    fn finish(&self, app: &mut App) {
        let render_app = app.sub_app_mut(RenderApp);
        render_app.init_resource::<GameWorldPipeline>();
    }
}
