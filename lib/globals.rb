# frozen_string_literal: true
def refresh_quotations!
  [Currency, OpcvmFund].map do |model|
    query = (model == OpcvmFund) ? model.where(closed: false) : model
    query.all.reverse.map do |item|
      puts "refresh #{item.name} (#{item.try(:isin)})"
      item.refresh_data
      item.refresh_quotation_history
    end
  end
  private_quotations!
end

def import_transactions!
  import_transactions_from_gnucash!(1, 'Bank Savings LT:Linxea:Vie')
  import_transactions_from_gnucash!(2, 'Bank Savings LT:Linxea:Spirit')
  import_transactions_from_gnucash!(3, 'Bank Savings LT:Boursorama:Vie')
  import_transactions_from_gnucash!(4, 'Bank Savings LT:Boursorama:PEA')
  import_transactions_from_gnucash!(5, 'Bank Savings LT:Degiro')
  import_transactions_from_gnucash!(6, 'Stock')
  import_transactions_from_gnucash!(7, 'Bank Savings LT:Coinbase')
  import_transactions_from_gnucash!(8, 'Bank Savings LT:Linxea:Avenir')
  import_transactions_from_gnucash!(9, 'Bank Savings LT:Amundi')
  import_transactions_from_gnucash!(10, 'Bank Savings LT:Interactive Brokers')
  import_transactions_from_gnucash!(11, 'Bank Savings LT:Homunity')
  import_transactions_from_gnucash!(12, 'Bank Savings LT:Brand New Day')
end

def excel_export!(path)
  Portfolio.all.map do |portfolio|
    puts "excel: #{portfolio.name}"
    PortfolioFormatter.new(portfolio).excel("#{path}/#{portfolio.name}.xlsx")
  end
  puts 'excel: global'
  PortfolioFormatter.new(Portfolio.where.not(name: ["Stock"]).pluck(:id)).excel("#{path}/Global.xlsx")
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

def import_transactions_from_gnucash!(id, identifier)

  PortfolioTransaction.where(portfolio_id: id).delete_all

  root = GnuCash::Account.find_by_identifier(identifier)

  splits = GnuCash::Split.where(account: root.deep_children + [root])
  transactions = GnuCash::Transaction.includes(:splits).where(guid: splits.map(&:tx_guid).uniq)

  result = []

  eur_currency = GnuCash::Commodity.where(mnemonic: 'EUR').first

  transactions.each do |tx|
    date_format = if tx.post_date.length == 14
               "%Y%m%d%H%M%S"
             else
               "%Y-%m-%d %H:%M:%S"
             end

    date = Time.strptime(tx.post_date, date_format).in_time_zone('Europe/Paris').to_date
    tx.splits.select{|s| s.memo != ''}.each do |split|
      line = split.account.identifier
      category = split.memo
      sign = 1
      if !line.starts_with?(identifier)
        line = split.memo
        category = split.account.identifier
        sign = -1
      else
        line = line.split(':').last
      end

      shares = nil
      if split.quantity_num != split.value_num
        shares = Rational(sign * split.quantity_num, split.quantity_denom)
      end

      category.sub!(/^Expense:/, '')
      category.sub!(/^Income:/, '')

      line = private_aliases!(line)

      amount = Rational(sign * split.value_num, split.value_denom)
      amount = private_amounts!(split.account.identifier, amount)

      if category.end_with?(':USD') || split.account.identifier == "Bank Savings LT:Interactive Brokers:Stock:Datadog"
        amount = Amount.new(amount, 'USD', date).to_eur.value
      end
      if category.end_with?(':USD')
        category = category.rpartition(':').first
      end

      fund = OpcvmFund.where(name: line).first || ScpiFund.where(name: line).first || EuroFund.where(name: line).first
      raise "Can't find fund named #{line}" if fund.nil?
      result << PortfolioTransaction.create(
        fund: fund,
        portfolio_id: id,
        done_at: date,
        shares: shares,
        amount_original: amount,
        amount_currency: 'EUR',
        amount_date: date,
        category: category,
      )
    end
  end

  result
end
