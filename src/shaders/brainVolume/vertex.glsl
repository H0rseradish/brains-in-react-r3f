// Code from https://github.com/mrdoob/three.js/blob/master/examples/jsm/shaders/VolumeShader.js and separated out into vertex.glsl

// NB I HAVE BRUNO-FIED IT!! For understanding.

varying vec3 vPosition;
varying vec4 vNearPosition;
varying vec4 vFarPosition;


void main() {
    // Prepare transforms to map to "camera view". See also:
    // https://threejs.org/docs/#api/renderers/webgl/WebGLProgram
    // mat4 viewtransformf = modelViewMatrix;

    // is it worth even making this variable here?
    mat4 viewToLocalMatrix = inverse(modelViewMatrix);

    
    // Project local vertex coordinate to camera position. Then do a step
    // backward (in cam coords) to the near clipping plane, and project back. Do
    // the same for the far clipping plane. This gives us all the information we
    // need to calculate the ray and truncate it to the viewing cone.
    // vec4 position4 = vec4(position, 1.0);

    // Bruno-ify getting to the final position:
    // vec4 modelPosition = modelMatrix * vec4(position, 1.0);
    // vec4 viewPosition = viewMatrix * modelPosition;
    // vec4 projectedPosition = projectionMatrix * viewPosition;
    // gl_Position = projectedPosition;


    vec4 viewPosition = modelViewMatrix * vec4(position, 1.0);
    //instead of this:
    // vec4 pos_in_cam = viewtransformf * position4;

    // Final position
    // gl_Position = projectionMatrix * viewMatrix * modelMatrix * vec4(position, 1.0);
    gl_Position = projectionMatrix * viewPosition;


    // Varyings
    // this reassigning to get the varyings was more difficult for me to understand and then felt nasty:
    // Intersection of ray and near clipping plane (z = -1 in clip coords)
    // pos_in_cam.z = -pos_in_cam.w;
    // vNearPosition = viewtransformi * pos_in_cam;
    // // Intersection of ray and far clipping plane (z = +1 in clip coords)
    // pos_in_cam.z = pos_in_cam.w;
    // vFarPosition = viewtransformi * pos_in_cam;

    // Bruno-fication plus pedestrianised by making some interim variables...

    vec4 nearViewPosition = viewPosition;
    // Intersection of ray and near clipping plane (z = -1 in clip coords)
    nearViewPosition.z = - viewPosition.w;

    vec4 farViewPosition = viewPosition;
    // Intersection of ray and far clipping plane (z = +1 in clip coords)
    farViewPosition.z = viewPosition.w;

    vNearPosition = viewToLocalMatrix * nearViewPosition;
    vFarPosition = viewToLocalMatrix * farViewPosition;
    vPosition = position;

}