#import "shaders/constants.wgsl"::{WORLD_HEIGHT, WORLD_WIDTH};

fn is_out_of_bounds(l: vec2<i32>) -> bool {
    return l.y < 0 || l.y >= WORLD_HEIGHT || l.x < 0 || l.x >= WORLD_WIDTH;
}
