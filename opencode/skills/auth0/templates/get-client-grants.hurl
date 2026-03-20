GET {{tenant}}/api/v2/client-grants?per_page=50&page=0&include_totals=true&client_id={{client_id_target}}
Authorization: Bearer {{access_token}}
Content-Type: application/json
[Options]
cacert: {{cacert}}
