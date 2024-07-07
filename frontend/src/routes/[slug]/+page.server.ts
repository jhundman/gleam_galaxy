import type { PageServerLoad } from './$types';
export const load: PageServerLoad = async ({ params, fetch, setHeaders }) => {
	const url = `/api/package/${params.slug}`;
	const response = await fetch(url);
	const payload = await response.json();

	setHeaders({
		age: '0',
		'cache-control': 'max-age=max-age=14400'
	});

	if (!response.ok) throw new Error(`HTTP error! Status: ${response.status}`);

	return { payload, maxage: 14400 };
};
