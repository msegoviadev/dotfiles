POST {{base_url_confluence}}/api/v2/pages
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
Content-Type: application/json

{
  "spaceId": "{{space_id}}",
  "parentId": "{{parent_id}}",
  "title": "{{title}}",
  "body": {
    "representation": "storage",
    "value": "{{body}}"
  }
}
