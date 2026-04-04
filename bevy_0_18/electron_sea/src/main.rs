//! Electron Sea — Bevy 0.18 FullscreenMaterial
//!
//! Usage: cargo run

use bevy::{
    core_pipeline::{
        core_3d::graph::Node3d,
        fullscreen_material::{FullscreenMaterial, FullscreenMaterialPlugin},
    },
    prelude::*,
    reflect::TypePath,
    render::{
        extract_component::ExtractComponent,
        render_graph::{InternedRenderLabel, RenderLabel},
        render_resource::ShaderType,
    },
    shader::ShaderRef,
};

const SHADER_PATH: &str = "shaders/electron_sea.wgsl";

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "Electron Sea — Bevy 0.18 WGSL".into(),
                ..default()
            }),
            ..default()
        }))
        .add_plugins(FullscreenMaterialPlugin::<ElectronSeaMaterial>::default())
        .add_systems(Startup, setup)
        .add_systems(Update, update_time)
        .run();
}

// -- Material ----------------------------------------------------------------
//
// Constraints for FullscreenMaterial (identified via compiler errors):
//   Component + ExtractComponent + Clone + Copy + ShaderType + WriteInto + Default
//
// -> The entire struct must be a "flat type" directly writable to the GPU.
//    Handled collectively via #[derive(ShaderType)].
//    (AsBindGroup is not required — FullscreenMaterial handles it internally).

#[derive(Component, ExtractComponent, Clone, Copy, Default, ShaderType, TypePath)]
struct ElectronSeaMaterial {
    time: f32,
    resolution: Vec2,
}

impl FullscreenMaterial for ElectronSeaMaterial {
    fn fragment_shader() -> ShaderRef {
        SHADER_PATH.into()
    }

    fn node_edges() -> Vec<InternedRenderLabel> {
        vec![
            Node3d::Tonemapping.intern(),
            Self::node_label().intern(),
            Node3d::EndMainPassPostProcessing.intern(),
        ]
    }
}

// -- Setup -------------------------------------------------------------------

fn setup(mut commands: Commands) {
    // FullscreenMaterial is attached directly to the Camera as a Component.
    commands.spawn((Camera3d::default(), ElectronSeaMaterial::default()));
}

// -- Per-frame Update --------------------------------------------------------

fn update_time(time: Res<Time>, windows: Query<&Window>, mut q: Query<&mut ElectronSeaMaterial>) {
    let resolution = match windows.single() {
        Ok(w) => Vec2::new(w.width(), w.height()),
        Err(_) => Vec2::new(1280.0, 720.0),
    };

    for mut mat in &mut q {
        mat.time = time.elapsed_secs();
        mat.resolution = resolution;
    }
}
