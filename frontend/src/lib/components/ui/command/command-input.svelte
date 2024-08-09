<script lang="ts">
	import { Command as CommandPrimitive } from 'cmdk-sv';
	import Search from 'lucide-svelte/icons/search';
	import { cn } from '$lib/utils.js';

	type $$Props = CommandPrimitive.InputProps;

	let className: string | undefined | null = undefined;
	export { className as class };
	export let value: string = '';
</script>

<div class="flex items-center border-b-4 border-foreground px-2" data-cmdk-input-wrapper="">
	<Search class="mr-2 h-6 w-8 shrink-0 text-primary opacity-90 " />
	<CommandPrimitive.Input
		class={cn(
			'flex h-14 w-full rounded-md bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50',
			className
		)}
		{...$$restProps}
		bind:value
	/>
</div>
