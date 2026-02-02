import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './global.css' 
import { Canvas } from '@react-three/fiber'
import { Leva } from 'leva'
import App from './App.jsx'
// import AppNoDrei from './AppNoDrei.jsx'

import { createXRStore, XR } from '@react-three/xr'
const store = createXRStore()

// frustum height and other settings from Mr Doob - they worked in three.js...
// const h = 512; 
// const aspect = window.innerWidth / window.innerHeight;

// const orthographicCameraSettings = {
//     left: - h * aspect / 2,
//     right: h * aspect / 2,
//     top: h / 2,
//     bottom: - h / 2,
//     near: 1,
//     far: 1000
// }


createRoot(document.getElementById('root')).render(
  <StrictMode>
    <>
        <button onClick={() => store.enterVR()}>Enter VR</button>
        <button onClick={() => store.enterAR()}>Enter AR</button>
        <Leva collapsed />
        <Canvas 
        // orthographic
        // camera={ {
        //   fov: 45,
        //   zoom: 1,
        //   near: 0.1,
        //   far: 1000,
        //   position: [ 1, 2, 3 ]
        // } }
        >
            <XR store={ store }>
                <App />
            </XR>
        </Canvas>
    </>
  </StrictMode>,
)
