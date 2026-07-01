// Code from https://github.com/mrdoob/three.js/blob/master/examples/jsm/shaders/VolumeShader.js and separated out into fragment.glsl

precision highp float;
precision mediump sampler3D;

// uniform vec3 uCameraPosition; // for perspective - but its available anyway as attribute so no need to pass it in!

// Need both these?:
uniform vec3 uVolumeDimensions;
uniform vec3 uVolumeScaledPhysicalSize;

uniform float uVolumeScaleFactor;

uniform float uIsoSurfaceThreshold;
uniform vec2 uColorMapValueRange;

uniform sampler3D uVolumeDataTexture;
uniform sampler2D uColorMapTexture;

// varying vec3 vPosition;
varying vec4 vNearPosition;
varying vec4 vFarPosition;
varying vec3 vWorldPosition;

// The maximum distance through our rendering volume is sqrt(3).
const int MAX_STEPS = 887;	// 887 for 512^3, 1774 for 1024^3
const int REFINEMENT_STEPS = 4;

//Step size is relative to scaled volume size?: if volumeDimensions then smaller values than 1.0 would slow the frame rate unacceptably: 
// - I'm going to replace this variable when used in the code below with my scaleRelativeStepSize so I can put a user control that is passed in as the uniform(declared in main because only consts can be declared globally....
// const float RELATIVE_STEP_SIZE = 0.1;

const float RELATIVE_STEP_SIZE_FACTOR = 100.0; // fudge factor to make step size smaller than the volume scale factor, so that the render is not too sparse , but not too heavy either.

//---------------
// These could come in as uniforms or not at all ?:
// they are overidden in the lighting function anyway, so...?
// vec4 ambient_color = vec4(0.2, 0.4, 0.2, 1.0);
// vec4 diffuse_color = vec4(0.8, 0.2, 0.2, 1.0);
// vec4 specular_color = vec4(1.0, 1.0, 1.0, 1.0);
// Still need this one though... or would it be better elsewhere??? Do I want it shiny even?
float shininess = 20.0;


// Functions are declared BEFORE use - because order matters:

bool raycastIsoSurface(
    vec3 rayStartVolumeCoords, 
    vec3 rayStep, 
    int stepCount, 
    vec3 viewRayDirection, 
    out float hitValue,
    out vec3 hitCoords
); 

vec4 addLighting(
    float scalarValue, 
    vec3 volumeCoords, 
    vec3 normalSampleStep, 
    vec3 viewDirection, 
    out float shadedScalarValue
);

vec4 applyColorMap(
    float shadedScalarValue
);

float sampleVolume(
    vec3 volumeCoords
    ); 


void main() {

    // Declare outs:
    // from raycastIsoSurface:
    float hitValue;
    vec3 hitCoords;
    // from addLighting:
    float shadedScalarValue;

    /*
    ** THE SETUP
    */ 

    // Normalize clipping plane info from vertex shader:
    vec3 nearPosition = vNearPosition.xyz / vNearPosition.w;
    vec3 farPosition = vFarPosition.xyz / vFarPosition.w;
    // The ray between these is the camera ray, so do not need uCameraPosition to calculate the ray direction, as the ray direction is from near to far, so from ray origin to ray end, so can just do far - near, (below). This is a bit different from the orthographic case where the ray direction is the same for all rays and is just from camera to position.
    //--------------

    // COMPUTE ENTRY/EXIT POINTS (OF BOX) USING PERSPECTIVE RAYS:

    // For PERSPECTIVE: Ray origin at near-plane intersection:
    // vec3 rayOrigin = nearPosition;
    vec3 rayOrigin = cameraPosition;
    // vec3 rayOrigin = rayOriginLocal + 0.5 * uVolumeDimensions;
    

    // For PERSPECTIVE: Direction into the scene (towards the far-plane intersection):
    // vec3 rayDirection = normalize(farPosition - nearPosition);
    vec3 rayDirection = normalize(vWorldPosition - cameraPosition);
    // vec3 rayDirection = rayDirLocal;


    // For PERSPECTIVE: Compute intersection (slab method) of ray with the axis-aligned volume box [0, uVolumeScaledPhysicalSize]

    // vec3 boxMinBounds =  vec3(0.0); 
    // centering the box/volume
    vec3 boxMinBounds = - 0.5 * uVolumeScaledPhysicalSize;

    // vec3 boxMaxBounds = uVolumeDimensions;
    // centering the box/volume ... 
    vec3 boxMaxBounds = 0.5 * uVolumeScaledPhysicalSize;

    // Precompute inverse of ray direction to avoid repeated division in the slab method:
    vec3 invDir = 1.0 / rayDirection;

    // Compute intersection distances to the two planes on each axis
    // t is used for the distance along the ray (in ray units) as a kind of standard in raytracing

    // So:
    // t = 0 is: at the ray origin - eg the entry point of the ray into the volume
    // t = 1 is unit along the ray eg the exit
    // t = 10 → 10 units along the ray

    // Compute intersection distances to the two planes on each axis
    vec3 t0s = (boxMinBounds - rayOrigin) * invDir;
    vec3 t1s = (boxMaxBounds - rayOrigin) * invDir;
    vec3 tsmaller = min(t0s, t1s);
    vec3 tbigger = max(t0s, t1s);

    float tEntry = max(max(tsmaller.x, tsmaller.y), tsmaller.z);
    float tExit = min(min(tbigger.x, tbigger.y), tbigger.z);

    // No intersection or entirely behind the camera
    if (tExit < max(tEntry, 0.0)) discard;

    // Clamp entry to zero (start at ray origin if origin is inside box)
    float rayEntryDistance = max(tEntry, 0.0);
    float rayExitDistance = tExit;

    // Compute entry/exit positions and sampling parameters
    vec3 rayEntryPosition = rayOrigin + rayDirection * rayEntryDistance;
    vec3 rayExitPosition = rayOrigin + rayDirection * rayExitDistance;
    float rayLength = rayExitDistance - rayEntryDistance;

    // Currently, as uVolumeDimensions gets smaller,:
    // 1. raylength gets smaller, 2. stepcount drops, so ray takes fewer samples so render gaps grow...
    // int stepCount = int(rayLength / RELATIVE_STEP_SIZE + 0.5);
    // if (stepCount < 1) discard;

    // Alternative:
    float rayLengthNorm = length((rayExitPosition - rayEntryPosition) / uVolumeScaledPhysicalSize);

    float maxDimensions = max(max(uVolumeDimensions.x, uVolumeDimensions.y), uVolumeDimensions.z);

    // This has to be declared here inside main! Because all globally declared variables must be constants in glsl! It's so that scale can be in user controls and passed in as a uniform.
    float scaledRelativeStepSize = uVolumeScaleFactor * RELATIVE_STEP_SIZE_FACTOR;

    int stepCount = int(rayLengthNorm * maxDimensions * scaledRelativeStepSize + 0.5);
    if (stepCount < 1) discard;


    // For PERSPECTIVE: The starting location and the steps in texture coordinates (volume coords normalized by uVolumeDimensions)

    // because am centering the box/volume so need to set the raymarch start accordingly
    vec3 rayStartVolumeCoords = (rayEntryPosition + 0.5 * uVolumeScaledPhysicalSize) / uVolumeScaledPhysicalSize;
    // vec3 rayStartVolumeCoords = rayEntryPosition / uVolumeDimensions;

    // Currently, as uVolumeDimensions gets smaller, rayStep gets bigger, so render gaps grow... (see also int stepCount) above...
    vec3 rayStep = (rayDirection / uVolumeScaledPhysicalSize) * (rayLength / float(stepCount));


    /*
    ** THE SAMPLING - separated out of the raycasting?????? except that it happens in the loop so NO.
    */ 

    /*
    ** RAYCASTING (RayMARCHING might be a better description.) 
    */ 
    
    // Raycast ISO: it returns a boolean, and there are 2 outs:
    bool hit = raycastIsoSurface(rayStartVolumeCoords, rayStep, stepCount, rayDirection, hitValue, hitCoords);
    // if there isn't a hit:
    if (!hit) discard;


    /*
    ** SHADING
    */ 

    // Define the size of the step between normal samples
    // gradientStep defines how far apart the samples are when estimating the gradient (the normal(!)) its the step between each compute of the gradient. The value 1.5 is a compromise for the smoothing between noise/artefacts and loss of detail. Should I call it normalSampleStep? or is that a step too far! 
    // vec3 normalSampleStep = 1.5 / uVolumeScaledPhysicalSize;
    //Alt:
    vec3 normalSampleStep = 1.5 / uVolumeDimensions;

    // add LIGHTING
    vec4 lighting = addLighting(hitValue, hitCoords, normalSampleStep, rayDirection, shadedScalarValue);

    // apply COLORMAP:
    vec4 color = applyColorMap(shadedScalarValue);
    
    // FINAL COLOR
    gl_FragColor = lighting * color;
    // gl_FragColor = vec4(abs(rayDirection), 1.0);
    // return;

    // if (gl_FragColor.a < 0.05)
    //         discard;
    #include <colorspace_fragment>
}

/*
* ISO Raycasting
*/

//so raycasting finds a hit, shading uses the hit 
//so this function should just be about finding the hits?
//so it actually just determines  whether each fragment is a surface (and currently colors and lights it if it is!!!!!! ) So it needs to be a boolean and then if its true can do FragColor addLighting! AND IT NEEDS TO RETURN DATA on the hit.
bool raycastIsoSurface(
    vec3 rayStartVolumeCoords, 
    vec3 rayStep, 
    int stepCount, 
    vec3 viewRayDirection,
    //outs: so can return more than one thing...
    out float hitValue,
    out vec3 hitCoords
) 
{
    //the current 'point' (obviously)
    vec3 currentVolumeCoords = rayStartVolumeCoords;

    //why is this 0.02 ???? It is to "Lower threshold to detect crossings before exact iso value" ?? still do not fully understand.
    float isoSurfaceSearchThreshold = uIsoSurfaceThreshold - 0.02 * (uColorMapValueRange[1] - uColorMapValueRange[0]);

    // Enter the raycasting loop:

    // NB "In WebGL 1 the loop index cannot be compared with a non-constant expression. So we use a hard-coded max, and an additional condition inside the loop".
    for (int iter = 0; iter < MAX_STEPS; iter++) {
        if (iter >= stepCount)
            break;
        // the volume is a 'scalar field', ie, at every point there is a single number stored (representing intensity, or density)
        // Sample from the 3D texture to get the scalarValue of each step
        float scalarValue = sampleVolume(currentVolumeCoords);

        if (scalarValue > isoSurfaceSearchThreshold) {
            // "...Take the last interval in smaller steps (refine the steps!)"
            vec3 refineVolumeCoords = currentVolumeCoords - 0.5 * rayStep;
            vec3 refineStep = rayStep / float(REFINEMENT_STEPS);

            for (int i = 0; i < REFINEMENT_STEPS; i++) {
                scalarValue = sampleVolume(refineVolumeCoords);

                if (scalarValue > uIsoSurfaceThreshold) {
                    // And if so,  
                    // these can be passed out: (addLighting needs them)
                    hitValue = scalarValue;
                    hitCoords = refineVolumeCoords;
                    //And yes its a hit:
                    return true;
                }
                // take the next refined step:
                refineVolumeCoords += refineStep;
            }
        }
        // Advance the location (currentVolumeCoords) deeper into the volume, or in other words, Step!
        currentVolumeCoords += rayStep;
    }
    //if the scalarValue is less than the SearchThreshold:
    return false;
}


/* 
** Lighting - Move into an includes? 

******.  What about separating out calculation of the normals!!!!  **** then also add lights as individual lights, rather than having them coupled together, then can change theses easily!!!!! THIS IS THE WAY
*/

vec4 addLighting(float scalarValue, vec3 volumeCoords, vec3 normalSampleStep, vec3 viewDirection, out float shadedScalarValue)
{

    viewDirection = normalize(viewDirection);

    // calculate the normal vector from gradient (normalSampleStep is the gradient step...)
    vec3 N;
    float val1, val2;
    //this is progressively sampling through the volume and computing the normal xyz values accordingly, and also updating the scalarValue is theis
    val1 = sampleVolume(
        volumeCoords + vec3(- normalSampleStep[0], 
        0.0, 
        0.0)
    );
    val2 = sampleVolume(volumeCoords + vec3(+ normalSampleStep[0], 0.0, 0.0));
    N[0] = val1 - val2;
    scalarValue = max(max(val1, val2), scalarValue);

    val1 = sampleVolume(volumeCoords + vec3(0.0, - normalSampleStep[1], 0.0));
    val2 = sampleVolume(volumeCoords + vec3(0.0, + normalSampleStep[1], 0.0));
    N[1] = val1 - val2;
    scalarValue = max(max(val1, val2), scalarValue);

    val1 = sampleVolume(volumeCoords + vec3(0.0, 0.0, - normalSampleStep[2]));
    val2 = sampleVolume(volumeCoords + vec3(0.0, 0.0, + normalSampleStep[2]));
    N[2] = val1 - val2;
    scalarValue = max(max(val1, val2), scalarValue);

    float gm = length(N); // == gradient magnitude - NOT USED?????

    // re-normalise:
    N = normalize(N);

    // Flip normal so it points towards viewer
    float Nselect = float(dot(N, viewDirection) > 0.0);
    N = (2.0 * Nselect - 1.0) * N;	// ==	Nselect * N - (1.0 - Nselect) * N;

    // Init colors - making the alpha 1.0 so the volume is opaque, - color is determined by the colormap. (According to copilot the alpha of the colormap is not used?)
    vec4 ambient_color = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 diffuse_color = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 specular_color = vec4(0.0, 0.0, 0.0, 1.0);

    // 'note: could allow multiple lights' - ITS CURRENTLY SUPERFLUOUS?
    // And loop will always be unnecessary if I deal with each light as  separate includes?:
    for (int i = 0; i < 1; i++)
    {
            // Get light direction (make sure to prevent zero division)
            vec3 L = normalize(viewDirection);	//lightDirs[i];
            float lightEnabled = float( length(L) > 0.0 );
            L = normalize(L + (1.0 - lightEnabled));

            // Calculate lighting properties
            float lambertTerm = clamp(dot(N, L), 0.0, 1.0);
            vec3 H = normalize(L+ viewDirection); // Halfway vector
            float specularTerm = pow(max(dot(H, N), 0.0), shininess);

            // Calculate mask
            float mask1 = lightEnabled;

            // Calculate colors
            ambient_color += mask1 * ambient_color;	// * gl_LightSource[i].ambient;
            diffuse_color += mask1 * lambertTerm;
            specular_color += mask1 * specularTerm * specular_color;
    }
    // I cant actually see a difference with or without specular color...
    vec4 final_lighting =(ambient_color + diffuse_color) + specular_color;

    // not sure what to do about this...:
    // final_lighting.a = colorMap.a;

    // the out (needed by applyColorMap()):
    shadedScalarValue = scalarValue;

    return final_lighting;
}


// shadedScalarValue is an out from addlighting - it is the result of modifying hitValue/scalarValue in addLighting

vec4 applyColorMap(float shadedScalarValue) 
{
    // Normalize/clamp min/max values to 0.0 and 1.0? before applying the colorMap:
    shadedScalarValue = (shadedScalarValue - uColorMapValueRange[0]) / (uColorMapValueRange[1] - uColorMapValueRange[0]);
    return texture2D(uColorMapTexture, vec2(shadedScalarValue, 0.5));
}


// Sample the volume: Given a position inside the volume, (or volumeDataTexture), return the stored intensity value:
float sampleVolume(vec3 volumeCoords)
{
    /* Sample float value from a 3D texture. Assumes intensity data. */
    return texture(uVolumeDataTexture, volumeCoords.xyz).r;
}