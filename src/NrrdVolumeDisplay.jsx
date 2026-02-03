// Getting the brain .nrrd to render in r3f, based on the nrrdLoader usage in vanilla js example
// Renaming variables more explicitly (like Bruno!) for my own understanding

import { useMemo, useEffect, useState, useRef } from "react";
import { Vector2, Vector3, Data3DTexture, RedFormat, FloatType, LinearFilter, TextureLoader, BackSide, UniformsUtils } from "three";
import { NRRDLoader } from "three/examples/jsm/Addons.js";
import { useControls } from 'leva';
import { Perf } from 'r3f-perf'

// import { VolumeRenderShader1 } from "three/examples/jsm/Addons.js";
// VolumeRenderShader1 is here: https://github.com/mrdoob/three.js/blob/master/examples/jsm/shaders/VolumeShader.js

import brainVolumeVertexShader from './shaders/brainVolume/vertex.glsl'
import brainVolumeFragmentShader from './shaders/brainVolume/fragment.glsl'
//ah I needed a vite glsl plugin...!!
// console.log(brainVolumeFragmentShader)


export default function NrrdVolumeDisplay( { nrrdUrl, colorMapURL, } ) 
{
    // leva controls
    const { perfVisible } = useControls({
        perfVisible: false
    })


    // TIDIED into one thing - DONE
    const [volumeSize, setVolumeSize] = useState(null);

    // (volconfig was for a gui)
    // const [volconfig, setVolconfig] = useState()
    
    // NOOOOOOOOOO......This was a HUUUUUUGE error... leaving it here  commented out to remind me of my own folly:
    // const [uniforms, setUniforms] = useState()

    const brainModel = useRef()

    // ColormapTexture texture 'cache' it (or them) with useMemo??
    const colorMapTexture = useMemo(() => 
    {
        const loader = new TextureLoader();
        return loader.load(colorMapURL);

    }, [colorMapURL]);

    //NB see Bruno's lesson 61 for Drei helper for shader Material that I could use instead of doing this?... Maybe I should have but this is good for learning?
    // uniforms memoized as for colorMap:
    const uniforms = useMemo(() => (
    {
        
        // nb doing this Vector2() here means must use set() elsewhere so am not re-creating vectors:
        //the colorMapValueRange: might be worth putting in a gui and changing it so can diffrentiate betqween surfaces... or would that be a calculation based on the when there is clear space in the data ie 
        uColorMapValueRange: { value: new Vector2(0, 2) }, 
        //nb used null because am re-creating the vectors elsewhere:
        uColorMapTexture: { value: null }, // cm_data is colormap too... - 
        uVolumeDataTexture: { value: null }, 
        // Ok this is the ISO threshold which defines the intensity level at which a surface exists:
        uIsoSurfaceThreshold: { value: 0.15},
        uVolumeSize: { value: new Vector3() }, // the volume size('lengths')

    }), [])
    
    // console.log(volumeData)
    
    // is this right? Yes - do it once unless dependencies change.
    useEffect(() => {

        new NRRDLoader().load(nrrdUrl, (volume) => 
        {

        //convert datatype to Float32Array from uint8 or uint16, which is how Tirso's data was - (was there an option for datatype in 3dslicer?? )
        volume.data = new Float32Array(volume.data)
        // console.log(volume.data)// ok this worked!

        // set the volume (model) lengths in each direction:
        setVolumeSize({
            x: volume.xLength,
            y: volume.yLength,
            z: volume.zLength
        })
        
        // remember do not use the React state inside the thing that sets it!!!!!:
        const texture = new Data3DTexture( volume.data, volume.xLength, volume.yLength, volume.zLength);
        
        texture.format = RedFormat;
        texture.type = FloatType;
        // didnt know you could do this (Mr Doob code):
        texture.minFilter = texture.magFilter = LinearFilter;

        texture.unpackAlignment = 1;
        texture.needsUpdate = true;

    
        uniforms.uColorMapTexture.value = colorMapTexture;
         // Is a Data3DTexture, the actual MRI texture - 
        uniforms.uVolumeDataTexture.value = texture;
        // remember do not use the React state inside the thing that sets it!!!!!
        uniforms.uVolumeSize.value.set(volume.xLength, volume.yLength, volume.zLength); 

        })
        // dont need uniforms (its already useMemo'd) in the dependencies because it wont change/need to trigger useEffect.
    }, [nrrdUrl, colorMapTexture ])
        

    return (
        <group position-z={ - 300 } rotation-x={ Math.PI * - 0.5 } rotation-z={ Math.PI }>
            {/* Just add this here, need to reposition it though!*/}
            { perfVisible ? <Perf position='top-left' /> : null}
            <mesh 
                ref={ brainModel }                
                // position-z={ - 300 }
            >
                { volumeSize && 
                    // set the size of the geometry that 'holds' it according to the size of the volume (model):
                    <boxGeometry 
                        // is this causing the issue NO ??? BUT DOING THIS (*2) IS RELATED TO CENTERING??????? as in only see a quarter of the volume if the geometry is set as the plain volume lengths... SO????? Yes and can get rid of all the 0.5-ness in the fragment shader accordingly and sort it in the vertex.
                        args={ [ volumeSize.x, volumeSize.y, volumeSize.z] } 
                    />
                } 
                
                { uniforms &&  
                    <shaderMaterial 
                    //can I just set the uniforms in here???? Did it in useMemo -  Drei has a helper that I should use?? but didnt.
                        uniforms={ uniforms }
                        vertexShader={ brainVolumeVertexShader } 
                        fragmentShader={ brainVolumeFragmentShader }
                        side={ BackSide }
                        // style={ {color: 'red' }}
                        // wireframe
                    />
                }
            </mesh>

            {/* debug mesh */}
            <mesh 
                // scale={ [ 0.5, 0.5, 0.5] }
                visible={ true }
            >
                {/* wait how do I get these: by using state...? */}
                { volumeSize && 
                    <boxGeometry 
                        args={ [ volumeSize.x, volumeSize.y, volumeSize.z] }
                        // translate={ [volumeSize.x / 2, volumeSize.y / 2, volumeSize.z / 2] }           
                    />
                } 
                <meshBasicMaterial
                    wireframe={ true }
                />

            </mesh>

        </group>
    )
}