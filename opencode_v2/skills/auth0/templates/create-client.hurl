POST {{tenant}}/api/v2/clients
Authorization: Bearer {{access_token}}
Content-Type: application/json
[Options]
cacert: {{cacert}}
file, {{body_file}};
