def refresh_quotations!
  [Currency, OpcvmFund].map do |model|
    model.all.reverse.map do |item|
      item.refresh_data
      item.refresh_quotation_history
    end
  end
end

begin
  load '~/.pryrc'
rescue LoadError
  puts 'Failed to load home pryrc'
end
