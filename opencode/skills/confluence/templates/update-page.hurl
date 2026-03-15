PUT {{base_url_confluence}}/api/v2/pages/{{page_id}}
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
Content-Type: application/json

{
  "id": "{{page_id}}",
  "title": "{{title}}",
  "version": {
    "number": {{version}},
    "message": "{{version_message}}"
  },
  "body": {
    "representation": "storage",
    "value": "{{body}}"
  }
}
