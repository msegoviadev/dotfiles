POST {{tenant}}/oauth/token
[FormParams]
grant_type: client_credentials
client_id: {{client_id}}
client_secret: {{client_secret}}
audience: {{resource_server_identifier}}
[Options]
cacert: {{cacert}}
