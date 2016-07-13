# frozen_string_literal: true
require 'json'

class BF::QuotationHistory
  VERSION = 1

  def initialize(symbol)
    @uri = "https://www.banque-france.fr/fileadmin/user_upload/banque_de_france/Economie_et_Statistiques/Changes_et_Taux/uc.d.#{symbol}.eur.sp00.a.csv"
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
    8.times { csv.shift } # skip header
    csv.each_with_object({}) do |i, a|
      next if i[1] == 'ND'
      a[Date.parse(i[0])] = i[1].sub(',', '.')
    end
  end

  def csv
    @csv ||= fetch_csv
  end

  def doc
    @doc ||= fetch_document
  end

  private def fetch_csv
    CSV.new(doc, col_sep: ';', row_sep: "\r\n")
  end

  private def fetch_document
    @http.get.encode('UTF-8', 'ISO-8859-1')
  end
end
