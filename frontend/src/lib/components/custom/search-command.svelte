<script lang="ts">
	import * as Command from '$lib/components/ui/command/index.js';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';

	// Input
	let open = false;
	let value = 'home';

	onMount(() => {
		function handleKeydown(e: KeyboardEvent) {
			if (e.key === 'k' && (e.metaKey || e.ctrlKey)) {
				value = 'home';
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

	// Search
	interface SearchResult {
		package_name: string;
		description: string;
		downloads_all_time: number;
	}

	let searchTerm = '';
	let searchResults: SearchResult[] = [];

	async function handleSearch(searchTerm: string) {
		if (searchTerm.length === 0) {
			searchResults = [];
			return searchResults;
		}

		searchResults = await performSearch(searchTerm);
		console.log(searchResults);
		return searchResults;
	}

	async function performSearch(term: string): Promise<SearchResult[]> {
		try {
			const response = await fetch(`/api/search?query=${term}`);
			if (!response.ok) {
				throw new Error(`HTTP error! status: ${response.status}`);
			}
			const res = await response.json();
			return res.data;
		} catch (error) {
			console.error('Search failed:', error);
			return [];
		}
	}

	$: {
		handleSearch(searchTerm);
	}
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

<Command.Dialog
	shouldFilter={false}
	bind:open
	bind:value
	loop
	class="max-w-screen-sm border-2 border-border bg-background"
>
	<Command.Input bind:value={searchTerm} class="text-foreground" placeholder="Search packages" />
	<Command.List>
		<Command.Empty>No results found.</Command.Empty>
		<Command.Group heading="General">
			<Command.Item>Home</Command.Item>
		</Command.Group>
		<Command.Group heading="Packages">
			{#each searchResults as pkg}
				<Command.Item>{pkg.package_name}</Command.Item>
			{/each}
		</Command.Group>
	</Command.List>
</Command.Dialog>
