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
      tr = trs_for_rate.select { |t| t.fund_id == item.fund_id && t.fund_type == item.fund_type && t.portfolio_id == item.portfolio_id }
      if tr.any? && !item.current_value.nil?
        eq_percent = (InterestRate.equivalent_rate(tr, item.current_value, -1, 10000, date) rescue 0)
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
        'eq%': eq_percent,
        perf_1erjanv: item.shareprice.nil? ? nil : ((item.fund.quotation_at(date) / item.fund.quotation_at(date.beginning_of_year) - 1).value rescue nil),
        perf_1mois: item.shareprice.nil? ? nil : ((item.fund.quotation_at(date) / item.fund.quotation_at(date - 1.month) - 1).value rescue nil),
        perf_6mois: item.shareprice.nil? ? nil : ((item.fund.quotation_at(date) / item.fund.quotation_at(date - 6.month) - 1).value rescue nil),
        perf_1an: item.shareprice.nil? ? nil : ((item.fund.quotation_at(date) / item.fund.quotation_at(date - 1.year) - 1).value rescue nil),
        perf_2ans: item.shareprice.nil? ? nil : ((item.fund.quotation_at(date) / item.fund.quotation_at(date - 2.years) - 1).value rescue nil),
        perf_3ans: item.shareprice.nil? ? nil : ((item.fund.quotation_at(date) / item.fund.quotation_at(date - 3.years) - 1).value rescue nil),
        perf_5ans: item.shareprice.nil? ? nil : ((item.fund.quotation_at(date) / item.fund.quotation_at(date - 5.years) - 1).value rescue nil)
      }
    end

    items = items.sort do |a, b|
      [ b[:%].nil? ? 0 : 1, b[:invested].to_f ] <=> [ a[:%].nil? ? 0 : 1, a[:invested].to_f ]
    end

    current_value = Amount.new(0, 'EUR', date)
    items.each do |h|
      current_value += h[:value] || Amount.new(0, 'EUR', date)
    end

    invested = @portfiolio_ids.map{|id| Portfolio.find(id).invested_at(date)}.reduce(:+)
    pv = current_value - invested
    percent = invested == 0 ? Amount.new(0, 'EUR', date) : (current_value / invested - 1).to_f
    eq_percent = items.empty? ? 0 : (InterestRate.equivalent_rate(trs_for_rate, current_value, -1, 10000, date) rescue 0)

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
      item[:perf_1erjanv] = format('%6s', format('%.2f', (item[:perf_1erjanv] * 100).round(2))) unless item[:perf_1erjanv].nil?
      item[:perf_1mois] = format('%6s', format('%.2f', (item[:perf_1mois] * 100).round(2))) unless item[:perf_1mois].nil?
      item[:perf_6mois] = format('%6s', format('%.2f', (item[:perf_6mois] * 100).round(2))) unless item[:perf_6mois].nil?
      item[:perf_1an] = format('%6s', format('%.2f', (item[:perf_1an] * 100).round(2))) unless item[:perf_1an].nil?
      item[:perf_2ans] = format('%6s', format('%.2f', (item[:perf_2ans] * 100).round(2))) unless item[:perf_2ans].nil?
      item[:perf_3ans] = format('%6s', format('%.2f', (item[:perf_3ans] * 100).round(2))) unless item[:perf_3ans].nil?
      item[:perf_5ans] = format('%6s', format('%.2f', (item[:perf_5ans] * 100).round(2))) unless item[:perf_5ans].nil?
      item.delete(:kind)
      item.delete(:shareprice)
      item
    end

    puts Hirb::Helpers::AutoTable.render(items, max_width: 240)
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
      start_date = PortfolioTransaction.where(portfolio_id: @portfiolio_ids).order('done_at ASC').first.try(:done_at) || Date.today
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

    items.group_by{|i| i[:date]}.map do |d, vs|
      {
        date: d,
        invested: vs.map{|i| i[:invested]}.reduce(&:+),
        value: vs.map{|i| i[:value] || Amount.new(0, 'EUR', d)}.reduce(&:+) ,
        pv: vs.map{|i| i[:pv]}.reduce(&:+)
      }rescue (binding.pry)
    end
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
      sheet.add_row ['PID', 'Kind', 'ID', 'Name', 'ISIN', 'Shares', 'Shareprice', 'Invested', 'Value', 'PV', 'Percent', 'Eq Pct', 'Perf 1er janv', 'Perf 1 mois', 'Perf 6 mois', 'Perf 1 an', 'Perf 2 ans', 'Perf 3 ans', 'Perf 5 ans']

      items.each do |item|
        invested = item[:invested].nil? ? nil : item[:invested].value
        shareprice = item[:shareprice].nil? ? nil : item[:shareprice].value
        value = item[:value].nil? ? nil : item[:value].value
        pv = item[:pv].nil? ? nil : item[:pv].value

        sheet.add_row [item[:'#pid'], item[:kind], item[:'#id'], item[:name], item[:isin], item[:shares], shareprice, invested, value, pv, item[:'%'], item[:'eq%'], item[:perf_1erjanv], item[:perf_1mois], item[:perf_6mois], item[:perf_1an], item[:perf_2ans], item[:perf_3ans], item[:perf_5ans]],
                      style: [nil, nil, nil, nil, nil, style_shares, style_currency, style_currency, style_currency, style_currency, style_percent, style_percent, style_percent, style_percent, style_percent, style_percent, style_percent, style_percent, style_percent]
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
        chart.add_series data: [sheet["D2"],sheet["D#{row_count + 1}"]], labels: [sheet["A2"],sheet["A#{row_count + 1}"]], title: 'PV'

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
