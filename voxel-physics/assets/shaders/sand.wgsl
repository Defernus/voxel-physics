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

    let randomNumber = randomFloat(invocation_id.y * num_workgroups.x + invocation_id.x);
    let alive = randomNumber > 0.9;
    let color = vec4<f32>(f32(alive));

    textureStore(texture, location, color);
}

fn is_out_of_bounds(pos: vec2<i32>) -> bool {
    if pos.y < 0 || pos.y >= i32(textureDimensions(texture).y) || pos.x < 0 || pos.x >= i32(textureDimensions(texture).x) {
        return true;
    }

    return false;
}

fn is_solid(location: vec2<i32>, offset_x: i32, offset_y: i32) -> bool {
    let pos = location + vec2<i32>(offset_x, -offset_y);

    if is_out_of_bounds(pos) {
        return true;
    }

    let value: vec4<f32> = textureLoad(texture, pos);
    return bool(value.x);
}

fn is_sand(location: vec2<i32>, offset_x: i32, offset_y: i32) -> bool {
    let pos = location + vec2<i32>(offset_x, -offset_y);

    if is_out_of_bounds(pos) {
        return false;
    }

    let value: vec4<f32> = textureLoad(texture, pos);
    return bool(value.x);
}

@compute @workgroup_size(8, 8, 1)
fn update(@builtin(global_invocation_id) invocation_id: vec3<u32>) {
    let location = vec2<i32>(i32(invocation_id.x), i32(invocation_id.y));

    var alive = is_sand(location, 0, 0) || is_sand(location, 0, 1);

    if is_sand(location, 0, 0) && !is_solid(location, 0, -1) {
        alive = false;
    } else if is_sand(location, 0, 0) && !is_solid(location, 1, 0) && !is_solid(location, 1, -1) {
        alive = false;
    } else if !is_sand(location, 0, 0) && is_sand(location, -1, 1) && is_solid(location, -1, 0) && !is_solid(location, 0, 1) {
        alive = true;
    } else if is_sand(location, 0, 0) && !is_solid(location, -1, 0) && !is_solid(location, -1, -1) {
        alive = false;
    } else if !is_sand(location, 0, 0) && is_sand(location, 1, 1) && is_solid(location, 1, 0) && !is_solid(location, 0, 1) {
        alive = true;
    }

    let color = vec4<f32>(f32(alive));

    storageBarrier();

    textureStore(texture, location, color);
}
