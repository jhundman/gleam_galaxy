<script lang="ts">
	import * as Card from '$lib/components/ui/card/index.js';
	import Link from '$lib/components/custom/link.svelte';
	import type { PageData } from './$types';
	export let data: PageData;
</script>

<div class="flex flex-wrap justify-center gap-6">
	<Card.Root class="h-36 w-52 overflow-hidden border-hidden bg-card shadow-lg">
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
	<Card.Root class="h-36 w-52 overflow-hidden border-hidden bg-card shadow-lg">
		<Card.Header>
			<Card.Title class="text-foreground">Project Info</Card.Title>
		</Card.Header>
		<Card.Content class="text-foreground">
			<p>Licenses: {data.licenses.join(', ')}</p>
		</Card.Content>
	</Card.Root>
	<Card.Root class="h-36 w-52 overflow-hidden border-hidden bg-card shadow-lg">
		<Card.Header>
			<Card.Title class="text-foreground">Total Downloads</Card.Title>
		</Card.Header>
		<Card.Content class="text-md font-medium text-foreground">
			{data.downloads_all_time}
		</Card.Content>
	</Card.Root>
	<Card.Root class="h-36 w-52 overflow-hidden border-hidden bg-card shadow-lg">
		<Card.Header>
			<Card.Title class="text-foreground">Dates</Card.Title>
		</Card.Header>
		<Card.Content class="text-sm text-foreground">
			<p>Last Updated: {new Date(data.hex_updated_at).toLocaleDateString()}</p>
			<p>Created: {new Date(data.hex_inserted_at).toLocaleDateString()}</p>
		</Card.Content>
	</Card.Root>
</div>
