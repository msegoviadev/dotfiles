---
name: confluence
description: Read, write, and respond to comments on Confluence pages via the REST API v2. Use when the user wants to fetch page content, search pages, update a page, create a new page, or address comments and suggestions left by others.
metadata:
  tags: confluence, wiki, page, comment, feedback, atlassian, sygnum
---

## When to Use

Use this skill when:
- User wants to read or search Confluence pages
- User wants to update a page (e.g., add release notes, fix grammar, restructure content)
- User wants to create a new page in a Confluence space
- User wants to address, reply to, or act on comments left on a page
- User references a Confluence URL (`sygnum.atlassian.net/wiki`)

## Prerequisites

- `hurl` installed: `brew install hurl`
- `jq` installed: `brew install jq`
- Credentials file set up: see `README.md`
- `<SKILLS_DIR>`: the root skills directory (e.g., `~/.config/opencode/skills/` for opencode, `~/.claude/skills/` for claude-code)

## Core Safety Principles

- **Fetch before modifying.** Always read the current page content and capture the version number before any update. Confluence requires the current version to prevent conflicts.
- **Show before writing.** Display proposed content for approval. Confluence has no built-in undo for API writes.
- **Never write without explicit approval.** Create, update, and reply operations must be approved by the user before executing.
- **Check for existing replies** before proposing a reply to a comment thread to avoid duplicates.
- **Do not resolve or delete comments** unless the user explicitly requests it.

## Workflow

### Step 1: Confirm credentials

```bash
[[ -f ~/.config/hurl/confluence/default.env ]] && echo "ok" || echo "credentials file not found: ~/.config/hurl/confluence/default.env"
```

If missing, stop and guide the user to set up the credentials file from the Prerequisites section.

### Step 2: Identify the target page

**From a URL** — extract the page ID from the path:
```
https://sygnum.atlassian.net/wiki/spaces/SPACE/pages/123456789/Page+Title
                                                      ^^^^^^^^^^ page ID
```

**By title search** — find the page ID when only a title is known:
```bash
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable title="<title>" - <<'EOF' | jq '.results[] | {id, title, spaceId}'
GET {{base_url_confluence}}/api/v2/pages
[QueryStringParams]
title: {{title}}
body-format: storage
limit: 5
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
```

**List pages in a space** (use the space key visible in Confluence URLs):
```bash
# First get the spaceId from the space key
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable space_key="<SPACE_KEY>" - <<'EOF' | jq '.results[] | {id, key, name}'
GET {{base_url_confluence}}/api/v2/spaces
[QueryStringParams]
keys: {{space_key}}
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF

# Then list pages in that space
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable space_id="<space_id>" - <<'EOF' | jq '.results[] | {id, title}'
GET {{base_url_confluence}}/api/v2/pages
[QueryStringParams]
spaceId: {{space_id}}
limit: 25
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
```

### Step 3: Read page content

```bash
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable page_id="<page_id>" - <<'EOF' | jq '{id, title, version: .version.number, body: .body.storage.value, spaceId}'
GET {{base_url_confluence}}/api/v2/pages/{{page_id}}
[QueryStringParams]
body-format: storage
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
```

The response includes:
- `id` — needed for updates
- `version.number` — required for the update request
- `body.storage.value` — current page content in Confluence storage format (HTML-like XML)
- `spaceId` — needed for creating child pages

### Step 4: Prepare the new content

For **updates**: take the existing storage-format body, apply the requested changes, and show a diff or the full new content to the user for approval.

For **creates**: draft the page content in storage format. Common elements:
- `<p>Paragraph text</p>`
- `<h1>Heading 1</h1>`, `<h2>Heading 2</h2>`
- `<ul><li>Item</li></ul>` / `<ol><li>Item</li></ol>`
- `<ac:structured-macro ac:name="code"><ac:plain-text-body><![CDATA[...]]></ac:plain-text-body></ac:structured-macro>` for code blocks

Present the proposed content and get explicit approval before proceeding.

### Step 5: Execute the write operation

**Creating a page** — use the create template. Requires `spaceId` and optionally `parentId`:

```bash
hurl --variables-file ~/.config/hurl/confluence/default.env \
  <SKILLS_DIR>/confluence/templates/create-page.hurl \
  --variable space_id="<space_id>" \
  --variable parent_id="<parent_page_id>" \
  --variable title="<Page Title>" \
  --variable body="<storage format content>"
```

**Updating a page** — use the update template. The `version` must be current version + 1:

```bash
hurl --variables-file ~/.config/hurl/confluence/default.env \
  <SKILLS_DIR>/confluence/templates/update-page.hurl \
  --variable page_id="<page_id>" \
  --variable title="<Page Title>" \
  --variable version=<current_version_plus_one> \
  --variable version_message="<short description of change>" \
  --variable body="<storage format content>"
```

## Page URL

After creating or updating, the page is accessible at:
```
https://sygnum.atlassian.net/wiki/spaces/<SPACE_KEY>/pages/<page_id>
```

## When to Load Full References

**Simple operations** (read a page by ID, title search, fetch comments) — no reference needed.

**Load `references/api-commands.md` for:**
- Advanced CQL queries
- Pagination through large result sets
- Ancestor/children page traversal
- Label management
- Space ID lookup details
- Fetching a single comment by ID
- Troubleshooting 400/403/409 errors

## Address Comments Workflow

### Step A: Fetch all comments

There are two comment types. Fetch both:

**Footer comments** (page-level discussion):
```bash
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable page_id="<page_id>" - <<'EOF' | jq '.results[] | {id, author: .author.displayName, body: .body.storage.value, replies: ._links.replies}'
GET {{base_url_confluence}}/api/v2/pages/{{page_id}}/footer-comments
[QueryStringParams]
body-format: storage
limit: 50
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
```

**Inline comments** (tied to specific text):
```bash
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable page_id="<page_id>" - <<'EOF' | jq '.results[] | {id, author: .author.displayName, body: .body.storage.value, status}'
GET {{base_url_confluence}}/api/v2/pages/{{page_id}}/inline-comments
[QueryStringParams]
body-format: storage
limit: 50
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
```

For each comment that has replies, fetch the thread:
```bash
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable comment_id="<comment_id>" - <<'EOF' | jq '.results[] | {id, author: .author.displayName, body: .body.storage.value}'
GET {{base_url_confluence}}/api/v2/comments/{{comment_id}}/replies
[QueryStringParams]
body-format: storage
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
```

### Step B: Assess each comment

For each comment/thread, decide:
- **Content change needed** — the comment suggests an edit to the page body (proceed with the update workflow)
- **Reply needed** — the comment asks a question or raises a point that warrants acknowledgment
- **Both** — apply the change and reply confirming it was addressed
- **No action** — already resolved, off-topic, or acknowledged in the thread

Present the full assessment to the user before proposing any action.

### Step C: Draft and present proposed actions

Collect all proposed replies and/or page edits into a single batch. Show them to the user for approval:

```
📝 Proposed Actions (2)

━━━ Comment #abc123 (footer) ━━━
Author: Jane Doe
Comment: "The deployment steps are missing the rollback procedure."

→ Action: Reply + page update
→ Reply: "Good catch — added a Rollback section under Deployment Steps."
→ Page change: [show diff of added section]

━━━ Comment #def456 (inline) ━━━
Author: Bob Smith
Comment: "Should this be idempotent?"

→ Action: Reply only
→ Reply: "Yes, this operation is idempotent. Added a note to clarify."
```

Wait for user to approve/reject each proposed action.

### Step D: Execute approved actions

**Post an approved reply:**
```bash
hurl --variables-file ~/.config/hurl/confluence/default.env \
  <SKILLS_DIR>/confluence/templates/reply-to-comment.hurl \
  --variable comment_id="<comment_id>" \
  --variable reply_text="<p>Reply text here.</p>"
```

**Apply page changes:** follow Step 3-5 of the main workflow (fetch version, prepare content, run `update-page.hurl`).

## Example Usage

**User:** "Update the release page at https://sygnum.atlassian.net/wiki/spaces/ENG/pages/987654/v2.5+Release+Notes with these new items: ..."

Agent:
1. Confirms credentials are set
2. Extracts page ID `987654` from the URL
3. Fetches current content and version with `hurl` GET on `/pages/987654?body-format=storage`
4. Drafts updated storage-format body incorporating the new items
5. Shows the proposed changes for approval
6. Runs `hurl update-page.hurl` with `version=<current+1>`
7. Returns the page URL to confirm success

**User:** "Create a new page under the Architecture space for the new payments service we just defined"

Agent:
1. Confirms credentials
2. Searches for the Architecture space to get its `spaceId`
3. Optionally prompts for a parent page or uses the space root
4. Drafts the page content in storage format based on what the user described
5. Shows the draft for approval
6. Runs `hurl create-page.hurl` with the space ID and content

**User:** "Address the comments on https://sygnum.atlassian.net/wiki/spaces/ENG/pages/987654/v2.5+Release+Notes"

Agent:
1. Confirms credentials
2. Extracts page ID `987654` from the URL
3. Fetches footer comments and inline comments for that page
4. For each comment with replies, fetches the full thread
5. Assesses each comment: content change, reply, or no action needed
6. Presents the full batch of proposed replies and/or page edits for approval
7. Executes approved replies via `reply-to-comment.hurl` and page updates via `update-page.hurl`
