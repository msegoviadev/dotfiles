POST {{base_url_confluence}}/api/v2/pages/{{page_id}}/labels
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
Content-Type: application/json

[
  {"name": "{{label}}"}
]
