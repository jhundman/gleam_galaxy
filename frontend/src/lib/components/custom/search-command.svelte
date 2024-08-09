<script lang="ts">
	import * as Command from '$lib/components/ui/command/index.js';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import Shortcut from '$lib/components/custom/shortcut.svelte';

	// Input
	let open = false;
	let value = 'home';
	function open_dialog() {
		open = !open;
	}

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
	let timer: ReturnType<typeof setTimeout>;

	const debouncedSearch = (term: string) => {
		clearTimeout(timer);
		timer = setTimeout(() => {
			handleSearch(term);
		}, 250);
	};

	async function handleSearch(term: string) {
		if (term.length === 0) {
			searchResults = [];
			return;
		}
		searchResults = await performSearch(term);
		console.log(searchResults);
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
		debouncedSearch(searchTerm);
	}
</script>

<p class="text-md pb-4 text-muted-foreground">
	Press
	<button on:click={open_dialog}><Shortcut /></button>
	to search
</p>

<Command.Dialog
	shouldFilter={false}
	bind:open
	bind:value
	loop
	class="max-w-screen-sm bg-background"
>
	<Command.Input bind:value={searchTerm} class="text-foreground" placeholder="Search packages" />
	<Command.List>
		{#if searchResults.length > 0}
			<Command.Group heading="Packages">
				{#each searchResults as pkg}
					<Command.Item value={pkg.package_name}>
						{pkg.package_name}
						<div class="absoluteright-0 ml-auto flex justify-center text-sm opacity-50">
							Downloads: {pkg.downloads_all_time}
						</div>
					</Command.Item>
				{/each}
			</Command.Group>
		{/if}
		<Command.Group heading="Home">
			<Command.Item>Home</Command.Item>
		</Command.Group>
	</Command.List>
</Command.Dialog>
