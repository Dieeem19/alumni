import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import { resolve } from 'path'
import { fileURLToPath } from 'url'

const __dir = fileURLToPath(new URL('.', import.meta.url))

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    {
      name: 'redirect-to-login',
      configureServer(server) {
        server.middlewares.use((req, res, next) => {
          const url = req.url?.split('?')[0]
          if (url === '/' || url === '/index.html') {
            res.writeHead(302, { Location: '/login.html' })
            res.end()
            return
          }
          next()
        })
      }
    }
  ],
  server: {
    open: '/login.html'
  },
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dir, 'login.html'),
        login: resolve(__dir, 'login.html'),
        register: resolve(__dir, 'register.html'),
        alumni: resolve(__dir, 'alumnipage.html'),
        admin: resolve(__dir, 'adminpage.html'),
        app: resolve(__dir, 'index.html'),
      }
    }
  }
})
