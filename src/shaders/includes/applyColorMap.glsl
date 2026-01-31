// shadedScalarValue is an out from addlighting - it is the result of modifying hitValue/scalarValue in addLighting

vec4 applyColorMap(float shadedScalarValue) 
{
    // Normalize/clamp min/max values to 0.0 and 1.0? before applying the colorMap:
    shadedScalarValue = (shadedScalarValue - uColorMapValueRange[0]) / (uColorMapValueRange[1] - uColorMapValueRange[0]);
    return texture2D(uColorMapTexture, vec2(shadedScalarValue, 0.5));
}