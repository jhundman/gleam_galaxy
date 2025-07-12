PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA foreign_keys=ON;
PRAGMA busy_timeout=5000;
PRAGMA temp_store=MEMORY;

CREATE TABLE IF NOT EXISTS packages (
    package_name TEXT PRIMARY KEY,
    hex_url TEXT,
    description TEXT,
    licenses TEXT, -- Stored as a JSON array string
    repository_url TEXT,
    owners TEXT, -- Stored as a JSON array string
    downloads_all_time INTEGER,
    hex_updated_at TEXT,
    hex_inserted_at TEXT,
    inserted_at TEXT
);

CREATE TABLE IF NOT EXISTS package_releases (
    package_name TEXT,
    release TEXT,
    release_downloads INTEGER,
    url TEXT,
    hex_updated_at TEXT,
    hex_inserted_at TEXT,
    inserted_at TEXT,
    PRIMARY KEY (package_name, release)
);

CREATE TABLE IF NOT EXISTS package_daily_downloads (
    package_name TEXT,
    downloads_yesterday INTEGER,
    date TEXT, -- Stored in 'YYYY-MM-DD' format
    inserted_at TEXT, -- Stored in ISO 8601 format
    PRIMARY KEY (package_name, date)
);

CREATE INDEX IF NOT EXISTS idx_package_releases_package_name ON package_releases (package_name);
CREATE INDEX IF NOT EXISTS idx_package_daily_downloads_package_name ON package_daily_downloads (package_name);
