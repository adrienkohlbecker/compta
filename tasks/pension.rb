def get_pension(lookback = 30.days)
  data = {}
  verification_token = nil
  date = Date.today

  backup = JSON.parse(File.read('data/pension.json'))
  previous_date = backup.keys.map{|k| Date.parse(k)}.max
  date_to_stop_at = [Date.parse("03-02-2021") - 1.day, Date.today - lookback, previous_date].max

  while date > date_to_stop_at
    uri = URI('http://host.docker.internal:4567/asr')
    uri.query = "verification_token=#{verification_token}&date=#{date.strftime("%d-%m-%Y")}" if !verification_token.nil?
    puts date

    begin
      response = JSON.parse(HTTParty.post(uri, body: {'cookies' => File.open('cookies.txt')}).body)
    rescue JSON::ParseError
      sleep 5
      response = JSON.parse(HTTParty.post(uri, body: {'cookies' => File.open('cookies.txt')}).body)
    end

    verification_token = response["next_verification_token"]
    date = Date.strptime(response["date"], "%d-%m-%Y")
    lines = response["table_lines"]

    data[date] = lines
    date -= 1.day
  end

  File.write('data/pension.json', JSON.pretty_generate(data.merge(backup)))

  data
rescue => e
  puts JSON.dump(data)
  raise e
end

# Creates an excel file with pension data
#
# here data is a Hash, mapping each date to the table_lines value:
#   { Date.new(2022, 06, 10) => [ ["ASR Duurzaam Wereldwijd Aandelen Fonds Hedged"], ... ] }
def export_pension(data)
  funds = []
  data.each do |date, situation|
    funds += situation.map(&:first)
    funds.uniq!
  end

  p = Axlsx::Package.new
  wb = p.workbook

  style_currency = wb.styles.add_style format_code: '# ##0.00 €;[Red]- # ##0.00 €'
  style_shares = wb.styles.add_style format_code: '0.00;[Red]- 0.00'

  wb.add_worksheet(name: 'History') do |sheet|
    row = sheet.add_row %w[Date] + funds.map { |f| [f, '', ''] }.reduce(:+)
    for i in 0..(funds.length-1)
      sheet.merge_cells(row.cells[((i*3+1)..(i*3+3))])
    end

    sheet.add_row [''] + funds.map { |_| %w[Shares Price Total]}.reduce(:+)

    data.each do |date, situation|
      row_data = [''] * situation.length * 3
      situation.each do |item|
        offset = funds.index(item[0])
        row_data[offset*3+0] = item[1]
        row_data[offset*3+1] = item[2]
        row_data[offset*3+2] = item[3]
      end
      sheet.add_row [date] + row_data,
        style: [nil] + [style_shares, style_currency, style_currency]*row_data.length,
        width: [:auto] + [14]*3*row_data.length

    end
    sheet.auto_filter = 'A1:A1'
  end

  p.serialize '/dataroom/Pension.xlsx'
end
