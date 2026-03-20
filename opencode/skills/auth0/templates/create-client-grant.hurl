POST {{tenant}}/api/v2/client-grants
Authorization: Bearer {{access_token}}
Content-Type: application/json
[Options]
cacert: {{cacert}}
file, {{body_file}};
