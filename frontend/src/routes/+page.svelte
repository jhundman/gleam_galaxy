<script lang="ts">
	import type { PageData } from './$types';
	export let data: PageData;
	let home = data.payload.data;

	function formatNumber(num: number): string {
		if (num >= 1_000_000_000_000) {
			return (num / 1_000_000_000_000).toFixed(1) + ' Trillion';
		} else if (num >= 1_000_000_000) {
			return (num / 1_000_000_000).toFixed(1) + ' Billion';
		} else if (num >= 1_000_000) {
			return (num / 1_000_000).toFixed(2) + ' Million';
		} else if (num >= 1_000) {
			return (num / 1_000).toFixed(2) + ' Thousand';
		} else {
			return num.toString();
		}
	}
</script>

<div class="grid h-full grid-rows-[1fr_5fr_5fr] gap-14">
	<div class="inline-flex justify-center text-lg">
		<p>
			Explore <span class="font-semibold text-primary">{home.num_packages}</span>{' '}Gleam packages
			with over
			<span class="font-semibold text-primary">{formatNumber(home.total_downloads)}</span
			>{' '}downloads from hexpm.
		</p>
	</div>
	<div class="grid grid-cols-2 gap-8">
		<div class="flex justify-center border-2">2</div>
		<div class="flex justify-center border-2">3</div>
	</div>

	<div class="grid grid-cols-2 gap-8">
		<a class="flex justify-center border-2" tabindex="-1" href="/wisp">wisp</a>
		<a class="flex justify-center border-2" tabindex="-1" href="/wisp">wisp</a>
	</div>
</div>
