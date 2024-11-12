import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import svgr from "vite-plugin-svgr";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  
  console.log(mode)

  if (mode === 'production') {
    return {
      define: {
        'process.env.VITE_API_URL': process.env.VITE_API_URL_PROD,
      },
      base: "/",
      plugins: [react(), svgr()],
      preview: {
        port: 8080,
        strictPort: true,
      },
      server: {
        port: 8080,
        strictPort: true,
        host: true,
      },
      css: {
        preprocessorOptions: {
          scss: {
            api: 'modern-compiler'
          }
        }
      }
    };
  }

  if (mode === 'preprod') {
    return {
      // Configuration spécifique pour la préproduction
      define: {
        'process.env.VITE_API_URL': process.env.VITE_API_URL_PREPROD,
      },
      // Vous pouvez ajouter d'autres options de configuration spécifiques à la préprodbase: "/",
      plugins: [react(), svgr()],
      preview: {
        port: 8100,
        strictPort: true,
      },
      server: {
        port: 8100,
        strictPort: true,
        host: true,
      },
      css: {
        preprocessorOptions: {
          scss: {
            api: 'modern-compiler'
          }
        }
      }
    }
  };

  return {
    define: {
      'process.env.VITE_API_URL': process.env.VITE_API_URL_DEV,
    },
    base: "/",
    plugins: [react(), svgr()],
    preview: {
      port: 8080,
      strictPort: true,
    },
    server: {
      port: 8080,
      strictPort: true,
      host: true,
    },
    css: {
      preprocessorOptions: {
        scss: {
          api: 'modern-compiler'
        }
      }
    }
  }
});