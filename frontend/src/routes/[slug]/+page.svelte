<script lang="ts">
	import type { PageData } from './$types';
	import DataBar from '$lib/components/custom/data-bar.svelte';
	export let data: PageData;
	let package_data = null;

	let package_history = null;

	$: package_data = data.payload.data[0];
	// eslint-disable-next-line
	$: package_history = data.payload.history.map((item: any) => ({
		...item,
		date: new Date(item.date)
	}));

	//Test
	import { LayerCake, Svg, Html } from 'layercake';

	import Line from '$lib/components/custom/graph/Line.svelte';

	import AxisX from '$lib/components/custom/graph/AxisX.svelte';
	import AxisY from '$lib/components/custom/graph/AxisY.svelte';
	import Tooltip from '$lib/components/custom/graph/Tooltip.svelte';
	import QuadTree from '$lib/components/custom/graph/QuadTree.svelte';

	const xKey = 'date';
	const yKey = 'downloads';
</script>

{#if package_data}
	<div>
		<!-- <p>CURRENT SLUG {currentSlug}</p> -->
		<h2 class="pb-2 font-mono text-2xl font-semibold text-[#ffaff3]">
			<a href={package_data.hex_url}>{package_data.package_name}</a>
		</h2>
		<p class="pb-4 opacity-80">{package_data.description}</p>

		<!-- Chart -->
		<div class="chart-container m-2 p-2">
			<LayerCake
				padding={{ top: 10, right: 25, bottom: 20, left: 25 }}
				x={xKey}
				y={yKey}
				yDomain={[0, null]}
				data={package_history}
			>
				<Svg>
					<AxisX />
					<AxisY ticks={4} />
					<Line />
				</Svg>
				<Html>
					<!-- <QuadTree let:x let:y let:visible>
						<div
							class="circle"
							style="top:{y}px;left:{x}px;display: {visible ? 'block' : 'none'};"
						></div>
					</QuadTree> -->
					<Tooltip />
				</Html>
			</LayerCake>
		</div>

		<!-- Data Bar -->
		<div class="mx-4 my-6 border-t border-muted-foreground opacity-25"></div>
		<DataBar data={package_data} />
	</div>
{:else}
	<div>Not found</div>
{/if}

<style>
	.chart-container {
		width: 100%;
		height: 350px;
	}
	.circle {
		position: absolute;
		border-radius: 50%;
		background-color: #ffaff3;
		transform: translate(-50%, -50%);
		pointer-events: none;
		width: 8px;
		height: 8px;
	}
</style>
