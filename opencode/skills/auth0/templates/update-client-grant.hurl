PATCH {{tenant}}/api/v2/client-grants/{{grant_id}}
Authorization: Bearer {{access_token}}
Content-Type: application/json
[Options]
cacert: {{cacert}}
file, {{body_file}};
