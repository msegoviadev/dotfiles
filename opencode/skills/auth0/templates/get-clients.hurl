GET {{tenant}}/api/v2/clients?per_page=50&page=0&include_totals=true&app_type=non_interactive&include_fields=true&fields=client_id,name,app_type,client_authentication_methods
Authorization: Bearer {{access_token}}
Content-Type: application/json
[Options]
cacert: {{cacert}}
