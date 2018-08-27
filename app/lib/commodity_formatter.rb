class CommodityFormatter

  attr_accessor :item_class

  def initialize(item_class)
    @item_class = item_class
  end

  def excel(path = './Currencies.xlsx')
    p = Axlsx::Package.new
    wb = p.workbook

    format_code = '# ##0.0000;[Red]- # ##0.0000'
    style_date = wb.styles.add_style format_code: 'dd/mm/yyyy'
    style_currency = wb.styles.add_style format_code: format_code

    relation = @item_class == Currency ? :quotations : :quotations_filled_eur
    start = @item_class == Currency ? Date.new(2007, 8, 31) : Date.new(2014, 11, 1)

    @item_class.includes(relation).find_each do |item|
      sheet_name = item_class == Currency ? item.name : item.isin

      wb.add_worksheet(name: sheet_name) do |sheet|
        sheet.add_row ['Date', '1EUR=', '=EUR', '', '', '', '', item.name]

        row_count = 0

        item.method(relation).call.each do |quote|

          # don't print useless data
          break if quote.date < start

          row_count += 1

          if item_class == Currency
            data = [quote.date, quote.value, 1/quote.value]
          else
            value = quote.value.value
            data = [quote.date, 1/value, value]
          end

          sheet.add_row data, style: [style_date, style_currency, style_currency]
        end

        sheet.add_chart(Axlsx::LineChart, start_at: [5, 4], end_at: [20, 42], title: '1 unit equals in EUR') do |chart|
          chart.add_series data: [sheet['C2'],sheet["C#{row_count + 1}"]], labels: [sheet['A2'],sheet["A#{row_count + 1}"]]

          chart.style = 1

          chart.catAxis.format_code = 'dd/mm/yyyy'
          chart.catAxis.label_rotation = -45
          chart.catAxis.tick_lbl_pos = :low

          chart.valAxis.format_code = format_code
        end
      end

    end

    p.serialize path
  end

end
