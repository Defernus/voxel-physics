/// Just an empty void
const PARTICLE_NOTHING = 0u;
/// Regular particle with mass and impulse
const PARTICLE_REGULAR = 1u;
const ERROR_COLOR = vec4<f32>(1.0, 1.0, 1.0, 1.0);
const CHANCE_OF_PARTICLE = 0.001;

const CELL_SIZE = 1.0;
const CELL_RADIUS = 0.5;

const PI = 3.14159265359;
const EPSILON = 0.00001;
const GRAVITY_CONSTANT = 1.0;
const DEFAULT_MASS = 1.0;
const CELL_CENTER = vec2<f32>(0.0, 0.0);

const CELL_00 = vec2<i32>(-1, -1);
const CELL_10 = vec2<i32>(0, -1);
const CELL_20 = vec2<i32>(1, -1);
const CELL_01 = vec2<i32>(-1, 0);
const CELL_21 = vec2<i32>(1, 0);
const CELL_02 = vec2<i32>(-1, 1);
const CELL_12 = vec2<i32>(0, 1);
const CELL_22 = vec2<i32>(1, 1);

const CELL_00F = vec2<f32>(-1.0, -1.0);
const CELL_10F = vec2<f32>(0.0, -1.0);
const CELL_20F = vec2<f32>(1.0, -1.0);
const CELL_01F = vec2<f32>(-1.0, 0.0);
const CELL_21F = vec2<f32>(1.0, 0.0);
const CELL_02F = vec2<f32>(-1.0, 1.0);
const CELL_12F = vec2<f32>(0.0, 1.0);
const CELL_22F = vec2<f32>(1.0, 1.0);

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
@group(0) @binding(1) var<storage, read_write> data_prev: array<CellData>;
@group(0) @binding(2) var<storage, read_write> data_next: array<CellData>;
const WORLD_WIDTH = 1024i;
const WORLD_HEIGHT = 1024i;
/// Default simulatuion step duration
const DEFAULT_STEP_DURATION = 1.0f;

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

/// Set cell data for the next frame
fn set_next_cell(location: vec2<i32>, value: CellData) {
    data_next[location_to_index(location)] = value;
}

/// Get cell data from previous frame
fn get_prev_cell(location: vec2<i32>) -> CellData {
    return data_prev[location_to_index(location)];
}

struct GravityData {
    /// position of gravity source relative to current cell
    to_source: vec2<f32>,
    strength: f32,
}

// TODO add mass to calculations
fn get_cell_gravity_data(current_cell: CellData, current_pos: vec2<i32>, neighbor_pos: vec2<i32>) -> GravityData {
    let neighbor_cell = get_prev_cell(neighbor_pos);

    let vec_to_cell = vec2<f32>(neighbor_pos - current_pos) + neighbor_cell.relative_pos - current_cell.relative_pos;
    let distance = length(vec_to_cell);
    
    // TODO fix this
    if distance == 0.0 {
        return GravityData (vec2<f32>(0.0, 0.0), 0.0);
    }

    if neighbor_cell.particle_type == PARTICLE_NOTHING {
        if neighbor_cell.gravity_strength < EPSILON {
            return GravityData (vec2<f32>(0.0, 0.0), 0.0);
        }

        let gravity_source_rel_pos = vec_to_cell + neighbor_cell.to_gravity_source;

        return GravityData(
            gravity_source_rel_pos,
            neighbor_cell.gravity_strength,
        );
    }

    return GravityData (vec_to_cell, neighbor_cell.mass);
}

@compute @workgroup_size(8, 8, 1)
fn init(@builtin(global_invocation_id) invocation_id: vec3<u32>, @builtin(num_workgroups) num_workgroups: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    if is_out_of_bounds(location) {
        return;
    }

    if random_float(invocation_id.y * num_workgroups.x + invocation_id.x) < (1.0 - CHANCE_OF_PARTICLE) {
        set_next_cell(location, new_empty_cell());
    } else {
        set_next_cell(location, new_particle_cell(DEFAULT_MASS, vec2<f32>(0.0, 0.0)));
    }

    // let distance = 100;

    // let r = distance / 2;
    // let center = vec2<i32>(WORLD_WIDTH / 2, WORLD_HEIGHT / 2);
    // let left_cell_pos = center - vec2<i32>(r, 0);
    // let right_cell_pos = center + vec2<i32>(r, 0);

    
    // if (location.x == left_cell_pos.x && location.y == left_cell_pos.y) {
    //     let left_cell = new_particle_cell(DEFAULT_MASS, vec2<f32>(0.0, 0.0));
    //     set_next_cell(location, left_cell);
    // } else if (location.x == right_cell_pos.x && location.y == right_cell_pos.y) {
    //     let right_cell = new_particle_cell(DEFAULT_MASS, vec2<f32>(0.0, 0.0));
    //     set_next_cell(location, right_cell);
    // } else {
    //     set_next_cell(location, new_empty_cell());
    // }
}

/// Called before every update step
@compute @workgroup_size(8, 8, 1)
fn pre_update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    if is_out_of_bounds(location) {
        return;
    }

    set_next_cell(location, get_prev_cell(location));
}

@compute @workgroup_size(8, 8, 1)
fn update_gravity(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    if is_out_of_bounds(location) {
        return;
    }

    var current = get_prev_cell(location);

    let gravity_00 = get_cell_gravity_data(current, location, location + CELL_00);
    let gravity_10 = get_cell_gravity_data(current, location, location + CELL_10);
    let gravity_20 = get_cell_gravity_data(current, location, location + CELL_20);
    let gravity_01 = get_cell_gravity_data(current, location, location + CELL_01);
    let gravity_21 = get_cell_gravity_data(current, location, location + CELL_21);
    let gravity_02 = get_cell_gravity_data(current, location, location + CELL_02);
    let gravity_12 = get_cell_gravity_data(current, location, location + CELL_12);
    let gravity_22 = get_cell_gravity_data(current, location, location + CELL_22);

    let total_strength = (
        gravity_00.strength
        + gravity_10.strength
        + gravity_20.strength
        + gravity_01.strength
        + gravity_21.strength
        + gravity_02.strength
        + gravity_12.strength
        + gravity_22.strength
    );

    if total_strength < EPSILON {
        current.to_gravity_source = vec2<f32>(0.0, 0.0);
        current.gravity_strength = 0.0;
    } else {
        current.to_gravity_source = (
            gravity_00.to_source * gravity_00.strength
            + gravity_10.to_source * gravity_10.strength
            + gravity_20.to_source * gravity_20.strength
            + gravity_01.to_source * gravity_01.strength
            + gravity_21.to_source * gravity_21.strength
            + gravity_02.to_source * gravity_02.strength
            + gravity_12.to_source * gravity_12.strength
            + gravity_22.to_source * gravity_22.strength
        ) / total_strength;
        current.gravity_strength = total_strength / 8.0;
    }

    set_next_cell(location, current);
}

@compute @workgroup_size(8, 8, 1)
fn update_impulse(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    if is_out_of_bounds(location) {
        return;
    }

    var current = get_prev_cell(location);

    if current.particle_type == PARTICLE_NOTHING {
        return;
    }

    let dist_sq = current.to_gravity_source.x * current.to_gravity_source.x + current.to_gravity_source.y * current.to_gravity_source.y;

    if dist_sq > EPSILON {
        current.impulse += normalize(current.to_gravity_source) * current.mass * current.gravity_strength / dist_sq  * delta_time();
    }
    
    current.relative_pos = current.impulse / current.mass * delta_time();


    // TODO cap max speed in a different way
    if length(current.relative_pos - CELL_CENTER) > 1.0 {
        current.relative_pos = CELL_CENTER + normalize(current.relative_pos - CELL_CENTER);
    }

    set_next_cell(location, current);
}

fn axis_to_dir(val: f32) -> i32 {
    // TODO get rid of if
    if val < -CELL_RADIUS {
        return -1;
    } else if val > CELL_RADIUS {
        return 1;
    }

    return 0;
}

fn rel_pos_to_dir(rel_pos: vec2<f32>) -> vec2<i32> {
    return vec2<i32>(axis_to_dir(rel_pos.x), axis_to_dir(rel_pos.y));
}

@compute @workgroup_size(8, 8, 1)
fn update_position(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    if is_out_of_bounds(location) {
        return;
    }

    var current = get_prev_cell(location);
    var changed = false;

    // go through all cells around and check if some cell is trying to move to this cell
    for (var x = -1; x <= 1; x += 1) {
        for (var y = -1; y <= 1; y += 1) {
            if x == 0 && y == 0 {
                continue;
            }

            let pos = vec2<i32>(x, y);
            let neightbor_pos = location + pos;
            let neightbor = get_prev_cell(neightbor_pos);

            if neightbor.particle_type == PARTICLE_NOTHING {
                continue;
            }

            let neightbor_relative_pos = rel_pos_to_dir(neightbor.relative_pos) + pos;            

            if neightbor_relative_pos.x != 0 || neightbor_relative_pos.y != 0 {
                continue;
            }

            // merge cells
            current.mass += neightbor.mass;
            current.impulse += neightbor.impulse;
            current.relative_pos = CELL_CENTER;
            current.particle_type = PARTICLE_REGULAR;
            changed = true;
            set_next_cell(neightbor_pos, new_empty_cell());
        }
    }

    if changed {
        set_next_cell(location, current);
    }

    let color = cell_to_color(current);

    textureStore(texture, location, color);
}
