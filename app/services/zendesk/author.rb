module Zendesk
  module Author
    def extract_author(comment)
      if @authors_recognized.pluck('author_id').include?(comment['author_id'])
        @authors_recognized.find { |ar| ar['author_id'] == comment['author_id'] }
      else
        new_author = search_author(comment)
        @authors_recognized << { author_id: new_author['id'], name: new_author['name'], organization_id: new_author['organization_id'] }.with_indifferent_access
        new_author
      end
    end

    private

    def search_author(comment)
      Zendesk::Api.new(comment['author_id']).author
    end
  end
end
