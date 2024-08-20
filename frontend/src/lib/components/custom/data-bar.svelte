<script lang="ts">
	import * as Card from '$lib/components/ui/card/index.js';
	import Link from '$lib/components/custom/link.svelte';
	import type { PageData } from './$types';
	export let data: PageData;
	function formatNumber(num: number): string {
		if (num >= 1_000_000_000_000) {
			return (num / 1_000_000_000_000).toFixed(1) + ' T';
		} else if (num >= 1_000_000_000) {
			return (num / 1_000_000_000).toFixed(1) + ' B';
		} else if (num >= 1_000_000) {
			return (num / 1_000_000).toFixed(2) + ' M';
		} else if (num >= 1_000) {
			return (num / 1_000).toFixed(2) + 'K';
		} else {
			return num.toString();
		}
	}
</script>

<div class="flex flex-wrap justify-center gap-4">
	<Card.Root class="flex-1  overflow-hidden border-hidden bg-card shadow-lg">
		<Card.Header>
			<Card.Title class="text-foreground">Links</Card.Title>
		</Card.Header>
		<Card.Content class="text-foreground">
			<a class="font-semibold text-[#ffaff3]" href={data.repository_url}
				><Link /> <span class="hover:underline">Repository</span></a
			>
			<br />
			<a class="font-semibold text-[#ffaff3]" href={data.hex_url}
				><Link /> <span class="hover:underline">Hex Package</span></a
			>
		</Card.Content>
	</Card.Root>
	<Card.Root class="flex-1 overflow-hidden border-hidden bg-card shadow-lg">
		<Card.Header>
			<Card.Title class="text-foreground">Project Info</Card.Title>
		</Card.Header>
		<Card.Content class="text-foreground ">
			<p>Licenses: {data.licenses.join(', ')}</p>
			<p>Last Updated: {new Date(data.hex_updated_at).toISOString().split('T')[0]}</p>
			<p>Created: {new Date(data.hex_inserted_at).toISOString().split('T')[0]}</p>
		</Card.Content>
	</Card.Root>
	<Card.Root class="flex-1  overflow-hidden border-hidden bg-card shadow-lg">
		<Card.Header>
			<Card.Title class="text-foreground">Package Stats</Card.Title>
		</Card.Header>
		<Card.Content class=" font-medium text-foreground">
			Downloads: {formatNumber(data.downloads_all_time)}
		</Card.Content>
	</Card.Root>
</div>
