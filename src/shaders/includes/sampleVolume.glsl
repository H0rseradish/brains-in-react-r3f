// Sample the volume: given a position inside the volume, return the stored value:
float sampleVolume(vec3 volumeCoords)
{
    /* Sample float value from a 3D texture. Assumes intensity data. */
    return texture(uVolumeDataTexture, volumeCoords.xyz).r;
}