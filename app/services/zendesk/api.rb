module Zendesk
  class Api
    include Zendesk::Authenticator
    include HTTParty

    attr_accessor :id

    base_uri Rails.configuration.zendesk[:url]

    def initialize(id = nil)
      @id = id
    end

    def create_ticket(user_type, attributes, kind)
      template = Zendesk::TicketTemplate.new(attributes)
      request = template.send("ticket_#{user_type}_struct", kind)

      return I18n.t('activerecord.attributes.zendesk.ticket.proactive_monitoring.invalid_ticket') unless request

      request = {
        headers: ticket_headers,
        body: request.to_json,
        basic_auth: auth,
        verify: false
      }

      response = self.class.post('/tickets.json', request)
      raise unless valid_response?(response)

      JSON.parse(response.body).with_indifferent_access[:ticket]
    end

    def update_attachment(file, filename)
      request = {
        basic_auth: auth,
        headers: file_headers,
        verify: false,
        body: file
      }
      response = self.class.post("/uploads?filename=#{filename}", request)
      raise unless valid_response?(response)

      JSON.parse(response).with_indifferent_access[:upload]
    rescue StandardError => _e
      'No fue posible crear el archivo'
    end

    def metrics
      response = self.class.get("/tickets/#{id}/metrics.json", { basic_auth: auth, verify: false })
      raise unless valid_response?(response)

      response.with_indifferent_access[:ticket_metric]
    rescue StandardError => _e
      'No fue posible extraer las métricas'
    end

    def comments
      response = self.class.get("/tickets/#{id}/comments.json", { basic_auth: auth, verify: false })
      raise unless valid_response?(response)

      response.with_indifferent_access[:comments]
    rescue StandardError => _e
      'No fue posible extraer los comentarios'
    end

    def author
      response = self.class.get("/users/#{id}.json", { basic_auth: auth, verify: false })
      raise unless valid_response?(response)

      response.with_indifferent_access[:user]
    rescue StandardError => _e
      'Sin autor'
    end

    def search(word)
      response = self.class.get("/users/search.json?query=#{word}",
                                { basic_auth: auth, verify: false })
      raise unless valid_response?(response)

      response.with_indifferent_access
    rescue StandardError => _e
      'No fue posible extraer resultados de la búsqueda'
    end

    def tickets_by_page
      response = self.class.get("/tickets.json#{id}", { basic_auth: auth,
                                                        verify: false })
      raise unless valid_response?(response)

      response.with_indifferent_access
    rescue StandardError => _e
      "No se pudieron extraer los tickets de la página #{id}"
    end

    def update_remote_ticket(message, zendesk_id)
      response = self.class.put("/tickets/#{id}.json", { headers: ticket_headers,
                                                         body: ticket_body(message, zendesk_id),
                                                         basic_auth: auth,
                                                         verify: false })
      raise unless valid_response?(response)

      response.with_indifferent_access
    rescue StandardError => _e
      "No se pudo actualizar el ticket #{id} en zendesk"
    end

    def create_satisfaction_rating(email, password, score, comment)
      request = {
        headers: ticket_headers,
        body: satisfaction_rating_body(score, comment),
        basic_auth: end_user_auth(email, password),
        verify: false
      }
      response = self.class.post("/tickets/#{id}/satisfaction_rating.json", request)
      raise StandardError.new "#{response}" unless valid_response?(response)
    end

    def create_password_to_end_user
      data = password_body
      request = {
        headers: ticket_headers,
        body: data.to_json,
        basic_auth: auth,
        verify: false
      }
      response = self.class.post("/users/#{id}/password.json", request)
      raise StandardError.new "#{response}" unless valid_response?(response)

      data[:password]
    end

    def end_user_auth(email, password)
      {
        username: email,
        password: password
      }
    end

    def show_ticket
      response = self.class.get("/tickets/#{id}.json", { basic_auth: auth, verify: false })
      raise unless valid_response?(response)

      response.with_indifferent_access[:ticket]
    rescue StandardError => _e
      response['error']
    end

    private

    def password_body
      { password: SecureRandom.hex(8) }
    end

    def satisfaction_rating_body(score, comment)
      {
        satisfaction_rating: {
          score: score,
          comment: comment
        }
      }.to_json
    end

    def ticket_body(message, zendesk_id)
      { ticket: { comment: { body: message,
                             author_id: zendesk_id },
                  status: 'open' } }.to_json
    end

    def ticket_headers
      { 'Content-Type' => 'application/json' }
    end

    def file_headers
      { 'Content-Type' => 'application/binary' }
    end

    def valid_response?(response)
      (200..204).cover?(response.code)
    end

  end
end
