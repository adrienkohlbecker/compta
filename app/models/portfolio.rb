# == Schema Information
#
# Table name: portfolios
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Portfolio < ActiveRecord::Base
  has_many :transactions, class_name: 'PortfolioTransaction'
  has_many :euro_fund_investments

  def currency
    "EUR"
  end

  def append_opcvm_transaction(fund_id:, shares:, amount:, date:)

    transactions.create(
      fund: OpcvmFund.find(fund_id),
      shares: shares,
      amount: Amount.new(amount, currency, date),
      done_at: date
    )

  end

  def append_euro_transaction(fund_id:, amount:, date:)

    transactions.create(
      fund: EuroFund.find(fund_id),
      shares: nil,
      amount: Amount.new(amount, currency, date),
      done_at: date
    )

  end

  def list_situation(date = Date.today)

    items = []
    OpcvmFund.order(:id).each do |fund|

      shares = PortfolioTransaction.where(fund: fund).where('done_at < ?', date).pluck(:shares).reduce(:+) || Amount.zero
      invested = PortfolioTransaction.where(fund: fund, category: "Virement").where('done_at < ?', date).map(&:amount).reduce(:+).try(:to_eur) || Amount.zero
      invested += PortfolioTransaction.where(fund: fund, category: "Arbitrage").where('done_at < ?', date).map(&:amount).reduce(:+).try(:to_eur) || Amount.zero
      current_value = (fund.quotation_at(date) * shares).to_eur

      pv = current_value - invested
      percent = (current_value / invested - 1).value

      if shares <= 0.0001
        shares = nil
        percent = nil
        current_value = nil
      end

      if invested == 0
        invested = nil
      end

      if pv == 0
        pv = nil
      end

      items << {
        kind: 'OPCVM',
        '#id': fund.id,
        name: fund.name,
        isin: fund.isin,
        shares: shares,
        invested: invested,
        value: current_value,
        pv: pv,
        '%': percent
      }

    end
    EuroFund.order(:id).each do |fund|

      invested = PortfolioTransaction.where(fund: fund, category: 'Virement').where('done_at < ?', date).map(&:amount).reduce(:+) || 0
      invested += PortfolioTransaction.where(fund: fund, category: 'Arbitrage').where('done_at < ?', date).map(&:amount).reduce(:+) || 0
      actual_pv = PortfolioTransaction.where(fund: fund).where('done_at < ?', date).where.not(category: 'Virement').where.not(category: 'Arbitrage').map(&:amount).reduce(:+) || 0

      rate = fund.current_interest_rate(date)

      value_at_beginning_of_year = PortfolioTransaction.where(fund: fund).where('done_at < ?', date.beginning_of_year).map(&:amount).reduce(:+) || 0
      latent_pv = value_at_beginning_of_year * ((1 + rate) ** ((date - date.beginning_of_year) / 365.0) - 1)

      PortfolioTransaction.where(fund: fund).where('done_at >= ?', date.beginning_of_year).where('done_at < ?', date).order('done_at ASC').each do |t|
        latent_pv += t.amount * ((1 + rate) ** ((date - t.done_at - 1) / 365.0) - 1)
      end
      pv = latent_pv + actual_pv

      if invested == 0
        invested = nil
      end

      if pv == 0
        pv = nil
      end

      items << {
        kind: 'EUR',
        '#id': fund.id,
        name: fund.name,
        isin: nil,
        shares: nil,
        invested: invested,
        value: invested + pv,
        pv: pv,
        '%': ((invested + pv) / invested - 1).value
      }

    end

    items
  end

  def print_situation(date = Date.today)

    items = list_situation(date)
    items = items.map { |item|
      item[:shares] = '%.5f' % item[:shares].round(5) unless item[:shares].nil?
      item[:'%'] = '%.2f' % (item[:'%'] * 100).round(2) unless item[:'%'].nil?
      item.delete(:kind)
      item
    }

    puts Hirb::Helpers::AutoTable.render(items)

    invested = Amount.new(0, "EUR", Date.today)
    value = Amount.new(0, "EUR", Date.today)
    pv = Amount.new(0, "EUR", Date.today)

    items.each do |h|
      invested += h[:invested] || 0
      value += h[:value] || 0
      pv += h[:pv] || 0
    end

    puts "Invested: #{invested} / Current: #{value} / PV: #{pv} / %: #{(value / invested * 100 - 100).round(2)}"

  end

  def list_transactions

    items = []

    transactions.includes(:fund).order(:done_at, :id).each do |t|

      items << {
        '#id': t.id,
        date: t.done_at,
        name: t.fund.name,
        isin: t.fund.try(:isin),
        shares: t.shares,
        amount: t.amount,
        shareprice: t.shareprice,
        category: t.category
      }

    end

    items

  end

  def print_transactions

    items = list_transactions
    items = items.map { |item|
      item[:shares] = '%.4f' % item[:shares] unless item[:shares].nil?
      item
    }

    puts Hirb::Helpers::AutoTable.render(items)

  end

  def invested_at(date)
    amount = transactions.where(category: "Virement").where("done_at <= ?", date).map{|t| t.amount.to_eur}.reduce(:+) || 0
    amount += transactions.where(category: "Arbitrage").where("done_at <= ?", date).map{|t| t.amount.to_eur}.reduce(:+) || 0
    amount
  end

  def value_at(date)
    ret = transactions.where(fund_type: "OpcvmFund").where("done_at <= ?", date).map{|t| (t.fund.quotation_at(date) * t.shares).to_eur}.reduce(:+) || 0
    ret += transactions.where(fund_type: "EuroFund").where("done_at <= ?", date).map{|t| t.amount.to_eur}.reduce(:+) || 0
    ret
  end

  def list_performance(start_date = nil)

    if start_date.nil?
      start_date = transactions.order("done_at ASC").first.done_at
    end
    end_date = Date.today

    items = []

    (start_date..end_date).each do |date|

      value = value_at(date)
      invested = invested_at(date)
      pv = value - invested

      items << {
        date: date,
        invested: invested,
        value: value,
        pv: pv
      }
    end

    items

  end

  def print_performance(start_date = nil)

    items = list_performance(start_date)
    items = items.map do |item|
      item[:value] = item[:value].round(2)
      item[:pv] = item[:pv].round(2)
      item
    end

    puts Hirb::Helpers::AutoTable.render(items)

  end

  def excel

    p = Axlsx::Package.new
    wb = p.workbook

    style_currency = wb.styles.add_style :format_code => '# ##0.00 €;[Red]- # ##0.00 €'
    style_percent = wb.styles.add_style :format_code => '0.00%;[Red]- 0.00%'
    style_shares = wb.styles.add_style :format_code => '0.00000;[Red]- 0.00000'
    style_date = wb.styles.add_style :format_code => 'dd/mm/yyyy'

    wb.add_worksheet(:name => "Situation") do |sheet|

      sheet.add_row ["Kind", "ID", "Name", "ISIN", "Shares", "Invested", "Value", "PV", "Percent"]

      list_situation.each do |item|

        invested = item[:invested].nil? ? nil : item[:invested].value
        value = item[:value].nil? ? nil : item[:value].value
        pv = item[:pv].nil? ? nil : item[:pv].value

        sheet.add_row [item[:kind], item[:'#id'], item[:name], item[:isin], item[:shares], invested, value, pv, item[:'%']],
          style: [nil, nil, nil, nil, style_shares, style_currency, style_currency, style_currency, style_percent]
      end

      sheet.auto_filter = 'A1:C1'
    end

    wb.add_worksheet(:name => "Transactions") do |sheet|

      sheet.add_row ["ID", "Date", "Category", "Fund", "ISIN", "Shares", "Amount", "Shareprice"]

      list_transactions.reverse.each do |item|

        amount = item[:amount].nil? ? nil : item[:amount].value
        shareprice = item[:shareprice].nil? ? nil : item[:shareprice].value

        sheet.add_row [item[:'#id'], item[:date], item[:category], item[:name], item[:isin], item[:shares], amount, shareprice],
          style: [nil, style_date, nil, nil, nil, style_shares, style_currency, style_currency]
      end

      sheet.auto_filter = 'A1:E1'
    end

    wb.add_worksheet(:name => "Performance") do |sheet|

      sheet.add_row ["Date", "Invested", "Value", "PV"]

      row_count = 0

      list_performance.reverse.each do |item|

        row_count += 1

        invested = item[:invested].nil? ? nil : item[:invested].value
        value = item[:value].nil? ? nil : item[:value].value
        pv = item[:pv].nil? ? nil : item[:pv].value

        sheet.add_row [item[:date], invested, value, pv],
          style: [style_date, style_currency, style_currency, style_currency]
      end

      sheet.add_chart(Axlsx::LineChart, :start_at => [5,2], :end_at => [20, 40], :title => 'Performance') do |chart|
        chart.add_series :data => sheet["D2:D#{row_count+1}"], :labels => sheet["A2:A#{row_count+1}"], :title => 'PV'
      end
    end

    p.serialize 'export.xlsx'

  end
end
