/// Just an empty void
const PARTICLE_NOTHING = 0u;
/// Regular particle with mass and impulse
const PARTICLE_REGULAR = 1u;
const ERROR_COLOR = vec4<f32>(1.0, 0.0, 1.0, 1.0);
const CHANCE_OF_PARTICLE = 0.01f;

const GRAVITY_CONSTANT = 1.32;
const DEFAULT_MASS = 1.0;

struct CellData {
    gravity: f32,
    particle_type: u32,
    mass: f32,
    impulse: vec2<f32>,
}

fn new_empty_cell() -> CellData {
    return CellData(0.0, PARTICLE_NOTHING, 0.0, vec2<f32>(0.0, 0.0));
}

fn new_particle_cell(mass: f32, particle_vel: vec2<f32>) -> CellData {
    let impulse: vec2<f32> = particle_vel * mass;
    return CellData(mass, PARTICLE_REGULAR, mass, impulse);
}

fn cell_to_color(state: CellData) -> vec4<f32> {
    if state.particle_type == PARTICLE_NOTHING {
        return vec4<f32>(0.0, 0.0, 1.0 - 1.0 / (1.0 + state.gravity), 1.0);
    } else if state.particle_type == PARTICLE_REGULAR {
        return vec4<f32>(1.0, 1.0, 1.0, 1.0);
    }

    return ERROR_COLOR;
}

fn hash(value: u32) -> u32 {
    var state = value;
    state = state ^ 2747636419u;
    state = state * 2654435769u;
    state = state ^ state >> 16u;
    state = state * 2654435769u;
    state = state ^ state >> 16u;
    state = state * 2654435769u;
    return state;
}

fn random_float(value: u32) -> f32 {
    return f32(hash(value)) / 4294967295.0;
}

@group(0) @binding(0) var texture: texture_storage_2d<rgba8unorm, read_write>;
@group(0) @binding(1) var<storage, read_write> data: array<CellData>;
const WORLD_WIDTH = 1280i;
const WORLD_HEIGHT = 720i;
/// Default simulatuion step duration
const DEFAULT_STEP_DURATION = 0.1f;

fn is_out_of_bounds(l: vec2<i32>) -> bool {
    return l.y < 0 || l.y >= WORLD_HEIGHT || l.x < 0 || l.x >= WORLD_WIDTH;
}

fn delta_time() -> f32 {
    return DEFAULT_STEP_DURATION;
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

/// Set vec4 to data array
fn set_cell_data(location: vec2<i32>, value: CellData) {
    data[location_to_index(location)] = value;
}

/// Get vec4 from data array
fn get_cell_data(location: vec2<i32>) -> CellData {
    return data[location_to_index(location)];
}

fn get_cell_gravity(current_pos: vec2<i32>, cell_pos: vec2<i32>) -> f32 {
    let cell = get_cell_data(cell_pos);

    let distance_vec = vec2<f32>(cell_pos - current_pos);
    let distance_squared = distance_vec.x * distance_vec.x + distance_vec.y * distance_vec.y;

    if cell.particle_type == PARTICLE_NOTHING {
        return cell.gravity / distance_squared * GRAVITY_CONSTANT;
    }

    return cell.mass / distance_squared * GRAVITY_CONSTANT;
}

@compute @workgroup_size(8, 8, 1)
fn init(@builtin(global_invocation_id) invocation_id: vec3<u32>, @builtin(num_workgroups) num_workgroups: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    if is_out_of_bounds(location) {
        return;
    }

    if random_float(invocation_id.y * num_workgroups.x + invocation_id.x) < (1.0 - CHANCE_OF_PARTICLE) {
        set_cell_data(location, new_empty_cell());
    } else {
        set_cell_data(location, new_particle_cell(DEFAULT_MASS, vec2<f32>(0.0, 0.0)));
    }
}

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    if is_out_of_bounds(location) {
        return;
    }


    var current = get_cell_data(location);

    var gravity = 0.0;

    for (var x = -1; x <= 1; x = x + 1) {
        for (var y = -1; y <= 1; y = y + 1) {
            if (x == 0 && y == 0) {
                continue;
            }

            let pos = location + vec2<i32>(x, y);

            gravity = gravity + get_cell_gravity(location, pos);
        }
    }

    current.gravity = gravity / 8.0;
    set_cell_data(location, current);

    let color = cell_to_color(current);

    textureStore(texture, location, color);
}
