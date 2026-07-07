import { useState,  } from "react";

import NrrdVolumeDisplay from './NrrdVolumeDisplayv2DreiShaderMat.jsx'
import UserControls from './UserControls.jsx'



export default function Experience({ store }) {
  const [scale, setScale] = useState(1)


  return (
    <>

        <UserControls store={store} onScaleChange={setScale}/>

        <NrrdVolumeDisplay nrrdUrl="MNI152_T1_1mm_brain.seg.nrrd" colorMapURL="cm_gray.png" scale={scale}/>

        <mesh 
            position={[ 0.3, 0, 0 ]}  
            scale={[ 1, 1, 1 ]} 
            onClick={() => {
                console.log('clicked mesh')
                store.getState().session?.end()
            } }
        >
            <boxGeometry args={[ 0.05, 0.05, 0.05 ]} />
            <meshBasicMaterial color="green" />
        </mesh>

    </>
  )
}