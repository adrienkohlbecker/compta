# frozen_string_literal: true
require 'nokogiri'

class Boursorama::Fund
  VERSION = 1

  def initialize(boursorama_id, boursorama_type)
    @uri = "https://www.boursorama.com/bourse/#{boursorama_type}/cours/#{boursorama_id}/"
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

  def name
    doc.css('.c-faceplate__company-link').first.content.strip
  end

  def isin
    doc.css('.c-faceplate__isin').first.content.match(/^([a-zA-Z]{2}[0-9a-zA-Z]{10}).*/)[1]
  end

  def currency
    doc.css('.c-faceplate__price-currency').first.content.strip
  end

  def doc
    @doc ||= fetch_document
  end

  private def fetch_document
    Nokogiri::HTML(@http.get, nil, 'ISO-8859-15')
  end
end
