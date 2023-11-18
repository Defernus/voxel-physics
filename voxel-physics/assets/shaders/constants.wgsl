const ERROR_COLOR = vec4<f32>(1.0, 1.0, 1.0, 1.0);

/// Just an empty void
const PARTICLE_NOTHING = 0u;
/// Regular particle with mass and impulse
const PARTICLE_REGULAR = 1u;
const CHANCE_OF_PARTICLE = 0.001;

const CELL_SIZE = 1.0;
const CELL_RADIUS = 0.5;

const PI = 3.14159265359;
const EPSILON = 0.00001;
const GRAVITY_CONSTANT = 1.0;
const DEFAULT_MASS = 1.0;
const CELL_CENTER = vec2<f32>(0.0, 0.0);

const WORLD_WIDTH = 1024i;
const WORLD_HEIGHT = 1024i;
/// Default simulatuion step duration
const DEFAULT_STEP_DURATION = 1.0f;
