POST https://gitlab.com/api/v4/projects/{{project_id}}/merge_requests/{{mr_iid}}/discussions
Authorization: Bearer {{token}}
Content-Type: application/json
[Options]
cacert: {{cacert}}
{
  "body": "{{body}}",
  "position": {
    "base_sha": "{{base_sha}}",
    "head_sha": "{{head_sha}}",
    "start_sha": "{{start_sha}}",
    "position_type": "text",
    "old_path": "{{old_path}}",
    "old_line": {{old_line}}
  }
}