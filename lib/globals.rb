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
    PortfolioFormatter.new(portfolio).excel("#{path}/#{portfolio.name}.xlsx")
  end
  puts "Global"
  PortfolioFormatter.new(Portfolio.all.pluck(:id)).excel("#{path}/Global.xlsx")
  puts "Currencies"
  CommodityFormatter.new(Currency).excel("#{path}/Currencies.xlsx")
  puts "OPCVM"
  CommodityFormatter.new(OpcvmFund).excel("#{path}/OPCVM.xlsx")
  puts "SCPI"
  CommodityFormatter.new(ScpiFund).excel("#{path}/SCPI.xlsx")
end
