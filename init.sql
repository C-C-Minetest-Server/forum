CREATE TABLE IF NOT EXISTS luanti_forum_groups (
    group_id SERIAL PRIMARY KEY,
    parent_id INTEGER DEFAULT 0 REFERENCES luanti_forum_groups ON DELETE SET DEFAULT (group_id),
    group_title VARCHAR(255),
    group_desc BPCHAR
);

CREATE TABLE IF NOT EXISTS luanti_forum_forums (
    forum_id SERIAL PRIMARY KEY,
    parent_id INTEGER NOT NULL DEFAULT 0 REFERENCES luanti_forum_groups(group_id) ON DELETE SET DEFAULT,
    forum_name VARCHAR DEFAULT '',
    forum_last_thread_id INTEGER REFERENCES luanti_forum_threads ON DELETE SET NULL (thread_id),
    forum_last_thread_poster VARCHAR(20),
    forum_last_thread_time TIMESTAMP,
    forum_owner VARCHAR(20),
    forum_access_rules_default INTEGER UNSIGNED,
    forum_hidden BOOLEAN
);

CREATE TABLE IF NOT EXISTS luanti_forum_access_rules (
    forum_id SERIAL REFERENCES luanti_forum_forums ON DELETE CASCADE (forum_id),
    user_name VARCHAR(20),
    access_rules INTEGER UNSIGNED
    PRIMARY KEY (forum_id, user_name)
);

CREATE TABLE IF NOT EXISTS luanti_forum_threads (
    thread_id SERIAL PRIMARY KEY,
    forum_id INTEGER REFERENCES luanti_forum_forums ON DELETE CASCADE (forum_id),
    thread_title VARCHAR(255),
    thread_time TIMESTAMP,
    thread_first_post_id INTEGER REFERENCES luanti_forum_posts ON DELETE CASCADE (post_id),
    thread_first_post_poster VARCHAR(20),
    thread_pending_review BOOLEAN,
    thread_hidden BOOLEAN
);

CREATE TABLE IF NOT EXISTS luanti_forum_posts (
    post_id SERIAL PRIMARY KEY,
    thread_id INTEGER REFERENCES luanti_forum_threads ON DELETE CASCADE (thread_id),
    post_poster_name VARCHAR(20),
    post_time TIMESTAMP,
    post_text BPCHAR,
    post_parser VARCHAR(10) DEFAULT 'plain',
    post_pending_review BOOLEAN,
    post_hidden BOOLEAN
);