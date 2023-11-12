@group(0) @binding(0) var texture: texture_storage_2d<rgba8unorm, read_write>;

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

fn randomFloat(value: u32) -> f32 {
    return f32(hash(value)) / 4294967295.0;
}

@compute @workgroup_size(8, 8, 1)
fn init(@builtin(global_invocation_id) invocation_id: vec3<u32>, @builtin(num_workgroups) num_workgroups: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    let index = invocation_id.y * num_workgroups.x + invocation_id.x;

    let random_number = randomFloat(index);
    if random_number < 0.999 {
        textureStore(texture, location, vec4<f32>(0.0, 0.0, 0.0, 1.0));
        return;
    }


    let type_number = randomFloat(index + num_workgroups.x * num_workgroups.y);

    var color = vec4<f32>(0.0, 0.0, 0.0, 1.0);

    if type_number < 0.33 {
        color = vec4<f32>(1.0, 0.0, 0.0, 1.0);
    } else if type_number < 0.66 {
        color = vec4<f32>(0.0, 1.0, 0.0, 1.0);
    } else {
        color = vec4<f32>(0.0, 0.0, 1.0, 1.0);
    }

    textureStore(texture, location, color);
}

fn is_out_of_bounds(pos: vec2<i32>) -> bool {
    if pos.y < 0 || pos.y >= i32(textureDimensions(texture).y) || pos.x < 0 || pos.x >= i32(textureDimensions(texture).x) {
        return true;
    }

    return false;
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

    let color = textureLoad(texture, location);

    for (var x = -1; x <= 1; x = x + 1) {
        for (var y = -1; y <= 1; y = y + 1) {
            if (x == 0 && y == 0) {
                continue;
            }

            let pos = location + vec2<i32>(x, y);

            if is_out_of_bounds(pos) {
                continue;
            }

            let neighbor = textureLoad(texture, pos);

            if is_lose(color, neighbor) {
                storageBarrier();

                textureStore(texture, location, neighbor);
                return;
            }
        }
    }

    storageBarrier();

    textureStore(texture, location, color);
}
