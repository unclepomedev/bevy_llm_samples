#import bevy_pbr::forward_io::VertexOutput

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    let emission_wave = in.color.r;
    let armor_mask = in.color.g;

    let armor_color = vec3<f32>(0.3, 0.3, 0.3);
    let groove_color = vec3<f32>(0.05, 0.05, 0.05);
    let base_color = mix(groove_color, armor_color, armor_mask);

    let glow_color = vec3<f32>(0.0, 0.8, 1.0);
    let emissive = glow_color * emission_wave;
    let surface_color = base_color + emissive;

    // Extract edge by thresholding the screen-space variance of normals
    let normal_change = fwidth(in.world_normal);
    let edge_intensity = length(normal_change);
    let is_edge = step(0.01, edge_intensity);

    let edge_color = vec3<f32>(1.0, 1.0, 1.0);
    let final_color = mix(surface_color, edge_color, is_edge);

    return vec4<f32>(final_color, 1.0);
}
