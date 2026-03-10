// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  site: 'https://lamngockhuong.github.io',
  base: '/utilux',
  vite: {
    plugins: [tailwindcss()]
  }
});