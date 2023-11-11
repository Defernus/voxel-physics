use bevy::{prelude::*, render::render_resource::TextureUsages};

pub trait ImageUtils {
    fn with_description_usage(self, usage: TextureUsages) -> Self;
}

impl ImageUtils for Image {
    fn with_description_usage(mut self, usage: TextureUsages) -> Self {
        self.texture_descriptor.usage = usage;
        self
    }
}
