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


    // Constants -------------
    // The maximum distance through our rendering volume is sqrt(3).
    const int MAX_STEPS = 887;	// 887 for 512^3, 1774 for 1024^3
    const int REFINEMENT_STEPS = 4;
    const float RELATIVE_STEP_SIZE = 1.0;

    // Not strictly necessary:
    const float shininess = 40.0;

    // Function declarations (because order matters) ---------

    bool raycastIsoSurface(
        vec3 rayStartVolumeCoords, 
        vec3 rayStep, 
        int stepCount, 
        vec3 viewRayDirection, 
        out float hitValue,
        out vec3 hitCoords
    ); 

    float sampleVolume(
        vec3 volumeCoords
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

    

    // ------- 

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

        // Normalize clipping plane info:
        vec3 farPosition = vFarPosition.xyz / vFarPosition.w;
        vec3 nearPosition = vNearPosition.xyz / vNearPosition.w;

        // Calculate vector pointing in the view direction through this fragment.
        vec3 viewRayDirection = normalize(nearPosition.xyz - farPosition.xyz);

        // Compute the (negative) distance to the front surface or near clipping plane.
        // vPosition is the back face of the cuboid, so initial distance calculated in the dot calc - distance from near clip plane to the back of the cuboid

        // 1. Get the distance along the ray from position to the near clipping plane:
        float rayEntryDistance = dot(nearPosition - vPosition, viewRayDirection);

        // 2. Further refine rayEntryDistance in 3 reassignments; progressively computing all the cases, ie find the latest of the (earliest) entry points:

        // 2a. Entry after the x taken into account:
        rayEntryDistance = max(
            rayEntryDistance, 
            min(
                ( - vPosition.x) / viewRayDirection.x,
                (1.0 - vPosition.x) / viewRayDirection.x
            )
        );
        // 2b. Entry after the y:
        rayEntryDistance = max(
            rayEntryDistance, 
            min(
                ( - vPosition.y) / viewRayDirection.y,
                (1.0 - vPosition.y) / viewRayDirection.y
            )
        );
        // 2c. Entry after the z:
        rayEntryDistance = max(
            rayEntryDistance, 
            min(
                ( - vPosition.z) / viewRayDirection.z,
                (1.0 - vPosition.z) / viewRayDirection.z)
        );
         // So can now find the starting position on the front surface:
        vec3 rayEntryPosition = vPosition + viewRayDirection * rayEntryDistance;

        // Determine steps count:
        int stepCount = int(- rayEntryDistance / RELATIVE_STEP_SIZE + 0.5);
        if ( stepCount < 1 )
                discard;

        // Get step vector for raycasting, and  the starting location in texture coordinates:
        //vec3 rayStep = ((vPosition - rayEntryPosition) / uVolumeSize) / float(stepCount);
        vec3 rayStep = (vPosition - rayEntryPosition) / float(stepCount);
        //

        //-------
        //is this the issue because spatialstrates is 0,1?????:
        // vec3 rayStartVolumeCoords = rayEntryPosition / uVolumeSize;

        vec3 rayStartVolumeCoords = rayEntryPosition;
        //---------
        /* 
        ** SAMPLING & RAYMARCHING (NB orthographic view)
        */ 
        // Raycast Iso: it returns a boolean, and there are 2 outs:
        bool hit = raycastIsoSurface(rayStartVolumeCoords, rayStep, stepCount, viewRayDirection, hitValue, hitCoords);

        //debug
        // gl_FragColor = vec4(vPosition, 1.0);
        // return;

        // if there isn't a hit:
        if (!hit) discard;

        /*
        ** SHADING
        */ 

        // Define the size of the step between normal samples
        // gradientStep defines how far apart the samples are when estimating the gradient (the normal(!)) its the step between each compute of the gradient. The value 1.5 is a compromise for the smoothing between noise/artefacts and loss of detail. Should I call it normalSampleStep? or is that a step too far! 
        vec3 normalSampleStep = 1.5 / uVolumeSize;

        // add LIGHTING
        vec4 lighting = addLighting(hitValue, hitCoords, normalSampleStep, viewRayDirection, shadedScalarValue);

        // apply COLORMAP:
        vec4 color = applyColorMap(shadedScalarValue);
        
        // FINAL COLOR
        // gl_FragColor = lighting * color;

        if (gl_FragColor.a < 0.05)
            discard;

        #include <colorspace_fragment>
        
    }

    // ------- Functions -------

    /*
    * ISO Raycasting
    */
    // raycasting finds a hit, shading uses the hit

    // function to determine whether each fragment is a surface - so boolean - if true returns data and do FragColor addLighting. 

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
        // the current 'point' 
        vec3 currentVolumeCoords = rayStartVolumeCoords;

        // 0.02 to "Lower threshold to detect crossings before exact iso value" 
        float isoSurfaceSearchThreshold = uIsoSurfaceThreshold - 0.02 * (uColorMapValueRange[1] - uColorMapValueRange[0]);

        // Enter the raycasting loop:
        // NB "In WebGL 1 the loop index cannot be compared with a non-constant expression. So we use a hard-coded max, and an additional condition inside the loop".
        for (int iter = 0; iter < MAX_STEPS; iter++) {
            if (iter >= stepCount)
                break;
            // volume is 'scalar field', ie, a single number stored at each point - intensity/density)
            // Sample from 3D texture to get scalarValue of each step:
            float scalarValue = sampleVolume(currentVolumeCoords);

            if (scalarValue > isoSurfaceSearchThreshold) {
                // "...Take the last interval in smaller steps (refine the steps!)"
                vec3 refineVolumeCoords = currentVolumeCoords - 0.5 * rayStep;
                vec3 refineStep = rayStep / float(REFINEMENT_STEPS);

                for (int i = 0; i < REFINEMENT_STEPS; i++) {
                    scalarValue = sampleVolume(refineVolumeCoords);

                    if (scalarValue > uIsoSurfaceThreshold) {
                        // these can be passed out: (addLighting needs them)
                        hitValue = scalarValue;
                        hitCoords = refineVolumeCoords;
                        // and hit boolean is true:
                        return true;
                    }
                    // take the next refined step:
                    refineVolumeCoords += refineStep;
                }
            }
            // Advance the location (currentVolumeCoords) deeper into volume, aka Step!
            currentVolumeCoords += rayStep;
        }
        // If scalarValue less than isoSurfaceSearchThreshold:
        return false;
    }

    /* 
    ** Lighting 
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

        // Init colors
        vec4 ambient_color = vec4(0.0, 0.0, 0.0, 0.0);
        vec4 diffuse_color = vec4(0.0, 0.0, 0.0, 0.0);
        vec4 specular_color = vec4(0.0, 0.0, 0.0, 0.0);

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

    /* 
    ** Colormap 
    */

    // shadedScalarValue is an out from addlighting - from modifying hitValue/scalarValue in addLighting

    vec4 applyColorMap(float shadedScalarValue) 
    {
        // Normalize/clamp min/max values to 0.0 and 1.0? before applying the colorMap:
        shadedScalarValue = (shadedScalarValue - uColorMapValueRange[0]) / (uColorMapValueRange[1] - uColorMapValueRange[0]);
        return texture2D(uColorMapTexture, vec2(shadedScalarValue, 0.5));
    }

    /* 
    ** Sample volume 
    */
    // Given a position inside the volume (volumeDataTexture), return the stored intensity value:

    float sampleVolume(vec3 volumeCoords)
    {
        // Sample float value from a 3D texture. Assumes intensity data:
        return texture(uVolumeDataTexture, volumeCoords.xyz).r;
    }