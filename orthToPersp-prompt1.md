## Plan: Convert Volume Raycasting from Orthographic to Perspective

TL;DR: Update the existing volume raycasting shader so it computes camera rays in local volume space using perspective projection, rather than the current orthographic-like ray setup. This requires adjusting the vertex shader ray endpoint math, introducing or clarifying camera origin/direction in the fragment shader, and validating with a perspective camera.


**Steps**
*Made new uCameraPosition uniform*

1. Inspect current ray setup in `src/shaders/brainVolume/vertex.glsl` and `src/shaders/brainVolume/single-fragment.glsl`.
*made copies of shaders for safety - fragment-perspective.glsl etc*


2. Define the perspective ray math goal:
   - Ray origin should be the camera position in local volume coordinates.
   *Is this the modelViewMatrix? aka world space? I need to pass cameraPosition as a uniform -I think?*
   - Ray direction should point from camera through the fragment’s position on the near plane (or through the backface sample point) for a perspective camera.
   

3. Modify the vertex shader to pass explicit ray endpoints and/or camera origin:
   - Keep `vPosition` as the local volume box position if needed.
   - Pass a `vViewRayOrigin` in local volume coordinates and/or `vNearPosition`/`vFarPosition` computed with proper perspective transformation.
   - Ensure `vNearPosition`/`vFarPosition` convert from clip/view space to local space correctly.

4. Update the fragment shader:
   - Replace the current `viewRayDirection = normalize(nearPosition.xyz - farPosition.xyz)` with a perspective-safe ray direction computed from camera origin to the fragment position on the near plane.
   - Compute ray entry and exit intersections with box bounds using the new perspective ray.
   - Normalize the ray direction and compute `rayStep` from entry to exit if using a backface/near-plane sample.

5. Add or verify uniforms and variant support:
   - Confirm `uVolumeSize` remains correct and that volume coordinates are centered consistently.
   - If supporting both orthographic and perspective, add a `bool uUsePerspective` or a camera-type uniform and branch only the ray origin/direction math.

6. Validate in React scene:
   - Use a perspective camera in `src/App.jsx` or `src/AppNoDrei.jsx` to confirm the shader renders with perspective.
   - Optionally compare with the current `OrthographicCamera` behavior to ensure the same volume still renders correctly under the new ray math.
   
7. Test edge cases:
   - rays through corners, near-plane clipping, and correct entry/exit when the box is partially outside view.
   - Check if the `BackSide` geometry and the `vPosition` offset are still required or can be simplified.


**Verification**

1. Render with a `PerspectiveCamera` and verify the brain volume looks perspective-correct (objects closer appear larger, rays converge).

2. Confirm the ray entry logic still correctly hits the volume when the mesh is rotated or translated.

3. Compare visual output before and after: if the shader previously appeared orthographic, the new output should show correct perspective depth.

4. Optionally add a debug mode rendering ray count or ray origin to validate the new perspective rays.


**Decisions / Assumptions**

- The current fragment shader is effectively treating the box as if it were being rendered orthographically, so the main change is the ray origin/direction calculation.

- The plan assumes the volume box is already positioned and scaled correctly, and that the shader should support perspective without altering volume texture sampling.

- If the user wants both orthographic and perspective, the plan includes a flag-based approach.


Reviewing the current prompt content and then converting it into a concrete implementation plan.

Read [](file:///Users/sarahhartill/Documents/projects/brains/brains-in-react-r3f/orthToPersp-prompt1.md)

## Step-by-step implementation

1. **Make a safe copy of the shaders**
   - Copy vertex.glsl to `vertex-perspective.glsl`
   - Copy single-fragment.glsl to `fragment-perspective.glsl`
*Done*


2. **Update the vertex shader ray data**
   - Keep `vPosition` as the volume-local vertex position.
   - Compute `viewPosition = modelViewMatrix * vec4(position, 1.0)`.
   *As existing code*

   - Build `nearViewPosition` with `nearViewPosition.z = -viewPosition.w`.
    *As existing code*
   - Build `farViewPosition` with `farViewPosition.z = viewPosition.w`.
    *As existing code*
   - Transform both back to local volume coordinates using `inverse(modelViewMatrix)`.
   *As existing code*
   - Pass them as varyings: `vNearPosition` and `vFarPosition`.
   *As existing code*
   - If the volume is centered in local space, keep the existing `volumeOffset = 0.5 * uVolumeSize` adjustment.
*All as existing code*

3. **Make the fragment shader compute the perspective ray**
   - Normalize the varyings:  
     `vec3 nearPosition = vNearPosition.xyz / vNearPosition.w;`  
     `vec3 farPosition = vFarPosition.xyz / vFarPosition.w;`
     *As existing code*
   - Derive a ray origin and direction for perspective:
     - `vec3 rayOrigin = nearPosition;`
     *Made new variable*
     - `vec3 viewRayDirection = normalize(farPosition - nearPosition);`
     *Changed value of variable*
   - This is the key perspective change: the ray starts at the camera’s near-plane intersection and points through the fragment toward the far plane.
*Done*

4. **Compute entry/exit of the box using perspective rays**
   - Replace the current orthographic-style `rayEntryDistance` logic with a slab intersection method:
     - For each axis, compute `tMin` / `tMax` between the ray and the box bounds `[0, uVolumeSize]`.
     - Use `max(tMin)` and `min(tMax)` to get the valid ray interval.
   - If `tMax < tMin`, discard the fragment.
   - Use `rayEntryDistance = max(tMin, 0.0)` as the first valid hit into the volume.
*done with help of Copilot*

5. **Generate the raymarching start point and step**
   - Compute:
     - `vec3 rayEntryPosition = rayOrigin + viewRayDirection * rayEntryDistance;`
     - `vec3 rayExitPosition = rayOrigin + viewRayDirection * rayExitDistance;`
   - Determine ray length: `float rayLength = rayExitDistance - rayEntryDistance;`
   - Compute step count from `rayLength` and `RELATIVE_STEP_SIZE`.
   - Set `rayStep = (rayExitPosition - rayEntryPosition) / float(stepCount)` or using volume texture coordinates:
     - `vec3 rayStartVolumeCoords = rayEntryPosition / uVolumeSize;`
     - `vec3 rayStep = (viewRayDirection / uVolumeSize) * (rayLength / float(stepCount));`
   *done with help of Copilot*

6. **Keep the existing raycast + shading flow**
   - Call `raycastIsoSurface(rayStartVolumeCoords, rayStep, stepCount, viewRayDirection, hitValue, hitCoords)`.
   - Keep lighting and colormap logic untouched.
   - Ensure `viewRayDirection` is used consistently for shading.
   *just changed some variable names*

7. **Verify coordinate centering and uniforms**
   - Confirm `uVolumeSize` is still set from the loaded volume dimensions.
   - If you center the model in the vertex shader with `volumeOffset`, make sure the same offset is applied to all ray computations.
   - If the volume is not centered, adjust the ray origin and box bounds accordingly.
   *No change to original*

8. **Switch the React scene to perspective**
   - In App.jsx or AppNoDrei.jsx, replace `OrthographicCamera` with a `PerspectiveCamera` or use the default canvas camera.
   - Render `NrrdVolumeDisplay` with that perspective camera.
   - Observe whether the volume now appears perspective-correct.
*Already done*

9. **Test and refine**
   - Rotate/translate the volume and confirm rays still enter/exit correctly.
   - Check corners and partial volume visibility.
   - If you want both modes, add a uniform like `uUsePerspective` and branch only the ray origin/direction calculation.

### Summary
- The main shader change is: compute the ray from the camera’s near-plane position, not from a fixed orthographic direction.
- Keep the box intersection and raymarching loop, but derive `rayStep` from the perspective ray interval.
- Validate the result using a `PerspectiveCamera` in React.

If you want, I can next generate the exact GLSL code changes for vertex.glsl and single-fragment.glsl.