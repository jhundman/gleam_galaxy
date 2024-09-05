# Gleam Galaxy
***Search the stars, find Gleam Packages and their stats***

Inspired by [ClickPy](https://clickpy.clickhouse.com/), ***Gleam Galaxy*** is an analytics website for
[Gleam](https://gleam.run/) packages. Slightly different than Clickpy, Gleam Galaxy works by logging
daily package information from [Hex](https://hex.pm/)

## Structure
- Frontend: Contains all things frontend. It is built using sveltekit and deployed to cloudflare pages
- Backend: A Gleam [Wisp](https://hexdocs.pm/wisp/) server which handles backend APIs and Cron, deployed to fly.io
- Database: [Tinybird](https://www.tinybird.co/)

## Logo

Lucy was modified from [Gleam's branding](https://gleam.run/branding/) and is now a shooting star 💫
![Lucy](frontend/static/lucy-galaxy.svg?width=300&height=200)

## Future Ideas
[] Enable alerts for Cron Job failures
[] Add more stats to homepage
[] Add more stats to package page
[] Add a data export so others can bulk download
[] Fix backend route naming lol
