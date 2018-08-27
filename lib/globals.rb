# frozen_string_literal: true
def refresh_quotations!
  [Currency, OpcvmFund].map do |model|
    query = (model == OpcvmFund) ? model.where(closed: false) : model
    query.all.reverse.map do |item|
      puts "refresh #{item.name}"
      item.refresh_data
      item.refresh_quotation_history
    end
  end
  puts 'refresh matview'
  Matview::Base.refresh_all
  puts 'gnucash prices'
  GnuCash.refresh_from_quotations
end

def excel_export!(path)
  Portfolio.all.map do |portfolio|
    puts "excel: #{portfolio.name}"
    PortfolioFormatter.new(portfolio).excel("#{path}/#{portfolio.name}.xlsx")
  end
  puts 'excel: global'
  PortfolioFormatter.new(Portfolio.all.pluck(:id)).excel("#{path}/Global.xlsx")
  puts 'excel: Currencies'
  CommodityFormatter.new(Currency).excel("#{path}/Currencies.xlsx")
  puts 'excel: OPCVM'
  CommodityFormatter.new(OpcvmFund).excel("#{path}/OPCVM.xlsx")
  puts 'excel: SCPI'
  CommodityFormatter.new(ScpiFund).excel("#{path}/SCPI.xlsx")
end
