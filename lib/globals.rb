def refresh_quotations!
  [Currency, OpcvmFund].map do |model|
    query = (model == OpcvmFund) ? model.where(closed: false) : model
    query.all.reverse.map do |item|
      ap item.name
      item.refresh_data
      item.refresh_quotation_history
    end
  end
  Matview::Base.refresh_all
end

def excel_export!(path)
  Portfolio.all.map do |portfolio|
    ap portfolio.name
    portfolio.excel(path)
  end
end

def backup!(path)
  `pg_dump --format=p --verbose --encoding=UTF-8 --no-owner --no-privileges --inserts --dbname=compta-backend_development --file=#{path}/#{Date.today.strftime('%d')}.sql`
end
