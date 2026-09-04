import { useState,  } from "react";

import NrrdVolumeDisplay from './NrrdVolumeDisplayV2Drei.jsx'
import UserControls from './UserControls.jsx'



export default function Experience({ store }) {
  const [scale, setScale] = useState(1)


  return (
    <group>
        <UserControls store={store} onScaleChange={setScale} scale={scale} />

        <NrrdVolumeDisplay nrrdUrl="MNI152_T1_1mm_brain.seg.nrrd" colorMapURL="cm_gray.png" scale={scale} />

        <NrrdVolumeDisplay nrrdUrl="MNI152_T1_0.5mm_delete_segs_0_to_50.seg.nrrd" colorMapURL="cm_viridis.png" scale={scale} />


        {/* Need to convert this to a .nrrd file!! */}
        {/* <NrrdVolumeDisplay nrrdUrl="language_association-test_z_FDR_0.01.nii.gz" scale={scale} /> */}

        {/* <mesh 
            position={[ 0.3, 0, 0 ]}  
            scale={[ 1, 1, 1 ]} 
            onClick={() => {
                console.log('clicked mesh')
                store.getState().session?.end()
            } }
        >
            <boxGeometry args={[ 0.05, 0.05, 0.05 ]} />
            <meshBasicMaterial color="green" />
        </mesh> */}

    </group>
  )
}