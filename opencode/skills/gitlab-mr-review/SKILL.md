---
name: gitlab-mr-review
description: Review GitLab merge requests by analyzing code changes and posting inline comments. Always shows comments for approval before posting and checks for duplicates. Use when reviewing someone else's MR.
metadata:
  tags: gitlab, mr, review, code-review, inline-comments
---

## When to Use

Use this skill when:
- User asks to review a merge request
- User provides an MR URL or IID
- Goal is to analyze code and provide feedback

## Prerequisites

- glab CLI installed and authenticated: `glab auth login`
- hurl installed: `brew install hurl`
- jq installed: `brew install jq`
- User has comment access to the project

## Workflow

### Step 1: Receive MR Reference

User provides MR via:
- Full URL: `https://gitlab.com/user/repo/-/merge_requests/123`
- MR IID (if in project context): `123`

Extract:
- Project ID: URL-encoded path (e.g., `user%2Frepo`)
- MR IID: The merge request number

### Step 2: Fetch MR Details and Diff

**Get the token first (needed for inline comments):**
```bash
TOKEN=$(glab auth status -t 2>&1 | grep "Token found:" | awk '{print $NF}')
```

Get MR metadata and commit SHAs (required for inline comments):

```bash
# Human-readable summary
glab mr view <iid>

# Get diffRefs (needed for inline comments)
glab api projects/:id/merge_requests/:iid | jq '{iid, title, author: .author.username, state, diffRefs: .diff_refs}'
```

Get the diff:

```bash
glab mr diff <iid>
```

### Step 3: Fetch Existing Discussions

CRITICAL: Always fetch existing discussions first to avoid duplicates.

```bash
glab api projects/:id/merge_requests/:iid/discussions
```

Parse discussions to identify:
- Existing inline comments (check `position` field for file/line)
- Comment content already posted
- Discussion IDs (for checking duplicates)

### Step 4: Analyze Code Changes

Review the diff for:
- Logic errors or bugs
- Security concerns
- Performance issues
- Code style and readability
- Missing tests or documentation
- Edge cases

### Step 5: Generate Inline Comments

For each finding, prepare:
- File path (`new_path` for additions, `old_path` for deletions)
- Line number (`new_line` for additions, `old_line` for deletions)
- Comment body
- Commit SHAs from diffRefs: `base_sha`, `head_sha`, `start_sha`

Check against existing discussions to avoid duplicates.

DO NOT propose:
- Duplicate comments (same file/line with similar content)
- Test comments
- Connectivity check comments

### Step 6: Present for Approval

Show all proposed comments in batch format:

```
📝 Proposed Inline Comments (3)

━━━ Comment 1 ━━━
📍 File: src/auth.ts
📍 Line: 45

> Consider using a constant for this magic number instead of hardcoding 30.

[Approve] [Reject] [Edit]

━━━ Comment 2 ━━━
📍 File: src/api.ts
📍 Line: 102

> This error case isn't handled. What happens if the API returns null?

[Approve] [Reject] [Edit]
```

Wait for user to approve/reject each comment.

### Step 7: Post Approved Comments

For approved comments, use **hurl** with the inline comment template. glab api does not support nested JSON bodies correctly for inline comments.

**Templates are located in:** `../gitlab-mr-shared/templates/` (relative to this skill's directory)

Resolve the template path based on where `gitlab-mr-review/SKILL.md` is installed.

**For new lines (additions):**

```bash
hurl <SKILLS_DIR>/gitlab-mr-shared/templates/create-inline-comment.hurl \
  --variable token=$TOKEN \
  --variable project_id=user%2Frepo \
  --variable mr_iid=123 \
  --variable body="Comment text" \
  --variable base_sha=<base_sha> \
  --variable head_sha=<head_sha> \
  --variable start_sha=<start_sha> \
  --variable new_path=src/file.ts \
  --variable new_line=45
```

**For old lines (deletions/modifications):**

Use `create-inline-comment-old.hurl` with `old_path` and `old_line` instead:

```bash
hurl <SKILLS_DIR>/gitlab-mr-shared/templates/create-inline-comment-old.hurl \
  --variable token=$TOKEN \
  --variable project_id=user%2Frepo \
  --variable mr_iid=123 \
  --variable body="Comment text" \
  --variable base_sha=<base_sha> \
  --variable head_sha=<head_sha> \
  --variable start_sha=<start_sha> \
  --variable old_path=src/file.ts \
  --variable old_line=20
```

Where `<SKILLS_DIR>` is the root skills directory (e.g., `~/.config/opencode/skills/` for opencode, or equivalent for other tools).

## NEVER Auto-Post

- Always show proposed content first
- Get explicit user approval per comment
- Check for duplicates before proposing
- Never post test or connectivity comments

## Command Reference

### Get MR Info

```bash
# View MR summary
glab mr view <iid>

# Get MR details with diffRefs
glab api projects/:id/merge_requests/:iid | jq '{iid, title, diffRefs: .diff_refs}'

# Get diff
glab mr diff <iid>
```

### Get Discussions

```bash
# All discussions
glab api projects/:id/merge_requests/:iid/discussions

# Parse for inline comments only
glab api projects/:id/merge_requests/:iid/discussions | jq '[.[] | .notes[] | select(.position != null) | {path: .position.new_path, line: .position.new_line, body: .body}]'
```

### Project ID Extraction

From MR URL `https://gitlab.com/user/repo/-/merge_requests/123`:
- Project path: `user/repo` → URL-encode: `user%2Frepo`
- MR IID: `123`

## hurl Templates

Templates are in `../gitlab-mr-shared/templates/` (relative to this skill's directory):
- `create-inline-comment.hurl` - Post inline comment on new file/line
- `create-inline-comment-old.hurl` - Post inline comment on old file/line (deletions)

Resolve the path based on where the skills are installed.

## Advanced Reference

For additional commands, filtering options, and error handling, see:
`../gitlab-mr-shared/api-commands.md`

## Example Usage

User: "Review this MR: https://gitlab.com/user/repo/-/merge_requests/42"

Agent:
1. Extracts project path (`user%2Frepo`) and MR IID (`42`)
2. Gets token: `TOKEN=$(glab auth status -t 2>&1 | grep "Token found:" | awk '{print $NF}')`
3. Runs `glab api projects/user%2Frepo/merge_requests/42 | jq '.diff_refs'`
4. Runs `glab mr diff 42`
5. Runs `glab api projects/user%2Frepo/merge_requests/42/discussions` to check existing
6. Analyzes code, generates comments (filtered for duplicates)
7. Presents comments for approval
8. Gets approval for each
9. Resolves template path relative to skill directory, posts via `hurl`