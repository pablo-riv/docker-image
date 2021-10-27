class MixpanelTrackWorker
  def track_action(source: '', data: {}, result: {}, status: 'success', account: {})
    return unless source.present?

    MixpanelService.tracker(source: source,
                            data: data,
                            result: result,
                            status: status,
                            account: account)
  end
end
