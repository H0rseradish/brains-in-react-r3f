# Interactive Brain project so far 

Goal: Create a web-based app that will assist educators in teaching neuroanatomy to students using MRI data, with the eventual aim of leveraging Spatialstrates.

Prior knowledge included basic javascript and Three.js, together with some very rudimentary knowledge of React and React Three Fiber. 

It made sense to use these, particularly as Spatialstrates is built on React Three Fiber. 

First step was to investigate some of the software in use to display MRI data, supplied in .nii format, primariliy Niivue and 3D Slicer. Once it was established that the data supplied could be displayed as slices in Niivue (and activity data displayed overlaying the brain volume), the next step was to work out how .nii files could be used in three.js. 

An initial search uncovered the Three.js NRRDLoader https://threejs.org/examples/#webgl_loader_nrrd. It was simple to use 3D slicer to convert the.nii file to .nrrd format, and Mr Doob's code was used almost verbatim to render the volume using with three.js. One thing I had to do though was to change the volume data to a Float32Array (from uint16, I think it was).

Currently working on this r3f -> webxr version


### Brain data

The 3D head/brain data is the 'Montreal Neurological Institute (MNI) template' from TemplateFlow "...a publicly available framework for human and non-human brain models. The framework combines an open database with software for access, management, and vetting, allowing scientists to share their resources under FAIR—findable, accessible, interoperable, and reusable—principles." 

"TemplateFlow: FAIR-sharing of multi-scale, multi-species brain models", doi: 10.1038/s41592-022-01681-2

MNI152_T1_0.5mm_delete_segs_0_to_50.seg.nrrd was converted from .nii to .nrrd format using 3D Slicer. 3D Slicer was also used to delete segments 0 - 50, which were low values in the space around the head.


### React + Vite info (from Vite)

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Babel](https://babeljs.io/) (or [oxc](https://oxc.rs) when used in [rolldown-vite](https://vite.dev/guide/rolldown)) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/) for Fast Refresh

#### React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

#### Expanding the ESLint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and [`typescript-eslint`](https://typescript-eslint.io) in your project.

