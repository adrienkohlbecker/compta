class PortfolioFormatter

  attr_accessor :portfiolio_ids

  def initialize(portfiolio_ids)
    @portfiolio_ids = Array(portfiolio_ids)
  end

  def list_situation(date = Date.today)
    items = []

    trs_for_rate = Matview::PortfolioTransactionsWithInvestmentEur.where(portfolio_id: @portfiolio_ids, category: PortfolioTransaction::CATEGORY_FOR_INVESTED).where("done_at <= ?", date).all

    Matview::PortfolioHistory.where(date: date, portfolio_id: @portfiolio_ids).includes(:fund).each do |item|
      eq_percent = nil
      tr = trs_for_rate.select { |t| t.fund_id == item.fund_id && t.fund_type == item.fund_type }
      if tr.any? && !item.current_value.nil?
        eq_percent = InterestRate.equivalent_rate(tr, item.current_value, -1, 1000)
      end

      next if item.invested.nil?

      items << {
        '#pid': item.portfolio_id,
        kind: item.fund_type.gsub('Fund', '').upcase,
        '#id': item.fund_id,
        name: item.fund.name,
        isin: item.fund.try(:isin),
        shares: item.shares,
        shareprice: item.shareprice,
        invested: item.invested,
        value: item.current_value,
        pv: item.pv,
        '%': item.percent,
        'eq%': eq_percent
      }
    end

    items = items.sort do |a, b|
      b[:invested] <=> a[:invested]
    end

    current_value = Amount.new(0, 'EUR', date)
    items.each do |h|
      current_value += h[:value] || 0
    end

    invested = @portfiolio_ids.map{|id| Portfolio.find(id).invested_at(date)}.reduce(:+)
    pv = current_value - invested
    percent = (current_value / invested - 1).to_f
    eq_percent = InterestRate.equivalent_rate(trs_for_rate, current_value, -1, 1)

    {
      current_value: current_value,
      invested: invested,
      pv: pv,
      percent: percent,
      eq_percent: eq_percent,
      items: items
    }
  end

  def print_situation(date = Date.today)
    situation = list_situation(date)
    items = situation[:items]

    items = items.map do |item|
      item[:'#id'] = format('%2s', item[:'#id'])
      item[:shares] = format('%8s', format('%.5f', item[:shares].round(5))) unless item[:shares].nil?
      item[:shareprice] = format('%11s', item[:shareprice])
      item[:'%'] = format('%6s', format('%.2f', (item[:'%'] * 100).round(2))) unless item[:'%'].nil?
      item[:'eq%'] = format('%6s', format('%.2f', (item[:'eq%'] * 100).round(2))) unless item[:'eq%'].nil?
      item[:invested] = format('%11s', item[:invested])
      item[:pv] = format('%10s', item[:pv])
      item[:value] = format('%11s', item[:value])
      item.delete(:kind)
      item.delete(:shareprice)
      item
    end

    puts Hirb::Helpers::AutoTable.render(items)
    puts "Invested: #{situation[:invested]} / Current: #{situation[:current_value]} / PV: #{situation[:pv]} / %: #{(situation[:percent] * 100).round(2)} / eq%: #{(situation[:eq_percent] * 100).round(2)}"
  end

  def list_transactions
    items = []

    PortfolioTransaction.where(portfolio_id: @portfiolio_ids).includes(:fund).order(:done_at, :id).each do |t|
      items << {
        '#pid': t.portfolio_id,
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
    items = items.map do |item|
      item[:shares] = format('%.5f', item[:shares]) unless item[:shares].nil?
      item
    end

    puts Hirb::Helpers::AutoTable.render(items)
  end

  def list_performance(start_date = nil)
    if start_date.nil?
      start_date = PortfolioTransaction.where(portfolio_id: @portfiolio_ids).order('done_at ASC').first.done_at
    end
    end_date = Date.today

    items = []

    Matview::PortfolioPerformance.where(portfolio_id: @portfiolio_ids).where('date >= ?', start_date).where('date <= ?', end_date).each do |item|
      items << {
        '#pid': item.portfolio_id,
        date: item.date,
        invested: item.invested,
        value: item.current_value,
        pv: item.pv
      }
    end

    items.group_by{|i| i[:date]}.map{|d, vs| {date: d, invested: vs.map{|i| i[:invested]}.reduce(&:+), value: vs.map{|i| i[:value]}.reduce(&:+), pv: vs.map{|i| i[:pv]}.reduce(&:+)}}
  end

  def print_performance(start_date = nil)
    items = list_performance(start_date)
    items = items.map do |item|
      item[:invested] = format('%11s', item[:invested])
      item[:value] = format('%11s', item[:value])
      item[:pv] = format('%11s', item[:pv])
      item
    end

    puts Hirb::Helpers::AutoTable.render(items)
  end

  def excel(path = './Portfolio.xlsx')
    p = Axlsx::Package.new
    wb = p.workbook

    style_currency = wb.styles.add_style format_code: '# ##0.00 €;[Red]- # ##0.00 €'
    style_percent = wb.styles.add_style format_code: '0.00%;[Red]- 0.00%'
    style_shares = wb.styles.add_style format_code: '0.00000;[Red]- 0.00000'
    style_date = wb.styles.add_style format_code: 'dd/mm/yyyy'

    situation = list_situation
    items = situation[:items]

    wb.add_worksheet(name: 'Overview') do |sheet|
      sheet.add_row ['Invested', situation[:invested].value], style: [nil, style_currency]
      sheet.add_row ['Current Value', situation[:current_value].value], style: [nil, style_currency]
      sheet.add_row ['PV', situation[:pv].value], style: [nil, style_currency]
      sheet.add_row ['%', situation[:percent]], style: [nil, style_percent]
      sheet.add_row ['eq%', situation[:eq_percent]], style: [nil, style_percent]
    end

    wb.add_worksheet(name: 'Situation') do |sheet|
      sheet.add_row ['PID', 'Kind', 'ID', 'Name', 'ISIN', 'Shares', 'Shareprice', 'Invested', 'Value', 'PV', 'Percent', 'Eq Pct']

      items.each do |item|
        invested = item[:invested].nil? ? nil : item[:invested].value
        shareprice = item[:shareprice].nil? ? nil : item[:shareprice].value
        value = item[:value].nil? ? nil : item[:value].value
        pv = item[:pv].nil? ? nil : item[:pv].value

        sheet.add_row [item[:'#pid'], item[:kind], item[:'#id'], item[:name], item[:isin], item[:shares], shareprice, invested, value, pv, item[:'%'], item[:'eq%']],
                      style: [nil, nil, nil, nil, nil, style_shares, style_currency, style_currency, style_currency, style_currency, style_percent, style_percent]
      end

      sheet.auto_filter = 'A1:C1'
    end

    wb.add_worksheet(name: 'Transactions') do |sheet|
      sheet.add_row %w(PID ID Date Category Fund ISIN Shares Amount Shareprice)

      list_transactions.reverse.each do |item|
        amount = item[:amount].nil? ? nil : item[:amount].value
        shareprice = item[:shareprice].nil? ? nil : item[:shareprice].value

        sheet.add_row [item[:'#pid'], item[:'#id'], item[:date], item[:category], item[:name], item[:isin], item[:shares], amount, shareprice],
                      style: [nil, nil, style_date, nil, nil, nil, style_shares, style_currency, style_currency]
      end

      sheet.auto_filter = 'A1:E1'
    end

    wb.add_worksheet(name: 'Performance') do |sheet|
      sheet.add_row %w(Date Invested Value PV)

      row_count = 0

      list_performance.reverse.each do |item|
        row_count += 1

        invested = item[:invested].nil? ? nil : item[:invested].value
        value = item[:value].nil? ? nil : item[:value].value
        pv = item[:pv].nil? ? nil : item[:pv].value

        sheet.add_row [item[:date], invested, value, pv],
                      style: [style_date, style_currency, style_currency, style_currency]
      end

      sheet.add_chart(Axlsx::LineChart, start_at: [5, 2], end_at: [20, 40], title: 'Performance') do |chart|
        chart.add_series data: sheet["D2:D#{row_count + 1}"], labels: sheet["A2:A#{row_count + 1}"], title: 'PV'

        chart.style = 1

        chart.catAxis.format_code = 'dd/mm/yyyy'
        chart.catAxis.label_rotation = -45
        chart.catAxis.tick_lbl_pos = :low

        chart.valAxis.format_code = '# ##0.00 €;[Red]- # ##0.00 €'
      end
    end

    p.serialize path
  end

end
