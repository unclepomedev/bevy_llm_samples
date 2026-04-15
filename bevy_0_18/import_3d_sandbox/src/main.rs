use bevy::prelude::*;
use bevy::render::render_resource::AsBindGroup;
use bevy::shader::ShaderRef;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugins(MaterialPlugin::<TurretMaterial>::default())
        .add_systems(Startup, setup)
        .add_systems(Update, (apply_material, fire_input, animate_recoil))
        .run();
}

#[derive(Asset, TypePath, AsBindGroup, Debug, Clone, Default)]
struct TurretMaterial {}

impl Material for TurretMaterial {
    fn fragment_shader() -> ShaderRef {
        "shaders/turret.wgsl".into()
    }
}

fn setup(mut commands: Commands, asset_server: Res<AssetServer>) {
    commands.spawn((
        DirectionalLight::default(),
        Transform::from_xyz(10.0, 10.0, 10.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));

    commands.spawn((
        Camera3d::default(),
        Transform::from_xyz(5.0, 5.0, 5.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));

    commands.spawn(SceneRoot(
        asset_server.load(GltfAssetLabel::Scene(0).from_asset("models/turret.glb")),
    ));
}

fn apply_material(
    mut commands: Commands,
    query: Query<Entity, Added<Mesh3d>>,
    mut materials: ResMut<Assets<TurretMaterial>>,
) {
    let material_handle = materials.add(TurretMaterial::default());
    for entity in &query {
        commands
            .entity(entity)
            .insert(MeshMaterial3d(material_handle.clone()));
    }
}

#[derive(Component)]
struct RecoilAnimation {
    timer: f32,
    start_z: f32,
}

fn fire_input(
    mouse: Res<ButtonInput<MouseButton>>,
    mut commands: Commands,
    query: Query<(Entity, &Name, &Transform)>,
) {
    if mouse.just_pressed(MouseButton::Left) {
        for (entity, name, transform) in &query {
            if name.as_str() == "pitch" {
                commands.entity(entity).insert(RecoilAnimation {
                    timer: 0.1,
                    start_z: transform.translation.z,
                });
            }
        }
    }
}

fn animate_recoil(
    time: Res<Time>,
    mut query: Query<(&mut Transform, &mut RecoilAnimation, Entity)>,
    mut commands: Commands,
) {
    for (mut transform, mut recoil, entity) in &mut query {
        recoil.timer -= time.delta_secs();

        let progress = (recoil.timer / 0.1).max(0.0);
        let offset = progress * -0.15;

        transform.translation.z = recoil.start_z + offset;

        if recoil.timer <= 0.0 {
            transform.translation.z = recoil.start_z;
            commands.entity(entity).remove::<RecoilAnimation>();
        }
    }
}
