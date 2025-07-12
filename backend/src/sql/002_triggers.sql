CREATE VIRTUAL TABLE IF NOT EXISTS packages_fts USING fts5(
    package_name,
    description,
    content='packages',
    content_rowid='rowid'
);

CREATE TRIGGER IF NOT EXISTS packages_after_insert
AFTER INSERT ON packages
BEGIN
    INSERT INTO packages_fts(rowid, package_name, description)
    VALUES (new.rowid, new.package_name, new.description);
END;

CREATE TRIGGER IF NOT EXISTS packages_after_delete
AFTER DELETE ON packages
BEGIN
    INSERT INTO packages_fts(packages_fts, rowid, package_name, description)
    VALUES ('delete', old.rowid, old.package_name, old.description);
END;

CREATE TRIGGER IF NOT EXISTS packages_after_update
AFTER UPDATE ON packages
BEGIN
    INSERT INTO packages_fts(packages_fts, rowid, package_name, description)
    VALUES ('delete', old.rowid, old.package_name, old.description);
    INSERT INTO packages_fts(rowid, package_name, description)
    VALUES (new.rowid, new.package_name, new.description);
END;
