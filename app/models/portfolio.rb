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

    Matview::PortfolioHistory.where(date: date, portfolio_id: id).includes(:fund).each do |item|

      items << {
        kind: item.fund_type.gsub('Fund', '').upcase,
        '#id': item.fund_id,
        name: item.fund.name,
        isin: item.fund.try(:isin),
        shares: item.shares,
        invested: item.invested,
        value: item.current_value,
        pv: item.pv,
        '%': item.percent
      }

    end

    items.sort do |a, b|
      if b[:invested].nil?
        -1
      elsif a[:invested].nil?
        1
      else
        b[:invested] <=> a[:invested]
      end
    end
  end

  def print_situation(date = Date.today)

    items = list_situation(date)


    value = Amount.new(0, "EUR", Date.today)
    items.each do |h|
      value += h[:value] || 0
    end

    invested = invested_at(Date.today)
    pv = value - invested

    items = items.map { |item|
      item[:'#id'] = '%2s' % item[:'#id']
      item[:shares] = '%8s' % ('%.5f' % item[:shares].round(5)) unless item[:shares].nil?
      item[:'%'] = '%6s' % ('%.2f' % (item[:'%'] * 100).round(2)) unless item[:'%'].nil?
      item[:invested] = '%11s' % item[:invested]
      item[:pv] = '%10s' % item[:pv]
      item[:value] = '%11s' % item[:value]
      item.delete(:kind)
      item
    }

    puts Hirb::Helpers::AutoTable.render(items)
    puts "Invested: #{invested} / Current: #{value} / PV: #{pv} / %: #{(value / invested * 100 - 100).round(2)}"

  end

  def list_transactions

    items = []

    transactions.includes(:fund).order(:done_at, :id).each do |t|

      items << {
        '#id': t.id,
        date: t.done_at,
        name: t.fund.try(:name),
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
    transactions.where(category: ["Virement", "Arbitrage"]).where("done_at <= ?", date).map{|t| t.amount.to_eur}.reduce(:+) || 0
  end

  def list_performance(start_date = nil)

    if start_date.nil?
      start_date = transactions.order("done_at ASC").first.done_at
    end
    end_date = Date.today

    items = []

    Matview::PortfolioPerformance.where(portfolio_id: id).where('date >= ?', start_date).where('date <= ?', end_date).each do |item|

      items << {
        date: item.date,
        invested: item.invested,
        value: item.current_value,
        pv: item.pv
      }

    end

    items

  end

  def print_performance(start_date = nil)

    items = list_performance(start_date)
    items = items.map do |item|
      item[:invested] = '%11s' % item[:invested]
      item[:value] = '%11s' % item[:value]
      item[:pv] = '%11s' % item[:pv]
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

        chart.style = 1

        chart.catAxis.format_code = 'dd/mm/yyyy'
        chart.catAxis.label_rotation = -45
        chart.catAxis.tick_lbl_pos = :low

        chart.valAxis.format_code = '# ##0.00 €;[Red]- # ##0.00 €'
      end
    end

    p.serialize 'export.xlsx'

  end
end
