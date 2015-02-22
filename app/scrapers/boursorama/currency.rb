require 'nokogiri'

class Boursorama::Currency
  VERSION = 1

  def initialize(uri)
    @uri = uri
    @http = HTTPCache.new(uri, key: :boursorama, expires_in: 3600 * 24)
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

  def name
    doc.css('.cotation').first.content.split(' ').last
  end

  def boursorama_id
    @uri.split('?symbole=').last
  end

  def quotation
    doc.css('.cotation').first.content.split(' ').first
  end

  def quotation_date
    Date.today
  end

  def doc
    @doc ||= fetch_document
  end

  private def fetch_document
    Nokogiri::HTML(@http.get, nil, 'ISO-8859-15')
  end
end
