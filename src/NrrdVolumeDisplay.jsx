// Getting the brain .nrrd to render in r3f, based on the nrrdLoader usage in vanilla js example
// Renaming variables more explicitly (like Bruno!) for my own understanding

import { useMemo, useEffect, useState, useRef } from "react";
import { Vector2, Vector3, Data3DTexture, RedFormat, FloatType, LinearFilter, TextureLoader, BackSide, UniformsUtils } from "three";
import { NRRDLoader } from "three/examples/jsm/Addons.js";
// Will try to use shaders locally instead of this so that can adapt them?
// import { VolumeRenderShader1 } from "three/examples/jsm/Addons.js";
// VolumeRenderShader1 is here: https://github.com/mrdoob/three.js/blob/master/examples/jsm/shaders/VolumeShader.js

import brainVolumeVertexShader from './shaders/brainVolume/vertex.glsl'
import brainVolumeFragmentShader from './shaders/brainVolume/fragment.glsl'
//ah I needed a vite glsl plugin...!!
// console.log(brainVolumeFragmentShader)


export default function NrrdVolumeDisplay( { nrrdUrl, colorMapURL } ) 
{
    //do I need these - is this the way? I think it is BUT IT CAN BE TIDIED into one thing!!!
    const [volumeXLength, setVolumeXLength] = useState()
    const [volumeYLength, setVolumeYLength] = useState()
    const [volumeZLength, setVolumeZLength] = useState()

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
    // same for uniforms as for colorMap: the clue is 'UNIFORM'!!!
    const uniforms = useMemo(() => (
    {
        
        // nb doing this Vector2() here means must use set() elsewhere so am not re-creating vectors:
        //the colorMapValueRange: might be worth putting in a gui and changing it so can diffrentiate betqween surfaces... or would that be a calculation based on the when there is clear space in the data ie 
        uColorMapValueRange: { value: new Vector2(0, 2) }, // colormap thing - 'clim' RENAMED!
        //nb used null because am re-creating the vectors elsewhere:
        uColorMapTexture: { value: null }, // cm_data is colormap too... - RENAMED!
        uVolumeDataTexture: { value: null }, // Should be aData3DTexture, as in the actual MRI texture - RENAME?
        // u_renderstyle: { value: 1 }, // 1 is ISO ...can I get rid? YES.. Will I ever need mip???? If so it would be in separate shader anyway.
        // Ok this is the ISO threshold which defines the intensity level at which a surface exists:
        uIsoSurfaceThreshold: { value: 0.15 }, //not sure....
        uVolumeSize: { value: new Vector3() }, // the volume size('lengths')

    }), [])
    
    // console.log(volumeData)
    
    // is this right?
    useEffect(() => {

        // setVolconfig({ clim1: 0, clim2: 1, renderstyle: 'iso', isothreshold: 0.15, colormap: 'viridis' });

        new NRRDLoader().load(nrrdUrl, (volume) => 
        {

        //convert datatype to Float32Array from uint8 or uint16, which is how Tirso's data was - (was there an option for datatype in 3dslicer?? )
        volume.data = new Float32Array(volume.data)
        // console.log(volume.data)// ok this worked!

        // set the volume (model) lengths in each direction:
        setVolumeXLength(volume.xLength)
        setVolumeYLength(volume.yLength)
        setVolumeZLength(volume.zLength)
        
        const texture = new Data3DTexture( volume.data, volume.xLength, volume.yLength, volume.zLength);
        
        texture.format = RedFormat;
        texture.type = FloatType;
        // didnt know you could do this (Mr Doob code):
        texture.minFilter = texture.magFilter = LinearFilter;

        texture.unpackAlignment = 1;
        texture.needsUpdate = true;

        // getting the uniforms out of the imported shader that is written within a js file: maybe I should make these myself if I'm making my own shaders: - YES
        // const shader = VolumeRenderShader1;
        // const uniforms = UniformsUtils.clone(shader.uniforms);
        // console.log(uniforms)

        //these have to be set like this, not by replacing the objects!!! (as in writing uniform={ value: something})
        // remember do not use the React state inside the thing that sets it!!!!!
        // u_clim is a colormap thing - RENAME?
        // uniforms.u_clim.value.set (0, 2);
        // cm_data is colormap too... - RENAME YES?
        uniforms.uColorMapTexture.value = colorMapTexture; // Should be Texture

         // Should be Data3DTexture, as in the actual MRI texture - RENAME?
        uniforms.uVolumeDataTexture.value = texture;
        
        //get rid because it will always be iso? 
        // uniforms.u_renderstyle.value = 1; // 1 is iso rendering, 0 is mip

        // uniforms.u_renderthreshold.value = 0.15; 
        //because this needs to be passed to shaders
        uniforms.uVolumeSize.value.set(volume.xLength, volume.yLength, volume.zLength) ; //so a Vector3

        // console.log(uniforms)
        // setUniforms(uniforms);
        })
        // dont need uniforms (its already useMemo'd) in here because it wont change/need to trigger useEffect.
    }, [nrrdUrl, colorMapTexture ])
        

    // ColormapTexture textures in a use Memo


    //ok this is here:
    // console.log(VolumeRenderShader1.vertexShader)
    // console.log(VolumeRenderShader1.fragmentShader)
    

   
    return (
        <>
            <mesh 
                ref={ brainModel }
                // centre the mesh: better elsewhere though? in the vertex?? 
                position={ [ volumeXLength * - 0.5, volumeYLength * - 0.5, volumeZLength * - 0.5 ] } 
                // rotation={ [ 0, 0, Math.PI * 0.25] }
            >
                {/* wait how do I get these: by using state...? */}
                { volumeXLength && 
                    // set the size of the geometry that 'holds' it according to the size of the volume (model)
                    <boxGeometry 
                        // args={ [volumeXLength, 8, 8] } 
                        // is this causing the issue NO ??? BUT DOING THIS (*2) IS RELATED TO CENTERING??????? as in only see a quarter of the volume if the geometry is set as the plain volume lengths... SO?????
                        args={ [ volumeXLength * 2, volumeYLength * 2, volumeZLength * 2 ] } 
                    />
                } 
                
                { uniforms &&  
                    <shaderMaterial 
                    //can I just set the uniforms in here???? Did it in useMemo -  Drei has a helper that I should use? but didnt.
                        uniforms={ uniforms }
                        vertexShader={ brainVolumeVertexShader } 
                        fragmentShader={ brainVolumeFragmentShader }
                        side={ BackSide }
                        // wireframe
                    />}

            </mesh>
        </>
    )
}