// Sample the volume: Given a position inside the volume, (or volumeDataTexture), return the stored intensity value:
float sampleVolume(vec3 volumeCoords)
{
    /* Sample float value from a 3D texture. Assumes intensity data. */
    return texture(uVolumeDataTexture, volumeCoords.xyz).r;
}