<script lang="ts">
	import '../app.pcss';
	import '@fontsource/lexend/100.css';
	import lexend_100 from '@fontsource/lexend/files/lexend-latin-100-normal.woff';
	import '@fontsource/lexend/200.css';
	import lexend_200 from '@fontsource/lexend/files/lexend-latin-200-normal.woff2';
	import '@fontsource/lexend/300.css';
	import lexend_300 from '@fontsource/lexend/files/lexend-latin-300-normal.woff2';
	import '@fontsource/lexend/400.css';
	import lexend_400 from '@fontsource/lexend/files/lexend-latin-400-normal.woff2';
	import '@fontsource/lexend/500.css';
	import lexend_500 from '@fontsource/lexend/files/lexend-latin-500-normal.woff2';
	import '@fontsource/lexend/600.css';
	import lexend_600 from '@fontsource/lexend/files/lexend-latin-600-normal.woff2';
	import '@fontsource/lexend/700.css';
	import lexend_700 from '@fontsource/lexend/files/lexend-latin-700-normal.woff2';
	import '@fontsource/lexend/800.css';
	import lexend_800 from '@fontsource/lexend/files/lexend-latin-800-normal.woff2';
	import '@fontsource/lexend/900.css';
	import lexend_900 from '@fontsource/lexend/files/lexend-latin-900-normal.woff2';
</script>

<svelte:head>
	<link rel="preload" as="font" href={lexend_100} type="font/woff2" crossorigin="anonymous" />
	<link rel="preload" as="font" href={lexend_200} type="font/woff2" crossorigin="anonymous" />
	<link rel="preload" as="font" href={lexend_300} type="font/woff2" crossorigin="anonymous" />
	<link rel="preload" as="font" href={lexend_400} type="font/woff2" crossorigin="anonymous" />
	<link rel="preload" as="font" href={lexend_500} type="font/woff2" crossorigin="anonymous" />
	<link rel="preload" as="font" href={lexend_600} type="font/woff2" crossorigin="anonymous" />
	<link rel="preload" as="font" href={lexend_700} type="font/woff2" crossorigin="anonymous" />
	<link rel="preload" as="font" href={lexend_800} type="font/woff2" crossorigin="anonymous" />
	<link rel="preload" as="font" href={lexend_900} type="font/woff2" crossorigin="anonymous" />
</svelte:head>

<div class="mx-auto flex max-w-screen-lg justify-center border-2 p-6">
	<slot></slot>
</div>
