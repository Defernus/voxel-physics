use bevy::{prelude::*, reflect::GetTypeRegistration};

/// Helper trait for **adding and registering resources in one step**, to avoid
/// forgetting to register a resource's type.
pub trait AddAndRegisterRes {
    fn init_and_register_res<T: Resource + FromWorld + GetTypeRegistration>(&mut self)
        -> &mut Self;
    fn insert_and_register_res<T: Resource + GetTypeRegistration>(
        &mut self,
        resource: T,
    ) -> &mut Self;
}

impl AddAndRegisterRes for App {
    /// Initialize resource and register its type.
    fn init_and_register_res<T: Resource + FromWorld + GetTypeRegistration>(
        &mut self,
    ) -> &mut Self {
        self.init_resource::<T>().register_type::<T>()
    }

    /// Insert resource and register its type.
    fn insert_and_register_res<T: Resource + GetTypeRegistration>(
        &mut self,
        resource: T,
    ) -> &mut Self {
        self.insert_resource(resource).register_type::<T>()
    }
}
