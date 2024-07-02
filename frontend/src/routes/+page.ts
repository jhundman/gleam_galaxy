import type { PageLoad } from './$types';

export const load: PageLoad = async ({ fetch }) => {
	try {
		const response = await fetch('/api/home');
		console.log('Response:', response);

		if (!response.ok) {
			throw new Error(`HTTP error! Status: ${response.status}`);
		}

		const payload = await response.json();
		console.log('Payload:', payload);
		return { payload };
	} catch (error) {
		console.error('Error loading data:', error);
		return { payload: null };
	}
};
