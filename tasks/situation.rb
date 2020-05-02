def export_situation
  accounts = parse_tsv('/app/data/accounts.tsv').map {|i| GnuCash::Account.find_by_identifier(i[:account]) }
  situation = accounts.map { |account| account.value_tuples }.reduce(:+)

  p = Axlsx::Package.new
  wb = p.workbook

  style_currency = wb.styles.add_style format_code: '# ##0.00 €;[Red]- # ##0.00 €'
  style_shares = wb.styles.add_style format_code: '0.00000;[Red]- 0.00000'

  wb.add_worksheet(name: 'Situation') do |sheet|
    sheet.add_row ['Account', 'Name', 'ISIN', 'Shares', 'Price', 'Value']

    situation.each do |item|
      sheet.add_row [item[0], item[1], item[2], item[3], item[4], item[5]],
                    style: [nil, nil, nil, style_shares, style_currency, style_currency]
    end

    sheet.auto_filter = 'A1:C1'
  end

  wb.add_worksheet(name: 'Accounts') do |sheet|
    sheet.add_row ['Account', 'Value']

    situation.group_by { |item| item[0] }.each_with_object([]) { |(account, items), a| a << [account, items.map{|item| item[5]}.reduce(:+)]}.each do |item|
      sheet.add_row [item[0], item[1]],
                    style: [nil, style_currency]
    end
  end

  p.serialize '/dataroom/Situation.xlsx'
end
