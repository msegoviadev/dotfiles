POST {{tenant}}/oauth/token
[FormParams]
grant_type: client_credentials
client_assertion_type: urn:ietf:params:oauth:client-assertion-type:jwt-bearer
client_assertion: {{client_assertion}}
audience: {{resource_server_identifier}}
[Options]
cacert: {{cacert}}
