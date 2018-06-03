# frozen_string_literal: true
require 'json'

class Coingecko::QuotationHistory
  VERSION = 1

  def initialize(chart)
    @uri = "https://www.coingecko.com/chart/#{chart}/eur.json?locale=en"
    @http = HTTPCache.new(@uri, key: :coingecko, expires_in: 3600 * 24)
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
    json['stats'].each_with_object({}) do |item, h|
      date = Time.at(item[0] / 1000).to_date
      h[date] = (1 / (item[1] / 1000)).to_s # we work in micro-currency units (mBTC, mETH)
    end
  end

  def json
    @json ||= fetch_json
  end

  private def fetch_json
    JSON.load(@http.get)
  end
end
