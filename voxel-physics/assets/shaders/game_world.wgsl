#import "shaders/world_data.wgsl"::{texture, CellData, set_next_cell, get_prev_cell, new_empty_cell, new_particle_cell, cell_to_color};
#import "shaders/constants.wgsl"::{
    WORLD_WIDTH,
    WORLD_HEIGHT,
    DEFAULT_STEP_DURATION,
    DEFAULT_MASS,
    CHANCE_OF_PARTICLE,
    PARTICLE_NOTHING,
    PARTICLE_REGULAR,
    PARTICLE_SOURCE,
    CELL_RADIUS,
    CELL_CENTER,
    EPSILON,
};
#import "shaders/gravity_data.wgsl"::{
    get_cell_gravity_data,
};
#import "shaders/utils.wgsl"::{
    is_out_of_bounds,
};
#import "shaders/random.wgsl"::{
    random_float,
};

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

    let gravity_00 = get_cell_gravity_data(current, location, location + vec2<i32>(-1, -1));
    let gravity_10 = get_cell_gravity_data(current, location, location + vec2<i32>(0, -1));
    let gravity_20 = get_cell_gravity_data(current, location, location + vec2<i32>(1, -1));
    let gravity_01 = get_cell_gravity_data(current, location, location + vec2<i32>(-1, 0));
    let gravity_21 = get_cell_gravity_data(current, location, location + vec2<i32>(1, 0));
    let gravity_02 = get_cell_gravity_data(current, location, location + vec2<i32>(-1, 1));
    let gravity_12 = get_cell_gravity_data(current, location, location + vec2<i32>(0, 1));
    let gravity_22 = get_cell_gravity_data(current, location, location + vec2<i32>(1, 1));

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

fn delta_time() -> f32 {
    return DEFAULT_STEP_DURATION;
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
