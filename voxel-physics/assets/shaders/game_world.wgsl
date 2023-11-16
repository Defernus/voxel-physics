@group(0) @binding(0) var texture: texture_storage_2d<rgba8unorm, read_write>;
@group(0) @binding(1) var<storage, read_write> data: array<vec4<f32>>;

const WORLD_WIDTH = 1280i;
const WORLD_HEIGHT = 720i;

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
fn set_cell_data(location: vec2<i32>, value: vec4<f32>) {
    if is_out_of_bounds(location) {
        return;
    }

    let index = location.y * WORLD_WIDTH + location.x;
    data[index] = value;
}

/// Get vec4 from data array
fn get_cell_data(location: vec2<i32>) -> vec4<f32> {
    if is_out_of_bounds(location) {
        return vec4<f32>(0.0, 0.0, 0.0, 0.0);
    }
    let index = location.y * WORLD_WIDTH + location.x;
    return data[index];
}

@compute @workgroup_size(8, 8, 1)
fn init(@builtin(global_invocation_id) invocation_id: vec3<u32>, @builtin(num_workgroups) num_workgroups: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    let index = invocation_id.y * num_workgroups.x + invocation_id.x;

    let random_number = random_float(index);
    if random_number < 0.999 {
        set_cell_data(location, vec4<f32>(0.0, 0.0, 0.0, 0.0));
        return;
    }


    let type_number = random_float(index + num_workgroups.x * num_workgroups.y);

    var cell = vec4<f32>(0.0, 0.0, 0.0, 0.0);

    if type_number < 0.33 {
        cell = vec4<f32>(1.0, 0.0, 0.0, 0.0);
    } else if type_number < 0.66 {
        cell = vec4<f32>(0.0, 1.0, 0.0, 0.0);
    } else {
        cell = vec4<f32>(0.0, 0.0, 1.0, 0.0);
    }

    set_cell_data(location, cell);
}

/// Channels:
/// - r - rock
/// - g - paper
/// - b - scissors
/// - a - empty
fn is_lose(current: vec4<f32>, neighbor: vec4<f32>) -> bool {
    if current.x > 0.5 && neighbor.y > 0.5 {
        return true;
    }
    if current.y > 0.5 && neighbor.z > 0.5 {
        return true;
    }
    if current.z > 0.5 && neighbor.x > 0.5 {
        return true;
    }
    return  current.x < 0.5 && current.y < 0.5 && current.z < 0.5
        && (neighbor.x > 0.5 || neighbor.y > 0.5 || neighbor.z > 0.5);
}

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    var current_cell = get_cell_data(location);

    let color = vec4<f32>(current_cell.x, current_cell.y, current_cell.z, 1.0);

    if is_out_of_bounds(location) {
        // storageBarrier();

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
                // storageBarrier();

                textureStore(texture, location, vec4<f32>(neighbor_cell.x, neighbor_cell.y, neighbor_cell.z, 1.0));
                return;
            }
        }
    }

    // storageBarrier();

    textureStore(texture, location, color);
}
