module SearchService
  class Download
    KIND = [*0..6].freeze
    STATUS = [*0..4].freeze

    def initialize(properties)
      @properties = properties
    end

    def search
      downloads = company.downloads.where(status: status, kind: kind).order(updated_at: :desc)
      { downloads: Kaminari.paginate_array(downloads).page(page).per(per), total: downloads.size }
    end

    private

    def id
      @properties[:id]
    end

    def company
      @properties[:company]
    end

    def status
      @properties[:status].present? ? @properties[:status] : STATUS
    end

    def kind
      [0, 1, 2, 3, 4]
    end

    def per
      @properties[:per]
    end

    def page
      @properties[:page]
    end

    def translate_status(status)
      case status
      when 'label' then 0
      when 'xlsx' then 1
      when 'image' then 2
      when 'docx' then 3
      when 'orders' then 4
      when 'manifest' then 4
      when 'pdf' then 4
      end
    end
  end
end
