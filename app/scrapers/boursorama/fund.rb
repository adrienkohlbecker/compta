require 'nokogiri'

class Boursorama::Fund
  VERSION = 1

  def initialize(uri)
    @uri = uri
    @http = HTTPCache.new(uri, key: :boursorama, expires_in: 3600 * 7)
  end

  def cached?
    @http.cached?
  end

  def version
    VERSION
  end

  def export
    methods = Boursorama::Fund.instance_methods(false)
    methods -= [:version, :export, :doc, :cached?]

    data = {}
    methods.each do |method|
      data[method] = send(method)
    end

    data
  end

  def name
    doc.css('[itemprop="name"]').first.content.strip
  end

  def boursorama_id
    @uri.split('?symbole=').last
  end

  def isin
    doc.css('.fv-isin').first.content.split('-').first.strip
  end

  def cotation
    doc.css('.cotation').first.content.split(' ').first.to_f
  end

  def cotation_date
    Date.parse(doc.css('#fiche_cours_details tr')[1].css('td')[2].content.strip)
  end

  def cotation_history_url
    'http://www.boursorama.com' + doc.content.match(/"(\/graphiques\/quotes.phtml.*)"/)[1]
  end

  def doc
    @doc ||= fetch_document
  end

  private def fetch_document
    Nokogiri::HTML(@http.get, nil, 'ISO-8859-15')
  end
end
