# frozen_string_literal: true
require 'nokogiri'

class Boursorama::Fund
  VERSION = 1

  def initialize(boursorama_id)
    @uri = "http://www.boursorama.com/bourse/opcvm/opcvm.phtml?symbole=#{boursorama_id}"
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
    doc.css('[itemprop="name"]').first.content.strip
  end

  def isin
    doc.css('.fv-isin').first.content.match(/.* ([a-zA-Z]{2}[0-9a-zA-Z]{10}) .*/)[1]
  end

  def quotation
    doc.css('.cotation').first.content.split(' ').first
  end

  def quotation_date
    date = nil
    doc.css('#fiche_cours_details tr').each do |tr|
      if tr.css('td')[0].content.strip.gsub(/\302\240/, '') == 'Date'
        date = Date.parse(tr.css('td')[2].content.strip.gsub(/\302\240/, ''))
      end

      next if tr.css('small[title="Données temps réel"]').empty?
      date = if Time.now.hour < 9 # avant l'ouverture, la page date d'hier
               Date.yesterday
             else
               Date.today
             end
    end
    date
  end

  def currency
    doc.css('.cotation').first.content.split(' ').last
  end

  def doc
    @doc ||= fetch_document
  end

  private def fetch_document
    Nokogiri::HTML(@http.get, nil, 'ISO-8859-15')
  end
end
