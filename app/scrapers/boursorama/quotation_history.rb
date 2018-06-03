# frozen_string_literal: true
require 'json'

class Boursorama::QuotationHistory
  VERSION = 1

  def initialize(symbol)
    @uri = "https://www.boursorama.com/bourse/action/graph/ws/GetTicksEOD?{%22symbol%22:%22#{symbol}%22,%22length%22:7300,%22period%22:0,%22guid%22:%22%22}"
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

  def quotation_history
    json['d']['QuoteTab'].each_with_object({}) do |item, h|
      date = Date.new(1970,1,1).days_since(item['d'])
      h[date] = item['c'].to_s
    end
  end

  def json
    @json ||= fetch_json
  end

  private def fetch_json
    JSON.load(@http.get)
  end
end
