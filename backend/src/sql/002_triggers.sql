CREATE VIRTUAL TABLE IF NOT EXISTS packages_fts USING fts5(
    package_name,
    description,
    content='packages',
    content_rowid='rowid'
);

CREATE TRIGGER IF NOT EXISTS packages_after_insert
AFTER INSERT ON packages
BEGIN
    INSERT INTO packages_fts VALUES (new.package_name, new.description);
END;

CREATE TRIGGER IF NOT EXISTS packages_after_delete
AFTER DELETE ON packages
BEGIN
    DELETE FROM packages_fts WHERE rowid = old.rowid;
END;

CREATE TRIGGER IF NOT EXISTS packages_after_update
AFTER UPDATE ON packages
BEGIN
    UPDATE packages_fts SET package_name = new.package_name, description = new.description
    WHERE rowid = old.rowid;
END;
