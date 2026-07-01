import { useMemo, useRef, useEffect, Suspense } from 'react'
import { Canvas, useThree } from '@react-three/fiber'
// check out import of Orbit Controls
import { OrthographicCamera, PerspectiveCamera, OrbitControls } from "@react-three/drei";

import { XROrigin, createXRStore, XR, useXR } from '@react-three/xr'
import { Leva } from 'leva'
import NrrdVolumeDisplay from "./NrrdVolumeDisplayv2DreiShaderMat.jsx"

export default function App()
{
    // now memoized... !!!!
    const store = useMemo(() => createXRStore(), [])


    // console.log(store.getState())
    
    
    return <>

        <button onClick={() => store.enterVR()}>Enter VR</button>
        <button onClick={() => store.enterAR()}>Enter AR</button>

        {/* <Leva collapsed /> */}
        <Canvas 
            gl={{ preserveDrawingBuffer: true }
        } >
            
            <XR store={ store }>

                {/* XROrigin is user's XR space - so if I wanted my volume to always placed relative to the user then I could make my group a child. If relative to the general scene then NOT in here. NB Volume does not move WITH the user, only on refresh. Need to consider if this is the best way - may need to change later*/}
                <XROrigin position={[0, -1.5, 1.0]} rotationY={ 0 } /> 

                {/* ensure assets are loaded for the XR with Suspense: */}
                <Suspense>

                    <PerspectiveCamera
                        makeDefault
                        fov={45}
                        near={0.1}
                        far={100}
                        position={[ 0, 0.5, -0.25 ]}
                    /> 
                    
                    {/* remember orbit controls will override any rotation set on the camera, so instead, use position as above: */}

                    
                    {/** (Orbit controls just ignored in XR) */}
                    <OrbitControls target={[ 0, 0, 0 ]} />

                    <group>
                        
                            <NrrdVolumeDisplay nrrdUrl="MNI152_T1_0.5mm_delete_segs_0_to_50.seg.nrrd" colorMapURL="cm_viridis.png"/>
                        
                    </group>

                </Suspense>
            </XR> 

        </Canvas>
        
    </>
}
