String notifications = """
CREATE TABLE IF NOT EXISTS notifications(
  id TEXT PRIMARY KEY,
  title_ar TEXT,
  body_ar TEXT,
  title_en TEXT,
  body_en TEXT,
  img TEXT,
  url TEXT,
  route TEXT,
  payload TEXT,
  is_read INTEGER DEFAULT 0,
  created_at INTEGER
);
""";

String notificationsIndexes = """
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
""";

String tmp = """
CREATE TABLE IF NOT EXISTS tmp(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name varchar(255),
  detail varchar(255),
  is_show INTEGER,
  created_at varchar(50),
  updated_at varchar(50)
);
""";

// create 
