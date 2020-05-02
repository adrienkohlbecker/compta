# frozen_string_literal: true

require_relative 'files.rb'

puts "Getting online prices for the last year..."
refresh_prices(Date.today - 1.year)

puts "Exporting situation spreadsheet"
export_situation
