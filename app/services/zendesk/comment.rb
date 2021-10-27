module Zendesk
  module Comment
    include Zendesk::Author

    def build_comments
      params_build_comments.map do |comment|
        author = extract_author(comment)
        { id: comment['id'],
          author_id: comment['author_id'],
          message: comment['html_body'],
          created_at: comment['created_at'],
          name: author['name'],
          organization_id: (author['organization_id'] || 0),
          public: comment['public'].nil? ? true : comment['public'],
          readed: readed(comment) }
      end
    rescue StandardError => _e
      'No fue posible extraer los comentarios'
    end

    def zendesk_comments
      Zendesk::Api.new(ticket_id).comments
    end

    private

    def params_build_comments
      support[:comments]
    end

    def readed(comment)
      return false if @ticket.nil?

      message_status = @ticket.messages.select { |message| message['id'] == comment['id'] }
      message_status.empty? ? false : message_status.first['readed']
    end
  end
end
