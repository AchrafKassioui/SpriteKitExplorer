void main() {
    vec2 uv = v_tex_coord;
    vec4 blurColor = vec4(0.0);
    // Adjust for more/less blur
    float offset = 0.01;
    
    for (float i = -3.0; i <= 3.0; i++) {
        blurColor += texture2D(u_texture, uv + vec2(i * offset, 0.0));
    }
    blurColor /= 7.0;
    
    gl_FragColor = blurColor;
}

