shader_type canvas_item;

// A cor do seu filtro
uniform vec4 tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

// A intensidade do filtro (0.0 = sprite original, 1.0 = cor sólida)
uniform float mix_weight : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    // Lê a cor original do pixel
    vec4 original_color = texture(TEXTURE, UV);
    
    // Mistura a cor RGB original com a nova cor baseada no mix_weight
    vec3 blended_color = mix(original_color.rgb, tint_color.rgb, mix_weight);
    
    // Aplica a cor misturada, mas preserva a transparência (alpha) exata do sprite
    COLOR = vec4(blended_color, original_color.a);
}