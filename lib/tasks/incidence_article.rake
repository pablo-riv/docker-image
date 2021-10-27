namespace :incidence_article do
  ARTICLES = [
    {
      title: 'Razones por las que te pediremos tu ayuda para solucionar una incidencia desde Suite',
      kind: 'Incidence',
      link: 'https://shipitcl.zendesk.com/hc/es-419/articles/4402637329819-Razones-por-las-que-te-pediremos-tu-ayuda-para-solucionar-una-incidencia-desde-Suite'
    },
    {
      title: '¿Cómo autogestionar mis problemas de dirección?',
      kind: 'Incidence',
      link: 'https://shipitcl.zendesk.com/hc/es-419/articles/4402644823579--C%C3%B3mo-autogestionar-mis-problemas-de-direcci%C3%B3n-'
    },
    {
      title: '¿Cómo autogestionar mis reembolsos? ',
      kind: 'Incidence',
      link: 'https://shipitcl.zendesk.com/hc/es-419/articles/4402644058523--C%C3%B3mo-autogestionar-mis-reembolsos-'
    }
  ].freeze
  desc 'Create incidence articles'
  task create: :environment do
    ARTICLES.each { |incidence_article| IncidenceArticle.create(incidence_article) }
  end
end
