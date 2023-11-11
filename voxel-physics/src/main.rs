use bevy::prelude::*;
use bevy_inspector_egui::quick::WorldInspectorPlugin;
use voxel_physics::game_world::GameWorldPlugin;

fn main() {
    App::new()
        // default plugins
        .add_plugins(DefaultPlugins)
        // third-party plugins
        .add_plugins(WorldInspectorPlugin::new())
        // custom plugins
        .add_plugins(GameWorldPlugin)
        .run();
}
