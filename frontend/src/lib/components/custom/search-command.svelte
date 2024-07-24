<script lang="ts">
	import * as Command from '$lib/components/ui/command/index.js';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	let open = false;
	let value = 'home';

	onMount(() => {
		function handleKeydown(e: KeyboardEvent) {
			if (e.key === 'k' && (e.metaKey || e.ctrlKey)) {
				e.preventDefault();
				open = !open;
			}
			if (e.key === 'Enter') {
				e.preventDefault();
				console.log(e);
				if (value === 'home') {
					goto('/');
					open = !open;
				} else {
					goto(`/${value}`);
					open = !open;
				}
			}
		}

		document.addEventListener('keydown', handleKeydown);

		return () => {
			document.removeEventListener('keydown', handleKeydown);
		};
	});
	let data = null;
</script>

<p class="text-md pb-4 text-muted-foreground">
	Press
	<kbd
		class="pointer-events-none inline-flex h-5 select-none items-center gap-1 rounded border bg-muted px-1.5 font-mono text-[10px] font-medium text-muted-foreground opacity-100"
	>
		<span class="text-sm">⌘</span>K
	</kbd>
	to search
</p>

<Command.Dialog bind:open bind:value class="max-w-screen-sm border-2 border-border bg-background">
	<Command.Input class="text-foreground" placeholder="Search packages" />
	<Command.List>
		<Command.Empty>No results found.</Command.Empty>
		<Command.Group heading="General">
			<Command.Item>Home</Command.Item>
		</Command.Group>
		<Command.Group heading="Packages">
			<Command.Item>Calendar</Command.Item>
			<Command.Item>wisp</Command.Item>
		</Command.Group>
	</Command.List>
</Command.Dialog>
