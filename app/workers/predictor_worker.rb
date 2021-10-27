class PredictorWorker < MixpanelTrackWorker
  include Sneakers::Worker
  from_queue 'core.update_delivery_dates', env: nil, ack: true

  def work(data)
    puts "data: #{data}"
    prediction = JSON.parse(data)
    operation_date = Package.find_by(id: prediction['package_id'])&.operation_date
    delivery_date = prediction['delivery_date'].to_i.business_days.after(operation_date)
    prediction = Prediction.create_with(delivery_date: delivery_date)
                           .find_or_create_by(package_id: prediction['package_id'])
    track_action(source: 'set_prediction',
                 data: prediction,
                 account: prediction.package&.company&.current_account,
                 status: 'success')
    ack!
  rescue StandardError => e
    Sneakers.logger.info e.message.red
    ack!
  end
end
