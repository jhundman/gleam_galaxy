import { defineConfig } from 'vite';
import { sveltekit } from '@sveltejs/kit/vite';

export default defineConfig({
	plugins: [sveltekit()]
	// server: {
	// 	proxy: {
	// 		'http://localhost:8080/api/*': {
	// 			target: 'http://localhost:8080/api',
	// 			changeOrigin: true,
	// 			secure: false,
	// 			rewrite: (path) => path
	// 		}
	// 	}
	// }
});
