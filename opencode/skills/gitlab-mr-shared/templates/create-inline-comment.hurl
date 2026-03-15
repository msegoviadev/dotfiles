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
    "new_path": "{{new_path}}",
    "new_line": {{new_line}}
  }
}