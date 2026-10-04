GET {{tenant}}/api/v2/resource-servers?page=0&per_page=100&include_totals=true&include_fields=true&fields=id,name,identifier,scopes
Authorization: Bearer {{access_token}}
Accept: application/json
[Options]
cacert: {{cacert}}
