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

def hledger_prices!
  groups = {}
  Currency.find_each do |currency|
    groups[currency.name] ||= []
    Matview::EurToCurrency.where(currency_name: currency.name).where('date >= ?', Date.new(2013, 01, 01)).where.not(value: nil).all.each do |i|
      groups[currency.name] << [i.date, currency.name, 1/i.value]
    end
  end
  ScpiFund.find_each do |fund|
    groups[fund.isin] = []
    Matview::ScpiQuotationsFilledEur.where(scpi_fund_id: fund.id).where('date >= ?', Date.new(2013, 01, 01)).where.not(value_original: nil).all.each do |i|
      groups[fund.isin] << [i.date, fund.isin, i.value_original]
    end
  end
  OpcvmFund.find_each do |fund|
    groups[fund.isin] = []
    Matview::OpcvmQuotationsFilledEur.where(opcvm_fund_id: fund.id).where('date >= ?', Date.new(2013, 01, 01)).where.not(value_original: nil).all.each do |i|
      groups[fund.isin] << [i.date, fund.isin, i.value_original]
    end
  end

  groups.each do |name, values|
    contents = values.map{ |v| "P #{v[0].strftime("%Y/%m/%d")} \"#{v[1]}\" \u20AC #{"%e" % v[2]}" }.join("\n")
    File.write("/hledger/prices/#{name}.journal", contents + "\n")
  end

  index = groups.keys.map { |k| "include #{k}.journal" }.join("\n")
  File.write("/hledger/prices/main.journal", index + "\n")

  true
end
