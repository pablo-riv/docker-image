json.extract! webhook, :id, :company_id
json.email account.email
json.authentication_token account.authentication_token
json.webhook webhook.configuration[webhook.service.name]['webhook']
