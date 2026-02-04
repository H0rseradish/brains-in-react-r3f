import { useMemo, Suspense } from 'react'
import { Canvas } from '@react-three/fiber'
import { OrthographicCamera, OrbitControls } from "@react-three/drei";
import { XROrigin, createXRStore, XR} from '@react-three/xr'
import { Leva } from 'leva'
import NrrdVolumeDisplay from "./NrrdVolumeDisplay"

export default function App()
{
    const store = useMemo(() => createXRStore(), [])
    // frustum height and other settings from Mr Doob - they worked in three.js...
    const h = 512; 
    const aspect = window.innerWidth / window.innerHeight;

    const orthographicCameraSettings = {
        left: - h * aspect / 2,
        right: h * aspect / 2,
        top: h / 2,
        bottom: - h / 2,
        near: 1,
        far: 1000
    }
    
    return <>

        <button onClick={() => store.enterVR()}>Enter VR</button>
        <button onClick={() => store.enterAR()}>Enter AR</button>

        <Leva collapsed />
        <Canvas>
            <XR store={ store }>
                <XROrigin position-z={ 256.0 }/>
                {/* ensure assets are loaded for the XR with Suspense: */}
                <Suspense>
                    {/* <App /> */}
                    
                    <OrthographicCamera 
                        makeDefault 
                        args={ [orthographicCameraSettings] }
            
                        // a value (any value) in position seems to be necessary for orbit controls to work - but WHY???:
                        //  y = 128 was working on screen... WHY 128?
                        position={ [ 0, 0, 0.1 ] }
                    
                        //this up value affects how the orbit controls work... ie which way round:
                        // up={ [ 0, 0, 1 ] }
                    />
                    
                    <OrbitControls />
                   
                    <NrrdVolumeDisplay nrrdUrl="./MNI152_T1_0.5mm_delete_segs_0_to_50.seg.nrrd" colorMapURL="cm_viridis.png"/>

                </Suspense>
            </XR>
        </Canvas>
        
    </>
}
