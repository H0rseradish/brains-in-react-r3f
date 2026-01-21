import NiivueLoad from './NiivueLoad.jsx';
import NiivueLoadOverlay from './NiivueLoadOverlay.jsx';

function NiivueDisplay() {
  
  return (
    <div>
        <h1>Trying out Niivue...</h1>
        <div id="first">
            <h2>Highest resolution file from Tirso</h2>
            <NiivueLoad imageUrl="./MNI152_T1_0.5mm.nii" />
        </div>  
        <div id="second">
            <h2>Lower resolution file from Tirso</h2>
            <NiivueLoad imageUrl="./MNI152_T1_2mm_brain.nii" />
        </div>    
        <div id="third">
            <h2>Overlaying the language association test data on the brain anatomy</h2>
            <NiivueLoadOverlay />
        </div> 
    </div>
  )
}

export default NiivueDisplay
