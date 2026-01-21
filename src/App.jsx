import NrrdVolumeDisplay from "./NrrdVolumeDisplay"
import { OrthographicCamera, OrbitControls } from "@react-three/drei";


export default function App()
{
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
        <OrthographicCamera 
            makeDefault 
            args={ [orthographicCameraSettings] }

            // z is how far the camera goes through the skull....:
            //so this will need to change according to the user but I think not in here.. would be very costly???:
            position={ [ -64, - 64, 64 ] }
            up={ [ 0, 0, 1 ] }
        />
        <OrbitControls />

        <NrrdVolumeDisplay nrrdUrl="./MNI152_T1_0.5mm_delete_segs_0_to_50.seg.nrrd" colorMapURL="cm_viridis.png"/>
        
    </>
}
