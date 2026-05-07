uniform vec3 uVolumeSize;

    varying vec3 vPosition;
    varying vec4 vNearPosition;
    varying vec4 vFarPosition;

    void main() {

        // Transform modelViewMatrix to get camera view to calculate the necessary varyings: 
        mat4 viewToLocalMatrix = inverse(modelViewMatrix);

        // Final position:

        vec4 viewPosition = modelViewMatrix * vec4(position, 1.0);
        vec4 projectedPosition = projectionMatrix * viewPosition;

        gl_Position = projectedPosition;

        // Varyings:

        // Intersection of the ray and near clipping plane (z = -1):
        vec4 nearViewPosition = viewPosition;
        nearViewPosition.z = - viewPosition.w;

        // Intersection of ray and far clipping plane (z = +1):
        vec4 farViewPosition = viewPosition;
        farViewPosition.z = viewPosition.w;

        // Offset for centering THIS IS WRONG ITS NOT IN 0,1 space:
        //vec3 volumeOffset = 0.5 * uVolumeSize;

        vNearPosition = viewToLocalMatrix * nearViewPosition;
        // vNearPosition.xyz += volumeOffset;
        vFarPosition = viewToLocalMatrix * farViewPosition;
        // vFarPosition.xyz += volumeOffset;

        vNearPosition.xyz += 0.5;
        vFarPosition.xyz += 0.5;

        // WRONG:
        // vPosition = position + volumeOffset;

        vPosition = position + 0.5;
    }