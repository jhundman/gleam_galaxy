<script lang="ts">
	import { onMount } from 'svelte';
	import { browser } from '$app/environment';

	let os = 'Unknown';

	onMount(() => {
		if (browser) {
			const userAgent = navigator.userAgent.toLowerCase();
			if (userAgent.indexOf('win') > -1) os = 'Windows';
			else if (userAgent.indexOf('mac') > -1) os = 'MacOS';
			else if (userAgent.indexOf('linux') > -1) os = 'Linux';
			else if (userAgent.indexOf('android') > -1) os = 'Android';
			else if (userAgent.indexOf('ios') > -1) os = 'iOS';
			console.log(os);
		}
	});
</script>

<kbd
	class="pointer-events-none inline-flex h-5 select-none items-center gap-1 rounded border bg-foreground px-1.5 font-mono text-xs font-bold font-medium text-muted-foreground opacity-100"
>
	<span class="text-sm">
		{#if os === 'MacOS'}
			⌘K
		{:else}
			Ctrl+K
		{/if}
	</span>
</kbd>
