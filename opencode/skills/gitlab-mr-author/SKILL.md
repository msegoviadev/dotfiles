---
name: gitlab-mr-author
description: Respond to feedback on your own merge request. Fetches discussions, proposes replies and code changes, and asks for approval before posting anything. Use when addressing review comments on your MR.
metadata:
  tags: gitlab, mr, author, feedback, discussions
---

## When to Use

Use this skill when:
- User has an MR with review comments
- User provides their MR URL or IID
- Goal is to address feedback and reply to comments

## Prerequisites

- glab CLI installed and authenticated: `glab auth login`
- hurl installed: `brew install hurl` (for potential inline comments, though author usually only replies)
- jq installed: `brew install jq`
- User has push access to the branch

## Workflow

### Step 1: Receive MR Reference

User provides MR via:
- Full URL: `https://gitlab.com/user/repo/-/merge_requests/123`
- MR IID (if in project context): `123`

Extract:
- Project ID: URL-encoded path (e.g., `user%2Frepo`)
- MR IID: The merge request number

### Step 2: Fetch All Discussions

```bash
glab api projects/:id/merge_requests/:iid/discussions
```

Parse to identify:
- Unresolved discussions (check `resolved` field)
- Actionable comments (need reply or code change)
- Discussion IDs for replies
- Position info for inline comments (file, line)

### Step 3: Parse and Categorize Feedback

Filter discussions to show only unresolved, actionable ones:

```bash
# Get unresolved discussions
glab api projects/:id/merge_requests/:iid/discussions | jq '[.[] | select(any(.notes[]; .resolvable == true and .resolved == false))]'
```

For each discussion:
- Is it resolved? (skip resolved)
- Is it actionable? (requires code change, reply, or clarification)
- Is it a question, suggestion, or blocker?

### Step 4: Process Each Comment

For each unresolved, actionable comment:

**a) Explain the feedback:**
```
💬 Discussion: "Error handling"
👤 @reviewer commented on src/api.ts:45:

> This error case isn't handled properly. What happens if the API returns 500?

Issue: Missing error handling for HTTP 500 responses.
```

**b) Propose a solution:**
- Code change (if applicable) - show the file and lines
- Reply text to address the feedback

**c) Present for approval:**
```
💬 Proposed Response

Thread: "Error handling" (discussion_id: abc123)
Original comment by @reviewer:
> This error case isn't handled properly.

Proposed reply:
> Good catch! I've added proper error handling for 500 responses.

Proposed code change:
📁 src/api.ts:45-50
- Add try-catch for HTTP errors

[Approve] [Reject] [Edit]
```

### Step 5: Get Batch Approval

Present ALL proposed actions at once:
- Replies to post
- Code changes to make

User reviews and approves/rejects each item.

### Step 6: Execute Approved Actions

**For approved code changes:**
1. Make changes locally
2. Show diff for confirmation
3. Commit only after user confirms

**For approved replies:**

```bash
glab api -X POST "projects/:id/merge_requests/:iid/discussions/:discussion_id/notes" \
  -f "body=Reply text here"
```

### Step 7: Ask About Resolution

For each addressed discussion where you've made the changes/replied:

```
✓ Discussion "Error handling" addressed with reply and code change.

Resolve this discussion? [Yes] [No]
```

Only resolve with explicit user approval:

```bash
glab api -X PUT "projects/:id/merge_requests/:iid/discussions/:discussion_id" \
  -f "resolved=true"
```

## NEVER Auto-Post

- Always show proposed replies first
- Check for duplicate replies (don't reply twice to same issue)
- Get explicit approval per action
- Don't auto-resolve discussions

## Command Reference

### Get MR Discussions

```bash
# All discussions
glab api projects/:id/merge_requests/:iid/discussions

# Unresolved discussions only
glab api projects/:id/merge_requests/:iid/discussions | jq '[.[] | select(any(.notes[]; .resolvable == true and .resolved == false))]'

# Get discussion ID and body
glab api projects/:id/merge_requests/:iid/discussions | jq '[.[] | {id: .id, notes: [.notes[] | {author: .author.username, body: .body, position: .position}]}]'
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

### Project ID Extraction

From MR URL `https://gitlab.com/user/repo/-/merge_requests/123`:
- Project path: `user/repo` → URL-encode: `user%2Frepo`
- MR IID: `123`

## Advanced Reference

For additional commands, filtering options, and error handling, see:
`../gitlab-mr-shared/api-commands.md`

## Example Usage

User: "Check my MR for feedback: https://gitlab.com/user/repo/-/merge_requests/42"

Agent:
1. Extracts project path (`user%2Frepo`) and MR IID (`42`)
2. Runs `glab api projects/user%2Frepo/merge_requests/42/discussions`
3. Parses unresolved comments
4. For each: explains issue, proposes reply/change
5. Presents all proposals for approval
6. Gets approval for each
7. Makes approved code changes
8. Posts approved replies
9. Asks about resolving discussions