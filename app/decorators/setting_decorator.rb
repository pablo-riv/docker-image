class SettingDecorator < Draper::Decorator
  delegate_all

  def algorithm
    opit = object.configuration['opit']
    return {} unless opit.present?

    { kind: opit['algorithm'], days: opit['algorithm_days'] }
  end
end
