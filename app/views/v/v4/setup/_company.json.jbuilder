json.extract! company, :id, :name, :run, :website, :email_domain, :commercial_business, :phone, :logo, :about,
                       :email_contact, :contact_name, :is_active, :email_notification, :email_commercial,
                       :term_of_service, :know_size_restriction, :know_base_charge, :business_name, :platform_version,
                       :business_turn, :bill_email, :bill_phone, :bill_address, :capture, :created_at, :updated_at

json.logo company.logo.url(:small)
json.preferences do
  json.email do
    json.color do
      json.background_header company.preferences['email']['color']['background_header']
      json.background_footer company.preferences['email']['color']['background_footer']
      json.font_color_footer company.preferences['email']['color']['font_color_footer']
    end
  end
end
