class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  TIMEZONE_OFFSET = Rails.configuration.timezone_offset
  def self.today
    where(created_at: current_time.beginning_of_day..current_time.end_of_day)
  end

  def self.week
    where(created_at: current_time.beginning_of_week..current_time.end_of_week)
  end

  def self.month
    where(created_at: current_time.beginning_of_month..current_time.end_of_month)
  end

  def self.last_months(quantity = 2)
    where(created_at: ((current_time.beginning_of_month - quantity.months)..current_time.end_of_month))
  end

  def self.current_date
    Date.current
  end

  def self.current_time(time)
    time.change(offset: TIMEZONE_OFFSET)
  end

  def self.current_date_time
    DateTime.current.change(offset: TIMEZONE_OFFSET)
  end

  def send_to_elastic
    Publisher.publish('callbacks', { type: self.class.name, id: self.id })
  end

  def manual_update!(attributes = {})
    new_changes = ["---\n"]
    errors = []
    attributes.each do |key, new_value|
      previous_value = try(key)
      new_changes << "#{key}:\n- #{previous_value}\n- #{new_value}\n"
    end
    errors << "Error al actualizar Package con atributos #{attributes}" unless update_columns(attributes)
    raise errors.join("\n") if errors.size.positive?

    generate_version!('update', new_changes.join)
  rescue StandardError => e
    Rails.logger.error { "ERROR: #{e.message}\nBACKTRACE: #{e.backtrace[0]}".red.swap }
  end

  def generate_version!(event, changes)
    data = {
      event: event,
      object: paper_trail.recordable_object,
      whodunnit: PaperTrail.whodunnit,
      item: self,
      object_changes: changes
    }
    PaperTrail::Version.create!(papertrail_metadata(data))
  end

  def papertrail_metadata(hash = {})
    paper_trail.merge_metadata_into(hash)
  end
end
