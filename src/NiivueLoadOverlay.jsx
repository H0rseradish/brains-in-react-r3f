import { useRef, useEffect } from "react";
import { Niivue } from "@niivue/niivue";

export default function NiivueLoadOverlay({ imageUrl }) {

    const canvas = useRef();
    const nvRef = useRef();
    
    useEffect(() => {
        // const volumeList = [
        // {
        //     url: imageUrl,
        // },
        // ];
        async function setupAndLoad() {
        const nv = new Niivue({
            isColorbar: true,
            backColor: [ 0, 0, 0, 0 ],
            show3Dcrosshair: true
        });
        nv.attachToCanvas(canvas.current);
        await nv.loadVolumes([
            {
                url: './MNI152_T1_0.5mm.nii',
                colormap: 'gray'
            },
            {
                url: './language_association-test_z_FDR_0.01.nii.gz',
                colormap: 'warm',
                colormapNegative: 'winter',
                cal_min: 3.0,
                cal_max: 6.0,
                cal_minNeg: -6.0,
                cal_maxNeg: -3.0 
            },
        ]);
        nvRef.current = nv;
        console.log(nv)
        }
        
        setupAndLoad()
    }, [imageUrl]);

    return <canvas ref={canvas} height={480} width={640} />;
    };

// From https://niivue.com/docs/

// import { useRef, useEffect } from "react";
// import { Niivue } from "@niivue/niivue";

// const NiiVue = ({ imageUrl }) => {
//   const canvas = useRef();
//   const nvRef = useRef();
//   useEffect(() => {
//     const volumeList = [
//       {
//         url: imageUrl,
//       },
//     ];
//     async function setupAndLoad() {
//       const nv = new Niivue();
//       nv.attachToCanvas(canvas.current);
//       await nv.loadVolumes(volumeList);
//       const nvRef.current = nv
//     }
//     setupAndLoad()
//   }, [imageUrl]);

//   return <canvas ref={canvas} height={480} width={640} />;
// };

// // use as: <NiiVue imageUrl={someUrl}> </NiiVue>

