import type { RequestHandler } from './$types';
import { PUBLIC_BACKEND_PATH } from '$env/static/public';

export const GET: RequestHandler = async ({ params, url, request }) => {
	try {
		const fullUrl = `${PUBLIC_BACKEND_PATH}/${params.path ?? ''}${url.search}`;

		const response = await fetch(fullUrl, {
			method: request.method,
			headers: request.headers,
			body: request.method !== 'GET' ? await request.text() : undefined
		});

		return response;
	} catch (error) {
		console.error('GET request failed:', error);
		console.error('Backend path:', PUBLIC_BACKEND_PATH);
		console.error('Request path:', params.path);
		throw error;
	}
};

export const POST: RequestHandler = async ({ params, url, request }) => {
	try {
		const fullUrl = `${PUBLIC_BACKEND_PATH}/${params.path ?? ''}${url.search}`;

		const response = await fetch(fullUrl, {
			method: request.method,
			headers: request.headers,
			body: await request.text()
		});

		return response;
	} catch (error) {
		console.error('POST request failed:', error);
		console.error('Backend path:', PUBLIC_BACKEND_PATH);
		console.error('Request path:', params.path);
		throw error;
	}
};

export const PATCH: RequestHandler = async ({ params, url, request }) => {
	try {
		const fullUrl = `${PUBLIC_BACKEND_PATH}/${params.path ?? ''}${url.search}`;

		const response = await fetch(fullUrl, {
			method: request.method,
			headers: request.headers,
			body: await request.text()
		});

		return response;
	} catch (error) {
		console.error('PATCH request failed:', error);
		console.error('Backend path:', PUBLIC_BACKEND_PATH);
		console.error('Request path:', params.path);
		throw error;
	}
};

export const PUT: RequestHandler = async ({ params, url, request }) => {
	try {
		const fullUrl = `${PUBLIC_BACKEND_PATH}/${params.path ?? ''}${url.search}`;

		const response = await fetch(fullUrl, {
			method: request.method,
			headers: request.headers,
			body: await request.text()
		});

		return response;
	} catch (error) {
		console.error('PUT request failed:', error);
		console.error('Backend path:', PUBLIC_BACKEND_PATH);
		console.error('Request path:', params.path);
		throw error;
	}
};

export const DELETE: RequestHandler = async ({ params, url, request }) => {
	try {
		const fullUrl = `${PUBLIC_BACKEND_PATH}/${params.path ?? ''}${url.search}`;

		const response = await fetch(fullUrl, {
			method: request.method,
			headers: request.headers
		});

		return response;
	} catch (error) {
		console.error('DELETE request failed:', error);
		console.error('Backend path:', PUBLIC_BACKEND_PATH);
		console.error('Request path:', params.path);
		throw error;
	}
};
