// val is determined by addlighting?

vec4 applyColorMap(float val) 
{
    // Normalize/clamp min/max values to 0.0 and 1.0? before applying the colorMap:
    val = (val - uColorMapValueRange[0]) / (uColorMapValueRange[1] - uColorMapValueRange[0]);
    return texture2D(uColorMapTexture, vec2(val, 0.5));
}