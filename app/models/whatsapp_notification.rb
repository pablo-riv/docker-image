class WhatsappNotification < ApplicationRecord
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }
  # RELATIONS
  belongs_to :company

  # CALLBACKS
  after_create :default_texts
  after_create :default_tags

  enum state: { in_preparation: 0, in_route: 1, delivered: 2, failed: 3, by_retired: 4 }, _suffix: true
  store :text, accessors: %i[subject one]
  store :tags, accessors: %i[buyer_name tracking_number package_reference package_courier company_name]

  def self.by(state)
    eval(state)
  end

  def default_subject
    case state
    when 'in_preparation' then I18n.t('activerecord.attributes.whatsapp_notification.text.subject.state.in_preparation')
    when 'in_route' then I18n.t('activerecord.attributes.whatsapp_notification.text.subject.state.in_route')
    when 'delivered' then I18n.t('activerecord.attributes.whatsapp_notification.text.subject.state.delivered')
    when 'failed' then I18n.t('activerecord.attributes.whatsapp_notification.text.subject.state.failed')
    when 'by_retired' then I18n.t('activerecord.attributes.whatsapp_notification.text.subject.state.by_retired')
    end
  end

  def state_name
    case state
    when 'in_preparation' then I18n.t('activerecord.attributes.package.statuses.in_preparation')
    when 'in_route' then I18n.t('activerecord.attributes.package.statuses.in_route')
    when 'delivered' then I18n.t('activerecord.attributes.package.statuses.delivered')
    when 'failed' then I18n.t('activerecord.attributes.package.statuses.failed')
    when 'by_retired' then I18n.t('activerecord.attributes.package.statuses.by_retired')
    end
  end

  def default_texts
    update!(one: state_text('one'), subject: default_subject)
  end

  def state_text(type)
    case state
    when 'in_preparation' then I18n.t("activerecord.attributes.whatsapp_notification.text.#{type}.state.in_preparation")
    when 'in_route' then I18n.t("activerecord.attributes.whatsapp_notification.text.#{type}.state.in_route")
    when 'by_retired' then I18n.t("activerecord.attributes.whatsapp_notification.text.#{type}.state.by_retired")
    when 'delivered' then I18n.t("activerecord.attributes.whatsapp_notification.text.#{type}.state.delivered")
    when 'failed' then I18n.t("activerecord.attributes.whatsapp_notification.text.#{type}.state.failed")
    end
  end

  def default_tags
    update(buyer_name: I18n.t('activerecord.attributes.whatsapp_notification.tags.buyer_name'),
           tracking_number: I18n.t('activerecord.attributes.whatsapp_notification.tags.tracking_number'),
           package_reference: I18n.t('activerecord.attributes.whatsapp_notification.tags.package_reference'),
           package_courier: I18n.t('activerecord.attributes.whatsapp_notification.tags.package_courier'),
           company_name: I18n.t('activerecord.attributes.whatsapp_notification.tags.company_name'))
  end

  def send_test(current_account, number)
    client = MercuryWhatsapp.new(phone: number, body: convert_tag(tags, one))
    client.send
  end

  def convert_tag(tags, text, attr = {})
    return '' unless text.present?

    tags.keys.each do |tag|
      text =
        case tag
        when 'buyer_name'
          text.gsub('{nombre_comprador}', attr.class == Package ? attr.full_name.try(:titleize) : company.current_account.full_name.try(:titleize))
        when 'tracking_number'
          text.gsub('{enlace_seguimiento}', attr.class == Package ? "https://seguimiento.shipit.cl/statuses?number=#{attr.tracking_number}" : "https://seguimiento.shipit.cl/statuses?number=TEST")
        when 'company_name'
          text.gsub('{mi_empresa}', attr.class == Package ? attr.branch_office_company_name.try(:upcase) : company.name.try(:upcase))
        when 'package_reference'
          text.gsub('{package_reference}', attr.class == Package ? attr.reference.try(:upcase) : 'TEST')
        when 'package_courier'
          text.gsub('{package_courier}', attr.class == Package ? attr.courier_for_client.try(:titleize) : ['Chilexpress', 'Starken', 'CorreosChile', 'DHL', 'Chileparcels', 'MotoPartner', 'Bluexpress', 'Shippify'].sample)
        else
          ''
        end
    end

    text
  end
end
