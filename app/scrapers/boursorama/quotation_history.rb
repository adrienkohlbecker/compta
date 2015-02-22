require 'json'

class Boursorama::QuotationHistory
  VERSION = 1

  def initialize(symbol, period = :daily)

    if period == :daily
      pe = '0'
      duree = '36'
    else
      pe = '1'
      duree = '120'
    end

    @uri = "http://www.boursorama.com/bourse/cours/graphiques/historique.phtml?symbole=#{symbol}&duree=#{duree}&pe=#{pe}"
    @http = HTTPCache.new(@uri, key: :boursorama, expires_in: 3600 * 24)
  end

  def cached?
    @http.cached?
  end

  def version
    VERSION
  end

  def export
    methods = self.class.instance_methods(false)
    methods -= [:version, :export, :doc, :cached?]

    data = {}
    methods.each do |method|
      data[method] = send(method)
    end

    data
  end

  def quotation_history_url
    'http://www.boursorama.com' + doc.content.match(%r{"(/graphiques/quotes.phtml.*)"})[1]
  end

  def quotation_history
    json['dataSets'].first['dataProvider'].each_with_object({}) do |item, h|
      date = Date.parse(item['d'].split(' ').first)
      h[date] = item['c'].to_s
    end
  end

  def doc
    @doc ||= fetch_document
  end

  def json
    @json ||= fetch_json
  end

  private def fetch_document
    Nokogiri::HTML(@http.get, nil, 'ISO-8859-15')
  end

  private def fetch_json
    JSON.load(HTTPCache.new(quotation_history_url, key: :boursorama, expires_in: 3600 * 24).get)
  end
end
