// Getting the brain .nrrd to render in r3f, based on the nrrdLoader usage in vanilla js example
// Renaming variables more explicitly (like Bruno!) for my own understanding

import { useMemo, useEffect, useState, useRef } from "react";
import { Vector2, Vector3, Data3DTexture, RedFormat, FloatType, LinearFilter, TextureLoader, BackSide, UniformsUtils, ShaderMaterial } from "three";
import { NRRDLoader } from "three/examples/jsm/Addons.js";
import { shaderMaterial } from '@react-three/drei';
import { useLoader, extend } from "@react-three/fiber";

import { useControls } from 'leva';
import { Perf } from 'r3f-perf';


// import { VolumeRenderShader1 } from "three/examples/jsm/Addons.js";
// VolumeRenderShader1 is here: https://github.com/mrdoob/three.js/blob/master/examples/jsm/shaders/VolumeShader.js

import vertexShader from './shaders/brainVolume/vertex-perspective.glsl'
import fragmentShader from './shaders/brainVolume/fragment-perspective-scalable.glsl'

// NB
// uVolume Dimensions was formerly called uVolumeSize (used in previous fragment shaders)


//this was originally to scale the head burt I am not sure that it does that.. (So was originally called METRES_T0_CM ->> need to pass in as new uniform I think.. and use to deteremine step s in the fragment shader, to make the code transferable!
const SCALE_FACTOR = 0.001;

// Note to self - percentage value has to be divided by 100 to get the scale factor for the volume, because the slider is 0-500 and the scale factor is 0-5. CoPilot: - 'So the scale factor is 0.01 * percentage value. This is done in the Experience.jsx file where the scale state is set'.

// the drei helper: 'new' is not required:
const BrainMaterial = shaderMaterial(
    // can pass uniforms values as props but ref better?  but must be defined here:
    {
        // uVolumeSize: new Vector3(),
        //leaving the above for previous fragment shaders even though its a duplicate

        uVolumeDimensions: new Vector3(),
        uVolumeScaledPhysicalSize: new Vector3(),
        uVolumeScaleFactor: 0,
        uColorMapTexture: null,
        uVolumeDataTexture: null,
        // plus some hardcoded values - these are not working here? should they be declared in the jsx though and not memoised in my uniforms useMemo??? copilot: think they should be declared in the jsx and not memoised in my uniforms useMemo because they are not changing and do not need to be memoised, but they do need to be declared here because they are used as uniforms in the shader and need to be defined for the shaderMaterial:
        uIsoSurfaceThreshold: 0,
        uColorMapValueRange: new Vector2(),
        // uCameraPosition: new Vector3(),
    },
    vertexShader,
    fragmentShader
);
// // make the class with extend:
extend({ BrainMaterial });



export default function NrrdVolumeDisplay( { nrrdUrl, colorMapURL, scale } ) 
{
    console.log(scale)

    // leva controls
    const { perfVisible } = useControls({
        perfVisible: true
    })
    
    const volumeDataTextureRef = useRef(null);

    
    // state needed for jsx:
    // const [volumeSize, setVolumeSize] = useState(null);
    const [volumeDimensions, setVolumeDimensions] = useState(null);

    // because the voume size in the real world would be 436 metres high... because 1 unit = 1 meter:
    const [physicalSize, setPhysicalSize] = useState(null);

    // possibly dont need this as state? - just use from the metadata in the .nrrd file:
    const [spacing, setSpacing] = useState({ x: 1, y: 1, z: 1 });

    // needed for perspective camera raymarching:EXCEPT CAMERAPOSITION IS AVAILABLE AS AN ATTRIBUTE SO NO NEED FOR THIS?
    // const cameraPosition = useThree((state) => state.camera.position); 
    // console.log(cameraPosition);

    // colorMap: with useLoader from r3f - remember it's a hook too!:
    const colorMapTexture = useLoader(TextureLoader, colorMapURL);
    // console.log(colorMapTexture);

    
    // Alternative with manual Three ShaderMaterial: CAN GET RID? AND JUST PASS VALUES DIRECTLY IN JSX..!!
    const uniforms = useMemo(() => (
    {
        uVolumeDimensions: { value: new Vector3() }, // the volume size('lengths')
        uVolumeScaledPhysicalSize: { value: new Vector3() }, // the physical size of the volume
        uVolumeScaleFactor: { value: SCALE_FACTOR }, // the scale factor for the volume, which is used to scale the volume to the correct size in the world
        //nb re-creating the vectors elsewhere:
        uColorMapTexture: { value: null }, // cm_data is colormap too... - 
        uVolumeDataTexture: { value: null }, 
        // Hardcoded ISO threshold which defines the intensity level at which a surface exists:
        uIsoSurfaceThreshold: { value: 0.1},
        uColorMapValueRange: { value: new Vector2(0, 2) }, 
        // uCameraPosition: { value: new Vector3() }

    }), [])

    
    // console.log(volumeData)
    // is this right? Yes - do it once unless dependencies change.
    useEffect(() => {

        new NRRDLoader().load(nrrdUrl, (volume) => {

            //convert datatype to Float32Array from uint8 or uint16, which is how Tirso's data was - (was there an option for datatype in 3dslicer?? )
            const volumeData = new Float32Array(volume.data);
            // console.log(volume.data)
        
            setVolumeDimensions({
                x: volume.xLength,
                y: volume.yLength,
                z: volume.zLength
            });

            // from the .nrrd file metadata so this would make my code transferable...(NB in this file -the 0.5mm MNI- the value is 0.5 obviously. Do I even need state for this though?)
            setSpacing({
                x: volume.spacing[0],
                y: volume.spacing[1],
                z: volume.spacing[2]
            });
            console.log(volume.spacing)

            // calculate the physical size of the volume based on its dimensions and spacing, plus the user scaling from the slider:
            setPhysicalSize({
                x: volume.xLength * volume.spacing[0] * SCALE_FACTOR * scale, // convert to cm for real world scale - doesnt really work?? - because need to change code eleswhere!
                y: volume.yLength * volume.spacing[1] * SCALE_FACTOR * scale,
                z: volume.zLength * volume.spacing[2] * SCALE_FACTOR * scale
            });

            console.log(volume.xLength)
            

            // remember do not use the React state inside the thing that sets it!!!!!:
            const texture = new Data3DTexture( volumeData, volume.xLength, volume.yLength, volume.zLength);
            
            texture.format = RedFormat;
            texture.type = FloatType;
            // (Mr Doob code style!):
            texture.minFilter = texture.magFilter = LinearFilter;

            texture.unpackAlignment = 1;
            texture.needsUpdate = true;

            //set the value on the ref that will be used for the uniforms:
            volumeDataTextureRef.current = texture;

            // Is below just duplicating the texture in memory? NO, because the value is a reference to the texture object, so it should not be creating a new texture in memory, just referencing the same one. 

            // Is a Data3DTexture, the actual MRI texture - 
            uniforms.uVolumeDataTexture.value = texture;

        })
   
    }, [nrrdUrl, colorMapTexture, volumeDataTextureRef, scale, uniforms]);

    //Ok so the 0.5 spacing anfd the scaling (SCALE!) is actually getting used:
    console.log(physicalSize)

    return (
        // scale here? NOOOOOOOO!!!!! Because it conflicts with all the shader maths!!!
        // this rotation though NO ... and orbit controls rotate origin is at centre of scene...
        <group>
        
            {/* Just add this here, need to reposition it though!*/}
            { perfVisible ? <Perf position='bottom-left' /> : null}
            
            { volumeDimensions &&
                <mesh>
                    {/* set the size of the geometry that 'holds' it according to the size of the volume (model): ie (364, 436, 364 ) for the 0.5 mm NRRD volume (see the nrrd file metadata) Spacing however is 0.5 (space directions metadata) so this needs to be taken into account see comment at bottom */ }
                  <boxGeometry args={ [ physicalSize.x, physicalSize.y, physicalSize.z] } /> 

                    <brainMaterial 
                        uniforms={ uniforms }
                        // should all the uniforms be passed here? - 
                        // - according to CoPilot yes, 'because the shaderMaterial is a class that is created with the uniforms, and the uniforms are passed to the shaderMaterial when it is created. So if the uniforms change, the shaderMaterial needs to be updated with the new uniforms. So yes, all the uniforms should be passed here.'
                        uVolumeDimensions = { volumeDimensions }
                        uVolumeScaledPhysicalSize = { physicalSize }
                        uVolumeScaleFactor = { scale * SCALE_FACTOR }
                        uColorMapTexture = { colorMapTexture }
                        side={ BackSide }
                    />

                </mesh>
            }

            {/* debug mesh */}
            { volumeDimensions && 
                <mesh visible={ true } >
                    <boxGeometry args={[ physicalSize.x, physicalSize.y, physicalSize.z] } />
                    <meshBasicMaterial wireframe={ true } />
                </mesh>
            }
        </group>
    )
}
// In my raymarching in the fragment shader the rayStep code assumes 1 unit in x = 1 unit in y = 1. But the 0.5 nrrd file has 1 voxel = 0.5 world units. So the rauymarching need to happen at the right scale. Not in shader though because I will need a pipeline for any data so best to fetch values from the nrrd file to use.