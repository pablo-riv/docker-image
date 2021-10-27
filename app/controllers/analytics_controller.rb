class AnalyticsController < ApplicationController
  include AnalyticsHelper
  before_action :prepare_data, only: [:index, :search_by_date]
  before_action :load_analytics, only: [:index, :search_by_date]

  def index; end

  def search_by_date
    render json: { all_packages: @data[:all_packages], packages: @data[:packages], orders: @data[:orders], notifications: @data[:notifications], supports: @data[:supports], charts: @data[:charts], dates: @data[:dates], period_length: @data[:period_length] }, status: :ok
  rescue => e
    puts e.message.to_s.red.swap
    render json: [], status: :bad_request
  end

  def set_dates(from, to)
    @from_date = from_date(from)
    @to_date = to_date(to)
    @period_length = set_period_length
    dates
  end

  private

  def load_analytics
    analytics = AnalyticsService.new(date: dates,
                                     company: current_account.current_company,
                                     account: current_account)
    @data = analytics.process
    params[:default_period] = 'week' if params[:default_period].present? && @data[:dates][:from_date].to_date == Date.current - 7.days
  rescue StandardError => e
    flash[:danger] = e.class != RuntimeError ? "#{e.message} \n #{e.backtrace.first(5).join("\n")}" : 'Error al cargar analíticas, favor contactar a soporte.'
  end

  def prepare_data
    if params[:dates].present?
      from_date = JSON.parse(params[:dates])['from'] || params[:dates]
      to_date = JSON.parse(params[:dates])['to']
    else
      from_date = (Date.current - 7.days).strftime('%d/%m/%Y')
      to_date = Date.current.strftime('%d/%m/%Y')
    end
    @from_date = from_date(from_date)
    @to_date = to_date(to_date)
    @period_length = set_period_length
  end

  def set_period_length
    period_length = set_period
    raise 'La fecha ingresada no es correcta' if period_length.negative?

    period_length + 1
  rescue RuntimeError => e
    render json: { state: :error, message: e.message }, status: :bad_request
  end

  def set_period
    period_length =
      if @to_date.present? && @from_date.present?
        (@to_date.to_date - @from_date.to_date).to_i
      elsif @from_date.present? && @to_date.blank?
        (Date.current - @from_date.to_date).to_i
      elsif @from_date.blank? && @to_date.blank?
        7
      end
    if period_length > 60
      @from_date = (@to_date.to_date - 7.days).strftime('%d/%m/%Y') 
      period_length = 7
    end
    period_length
  end

  def from_date(date)
    case date
    when 'week' then (Date.current - 7.days).strftime('%d/%m/%Y')
    when 'two_weeks' then (Date.current - 15.days).strftime('%d/%m/%Y')
    when 'month' then (Date.current - 30.days).strftime('%d/%m/%Y')
    when 'two_months' then (Date.current - 60.days).strftime('%d/%m/%Y')
    when date.blank? then (Date.current - 7.days).strftime('%d/%m/%Y')
    else
      date.to_date.is_a?(Date) ? date : (Date.current - 7.days).strftime('%d/%m/%Y')
    end
  rescue => e
    (Date.current - 7.days).strftime('%d/%m/%Y')
  end

  def to_date(date)
    date.to_date.is_a?(Date) ? date : Date.current.strftime('%d/%m/%Y')
  rescue => e
    Date.current.strftime('%d/%m/%Y')
  end

  def last_from_date
    (@from_date.to_date - (@period_length + 1).days).strftime('%d/%m/%Y')
  end

  def last_to_date
    (@from_date.to_date - 1.days).strftime('%d/%m/%Y')
  end

  def dates
    {
      from_date: @from_date,
      to_date: @to_date,
      period_length: @period_length,
      last_from_date: last_from_date,
      last_to_date: last_to_date
    }
  end
end
