import { useRef, useState } from 'react'

// Necessary or not?:
import { useXR } from '@react-three/xr'

import { Container, Text } from '@react-three/uikit'
import { Panel, Slider, Button } from '@react-three/uikit-horizon'




function BrainScaleSlider({ onValueChange }) {

    return (
        <Slider min={0} max={500} step={50} width={'auto'} onValueChange={onValueChange} />
    )
}

export default function UserControls({ store, onScaleChange })  {
    //coPilot gave me these!: might come in handy - or not?
    // const { isPresenting } = useXR()
    // const controlsRef = useRef() 

    return (
        <Panel 
            pixelSize={ 0.001 } 
            width={300} 
            padding={ 20 } 
            positionTop={ 300 } 
            backgroundColor="white"  flexDirection="column" 
            justifyContent="center" 
            alignItems="center" 
        >

            <BrainScaleSlider 
                onValueChange={(value) => {
                    console.log('scale changed to:', value)
                    onScaleChange(value / 100) // divide by 100 to get scale factor for volume, because slider is 0-500 and scale factor is 0-5
                }}
            />

            <Text marginTop={ 0 } color="white" anchorX="center">
                0% = life size
            </Text>

            <Button 
                marginTop={ 10 }
                onClick={() => {
                    console.log('Button clicked!')
                    store.getState().session?.end()
                }}>
                <Text size={ 0.05 } color="black" anchorX="center" anchorY="middle">
                    Leave AR/VR
                </Text>
            </Button>
            
        </Panel>
    )
}
    


