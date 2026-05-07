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

import vertexShader from './shaders/brainVolume/vertex.glsl'
import fragmentShader from './shaders/brainVolume/fragment.glsl'

// the drei helper: maybe this is unreliable in this case:
// const BrainMaterial = new shaderMaterial(
//     // can pass uniforms values as props but ref better?  but  must be defined here:
//     {
//         uVolumeSize: new Vector3(),
//         uColorMapTexture: null,
//         uVolumeDataTexture: null,
//         // plus some hardcoded values here?
//         uIsoSurfaceThreshold: 0.2,
//         uColorMapValueRange: new Vector2(0, 2),
//     },
//     vertexShader,
//     fragmentShader
// );
// // make the class with extend:
// extend({ BrainMaterial });



export default function NrrdVolumeDisplay( { nrrdUrl, colorMapURL, } ) 
{
    // leva controls
    const { perfVisible } = useControls({
        perfVisible: false
    })

    const brainMaterialRef = useRef(null);
    const volumeDataTextureRef = useRef(null);
    // remember to put the array in here!!! Empty arrays cause shader bugs according to chatgpt th Ref is needed fpr the uniforms??
    const volumeSizeRef = useRef([ 0, 0, 0 ]);
    // state needed for jsx:
    const [volumeSize, setVolumeSize] = useState(null);

    // colorMap: with useLoader from r3f - remember it's a hook too!:
    const colorMapTexture = useLoader(TextureLoader, colorMapURL);
    // console.log(colorMapTexture);

    // Alternative with manual Three ShaderMaterial:
    const uniforms = useMemo(() => (
    {
        // with Vector3() etc here means must use set() elsewhere so not re-creating 
        uVolumeSize: { value: new Vector3() }, // the volume size('lengths')
        //nb re-creating the vectors elsewhere:
        uColorMapTexture: { value: null }, // cm_data is colormap too... - 
        uVolumeDataTexture: { value: null }, 
        // Hardcoded ISO threshold which defines the intensity level at which a surface exists:
        uIsoSurfaceThreshold: { value: 0.15},
        uColorMapValueRange: { value: new Vector2(0, 2) }, 

    }), [])

    
    // console.log(volumeData)
    // is this right? Yes - do it once unless dependencies change.
    useEffect(() => {

        new NRRDLoader().load(nrrdUrl, (volume) => {

            //convert datatype to Float32Array from uint8 or uint16, which is how Tirso's data was - (was there an option for datatype in 3dslicer?? )
            const volumeData = new Float32Array(volume.data)
            // console.log(volume.data)// ok this worked!

            // set the volume (model) lengths in each direction:
            // const volumeSize = [
            //         volume.xLength,
            //         volume.yLength,
            //         volume.zLength
            //     ];
            // // Ref for the shaders, state for the JSX!: But do I really need both
            // volumeSizeRef.current = volumeSize;

            
            setVolumeSize({
                x: volume.xLength,
                y: volume.yLength,
                z: volume.zLength
            })

            // setVolumeSize([
            //     volume.xLength,
            //     volume.yLength,
            //     volume.zLength
            // ])
        

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

            //all these volume related uniforms for drei shaderMaterial - need to set here in the loader:
            // if (brainMaterialRef.current) {
            //     //can pass in refs here to the ref...
            //     brainMaterialRef.current.uVolumeDataTexture = texture;
            //     brainMaterialRef.current.uColorMapTexture = colorMapTexture;
            //     brainMaterialRef.current.uVolumeSize.set = (
            //         volume.xLength,
            //         volume.yLength,
            //         volume.zLength
            //     )
            // }

            uniforms.uColorMapTexture.value = colorMapTexture;
            // Is a Data3DTexture, the actual MRI texture - 
            uniforms.uVolumeDataTexture.value = texture;
            // remember do not use the React state inside the thing that sets it!!!!!
            uniforms.uVolumeSize.value.set(volumeSize); 
        })
    }, [nrrdUrl, colorMapTexture, uniforms, volumeSize])
        

    return (
        // scale!!!!!
        // this rotation though... and orbit controls rotate origin is at centre of scene...
        <group scale={ 1 } position-z={ -256 } rotation={ [Math.PI * - 0.55, 0, Math.PI] }>
            {/* Just add this here, need to reposition it though!*/}
            { perfVisible ? <Perf position='top-left' /> : null}

            { volumeSize &&
                <mesh>
                    {/* set the size of the geometry that 'holds' it according to the size of the volume (model): */}
                    <boxGeometry args={ [ volumeSize.x, volumeSize.y, volumeSize.z] } />
                    {/* <brainMaterial ref={ brainMaterialRef } side={ BackSide }/> */}
                    { uniforms &&
                        <shaderMaterial 
                            uniforms={ uniforms }
                            vertexShader={ vertexShader } 
                            fragmentShader={ fragmentShader }
                            side={ BackSide }
                        />
                    }
                </mesh>
            }

            {/* debug mesh */}
            { volumeSize && 
                <mesh visible={ true } >
                    <boxGeometry args={[ volumeSize.x, volumeSize.y, volumeSize.z] } />
                    <meshBasicMaterial wireframe={ true } />
                </mesh>
            }
        </group>
    )
}