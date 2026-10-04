# Confluence API Command Reference

Base URL: `{{base_url_confluence}}/api/v2`

All commands read credentials from `~/.config/hurl/confluence/default.env`.

---

## Spaces

### List all spaces
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/spaces
[QueryStringParams]
limit: 50
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  $TMPDIR/hurl_req.hurl | jq '.results[] | {id, key, name, type}'
```

### Get space by key
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/spaces
[QueryStringParams]
keys: {{space_key}}
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable space_key="<SPACE_KEY>" \
  $TMPDIR/hurl_req.hurl | jq '.results[0] | {id, key, name}'
```

The `id` returned here is the `spaceId` required when creating pages.

---

## Pages

### Get page by ID (with body)
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/pages/{{page_id}}
[QueryStringParams]
body-format: storage
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable page_id="<page_id>" \
  $TMPDIR/hurl_req.hurl | jq '{id, title, version: .version.number, spaceId, body: .body.storage.value}'
```

### Search pages by title
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/pages
[QueryStringParams]
title: {{title}}
limit: 10
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable title="<title>" \
  $TMPDIR/hurl_req.hurl | jq '.results[] | {id, title, spaceId}'
```

### List pages in a space
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/pages
[QueryStringParams]
spaceId: {{space_id}}
limit: 50
sort: title
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable space_id="<space_id>" \
  $TMPDIR/hurl_req.hurl | jq '.results[] | {id, title}'
```

### List child pages of a page
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/pages/{{parent_id}}/children
[QueryStringParams]
limit: 50
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable parent_id="<parent_id>" \
  $TMPDIR/hurl_req.hurl | jq '.results[] | {id, title}'
```

### Get page ancestors (breadcrumb)
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/pages/{{page_id}}/ancestors
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable page_id="<page_id>" \
  $TMPDIR/hurl_req.hurl | jq '.results[] | {id, title}'
```

### Paginate results

Results are cursor-paginated. Check `_links.next` in the response:
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/pages
[QueryStringParams]
spaceId: {{space_id}}
limit: 50
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable space_id="<space_id>" \
  $TMPDIR/hurl_req.hurl | jq '{results: [.results[] | {id, title}], next: ._links.next}'
```

Pass the cursor from `_links.next` as the `cursor` query parameter for subsequent pages. Max `limit` is 250.

---

## CQL Search (legacy v1 endpoint, still useful for complex queries)

```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/rest/api/content/search
[QueryStringParams]
cql: {{cql}}
expand: body.storage
limit: 10
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable cql="<query>" \
  $TMPDIR/hurl_req.hurl | jq '.results[] | {id, title}'
```

### Common CQL patterns

```
# Pages in a space
type=page AND space=ENG

# By title (exact)
title="Release Notes v2.5" AND type=page

# By title (fuzzy)
title~"release notes" AND type=page

# Recently modified
type=page AND space=ENG AND lastModified>2025-01-01

# Created by current user
type=page AND creator=currentUser()

# Combine filters
type=page AND space=ENG AND title~"architecture" ORDER BY created DESC
```

---

## Comments

### List footer comments on a page
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/pages/{{page_id}}/footer-comments
[QueryStringParams]
body-format: storage
limit: 50
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable page_id="<page_id>" \
  $TMPDIR/hurl_req.hurl | jq '.results[] | {id, author: .author.displayName, body: .body.storage.value}'
```

### List inline comments on a page
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/pages/{{page_id}}/inline-comments
[QueryStringParams]
body-format: storage
limit: 50
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable page_id="<page_id>" \
  $TMPDIR/hurl_req.hurl | jq '.results[] | {id, author: .author.displayName, status, body: .body.storage.value}'
```

### Get a single comment (with replies)
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/comments/{{comment_id}}
[QueryStringParams]
body-format: storage
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable comment_id="<comment_id>" \
  $TMPDIR/hurl_req.hurl | jq '{id, author: .author.displayName, body: .body.storage.value}'
```

### List replies on a comment thread
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/comments/{{comment_id}}/replies
[QueryStringParams]
body-format: storage
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable comment_id="<comment_id>" \
  $TMPDIR/hurl_req.hurl | jq '.results[] | {id, author: .author.displayName, body: .body.storage.value}'
```

### Reply to a comment
```bash
hurl --variables-file ~/.config/hurl/confluence/default.env \
  <SKILLS_DIR>/confluence/templates/reply-to-comment.hurl \
  --variable comment_id="<comment_id>" \
  --variable reply_text="<p>Reply text here.</p>"
```

---

## Labels

### Get page labels
```bash
cat > $TMPDIR/hurl_req.hurl << 'EOF'
GET {{base_url_confluence}}/api/v2/pages/{{page_id}}/labels
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
EOF
hurl --variables-file ~/.config/hurl/confluence/default.env \
  --variable page_id="<page_id>" \
  $TMPDIR/hurl_req.hurl | jq '.results[] | {id, name}'
```

### Add a label to a page
```bash
hurl --variables-file ~/.config/hurl/confluence/default.env \
  <SKILLS_DIR>/confluence/templates/add-label.hurl \
  --variable page_id="<page_id>" \
  --variable label="<label>"
```

---

## Storage Format Reference

Confluence storage format is an XML dialect. Common elements:

```xml
<!-- Paragraph -->
<p>Text here</p>

<!-- Headings -->
<h1>Heading 1</h1>
<h2>Heading 2</h2>
<h3>Heading 3</h3>

<!-- Unordered list -->
<ul>
  <li>Item one</li>
  <li>Item two</li>
</ul>

<!-- Ordered list -->
<ol>
  <li>First step</li>
  <li>Second step</li>
</ol>

<!-- Code block -->
<ac:structured-macro ac:name="code">
  <ac:parameter ac:name="language">javascript</ac:parameter>
  <ac:plain-text-body><![CDATA[const x = 1;]]></ac:plain-text-body>
</ac:structured-macro>

<!-- Info panel -->
<ac:structured-macro ac:name="info">
  <ac:rich-text-body><p>Info message</p></ac:rich-text-body>
</ac:structured-macro>

<!-- Warning panel -->
<ac:structured-macro ac:name="warning">
  <ac:rich-text-body><p>Warning message</p></ac:rich-text-body>
</ac:structured-macro>

<!-- Link to another Confluence page -->
<ac:link><ri:page ri:content-title="Target Page Title"/></ac:link>

<!-- Table -->
<table>
  <tbody>
    <tr><th>Column A</th><th>Column B</th></tr>
    <tr><td>Value 1</td><td>Value 2</td></tr>
  </tbody>
</table>
```

---

## Error Reference

| Code | Meaning | Action |
|------|---------|--------|
| 400  | Bad request (invalid body format, missing required field) | Check the request body structure and storage format XML |
| 401  | Authentication failed | Verify `email` and `token` in `~/.config/hurl/confluence/default.env` are correct |
| 403  | Permission denied | User lacks view/edit rights on the page or space |
| 404  | Page or space not found | Verify the page ID or space ID is correct |
| 409  | Version conflict | Re-fetch the page to get the current version number and retry |
| 429  | Rate limit exceeded | Wait for the `Retry-After` header duration (quota resets hourly) |
