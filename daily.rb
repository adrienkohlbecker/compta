# frozen_string_literal: true

require_relative 'files.rb'

refresh_prices(Date.today - 1.year)
export_situation
