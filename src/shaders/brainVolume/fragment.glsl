// Code from https://github.com/mrdoob/three.js/blob/master/examples/jsm/shaders/VolumeShader.js and separated out into fragment.glsl`

precision highp float;
precision mediump sampler3D;

uniform vec3 uVolumeSize;
// uniform int u_renderstyle;
uniform float uIsoSurfaceThreshold;
uniform vec2 uColorMapValueRange;

uniform sampler3D uVolumeDataTexture;
uniform sampler2D uColorMapTexture;

varying vec3 vPosition;
varying vec4 vNearPosition;
varying vec4 vFarPosition;

#include ../includes/constants.glsl
// Moved constants into includes



//---------------
// These can come in as uniforms or not at all ?:
// they are overidden in the lighting function anyway, so...?
vec4 ambient_color = vec4(0.2, 0.4, 0.2, 1.0);
vec4 diffuse_color = vec4(0.8, 0.2, 0.2, 1.0);
vec4 specular_color = vec4(1.0, 1.0, 1.0, 1.0);
float shininess = 40.0;


// Functions are declared BEFORE use because order matters - maybe move the actual definitions above void main to be Bruno-esque??) and RENAME also. OR as includes???
// Do not need MIP stuff:
// void cast_mip(vec3 rayStartTextureCoords, vec3 step, int stepCount, vec3 viewRayDirection);
// rayStepTextureCoords??
void raycastIsoSurface(vec3 rayStartTextureCoords, vec3 rayStep, int stepCount, vec3 viewRayDirection); 
float sampleVolume(vec3 texcoords); 
vec4 applyColorMap(float val);
vec4 addLighting(float val, vec3 loc, vec3 rayStep, vec3 viewRayDirection);


void main() {
    // Normalize clipping plane info
    vec3 farPosition = vFarPosition.xyz / vFarPosition.w;
    vec3 nearPosition = vNearPosition.xyz / vNearPosition.w;

    // Calculate unit vector pointing in the view direction through this fragment.
    vec3 viewRayDirection = normalize(nearPosition.xyz - farPosition.xyz);

    // Compute the (negative) distance to the front surface or near clipping plane.
    // vPosition is the back face of the cuboid, so the initial distance calculated in the dot
    // product below is the distance from near clip plane to the back of the cuboid
    // RENAMED to rayEntryDistance?? (especially because distance() is actually a function!!!!)
    float rayEntryDistance = dot(nearPosition - vPosition, viewRayDirection);


    //get rid of all the -0.5s - they are confusing the issue YES THEY WERE!!! centering now happens in the vertex.
    rayEntryDistance = max(
        rayEntryDistance, 
        min(
            //this might he the root of the centering issue? the shader is working on the geometry being centered? I thought it WAS??? It is conflicting?
            ( - vPosition.x) / viewRayDirection.x,
            (uVolumeSize.x  - vPosition.x) / viewRayDirection.x
        )
    );

    rayEntryDistance = max(
        rayEntryDistance, 
        min(
            ( - vPosition.y) / viewRayDirection.y,
            (uVolumeSize.y  - vPosition.y) / viewRayDirection.y
        )
    );

    rayEntryDistance = max(
        rayEntryDistance, 
        min(
            ( - vPosition.z) / viewRayDirection.z,
        (uVolumeSize.z  - vPosition.z) / viewRayDirection.z)
    );

    // Now we have the starting position on the front surface
    //RENAME to rayEntryPosition? front on its own doesnt mean much?
    vec3 front = vPosition + viewRayDirection * rayEntryDistance;

    // Decide how many steps to take
    int stepCount = int(- rayEntryDistance / RELATIVE_STEP_SIZE + 0.5);
    if ( stepCount < 1 )
            discard;

    // Get starting location and step vector in texture coordinates
    vec3 rayStep = ((vPosition - front) / uVolumeSize) / float(stepCount);
    vec3 rayStartTextureCoords = front / uVolumeSize;

    // For testing: show the number of steps. This helps to establish
    // whether the rays are correctly oriented
    //'gl_FragColor = vec4(0.0, float(stepCount) / 1.0 / uVolumeSize.x, 1.0, 1.0);
    //'return;

    // Then Raycast ISO:
    raycastIsoSurface(rayStartTextureCoords, rayStep, stepCount, viewRayDirection);

    if (gl_FragColor.a < 0.05)
            discard;
}

/* 
* FUNCTIONS
*/



// Sample the volume (aka pick from the texture??):
float sampleVolume(vec3 texcoords)
{
    /* Sample float value from a 3D texture. Assumes intensity data. */
    return texture(uVolumeDataTexture, texcoords.xyz).r;
}

// function to apply the colorMap
vec4 applyColorMap(float val) 
{
    // Normalize/clamp min/max values to 0.0 and 1.0? before applying the colorMap:
    val = (val - uColorMapValueRange[0]) / (uColorMapValueRange[1] - uColorMapValueRange[0]);
    return texture2D(uColorMapTexture, vec2(val, 0.5));
}


/*
* ISO Raycasting
*/


void raycastIsoSurface(vec3 rayStartTextureCoords, vec3 rayStep, int stepCount, vec3 viewRayDirection) 
{
    gl_FragColor = vec4(0.0);	// init transparent
    vec4 color3 = vec4(0.0);	// final color
    vec3 dstep = 1.5 / uVolumeSize;	// step to sample derivative
    vec3 loc = rayStartTextureCoords;

    float low_threshold = uIsoSurfaceThreshold - 0.02 * (uColorMapValueRange[1] - uColorMapValueRange[0]);

    // Enter the raycasting loop. In WebGL 1 the loop index cannot be compared with
    // non-constant expression. So we use a hard-coded max, and an additional condition
    // inside the loop.
    for (int iter = 0; iter < MAX_STEPS; iter++) {
            if (iter >= stepCount)
                    break;

            // Sample from the 3D texture
            float val = sampleVolume(loc);

            if (val > low_threshold) {
                    // Take the last interval in smaller steps
                    vec3 iloc = loc - 0.5 * rayStep;
                    vec3 istep = rayStep / float(REFINEMENT_STEPS);
                    for (int i = 0; i < REFINEMENT_STEPS; i++) {
                            val = sampleVolume(iloc);
                            if (val > uIsoSurfaceThreshold) {
                                    gl_FragColor = addLighting(val, iloc, dstep, viewRayDirection);
                                    return;
                            }
                            iloc += istep;
                    }
            }
            // Advance location deeper into the volume
            loc += rayStep;
    }
}


/* 
Lighting - Move into an includes?
*/

vec4 addLighting(float val, vec3 loc, vec3 rayStep, vec3 viewRayDirection)
{
    // Calculate color by incorporating lighting

    // View direction
    vec3 V = normalize(viewRayDirection);

    // calculate normal vector from gradient
    vec3 N;
    float val1, val2;

    val1 = sampleVolume(loc + vec3(-rayStep[0], 0.0, 0.0));
    val2 = sampleVolume(loc + vec3(+rayStep[0], 0.0, 0.0));
    N[0] = val1 - val2;
    val = max(max(val1, val2), val);
    val1 = sampleVolume(loc + vec3(0.0, -rayStep[1], 0.0));
    val2 = sampleVolume(loc + vec3(0.0, +rayStep[1], 0.0));
    N[1] = val1 - val2;
    val = max(max(val1, val2), val);
    val1 = sampleVolume(loc + vec3(0.0, 0.0, -rayStep[2]));
    val2 = sampleVolume(loc + vec3(0.0, 0.0, +rayStep[2]));
    N[2] = val1 - val2;
    val = max(max(val1, val2), val);

    float gm = length(N); // gradient magnitude
    N = normalize(N);

    // Flip normal so it points towards viewer
    float Nselect = float(dot(N, V) > 0.0);
    N = (2.0 * Nselect - 1.0) * N;	// ==	Nselect * N - (1.0-Nselect)*N;

    // Init colors
    vec4 ambient_color = vec4(0.0, 0.0, 0.0, 0.0);
    vec4 diffuse_color = vec4(0.0, 0.0, 0.0, 0.0);
    vec4 specular_color = vec4(0.0, 0.0, 0.0, 0.0);

    // note: could allow multiple lights
    for (int i = 0; i < 1; i++)
    {
            // Get light direction (make sure to prevent zero division)
            vec3 L = normalize(viewRayDirection);	//lightDirs[i];
            float lightEnabled = float( length(L) > 0.0 );
            L = normalize(L + (1.0 - lightEnabled));

            // Calculate lighting properties
            float lambertTerm = clamp(dot(N, L), 0.0, 1.0);
            vec3 H = normalize(L+V); // Halfway vector
            float specularTerm = pow(max(dot(H, N), 0.0), shininess);

            // Calculate mask
            float mask1 = lightEnabled;

            // Calculate colors
            ambient_color +=	mask1 * ambient_color;	// * gl_LightSource[i].ambient;
            diffuse_color +=	mask1 * lambertTerm;
            specular_color += mask1 * specularTerm * specular_color;
    }

    // Calculate final color by componing different components
    vec4 final_color;
    vec4 color = applyColorMap(val);

    final_color = color * (ambient_color + diffuse_color) + specular_color;
    final_color.a = color.a;

    return final_color;
}

