# frozen_string_literal: true
require 'json'

class BND::QuotationHistory
  VERSION = 1

  def initialize(fundId)
    @uri = 'https://secure.brandnewday.nl/service/navvaluesforfund'
    body = {
      'sort' => '',
      'page' => 1,
      'pageSize' => 1000,
      'group' => '',
      'filter' => '',
      'fundId' => fundId,
      'startDate' => '01-01-2010',
      'endDate' => Date.today.strftime('%d-%m-%Y'),
    }
    @http = HTTPCache.new(@uri, method: :post, body: body, key: :bnd, expires_in: 3600 * 24)
    @fundId = fundId
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
    raise "weird data" if json["Total"] < 50 || json["Errors"] != nil

    json['Data'].each_with_object({}) do |item, h|
      date = Time.at(item["Date"].match(/.*\((\d+)\).*/)[1].to_i/1000).to_date
      h[date] = item['NavMember']
    end
  end

  def json
    @json ||= fetch_json
  end

  private def fetch_json
    JSON.load(@http.get)
  end
end
