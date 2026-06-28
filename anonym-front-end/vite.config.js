import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import svgr from "vite-plugin-svgr";

const productionAllowedHosts = ['www.ano-nym.fr', 'ano-nym.fr'];
const preprodAllowedHosts = ['preprod.ano-nym.fr'];

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {

  if (mode === 'production') {
    return {
      define: {
        'process.env.VITE_API_URL': process.env.VITE_API_URL_PROD,
      },
      base: "/",
      plugins: [react(), svgr()],
      preview: {
        host: '0.0.0.0',
        port: 8080,
        strictPort: true,
        allowedHosts: productionAllowedHosts,
      },
      server: {
        port: 8080,
        strictPort: true,
        host: 'localhost',
      },
      css: {
        preprocessorOptions: {
          scss: {
            api: 'modern-compiler',
          },
        },
      },
    };
  }

  if (mode === 'preprod') {
    return {
      // Configuration spécifique pour la préproduction
      define: {
        'process.env.VITE_API_URL': process.env.VITE_API_URL_PREPROD,
      },
      // Vous pouvez ajouter d'autres options de configuration spécifiques à la préprod
      base: "/",
      plugins: [react(), svgr()],
      preview: {
        host: '0.0.0.0',
        port: 8100,
        strictPort: true,
        allowedHosts: preprodAllowedHosts,
      },
      server: {
        port: 8100,
        strictPort: true,
        host: 'localhost',
      },
      css: {
        preprocessorOptions: {
          scss: {
            api: 'modern-compiler',
          },
        },
      },
    }
  }

  return {
    define: {
      'process.env.VITE_API_URL': process.env.VITE_API_URL_DEV,
    },
    base: "/",
    plugins: [react(), svgr()],
    preview: {
      host: '0.0.0.0',
      port: 8080,
      strictPort: true,
      allowedHosts: [...productionAllowedHosts, ...preprodAllowedHosts],
    },
    server: {
      port: 8080,
      strictPort: true,
      host: 'localhost',
    },
    css: {
      preprocessorOptions: {
        scss: {
          api: 'modern-compiler',
        },
      },
    },
  };
});
