# Brain data

The 3D head/brain data is the 'Montreal Neurological Institute (MNI) template' from TemplateFlow "...a publicly available framework for human and non-human brain models. The framework combines an open database with software for access, management, and vetting, allowing scientists to share their resources under FAIR—findable, accessible, interoperable, and reusable—principles." 

"TemplateFlow: FAIR-sharing of multi-scale, multi-species brain models", doi: 10.1038/s41592-022-01681-2

MNI152_T1_0.5mm_delete_segs_0_to_50.seg.nrrd was converted from .nii to .nrrd format using 3D Slicer. 3D Slicer was also used to delete segments 0 - 50, which were low values in the space around the head.


## React + Vite info (from Vite)

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Babel](https://babeljs.io/) (or [oxc](https://oxc.rs) when used in [rolldown-vite](https://vite.dev/guide/rolldown)) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/) for Fast Refresh

### React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

### Expanding the ESLint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and [`typescript-eslint`](https://typescript-eslint.io) in your project.

