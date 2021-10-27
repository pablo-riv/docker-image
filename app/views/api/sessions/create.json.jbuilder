json.extract! @account, :id, :email, :authentication_token,  :created_at, :updated_at
json.first_name @account.person.first_name
json.last_name @account.person.last_name
json.company @account.entity.specific if @account.has_role? :owner
json.branch_office @account.entity.specific if @account.has_role? :employee
