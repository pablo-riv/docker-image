module ApiConnection
  def call(method: :get, url: '', headers: {}, query: {}, body: {})
    response = HTTParty.try(method.to_sym, url, { headers: headers, query: query, body: body, verify: false, timeout: 60 })
    render_response(response)
  end

  def render_response(api_response)
    render_rescue(api_response) unless api_response.success?
    response = JSON.parse(api_response.read_body)
    return response.try(:with_indifferent_access) if response.is_a?(Hash)

    response
  end

  def render_rescue(error_response)
    Rails.logger.info { "ERROR EN CONEXIÓN API: #{error_response}".red.swap }
    error_response
  end
end
