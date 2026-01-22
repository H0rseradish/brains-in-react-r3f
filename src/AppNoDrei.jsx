// This was made to exclude Drei as the culprit for the bug where if the angle goes below or above, (not sure which!!!)perpendicular then the pixels spread downwards from the base of the model.
// import { OrthographicCamera, OrbitControls } from "@react-three/drei";
import { useRef } from "react";
import { OrthographicCamera } from "three";
import { extend, useThree } from "@react-three/fiber";
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'

import NrrdVolumeDisplay from "./NrrdVolumeDisplay"


extend( { OrbitControls: OrbitControls })

export default function AppNoDrei()
{
    const brainModel = useRef()
    const { camera, gl } = useThree()

    console.log(camera) 
    

    //shadow acne?????
    // <directionalLight castShadow position={ [ 1, 2, 3 ] } intensity={ 4.5 } shadow-normalBias={ 0.04 } />


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

    return <>
        {/* <OrthographicCamera 
            makeDefault 
            args={ [orthographicCameraSettings] }
            // z is distance of camera, so...:
            position={ [ - 64, - 64, 64 ] }
            up={ [ 0, 0, 1 ] }
        /> */}
        <orbitControls args={[ camera, gl.domElement ]}/>

        <NrrdVolumeDisplay
            ref={ brainModel} 
            nrrdUrl="./MNI152_T1_0.5mm_delete_segs_0_to_50.seg.nrrd" colorMapURL="cm_viridis.png"

        />
        
    </>
}
