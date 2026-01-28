// Code from https://github.com/mrdoob/three.js/blob/master/examples/jsm/shaders/VolumeShader.js and separated out into fragment.glsl`

precision highp float;
precision mediump sampler3D;

uniform vec3 uVolumeSize;
uniform float uIsoSurfaceThreshold;
uniform vec2 uColorMapValueRange;

uniform sampler3D uVolumeDataTexture;
uniform sampler2D uColorMapTexture;

varying vec3 vPosition;
varying vec4 vNearPosition;
varying vec4 vFarPosition;

#include ../includes/constants.glsl
#include ../includes/sampleVolume.glsl
#include ../includes/applyColorMap.glsl


//---------------
// These can come in as uniforms or not at all ?:
// they are overidden in the lighting function anyway, so...?
// vec4 ambient_color = vec4(0.2, 0.4, 0.2, 1.0);
// vec4 diffuse_color = vec4(0.8, 0.2, 0.2, 1.0);
// vec4 specular_color = vec4(1.0, 1.0, 1.0, 1.0);
// Still need this one though... or would it be better elsewhere???
float shininess = 40.0;


// Functions are declared BEFORE use because order matters - maybe move the actual definitions above void main to be Bruno-esque??) and RENAME also. OR as includes???

void raycastIsoSurface(vec3 rayStartVolumeCoords, vec3 rayStep, int stepCount, vec3 viewRayDirection); 

// float sampleVolume(vec3 volumeCoords); 

// vec4 applyColorMap(float val);

vec4 addLighting(float val, vec3 loc, vec3 rayStep, vec3 viewRayDirection);




void main() {

    /*
    ** THE SETUP
    */ 

    // Normalize clipping plane info
    vec3 farPosition = vFarPosition.xyz / vFarPosition.w;
    vec3 nearPosition = vNearPosition.xyz / vNearPosition.w;

    // Calculate unit vector pointing in the view direction through this fragment.
    vec3 viewRayDirection = normalize(nearPosition.xyz - farPosition.xyz);

    // Compute the (negative) distance to the front surface or near clipping plane.
    // vPosition is the back face of the cuboid,(??) so the initial distance calculated in the dot: the distance from near clip plane to the back of the cuboid

    // 1. 
    // this is the distance along the ray from position to the near clipping plane:
    float rayEntryDistance = dot(nearPosition - vPosition, viewRayDirection);
    // ...so this is a starting point.... it's further refined in the next 3 reassignments. This is reassigning to progressively compute all the cases, ie find the latest of the (earliest) entry points:
    // 2. entry after the x
    rayEntryDistance = max(
        rayEntryDistance, 
        min(
            //this might he the root of the centering issue? the shader is working on the geometry being centered? I thought it WAS??? It is conflicting?
            ( - vPosition.x) / viewRayDirection.x,
            (uVolumeSize.x  - vPosition.x) / viewRayDirection.x
        )
    );
    // 3. entry after the x
    rayEntryDistance = max(
        rayEntryDistance, 
        min(
            ( - vPosition.y) / viewRayDirection.y,
            (uVolumeSize.y  - vPosition.y) / viewRayDirection.y
        )
    );
    // 3. entry after the x
    rayEntryDistance = max(
        rayEntryDistance, 
        min(
            ( - vPosition.z) / viewRayDirection.z,
        (uVolumeSize.z  - vPosition.z) / viewRayDirection.z)
    );

    // So can now find the starting position on the front surface
    vec3 rayEntryPosition = vPosition + viewRayDirection * rayEntryDistance;

    // Determine how many steps to take:
    int stepCount = int(- rayEntryDistance / RELATIVE_STEP_SIZE + 0.5);
    if ( stepCount < 1 )
            discard;

    // Get step vector for raycasting, and  the starting location in texture coordinates:
    vec3 rayStep = ((vPosition - rayEntryPosition) / uVolumeSize) / float(stepCount);
    vec3 rayStartVolumeCoords = rayEntryPosition / uVolumeSize;

    // "For testing: show the number of steps. This helps to establish
    // whether the rays are correctly oriented"
    //'gl_FragColor = vec4(0.0, float(stepCount) / 1.0 / uVolumeSize.x, 1.0, 1.0);
    //'return;

    /*
    ** THE SAMPLING - separated out of the raycasting??????
    */ 


    /*
    ** THE RAYCASTING
    */ 
    // Then Raycast ISO:
    raycastIsoSurface(rayStartVolumeCoords, rayStep, stepCount, viewRayDirection);

    // raycastIsoSurface1(rayStartVolumeCoords, rayStep, stepCount, viewRayDirection);

    /*
    ** THE SHADING
    */ 
    // If the ray isn't false:
    // Change to if the casting function returns true then add all the shading to the FragColor???

    // apply COLORMAP

    // add LIGHTING
    // gl_FragColor = addLighting(val, refineVolumeCoords, gradientStep, viewRayDirection);

    // FINAL COLOR
    if (gl_FragColor.a < 0.05)
            discard;
}

/* 
* FUNCTIONS to separate out???
*/


// // Sample the volume 
// float sampleVolume(vec3 volumeCoords)
// {
//     /* Sample float value from a 3D texture. Assumes intensity data. */
//     return texture(uVolumeDataTexture, volumeCoords.xyz).r;
// }


/*
* ISO Raycasting
*/

//so raycasting finds a hit, shading uses the hit 
//so this function should just be about finding the hits?
//so it actually just determines  whether each fragment is a surface (and currently colors and lights it if it is!!!!!! ) So it needs to be a boolean and then if its true can do FragColor addLighting! AND IT NEEDS TO RETURN DATA on the hit.
void raycastIsoSurface(
    vec3 rayStartVolumeCoords, 
    vec3 rayStep, 
    int stepCount, 
    vec3 viewRayDirection
    //outs: so can return more than one thing...
    out bool hit,
    out float hitScalarValue,
    out vec3 hitVolumeCoords
) 
{
    gl_FragColor = vec4(0.0);	// init transparent
    // vec4 color3 = vec4(0.0); // final color - this isnt doing anything - maybe this was originally intended to be used instead of going directly to FragColor...

    bool hit = false; // init as false

    // gradientStep defines how far apart the samples are when estimating the gradient (the normal(!)) its the step between each compute of the gradient. The value 1.5 is a compromise for the smoothing between noise/artefacts and loss of detail. Should I call it normalSampleStep? or is that a step too far!
    vec3 gradientStep = 1.5 / uVolumeSize;

    //the current 'point' (obviously)
    vec3 currentVolumeCoords = rayStartVolumeCoords;

    //what is this 0.02 ???? It is to "Lower threshold to detect crossings before exact iso value" ?? still do not fully understand.
    float isoSurfaceSearchThreshold = uIsoSurfaceThreshold - 0.02 * (uColorMapValueRange[1] - uColorMapValueRange[0]);


    // Enter the raycasting loop:

    // NB "In WebGL 1 the loop index cannot be compared with a non-constant expression. So we use a hard-coded max, and an additional condition inside the loop".
    for (int iter = 0; iter < MAX_STEPS; iter++) {
        if (iter >= stepCount)
            break;
        // the volume is a 'scalar field', ie, at every point there is a single number stored (representing intensity, or density)
        // Sample from the 3D texture to get the scalarValue:
        float scalarValue = sampleVolume(currentVolumeCoords);

        if (scalarValue > isoSurfaceSearchThreshold) {
            // "...Take the last interval in smaller steps (refine the steps!)"
            vec3 refineVolumeCoords = currentVolumeCoords - 0.5 * rayStep;
            vec3 refineStep = rayStep / float(REFINEMENT_STEPS);

            for (int i = 0; i < REFINEMENT_STEPS; i++) {
                scalarValue = sampleVolume(refineVolumeCoords);

                if (scalarValue > uIsoSurfaceThreshold) {

                    //so... outs defined here
                    hit = true;
                    hitScalarValue = scalarValue;
                    hitVolumeCoords = refineVolumeCoords;

                    // addLighting() needs to happen in main, so this needs to just return true - wait, the parameters come from from this function. - and I can only return one thing from a glsl function??
                    //this is where 'out' comes in.... 
                    gl_FragColor = addLighting(hitScalarValue, hitVolumeCoords, gradientStep, viewRayDirection);
                    return;
                }
                // take a refined step:
                refineVolumeCoords += refineStep;
            }
        }
        // Advance the location (currentVolumeCoords) deeper into the volume, or in other words, Step!
        currentVolumeCoords += rayStep;
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
            ambient_color += mask1 * ambient_color;	// * gl_LightSource[i].ambient;
            diffuse_color += mask1 * lambertTerm;
            specular_color += mask1 * specularTerm * specular_color;
    }

    // Calculate final color by componing different components
    vec4 final_lighting;
    // so would just return this if not applying colormap in the lighting function?



    // apply the colorMap, passing in val from (the raycasting???) the includes is in the fragment...
    // wait it must be better to separate this from lighting???
    vec4 colorMap = applyColorMap(val);

    //thses are actually the shadow variables...
    // final_lighting = colorMap * (ambient_color + diffuse_color) + specular_color;

    final_lighting =(ambient_color + diffuse_color) + specular_color;

    // final_lighting.a = colorMap.a;

    vec4 final_color =  colorMap * final_lighting;

    return final_color;
}

