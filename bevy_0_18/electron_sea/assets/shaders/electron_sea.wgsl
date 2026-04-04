// electron_sea.wgsl — Electron Sea
// For Bevy 0.18 FullscreenMaterial
//
// Internal layout of FullscreenMaterial (from official samples):
//   @group(0) @binding(0) -> screen_texture (previous frame)
//   @group(0) @binding(1) -> texture_sampler
//   @group(0) @binding(2) -> user uniform <- placed here

#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput

struct ElectronSeaMaterial {
    time: f32,
    resolution: vec2<f32>,
}

// Place in binding(2)
@group(0) @binding(2)
var<uniform> mat: ElectronSeaMaterial;

// -- Utilities ---------------------------------------------------------------

fn hash2(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(127.1, 311.7))) * 43758.5453);
}

fn vnoise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash2(i),                       hash2(i + vec2<f32>(1.0, 0.0)), u.x),
        mix(hash2(i + vec2<f32>(0.0, 1.0)), hash2(i + vec2<f32>(1.0, 1.0)), u.x),
        u.y
    );
}

fn fbm(p: vec2<f32>) -> f32 {
    var val: f32 = 0.0;
    var amp: f32  = 0.5;
    var pp: vec2<f32> = p;
    for (var i: i32 = 0; i < 5; i++) {
        val += amp * vnoise(pp);
        pp  *= 2.1;
        amp *= 0.5;
    }
    return val;
}

fn smin(a: f32, edge0: f32, edge1: f32) -> f32 {
    return 1.0 - smoothstep(edge0, edge1, a);
}

// -- Fragment Shader ---------------------------------------------------------

@fragment
fn fragment(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    let uv  = in.uv;
    let t   = mat.time;
    let res = mat.resolution;
    let asp = res.x / res.y;

    let COLS: f32 = 28.0;
    let ROWS: f32 = COLS / asp;
    let cell = vec2<f32>(uv.x * COLS, uv.y * ROWS);
    let ci   = floor(cell);
    let cf   = fract(cell);

    let wave =
          fbm(ci * 0.18 + vec2<f32>(t * 0.22, t * 0.14))
        + 0.40 * sin(ci.x * 0.6  + t * 1.10)
        + 0.30 * cos(ci.y * 0.7  - t * 0.80)
        + 0.25 * sin((ci.x + ci.y) * 0.4 + t * 1.40);

    var energy: f32 = clamp((wave + 1.2) * 0.42, 0.0, 1.0);

    let center_dist = length(ci - vec2<f32>(COLS * 0.5, ROWS * 0.5)) * 0.09;
    let ripple      = 0.5 + 0.5 * sin(center_dist * 6.0 - t * 2.5);
    energy          = mix(energy, energy * ripple, 0.3);

    let pulse = 0.5 + 0.5 * sin(t * 2.8 + hash2(ci) * 6.2831);
    let ep    = energy * (0.7 + 0.3 * pulse);

    let line_w = 0.018 + energy * 0.012;
    let lineH  = smin(abs(cf.y - 0.5), 0.0, line_w);
    let lineV  = smin(abs(cf.x - 0.5), 0.0, line_w);
    let lines  = max(lineH, lineV);

    let dot_r = 0.045 + ep * 0.065;
    let dot_d = length(cf - vec2<f32>(0.5));
    let dot   = smin(dot_d, dot_r - 0.01, dot_r + 0.01);

    let elec_prob   = hash2(ci + vec2<f32>(3.1,  7.3));
    let elec_phase  = hash2(ci + vec2<f32>(13.7, 5.1)) * 6.2831;
    let elec_active = select(0.0, 1.0, elec_prob > 0.82);
    let elec_pulse  = 0.5 + 0.5 * sin(t * 4.5 + elec_phase);
    let elec_glow   = elec_active * elec_pulse * smin(dot_d, 0.0, 0.18);

    let c_cyan    = vec3<f32>(0.0,  0.80, 1.0);
    let c_emerald = vec3<f32>(0.2,  1.0,  0.7);
    let c_purple  = vec3<f32>(0.6,  0.3,  1.0);
    let c_white   = vec3<f32>(1.0,  0.9,  1.0);

    var line_color = mix(c_cyan, c_emerald, energy);
    line_color     = mix(line_color, c_purple, elec_active * elec_pulse * 0.5);

    var dot_color  = mix(c_emerald, c_cyan, energy);
    dot_color      = mix(dot_color, c_white, elec_active * elec_pulse * 0.8);

    let bg_color   = vec3<f32>(0.008, 0.022, 0.06);

    let line_alpha = lines * (0.10 + energy * 0.55) * (0.7 + 0.3 * pulse);
    let dot_alpha  = dot  * (0.30 + ep * 0.70);
    let elec_alpha = elec_glow * 0.45;

    var col = bg_color;
    col = mix(col, line_color, line_alpha);
    col = mix(col, dot_color,  dot_alpha);
    col += line_color * elec_alpha;

    let scan_line = 0.92 + 0.08 * sin(uv.y * res.y * 1.5);
    col *= scan_line;

    let vign = 1.0 - smoothstep(0.4, 1.0, length(uv - vec2<f32>(0.5)) * 1.4);
    col *= vign;

    return vec4<f32>(col, 1.0);
}