shader_type canvas_item;
uniform float radius = 0.5;
uniform bool invert = false;

void fragment() {
    float dist = distance(UV, vec2(0.5));
    if (invert) {
        if (dist < radius) discard; 
    } else {
        if (dist > radius) discard;
    }
}