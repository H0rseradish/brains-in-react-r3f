// Code from https://github.com/mrdoob/three.js/blob/master/examples/jsm/shaders/VolumeShader.js and separated out into vertex.glsl
// 'BRUNO-FIED' For understanding.

uniform vec3 uVolumeSize;

varying vec3 vPosition;
varying vec4 vNearPosition;
varying vec4 vFarPosition;


void main() {
    // Prepare transforms to map to "camera view" (Bruno usually refers to viewPosition). See also:
    // https://threejs.org/docs/#api/renderers/webgl/WebGLProgram

    // mat4 viewtransformf = modelViewMatrix;
    // is it worth even making this variable here?
    mat4 viewToLocalMatrix = inverse(modelViewMatrix);

    
    // Project local vertex coordinate to camera position (aka viewPosition). 
    // Then do a step backward (in cam coords) to the near clipping plane, and project back. 
    // Do the same for the far clipping plane. This gives us all the information we need to calculate the ray and truncate it to the viewing cone.
    vec4 viewPosition = modelViewMatrix * vec4(position, 1.0);
    // ...more readable to me than this: vec4 pos_in_cam = viewtransformf * position4;

    // Final position
    // gl_Position = projectionMatrix * viewMatrix * modelMatrix * vec4(position, 1.0);
    gl_Position = projectionMatrix * viewPosition;

    // Varyings:
    // First, remember that the clipping plane values x y and z go from -1.0 to 1.0 

    // Intersection of ray and near clipping plane (z = -1 in clip coords) (via making an interim variable for clarity)
    vec4 nearViewPosition = viewPosition;
    nearViewPosition.z = - viewPosition.w;

    // Intersection of ray and far clipping plane (z = +1 in clip coords)
    vec4 farViewPosition = viewPosition;
    farViewPosition.z = viewPosition.w;

    //attempting to sort the centering issue here instaed of in the fragment calcs
    vec3 volumeOffset = 0.5 * uVolumeSize;

    vNearPosition = viewToLocalMatrix * nearViewPosition;
    vNearPosition.xyz += volumeOffset;

    vFarPosition = viewToLocalMatrix * farViewPosition;
    vFarPosition.xyz += volumeOffset;

    vPosition = position + volumeOffset;

}