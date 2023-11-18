use std::mem::size_of;

use bevy::{
    prelude::*,
    render::{extract_resource::ExtractResource, render_resource::*},
};
use bytemuck::{Pod, Zeroable};

#[derive(Default, Clone, Copy, Pod, Zeroable)]
#[repr(C)]
pub struct CellData {
    pub to_gravity_source: Vec2,
    pub gravity_strength: f32,
    pub particle_type: u32,
    pub mass: f32,
    pub impulse: Vec2,
    pub relative_pos: Vec2,
}

impl CellData {
    pub fn get_world_data_size(world_size: (u32, u32)) -> u64 {
        ((world_size.0 * world_size.1) as usize * size_of::<Self>()) as u64
    }
}

#[derive(Resource, AsBindGroup, Clone, ExtractResource)]
pub struct GameWorldData {
    #[texture(0, visibility(compute), dimension = "2d")]
    pub image: Handle<Image>,
    /// The previous state of the world. (Array of [`CellData`])
    #[storage(1, visibility(compute), buffer)]
    pub data_prev: Buffer,
    /// The next state of the world. (Array of [`CellData`])
    #[storage(2, visibility(compute), buffer)]
    pub data_next: Buffer,
}

impl GameWorldData {
    /// Swaps the previous and next state of the world.
    pub fn swap(&mut self) {
        std::mem::swap(&mut self.data_prev, &mut self.data_next);
    }
}

#[derive(Clone, Debug, Resource, ExtractResource, Deref, DerefMut)]
pub struct GameWorldBindGroup(pub BindGroup);

impl From<BindGroup> for GameWorldBindGroup {
    fn from(bind_group: BindGroup) -> Self {
        Self(bind_group)
    }
}
