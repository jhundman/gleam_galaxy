<script lang="ts">
	import type { PageData } from './$types';
	export let data: PageData;
	let string_data = JSON.stringify(data);
</script>

<div>
	<h1>Package: {data.package.package_name}</h1>
	<p>Hex URL: <a href={data.package.hex_url}>{data.package.hex_url}</a></p>
	<p>Description: {data.package.description}</p>
	<p>Licenses: {data.package.licenses.join(', ')}</p>
	<p>Repository URL: <a href={data.package.repository_url}>{data.package.repository_url}</a></p>
	<p>Downloads (all time): {data.package.downloads_all_time}</p>
	<p>Hex Inserted At: {data.package.hex_inserted_at}</p>
	<p>Hex Updated At: {data.package.hex_updated_at}</p>
	<h2>Daily Downloads</h2>
	<ul>
		{#each data.package.daily_downloads as daily_download}
			<li>{daily_download.date}: {daily_download.downloads} downloads</li>
		{/each}
	</ul>
</div>
