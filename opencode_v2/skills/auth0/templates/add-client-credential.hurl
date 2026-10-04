POST {{tenant}}/api/v2/clients/{{client_id_target}}/credentials
Authorization: Bearer {{access_token}}
Content-Type: application/json
[Options]
cacert: {{cacert}}
file, {{body_file}};
