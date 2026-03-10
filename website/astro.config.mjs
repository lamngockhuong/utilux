// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

// Local dev: http://localhost:4321, Production: https://utilux.khuong.dev
const isProd = process.env.NODE_ENV === 'production';
const siteUrl = isProd ? 'https://utilux.khuong.dev' : 'http://localhost:4321';

// https://astro.build/config
export default defineConfig({
  site: siteUrl,
  vite: {
    plugins: [tailwindcss()]
  }
});