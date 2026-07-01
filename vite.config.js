import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import glsl from 'vite-plugin-glsl'
import basicSsl from '@vitejs/plugin-basic-ssl'

// https://vite.dev/config/
export default defineConfig({
  plugins: 
  [
    react(),
    glsl(),
    basicSsl()
  ],
  // needed for github pages...
  base: "/brains-in-react-r3f/"
})
