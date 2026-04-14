#import bevy_pbr::forward_io::VertexOutput
#import bevy_pbr::mesh_view_bindings::globals

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    let noise_mask = in.color.r;
    let armor_mask = in.color.g;

    let armor_color = vec3<f32>(0.4, 0.4, 0.4);
    let groove_color = vec3<f32>(0.05, 0.05, 0.05);
    let base_color = mix(groove_color, armor_color, armor_mask);

    let light_dir = normalize(vec3<f32>(0.8, 1.0, 0.5));
    let shading = max(dot(in.world_normal, light_dir), 0.0) * 0.6 + 0.4;
    let shaded_base = base_color * shading;

    let wave_freq = 15.0;
    let wave_speed = 3.0;
    let scrolling_wave = sin(in.world_position.y * wave_freq - globals.time * wave_speed) * 0.5 + 0.5;

    let is_groove = 1.0 - armor_mask;
    let animate_pulse = scrolling_wave * noise_mask * is_groove;

    let glow_color = vec3<f32>(0.0, 0.8, 1.0);
    let emissive = glow_color * animate_pulse * 3.0;

    return vec4<f32>(shaded_base + emissive, 1.0);
}
