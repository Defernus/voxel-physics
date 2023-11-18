#import "shaders/constants.wgsl"::{WORLD_WIDTH, WORLD_HEIGHT, PARTICLE_NOTHING, PARTICLE_REGULAR, CELL_CENTER, ERROR_COLOR};

@group(0) @binding(0) var texture: texture_storage_2d<rgba8unorm, read_write>;
@group(0) @binding(1) var<storage, read_write> data_prev: array<CellData>;
@group(0) @binding(2) var<storage, read_write> data_next: array<CellData>;


struct CellData {
    /// Position of gravity source relative to current cell
    to_gravity_source: vec2<f32>,
    gravity_strength: f32,
    particle_type: u32,
    mass: f32,
    impulse: vec2<f32>,
    relative_pos: vec2<f32>,
}

fn new_empty_cell() -> CellData {
    return CellData(vec2<f32>(0.0, 0.0), 0.0, PARTICLE_NOTHING, 0.0, vec2<f32>(0.0, 0.0), CELL_CENTER);
}

fn new_particle_cell(mass: f32, particle_vel: vec2<f32>) -> CellData {
    let impulse: vec2<f32> = particle_vel * mass;
    return CellData(vec2<f32>(0.0, 0.0), mass, PARTICLE_REGULAR, mass, impulse, CELL_CENTER);
}

fn empty_cell_color(cell: CellData) -> vec4<f32> {
    let gravity_color = cell.to_gravity_source * 0.5 + 0.5;
    return vec4<f32>(gravity_color.x, 0.0, gravity_color.y, 1.0);
}

fn particle_cell_color(cell: CellData) -> vec4<f32> {
    let impulse_color = cell.impulse * 0.5 + 0.5;
    return vec4<f32>(impulse_color.x, 1.0, impulse_color.y, 1.0);
}

fn cell_to_color(cell: CellData) -> vec4<f32> {
    if cell.particle_type == PARTICLE_NOTHING {
        return empty_cell_color(cell);
    } else if cell.particle_type == PARTICLE_REGULAR {
        return particle_cell_color(cell);
    }

    return ERROR_COLOR;
}


fn true_mod(a: i32, b: i32) -> i32 {
    return (a % b + b) % b;
}

/// loop location around if out of bounds
fn loop_location(location: vec2<i32>) -> vec2<i32> {
    return vec2<i32>(true_mod(location.x, WORLD_WIDTH), true_mod(location.y, WORLD_HEIGHT));
}

fn location_to_index(location: vec2<i32>) -> u32 {
    let looped_location = loop_location(location);
    return u32(looped_location.y * WORLD_WIDTH + looped_location.x);
}

fn index_to_location(index: u32) -> vec2<i32> {
    let x = i32(index % u32(WORLD_WIDTH));
    let y = i32(index / u32(WORLD_WIDTH));
    return vec2<i32>(x, y);
}

/// Set cell data for the next frame
fn set_next_cell(location: vec2<i32>, value: CellData) {
    data_next[location_to_index(location)] = value;
}

/// Get cell data from previous frame
fn get_prev_cell(location: vec2<i32>) -> CellData {
    return data_prev[location_to_index(location)];
}
