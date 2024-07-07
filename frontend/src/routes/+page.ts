import type { PageLoad } from './$types';

export const load: PageLoad = async ({ fetch, setHeaders }) => {
	const url = `/api/home`;
	const response = await fetch(url);
	const payload = await response.json();

	setHeaders({
		age: '0',
		'cache-control': 'max-age=14400'
	});

	if (!response.ok) throw new Error(`HTTP error! Status: ${response.status}`);

	return { payload, maxage: 14400 };
};
