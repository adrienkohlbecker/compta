require 'json'

class Boursorama::FundCotationHistory
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

  def cotation_history
    doc["dataSets"].first["dataProvider"].each_with_object({}) do |item, h|
      date = Date.parse(item["d"].split(" ").first)
      h[date] = item["c"]
    end
  end

  def doc
    @doc ||= fetch_document
  end

  private def fetch_document
    JSON.load(@http.get)
  end
end
