<!--
  @component
  Generates a tooltip that works on multiseries datasets, like multiline charts. It creates a tooltip showing the name of the series and the current value. It finds the nearest data point using the [QuadTree.html.svelte](https://layercake.graphics/components/QuadTree.html.svelte) component.
 -->
<script>
	import { getContext } from 'svelte';
	import { format } from 'd3-format';
	import * as Card from '$lib/components/ui/card';

	import QuadTree from './QuadTree.svelte';

	const { data, width, yScale, config } = getContext('LayerCake');

	const commas = format(',');
	const titleCase = (d) => d.replace(/^\w/, (w) => w.toUpperCase());

	/** @type {Function} [formatTitle=d => d] - A function to format the tooltip title, which is `$config.x`. */
	export let formatTitle = (d) => {
		return new Date(d).toISOString().split('T')[0];
	};

	/** @type {Function} [formatValue=d => isNaN(+d) ? d : commas(d)] - A function to format the value. */
	export let formatValue = (d) => (isNaN(+d) ? d : commas(d));

	/** @type {Function} [formatKey=d => titleCase(d)] - A function to format the series name. */
	export let formatKey = (d) => titleCase(d);

	/** @type {Number} [offset=-20] - A y-offset from the hover point, in pixels. */
	export let offset = 100;

	/** @type {Array<Object>|undefined} [dataset] - The dataset to work off of—defaults to $data if left unset. You can pass something custom in here in case you don't want to use the main data or it's in a strange format. */
	export let dataset = undefined;

	const w = 180;
	const w2 = w / 2;

	/* --------------------------------------------
	 * Sort the keys by the highest value
	 */
	function sortResult(result) {
		if (Object.keys(result).length === 0) return [];
		const rows = Object.keys(result)
			.filter((d) => d !== $config.x)
			.map((key) => {
				return {
					key,
					value: result[key]
				};
			})
			.sort((a, b) => b.value - a.value);

		return rows;
	}
</script>

<QuadTree dataset={dataset || $data} y="x" let:x let:y let:visible let:found let:e>
	{@const foundSorted = sortResult(found)}
	{#if visible === true}
		<div style="left:{x}px;" class="line"></div>

		<Card.Root
			class="tooltip text-md rounded-md border-none bg-card transition-all duration-200 ease-out"
			style="
        width:{w}px;
        display: {visible ? 'block' : 'none'};
        top:{offset}px;
        left:{x}px;
        position: absolute;
        pointer-events: none;"
		>
			<Card.Content class="text-foreground">
				<div class="pt-4 font-semibold">{formatTitle(found[$config.x])}</div>
				<div class="text-nowrap font-semibold">
					{foundSorted[1].value} Downloads
				</div>
			</Card.Content>
		</Card.Root>
	{/if}
</QuadTree>

<style>
	.line {
		position: absolute;
		top: 0;
		bottom: 0;
		width: 1px;
		border-left: 2px dotted #969188;
		pointer-events: none;
	}
	.line {
		transition:
			left 200ms ease-out,
			top 200ms ease-out;
	}
</style>
