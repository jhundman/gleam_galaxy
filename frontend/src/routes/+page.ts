import type { PageLoad } from './$types';
export const load: PageLoad = () => {
	const payload = {
		package_count: 100,
		package_count_history: [{}],
		total_downloads: 10000,
		downloads_history: [{}],
		new_packages: [{}],
		top_packages: [{}],
		hot_packages: [{}]
	};
	return { payload };
};
