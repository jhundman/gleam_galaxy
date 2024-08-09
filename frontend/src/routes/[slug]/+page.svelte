<script lang="ts">
	import type { PageData } from './$types';
	export let data: PageData;
	let package_data = null;
	let package_history = null;
	$: package_data = data.payload.data[0];
	$: package_history = data.payload.history;
</script>

{#if package_data}
	<div>
		<!-- <p>CURRENT SLUG {currentSlug}</p> -->
		<h2>{package_data.package_name}</h2>
		<p>Hex URL: <a href={package_data.hex_url}>{package_data.hex_url}</a></p>
		<p>Description: {package_data.description}</p>
		<p>Licenses: {package_data.licenses.join(', ')}</p>
		<p>Repository URL: <a href={package_data.repository_url}>{package_data.repository_url}</a></p>
		<p>Owners: {package_data.owners.join(', ')}</p>
		<p>Downloads: {package_data.downloads_all_time}</p>
		<p>Hex Updated At: {package_data.hex_updated_at}</p>
		<p>Hex Inserted At: {package_data.hex_inserted_at}</p>
	</div>
{:else}
	<div>Not found</div>
{/if}

{#if package_history}
	{#each package_history as rec}
		<p>{rec.downloads}</p>
		<p>{rec.date}</p>
	{/each}
{/if}
