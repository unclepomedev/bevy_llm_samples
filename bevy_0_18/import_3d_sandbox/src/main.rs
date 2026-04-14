use bevy::prelude::*;
use bevy::render::render_resource::AsBindGroup;
use bevy::shader::ShaderRef;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugins(MaterialPlugin::<TurretMaterial>::default())
        .add_systems(Startup, setup)
        .run();
}

#[derive(Asset, TypePath, AsBindGroup, Debug, Clone, Default)]
struct TurretMaterial {}

impl Material for TurretMaterial {
    fn fragment_shader() -> ShaderRef {
        "shaders/turret.wgsl".into()
    }
}

fn setup(
    mut commands: Commands,
    asset_server: Res<AssetServer>,
    mut materials: ResMut<Assets<TurretMaterial>>,
) {
    commands.spawn((
        DirectionalLight::default(),
        Transform::from_xyz(10.0, 10.0, 10.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));

    commands.spawn((
        Camera3d::default(),
        Transform::from_xyz(5.0, 5.0, 5.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));

    commands.spawn((
        Mesh3d(asset_server.load("models/turret.glb#Mesh0/Primitive0")),
        MeshMaterial3d(materials.add(TurretMaterial::default())),
    ));
}
