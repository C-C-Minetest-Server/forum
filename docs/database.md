# Forum mod database and internal data types reference

The forum mod uses PostgreSQL.

## Database tables

### `luanti_forum_groups`

Defines forum groups.

| key | type | purpose | remarks |
|---|---|---|---|
| `group_id` | `SERIAL` | Unique ID for forum groups | `PRIMARY KEY` |
| `parent_id` | `INTEGER` | Parent of this forum group | `DEFAULT 0` |
| `group_title` | `VARCHAR(255)` | Title of this forum group | |
| `group_desc` | `BPCHAR` | Description of this forum group | |

### `luanti_forum_forums`

Metadata of a forum.

| key | type | purpose | remarks |
|---|---|---|---|
| `forum_id` | `SERIAL` | Unique ID for forums | `PRIMARY KEY` |
| `parent_id` | `INTEGER` | ID of the forum's forum group | `NOT NULL`<br />`DEFAULT 0`<br />`REFERENCES luanti_forum_groups(grou_id)` |
| `forum_name` | `VARCHAR` | Name of the forum | `DEFAULT ''` |
| `forum_last_thread_id` | `INTEGER` | ID of the last thread | `REFERENCES luanti_forum_threads(thread_id)` |
| `forum_last_thread_poster` | `VARCHAR(20)` | Name of the threader of the last thread | |
| `forum_last_thread_time` | `TIMESTAMP` | Time of the last thread | |
| `forum_owner` | `VARCHAR(20)` | Owner of the forum | |
| `forum_access_rules_default` | `INTEGER UNSIGNED` | Access rules for users that are not the owner nor listed in `luanti_forum_access_rules` | See [Access Rules](#access-rules) |
| `forum_hidden` | `BOOLEAN` | Whether this forum is hidden from those who does not have the right to delete forums | |

### `luanti_forum_access_rules`

[Access Rules](#access-rules) applied to players on a forum.

| key | type | purpose | remarks |
|---|---|---|---|
| `forum_id` | `SERIAL` | The forum this rule is applying to | `PRIMARY KEY`<br />`REFERENCES luanti_forum_forums(forum_id)` |
| `user_name` | `VARCHAR(20)` | The player this rule is applying to | `PRIMARY KEY` |
| `access_rules` | `INTEGER UNSIGNED` | Access rules this user on this forum | See [Access Rules](#access-rules) |

### `luanti_forum_threads`

Metedata of a thread.

| key | type | purpose | remarks |
|---|---|---|---|
| `thread_id` | `SERIAL` | Unique ID for threads | `PRIMARY KEY` |
| `forum_id` |  `INETEGR` | The forum this thread belongs to | `REFERENCES luanti_forum_forums(forum_id)` |
| `thread_title` | `VARCHAR(255)` | The title of this thread | |
| `thread_time` | `TIMESTAMP` | The time this thread is created. Usually the same as the first post. This will be updated when the thread passes review. | |
| `thread_first_post_id` | `INTEGER` | The first post of this thread | `REFERENCES luanti_forum_posts(post_id)` |
| `thread_first_post_poster` | `VARCHAR(20)` | The poster of the first post | |
| `thread_pending_review` | `BOOLEAN` | Whether this thread is pending review. | |
| `thread_hidden` | `BOOLEAN` | Whether this thread is hidden from those who does not have the right to delete threads | |

### `luanti_forum_posts`

Posts of a thread. Posts that are not the first one of a thread are called comments.

| key | type | purpose | remarks |
|---|---|---|---|
| `post_id` | `SERIAL` | Unique ID for posts | `PRIMARY KEY` |
| `thread_id` | `INTEGER` | The thread this post belongs to | `REFERENCES luanti_forum_threads(thread_id)` |
| `post_poster_name` | `VARCHAR(20)` | The poster of this post | |
| `post_time` | `TIMESTAMP` | The time this post is created. This will be updated when the post passes review. | |
| `post_text` | `BPCHAR` | The content of this post in its raw format. | |
| `post_parser` | `VARCHAR(10)` | The [parser](#parser) of this post | `DEFAULT 'plain'` |
| `post_pending_review` | `BOOLEAN` | Whether this comment is pending review. The first posts uses `thread_pending_review` instead of this. | |
| `post_hidden` | `BOOLEAN` | Whether this post is hidden from those who does not have the right to delete comments | |

## Internal types

### Access Rules

The access rules type is a `INTEGER UNSIGNED` containing binary data. Each bit of the data represents a privilege.

| Bin | Hex | Dec | Meaning |
|---|---|---|---|
| 2⁰ | 0x0001 | 1 | Read<br />Everything else depends on this |
| 2¹ | 0x0002 | 2 | Start a new thread |
| 2² | 0x0004 | 4 | Start a new thread without reviewing<br />Requires 2¹ to work |
| 2³ | 0x0008 | 8 | Review new threads |
| 2⁴ | 0x0010 | 16 | Edit and hide existing threads |
| 2⁵ | 0x0020 | 32 | Comment on threads |
| 2⁶ | 0x0040 | 64 | Comment on threads without reviewing<br />Requires 2³ to work |
| 2⁷ | 0x0080 | 128 | Review new comments |
| 2⁸ | 0x0100 | 256 | Edit and hide existing posts |
| 2⁹ | 0x0200 | 512 | Change forum settings |
| 2¹⁰ | 0x0400 | 1024 | Change other player's forum access rules |
| *Others* | | | Reserved for future use |

Note that the above rules may be overriden:

* The forum owner: Granted all permissions on forums they own (equivalent to all bits set to 1)
  * After transferring forum ownership, the old owner will get all rights unless removed manually.
* Players with the `forum_root` privilege: Granted all permissions on all forums

The following actions are reserved to the owner and `forum_root`:

* Change a forum's owner
* Hide a forum

### Parser

A parser is a set of functions that convert raw post contents into formspec. The following parsers are avaliable:

* `plain`: Show everything as-is. Meant for debugging and is not enabled by default.
* `basic`: Same as `plain`, but with basic @-mentioning and replying support. This is the default parser.
