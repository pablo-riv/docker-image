module Filterable
  extend ActiveSupport::Concern

  def self.included(klass)
    klass.instance_eval do
      scope :with_name, ->(name) { where(name: name) }
      scope :starts_with, ->(name) { where("name like ?", "#{name}%") }
    end
  end

  module ClassMethods
    def filter(filtering_params)
      results = self.where(nil)
      filtering_params.each do |key, value|
        results = results.public_send(key, value) if value.present?
      end
      results
    end

    def filterable_with_base(base = self.where(nil), filtering_params)
      results = base
      filtering_params.each do |key, value|
        results = results.try('send', key, value) if value.present?
      end
      results
    end

    def account_filter_packages(filtering_params, current_account)
      results = current_account.entity.specific.packages
      filtering_params.each do |key, value|
        next unless value.present?
        value = [:created, :in_preparation, :ready_to_dispatch, :dispatched] if value == :in_preparation
        value = ['created', 'in_preparation', 'ready_to_dispatch', 'dispatched'] if value == 'in_preparation'
        results = results.public_send(key, value)
      end
      results
    end
  end
end
