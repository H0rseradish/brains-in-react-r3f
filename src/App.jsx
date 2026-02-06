import { useMemo, Suspense } from 'react'
import { Canvas, useThree } from '@react-three/fiber'
import { OrthographicCamera, OrbitControls } from "@react-three/drei";
import { XROrigin, createXRStore, XR} from '@react-three/xr'
import { Leva } from 'leva'
import NrrdVolumeDisplay from "./NrrdVolumeDisplay"

export default function App()
{
    // now memoized... !!!!
    const store = useMemo(() => createXRStore(), [])
    // frustum height and other settings from Mr Doob - they worked in three.js...

    // these!!!!: what is the way?
    // apparently the unit is 1m in xr!!!! so NOOOO?!!!! so the frustum height is 512 metres?!!!!! Need to deal with the scaling- need to understand it first.
    const h = 512; 

    // three-ish but not r3f-ish:
    const aspect = window.innerWidth / window.innerHeight;

    /// r3f has a better way: NOOOOOOOOOOOO!!!!!! or not here anyway - App is not within the Canvas element... so r3f hooks wont work...(useThree())
    // 
    // const { size } = useThree()
    // const aspect = size.width / size.height

    //so... cant just put these in the jsx, because aspect ratio...
    // const orthographicCameraSettings = useMemo(() => ({
    //     right: h * aspect / 2,
    //     top: h / 2,
    //     bottom: - h / 2,
    //     near: 1,
    //     far: 1000
    // }),[ h, aspect ] )

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
                {/* ie 256 metres away...!!!!!!!! THIS IS DAFT */}
                <XROrigin position-z={ 256 }/>

                {/* ensure assets are loaded for the XR with Suspense: */}
                <Suspense>

                    <OrthographicCamera 
                        makeDefault 
                        args={ [orthographicCameraSettings] }
                        // positioning of orthographic camera does not change scale,ONLY WHAT IS VISIBLE IN THE FRUSTUM!
                        // a value (any value) in position seems to be necessary for orbit controls to work - but WHY???
                        position={ [ 0, 0, 0.1 ] }
                    
                        //this up value affects how the orbit controls work... ie which way round:
                        up={ [ 0, 1, 0 ] }
                    />
                    
                    <OrbitControls />
                   
                    <NrrdVolumeDisplay nrrdUrl="./MNI152_T1_0.5mm_delete_segs_0_to_50.seg.nrrd" colorMapURL="cm_viridis.png"/>

                </Suspense>
            </XR>

        </Canvas>
        
    </>
}
