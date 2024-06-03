<script lang="ts">
	import type { PageData } from './$types';
	export let data: PageData;
	let string_data = JSON.stringify(data);
</script>

<div class="grid min-h-80 grid-cols-2 grid-rows-2 gap-12 pt-12">
	<div class="col-span-2 flex justify-center border-2"># Packages {string_data}</div>
	<div class="row-start-2 flex justify-center border-2">2</div>
	<div class="row-start-2 flex justify-center border-2">3</div>
</div>

<div class="p-10"><a href="/wisp">wisp</a></div>
