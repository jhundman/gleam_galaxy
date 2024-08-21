import type { RequestHandler } from './$types';
import { PUBLIC_BACKEND_PATH } from '$env/static/public';

export const GET: RequestHandler = async ({ params, url, request }) => {
	const response = await fetch(`${PUBLIC_BACKEND_PATH}/${params.path ?? ''}${url.search}`, {
		method: request.method,
		headers: request.headers,
		body: request.method !== 'GET' ? await request.text() : undefined
	});

	return response;
};

export const POST: RequestHandler = async ({ params, url, request }) => {
	const response = await fetch(`${PUBLIC_BACKEND_PATH}/${params.path ?? ''}${url.search}`, {
		method: request.method,
		headers: request.headers,
		body: await request.text()
	});

	return response;
};

export const PATCH: RequestHandler = async ({ params, url, request }) => {
	const response = await fetch(`${PUBLIC_BACKEND_PATH}/${params.path ?? ''}${url.search}`, {
		method: request.method,
		headers: request.headers,
		body: await request.text()
	});

	return response;
};

export const PUT: RequestHandler = async ({ params, url, request }) => {
	const response = await fetch(`${PUBLIC_BACKEND_PATH}/${params.path ?? ''}${url.search}`, {
		method: request.method,
		headers: request.headers,
		body: await request.text()
	});

	return response;
};

export const DELETE: RequestHandler = async ({ params, url, request }) => {
	const response = await fetch(`${PUBLIC_BACKEND_PATH}/${params.path ?? ''}${url.search}`, {
		method: request.method,
		headers: request.headers
	});

	return response;
};
