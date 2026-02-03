import { StrictMode, Suspense } from 'react'
import { createRoot } from 'react-dom/client'
import './global.css' 
import { Canvas } from '@react-three/fiber'
import { Leva } from 'leva'
import { OrthographicCamera, OrbitControls } from "@react-three/drei";
import { IfInSessionMode, XROrigin, createXRStore, XR} from '@react-three/xr'

import NrrdVolumeDisplay from "./NrrdVolumeDisplay"

const store = createXRStore()

// import App from './App.jsx'
// import AppNoDrei from './AppNoDrei.jsx'

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

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <>
        <button onClick={() => store.enterVR()}>Enter VR</button>
        <button onClick={() => store.enterAR()}>Enter AR</button>

        <Leva collapsed />
        <Canvas>
            <XR store={ store }>
                {/* <XROrigin position-z={ - 3.0 }/> */}
                {/* ensure assets are loaded for the XR with Suspense: */}
                <Suspense>
                    {/* <App /> */}
                    <OrthographicCamera 
                        makeDefault 
                        args={ [orthographicCameraSettings] }
            
                        //so this will need to change according to the user but I think not in here????.. would be very costly???:
                        position={ [ 0, 128, -8 ] }
                    
                        //this up value affects how the orbit controls work... ie which way round:
                        up={ [ 0, 0, 1 ] }
                    />
                    {/* <IfInSessionMode deny={['immersive-ar', 'immersive-vr']}> */}
                        <OrbitControls />
                    {/* </IfInSessionMode> */}
                            
                    <NrrdVolumeDisplay nrrdUrl="./MNI152_T1_0.5mm_delete_segs_0_to_50.seg.nrrd" colorMapURL="cm_viridis.png"/>
                </Suspense>
            </XR>
        </Canvas>
    </>
  </StrictMode>,
)
