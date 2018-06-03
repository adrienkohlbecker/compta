class AddCoingeckoChartToCurrency < ActiveRecord::Migration
  def change
    add_column :currencies, :coingecko_chart, :string
  end
end
