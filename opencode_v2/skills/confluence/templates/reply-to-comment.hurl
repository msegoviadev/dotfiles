POST {{base_url_confluence}}/api/v2/comments/{{comment_id}}/replies
[Options]
user: {{email}}:{{token}}
cacert: {{cacert}}
Content-Type: application/json

{
  "body": {
    "representation": "storage",
    "value": "{{reply_text}}"
  }
}
