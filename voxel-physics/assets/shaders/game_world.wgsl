const STATE_NOTHING = 0u;
const STATE_ROCK = 1u;
const STATE_PAPER = 2u;
const STATE_SCISSORS = 3u;

struct CellData {
    state: u32,
    prev_state: u32,
    transition: f32,
}

@group(0) @binding(0) var texture: texture_storage_2d<rgba8unorm, read_write>;
@group(0) @binding(1) var<storage, read_write> data: array<CellData>;

const WORLD_WIDTH = 1280i;
const WORLD_HEIGHT = 720i;

fn state_to_color(state: CellData) -> vec4<f32> {
    if state.state == STATE_ROCK {
        return vec4<f32>(1.0, 0.0, 0.0, 1.0);
    } else if state.state == STATE_PAPER {
        return vec4<f32>(0.0, 1.0, 0.0, 1.0);
    } else if state.state == STATE_SCISSORS {
        return vec4<f32>(0.0, 0.0, 1.0, 1.0);
    }
    return vec4<f32>(0.0, 0.0, 0.0, 1.0);
}

fn is_out_of_bounds(l: vec2<i32>) -> bool {
    return l.y < 0 || l.y >= WORLD_HEIGHT || l.x < 0 || l.x >= WORLD_WIDTH;
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

/// Set vec4 to data array
fn set_cell_data(location: vec2<i32>, value: CellData) {
    if is_out_of_bounds(location) {
        return;
    }

    let index = location.y * WORLD_WIDTH + location.x;
    data[index] = value;
}

/// Get vec4 from data array
fn get_cell_data(location: vec2<i32>) -> CellData {
    if is_out_of_bounds(location) {
        return CellData (STATE_NOTHING, STATE_NOTHING, 1.0);
    }
    let index = location.y * WORLD_WIDTH + location.x;
    return data[index];
}

@compute @workgroup_size(8, 8, 1)
fn init(@builtin(global_invocation_id) invocation_id: vec3<u32>, @builtin(num_workgroups) num_workgroups: vec3<u32>) {
    let index = invocation_id.y * num_workgroups.x + invocation_id.x;
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    let random_number = random_float(index);
    if random_number < 0.999 {
        set_cell_data(location, CellData (STATE_NOTHING, STATE_NOTHING, 1.0));
        return;
    }


    let type_number = random_float(index + num_workgroups.x * num_workgroups.y);

    var cell = STATE_NOTHING;

    if type_number < 0.33 {
        cell = STATE_ROCK;
    } else if type_number < 0.66 {
        cell = STATE_PAPER;
    } else {
        cell = STATE_SCISSORS;
    }

    set_cell_data(location, CellData (cell, cell, 1.0));
}

/// Channels:
/// - r - rock
/// - g - paper
/// - b - scissors
/// - a - empty
fn is_lose(current: CellData, neighbor: CellData) -> bool {
    return (current.state == STATE_ROCK && neighbor.state == STATE_PAPER)
            || (current.state == STATE_PAPER && neighbor.state == STATE_SCISSORS)
            || (current.state == STATE_SCISSORS && neighbor.state == STATE_ROCK)
            || (current.state == STATE_NOTHING && neighbor.state != STATE_NOTHING);
}

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    var current_cell = get_cell_data(location);

    let color = state_to_color(current_cell);

    if is_out_of_bounds(location) {
        textureStore(texture, location, color);
        return;
    }


    for (var x = -1; x <= 1; x = x + 1) {
        for (var y = -1; y <= 1; y = y + 1) {
            if (x == 0 && y == 0) {
                continue;
            }

            let pos = location + vec2<i32>(x, y);

            if is_out_of_bounds(pos) {
                continue;
            }

            let neighbor_cell = get_cell_data(pos);

            if is_lose(current_cell, neighbor_cell) {
                set_cell_data(location, neighbor_cell);

                textureStore(texture, location, state_to_color(neighbor_cell));
                return;
            }
        }
    }

    textureStore(texture, location, color);
}
