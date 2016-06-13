# frozen_string_literal: true
def refresh_quotations!
  [Currency, OpcvmFund].map do |model|
    query = (model == OpcvmFund) ? model.where(closed: false) : model
    query.all.reverse.map do |item|
      ap item.name
      item.refresh_data
      item.refresh_quotation_history
    end
  end
  Matview::Base.refresh_all
  GnuCash.refresh_from_quotations
end

def excel_export!(path)
  Portfolio.all.map do |portfolio|
    ap portfolio.name
    portfolio.excel(path)
  end
end
