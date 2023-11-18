#import "shaders/world_data.wgsl"::{CellData, get_prev_cell};
#import "shaders/constants.wgsl"::{EPSILON, PARTICLE_NOTHING};

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
