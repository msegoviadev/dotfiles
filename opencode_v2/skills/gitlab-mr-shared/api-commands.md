# GitLab API Commands Reference

## Tool Division

| Operation | Tool | Reason |
|-----------|------|--------|
| View MR, get diff | `glab` | Native commands |
| Get discussions | `glab api` | Flat response |
| Reply to discussion | `glab api` | Flat fields |
| Resolve discussion | `glab api` | Flat fields |
| **Post inline comment** | **hurl** | Requires nested JSON (glab api doesn't support) |

## Authentication

```bash
# Check authentication status
glab auth status

# Get token for hurl (shows token in output)
glab auth status -t

# Extract token for scripting
TOKEN=$(glab auth status -t 2>&1 | grep "Token found:" | awk '{print $NF}')

# Login interactively
glab auth login
```

## Project ID

GitLab API accepts:
- Numeric project ID: `12345`
- URL-encoded path: `user%2Frepo`

```bash
# Extract from MR URL
# https://gitlab.com/user/repo/-/merge_requests/123
# project: user%2Frepo (URL-encoded)
# MR IID: 123

# Get numeric project ID from path
glab api projects/user%2Frepo | jq -r '.id'
```

## MR Operations

### View MR Details
```bash
# Human-readable summary
glab mr view <iid>

# JSON output via API (use jq to filter)
glab api projects/:id/merge_requests/:iid | jq '{iid, title, author: .author.username, state}'

# Get all fields
glab api projects/:id/merge_requests/:iid
```

### Get MR Diff
```bash
# Standard diff format
glab mr diff <iid>
```

### Get MR Changes (JSON)
```bash
# Includes diff_refs and changes array
glab api projects/:id/merge_requests/:iid/changes
```

### Get Commit SHAs
```bash
# Required for inline comments
glab api projects/:id/merge_requests/:iid | jq '{baseSha: .diff_refs.base_sha, headSha: .diff_refs.head_sha, startSha: .diff_refs.start_sha}'
```

## Discussions

### Get All Discussions
```bash
glab api projects/:id/merge_requests/:iid/discussions
```

Response structure:
```json
[
  {
    "id": "abc123",
    "individual_note": false,
    "notes": [
      {
        "id": 1,
        "type": "DiscussionNote",
        "body": "Comment text",
        "author": { "username": "reviewer" },
        "position": {
          "new_path": "src/file.ts",
          "new_line": 45
        },
        "resolvable": true,
        "resolved": false
      }
    ]
  }
]
```

### Get Single Discussion
```bash
glab api "projects/:id/merge_requests/:iid/discussions/:discussion_id"
```

### Create Inline Comment (New File / Additions)

**IMPORTANT:** glab api does NOT support nested JSON bodies for inline comments. Use hurl instead.

```bash
hurl create-inline-comment.hurl \
  --variables-file ~/.config/hurl/gitlab/default.env \
  --variable token="$(glab auth status -t 2>&1 | grep 'Token found:' | awk '{print $NF}')" \
  --variable project_id=user%2Frepo \
  --variable mr_iid=123 \
  --variable body="Your comment here" \
  --variable base_sha=<base_sha> \
  --variable head_sha=<head_sha> \
  --variable start_sha=<start_sha> \
  --variable new_path=path/to/file.ts \
  --variable new_line=45
```

### Create Inline Comment (Old File / Deletions)

Use `create-inline-comment-old.hurl` with `old_path` and `old_line` instead:

```bash
hurl create-inline-comment-old.hurl \
  --variables-file ~/.config/hurl/gitlab/default.env \
  --variable token="$(glab auth status -t 2>&1 | grep 'Token found:' | awk '{print $NF}')" \
  --variable project_id=user%2Frepo \
  --variable mr_iid=123 \
  --variable body="Your comment here" \
  --variable base_sha=<base_sha> \
  --variable head_sha=<head_sha> \
  --variable start_sha=<start_sha> \
  --variable old_path=path/to/old-file.ts \
  --variable old_line=20
```

### Create General Comment (No Position)
```bash
glab api -X POST projects/:id/merge_requests/:iid/discussions \
  -f "body=Your comment here"
```

### Reply to Discussion
```bash
glab api -X POST "projects/:id/merge_requests/:iid/discussions/:discussion_id/notes" \
  -f "body=Your reply here"
```

### Resolve Discussion
```bash
glab api -X PUT "projects/:id/merge_requests/:iid/discussions/:discussion_id" \
  -f "resolved=true"
```

### Unresolve Discussion
```bash
glab api -X PUT "projects/:id/merge_requests/:iid/discussions/:discussion_id" \
  -f "resolved=false"
```

## hurl Templates

Templates are in `templates/` (relative to this file's directory):

- `create-inline-comment.hurl` - For additions/new files (uses `new_path`/`new_line`)
- `create-inline-comment-old.hurl` - For deletions/old files (uses `old_path`/`old_line`)

Resolve the path based on where `gitlab-mr-shared/` is installed.

Usage:
```bash
hurl <SKILLS_DIR>/gitlab-mr-shared/templates/create-inline-comment.hurl \
  --variables-file ~/.config/hurl/gitlab/default.env \
  --variable token="$(glab auth status -t 2>&1 | grep 'Token found:' | awk '{print $NF}')" \
  --variable project_id=user%2Frepo \
  --variable mr_iid=123 \
  --variable body="Comment text" \
  --variable base_sha=<base_sha> \
  --variable head_sha=<head_sha> \
  --variable start_sha=<start_sha> \
  --variable new_path=src/file.ts \
  --variable new_line=45
```

Where `<SKILLS_DIR>` is the root skills directory for your tool.

## Extracting Project Path from MR URL

```bash
# Input: https://gitlab.com/msegoviadev1/msegoviadev-project/-/merge_requests/1
# Output project path: msegoviadev1%2Fmsegoviadev-project
# Output MR IID: 1

# Parser logic:
# 1. Extract domain: gitlab.com
# 2. Extract path after domain and before /-/: msegoviadev1/msegoviadev-project
# 3. URL-encode: replace / with %2F -> msegoviadev1%2Fmsegoviadev-project
# 4. Extract IID: number after merge_requests/
```

## Filtering JSON Output

Use `jq` to filter JSON responses:

```bash
# Get discussion IDs and bodies
glab api projects/:id/merge_requests/:iid/discussions | jq '[.[] | {id: .id, notes: [.notes[].body]}]'

# Get only unresolved discussions
glab api projects/:id/merge_requests/:iid/discussions | jq '[.[] | select(any(.notes[]; .resolvable == true and .resolved == false))]'

# Get inline comment positions
glab api projects/:id/merge_requests/:iid/discussions | jq '[.[] | .notes[] | select(.position != null) | {path: .position.new_path, line: .position.new_line, body: .body}]'

# Get specific fields from MR
glab api projects/:id/merge_requests/:iid | jq '{iid, title, author: .author.username, state}'
```

## Notes

- **Inline comments require hurl** - glab api silently ignores nested position fields
- Use `-f` for form fields in POST/PUT requests (works for flat fields only)
- Use `jq` to filter JSON responses (pipe glab api output to jq)
- Discussion IDs are UUIDs
- Position comments require all three SHAs: base_sha, head_sha, start_sha
- jq is a separate tool: `brew install jq`
- hurl is a separate tool: `brew install hurl`