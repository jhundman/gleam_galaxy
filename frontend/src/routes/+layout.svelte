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

	import Github from '$lib/components/custom/github.svelte';
	import SearchCommand from '$lib/components/custom/search-command.svelte';
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

<div class="mx-auto grid min-h-screen max-w-screen-lg grid-rows-[2fr_9fr_1fr] gap-4 pt-12">
	<div class=" grid justify-items-center">
		<h1 class="gradient-text text-4xl antialiased">
			<a href="/" target="_self" tabindex="-1">Gleam Galaxy</a>
		</h1>
		<p class=" text-sm text-muted-foreground">search among the stars</p>

		<SearchCommand />
	</div>

	<div class="py-4">
		<slot />
	</div>

	<div class="grid grid-cols-2 justify-items-center gap-4">
		<a
			class="transition duration-200 ease-linear hover:text-primary"
			href="https://twitter.com/jhundma"
			tabindex="-1"
		>
			by Hayes Hundman
		</a>
		<a href="https://github.com/jhundman" tabindex="-1">
			<Github />
		</a>
	</div>
</div>

<style>
	.gradient-text {
		background-image: linear-gradient(
			90deg,
			hsl(309deg 100% 84%) 0%,
			hsl(298deg 88% 84%) 13%,
			hsl(288deg 100% 86%) 23%,
			hsl(280deg 100% 87%) 31%,
			hsl(271deg 100% 88%) 38%,
			hsl(261deg 100% 88%) 43%,
			hsl(249deg 100% 89%) 47%,
			hsl(236deg 100% 89%) 50%,
			hsl(225deg 100% 88%) 51%,
			hsl(217deg 100% 86%) 52%,
			hsl(211deg 100% 85%) 53%,
			hsl(207deg 100% 84%) 53%,
			hsl(203deg 100% 83%) 53%,
			hsl(200deg 100% 82%) 54%,
			hsl(198deg 100% 81%) 55%,
			hsl(196deg 100% 81%) 57%,
			hsl(194deg 100% 81%) 60%,
			hsl(193deg 100% 81%) 64%,
			hsl(192deg 100% 81%) 70%,
			hsl(191deg 100% 81%) 77%,
			hsl(191deg 100% 82%) 87%,
			hsl(188deg 93% 82%) 100%
		);
		-webkit-background-clip: text;
		background-clip: text;
		-webkit-text-fill-color: transparent;
	}
</style>
