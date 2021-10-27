# This is the Main class, acting like model for a mongodb document created through different integrations
class DownloadService
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  def update_last_download(downloading)
    ActionCable.server.broadcast "integration_downloads_#{ Company.find_by(id: self.company_id).try(:entity).try(:id) }",
      message: downloading,
      company: self.company_id
    self['downloading'] = downloading
    self['last_time'] = DateTime.current
    self.save
  end
end
