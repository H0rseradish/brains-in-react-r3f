import { useMemo, useEffect, useState, useRef } from "react";
import { Data3DTexture, RedFormat, FloatType, LinearFilter, TextureLoader, BackSide, UniformsUtils } from "three";
import { NRRDLoader } from "three/examples/jsm/Addons.js";
import { VolumeRenderShader1 } from "three/examples/jsm/Addons.js";
// VolumeRenderShader1 is here: https://github.com/mrdoob/three.js/blob/master/examples/jsm/shaders/VolumeShader.js

export default function NrrdVolumeDisplay( { nrrdUrl, colorMapURL } ) 
{
    //do I need these - is this the way?
    const [volumeXLength, setVolumeXLength] = useState()
    const [volumeYLength, setVolumeYLength] = useState()
    const [volumeZLength, setVolumeZLength] = useState()
    // const [volconfig, setVolconfig] = useState()
    const [uniforms, setUniforms] = useState()

    const brainModel = useRef()

    // Colormap texture 'cache' it (or them) with useMemo??
    const colorMap = useMemo(() => 
    {
        const loader = new TextureLoader();
        return loader.load(colorMapURL);

    }, [colorMapURL]);
    
    // console.log(volumeData)
    
    // is this right?
    useEffect(() => {

        // setVolconfig({ clim1: 0, clim2: 1, renderstyle: 'iso', isothreshold: 0.15, colormap: 'viridis' });

        new NRRDLoader().load(nrrdUrl, (volume) => {
        //convert datatype to Float32Array (from uint8 or uint16?)
        volume.data = new Float32Array(volume.data)
        // console.log(volume.data)// ok this worked!

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

        const shader = VolumeRenderShader1;
        const uniforms = UniformsUtils.clone(shader.uniforms);
        // console.log(uniforms)

        
        //these have to be set like this, not by replacing the objects!!! (as in writing uniform={ value: something})

        // remember do not use the React state inside the thing that sets it!!!!!

        uniforms.u_clim.value.set (0, 2);
        uniforms.u_cmdata.value = colorMap; // Should be Texture

         // Should be Data3DTexture
        uniforms.u_data.value = texture;
        
        uniforms.u_renderstyle.value = 1; // 1 is iso rendering, 0 is mip

        uniforms.u_renderthreshold.value = 0.15; 

        uniforms.u_size.value.set(volume.xLength, volume.yLength, volume.zLength) ; //so a Vector3

        // console.log(uniforms)

        setUniforms(uniforms)
        })

    }, [nrrdUrl, colorMapURL, colorMap ])
        

        // Colormap textures in a use Memo

        // Material

        // material = new THREE.ShaderMaterial( {
        //     uniforms: uniforms,
        //     vertexShader: shader.vertexShader,
        //     fragmentShader: shader.fragmentShader,
        //     side: THREE.BackSide // The volume shader uses the backface as its "reference point"
        // } );

    //ok this is here:
    console.log(VolumeRenderShader1.vertexShader)
    console.log(VolumeRenderShader1.fragmentShader)
    

   
    return (
        <>
            <mesh 
                ref={ brainModel}
                position={ [ volumeXLength * - 0.5, volumeYLength * - 0.5, volumeZLength * - 0.5 ] } 
            >
                {/* wait how do I get these: by using state...? */}
                { volumeXLength && 
                    <boxGeometry 
                        // args={ [volumeXLength, 8, 8] } 
                        args={ [ volumeXLength * 2, volumeYLength * 2, volumeZLength * 2 ] } 
                    />
                } 
                
                { uniforms &&  
                    <shaderMaterial 
                        uniforms={ uniforms }
                        vertexShader={ VolumeRenderShader1.vertexShader } 
                        fragmentShader={ VolumeRenderShader1.fragmentShader }
                        side={ BackSide }
                    />}

            </mesh>
        </>
    )
}