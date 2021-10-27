class MailNotification < ApplicationRecord
  has_paper_trail ignore: [:updated_at], meta: { editor_type: 'account' }
  # RELATIONS
  belongs_to :company

  # CALLBACKS
  after_create :default_texts
  after_create :default_colors
  after_create :default_tags

  enum state: { in_preparation: 0, in_route: 1, delivered: 2, failed: 3, by_retired: 4 }
  store :text, accessors: %i[subject title_text one tracking_text two three footer]#, coder: JSON
  store :color, accessors: %i[title_color tracking_text_color title_font_color tracking_button]#, coder: JSON
  store :tags, accessors: %i[buyer_name tracking_number package_reference package_courier]#, coder: JSON

  def self.by(state)
    eval(state)
  end

  def default_subject
    case state
    when 'in_preparation' then I18n.t('activerecord.attributes.mail_notification.text.subject.state.in_preparation')
    when 'in_route' then I18n.t('activerecord.attributes.mail_notification.text.subject.state.in_route')
    when 'delivered' then I18n.t('activerecord.attributes.mail_notification.text.subject.state.delivered')
    when 'failed' then I18n.t('activerecord.attributes.mail_notification.text.subject.state.failed')
    when 'by_retired' then I18n.t('activerecord.attributes.mail_notification.text.subject.state.by_retired')
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
    update!(title_text: state_name,
            subject: default_subject,
            one: state_text('one'),
            two: state_text('two'),
            three: state_text('three'),
            footer: "#{company.name} - #{company.website}",
            tracking_text: '{package_courier} - {tracking_number}')
  rescue => e
    Slack::Ti.new({}, {}).alert('', "ERROR AL CREAR TEMPLATE CORREOS CLIENTE #{company.name} ERROR: #{e.message}\nBUGTRACE: #{e.backtrace[0]}")
  end

  def state_text(type)
    case state
    when 'in_preparation' then I18n.t("activerecord.attributes.mail_notification.text.#{type}.state.in_preparation")
    when 'in_route' then I18n.t("activerecord.attributes.mail_notification.text.#{type}.state.in_route")
    when 'by_retired' then I18n.t("activerecord.attributes.mail_notification.text.#{type}.state.by_retired")
    when 'delivered' then I18n.t("activerecord.attributes.mail_notification.text.#{type}.state.delivered")
    when 'failed' then I18n.t("activerecord.attributes.mail_notification.text.#{type}.state.failed")
    end
  end

  def default_colors
    color =
      case state
      when 'in_preparation' then '#58b5f4'
      when 'in_route' then '#f4cf58'
      when 'delivered' then '#04c778'
      when 'failed' then '#dd7272'
      when 'by_retired' then '#00c2de'
      end
    update!(title_color: color,
            tracking_button: color,
            tracking_text_color: '#ffffff',
            title_font_color: '#ffffff')
  end

  def default_tags
    update(buyer_name: I18n.t('activerecord.attributes.mail_notification.tags.buyer_name'),
           tracking_number: I18n.t('activerecord.attributes.mail_notification.tags.tracking_number'),
           package_reference: I18n.t('activerecord.attributes.mail_notification.tags.package_reference'),
           package_courier: I18n.t('activerecord.attributes.mail_notification.tags.package_courier'))
  end

  def send_test(current_account, emails)
    TrackingMailer.test_state_buyer(current_account, state, emails).deliver
  end

  def inject_params
    Notification.find_by(name: self.state).text_notification.each do |notification|
      self[:text][notification.paragraph_notification.name.to_s] =
        { content: define_content(notification, notification.paragraph_notification.name), customizable: notification.customizable }
    end
    self
  end

  def define_content(notification, name)
    notification.customizable ? self.text[name] : notification.text
  end
end
