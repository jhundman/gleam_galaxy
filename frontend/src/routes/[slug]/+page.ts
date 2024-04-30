import type { PageLoad } from './$types';
export const load: PageLoad = ({ params }) => {
	return {
		package: {
			param: params.slug,
			package_name: 'wisp',
			hex_url: 'https://hex.pm/packages/wisp',
			description: 'A practical web framework for Gleam',
			licenses: ['Apache-2.0'],
			repository_url: 'https://github.com/gleam-wisp/wisp',
			downloads_all_time: 3845,
			hex_inserted_at: '2023-07-18T18:17:34.314Z',
			hex_updated_at: '2023-07-18T18:17:34.314Z',
			daily_downloads: [
				{ downloads: 100, date: '2024-04-15' },
				{ downloads: 100, date: '2024-04-14' },
				{ downloads: 100, date: '2024-04-13' }
			]
		}
	};
};
