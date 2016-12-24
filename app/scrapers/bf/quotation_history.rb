# frozen_string_literal: true
require 'json'

class BF::QuotationHistory
  VERSION = 1

  def initialize(symbol)
    @uri = 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.zip'
    @http = HTTPCache.new(@uri, key: :ecb, expires_in: 3600 * 24)
    @symbol = symbol
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
    header = csv.first
    index = header.index(@symbol)

    csv.each_with_object({}) do |i, a|
      next if i[index] == 'N/A'
      a[Date.parse(i[0])] = i[1]
    end
  end

  def csv
    @csv ||= fetch_csv
  end

  def doc
    @doc ||= fetch_document
  end

  private def fetch_csv
    CSV.new(doc, col_sep: ',', row_sep: "\n")
  end

  private def fetch_document
    tmp = Tempfile.new('ecb')
    tmp.binmode
    tmp.write(@http.get)
    zip = Zip::File.open(tmp.path)
    entry = zip.get_entry('eurofxref-hist.csv')
    doc = entry.get_input_stream.read
    zip.close
    tmp.close
    tmp.unlink
    doc
  end
end
