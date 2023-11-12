use bevy::render::render_resource::CachedPipelineState;

pub trait PipelineStateUtils {
    fn is_ok(&self) -> bool;

    fn is_err(&self) -> bool;

    fn is_queued(&self) -> bool;
}

impl PipelineStateUtils for CachedPipelineState {
    fn is_ok(&self) -> bool {
        matches!(self, CachedPipelineState::Ok(_))
    }

    fn is_err(&self) -> bool {
        matches!(self, CachedPipelineState::Err(_))
    }

    fn is_queued(&self) -> bool {
        matches!(self, CachedPipelineState::Queued)
    }
}
