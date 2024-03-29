# frozen_string_literal: true

def refresh_prices(cutoff = Date.new(2007, 8, 31))
  GnuCash::Base.connection.execute('CREATE INDEX IF NOT EXISTS compta_index_prices ON prices (date, commodity_guid, source)')
  GnuCash::Price.where.not(source: 'user:price-editor').delete_all

  puts 'online quotes...'
  refresh_online_prices(cutoff)
  puts 'manual quotes...'
  refresh_manual_prices
end

def find_commodity(keyword)
  @cache ||= {}
  return @cache[keyword] if @cache.key?(keyword)

  result = GnuCash::Commodity.where(cusip: keyword).or(GnuCash::Commodity.where(mnemonic: keyword)).first
  raise "Could not find gnucash commodity with keyword `#{keyword}`" if result.nil?

  @cache[keyword] = result
  result
end

def parse_tsv(path)
  CSV.read(
    path,
    encoding: 'UTF-8',
    skip_lines: /^; /,
    skip_blanks: true,
    col_sep: "\t",
    headers: true,
    header_converters: ->(f) { f.strip.to_sym },
    converters: ->(f) { f.strip }
  )
end

def refresh_online_prices(cutoff = Date.new(2007, 8, 31))
  parse_tsv('/app/data/commodities.tsv').each do |item|
    puts item[:url]
    commodity = find_commodity(item[:isin])
    currency = find_commodity(item[:currency])

    response = HTTParty.get(URI(item[:url]))
    GnuCash::Base.transaction do
      JSON.parse(response.body).each do |quote|
        date = Date.strptime(quote['date'], '%Y-%m-%d')
        value = quote['close']

        next if date < cutoff

        # precision
        # coingecko 10-7
        # ecb 10-5
        # boursorama 10-5
        precision = item[:url].include?('coingecko') ? 10_000_000 : 100_000
        value = Rational((value * precision).to_i, precision)

        add_price(commodity, currency, date, value)
      end
    end
  end
end

def refresh_manual_prices
  GnuCash::Base.transaction do
    parse_tsv('/app/data/prices.tsv').each do |item|
      commodity = find_commodity(item[:isin])
      currency = find_commodity(item[:currency])

      date = Date.strptime(item[:date], '%Y-%m-%d')
      value = Rational(item[:price])

      add_price(commodity, currency, date, value)
    end
  end
end

def add_price(commodity, currency, date, value)
  if commodity.namespace == "CURRENCY"
    # gnucash stores currencies in inverse (1 X = ? EUR)
    value = 1/value
  end

  price = GnuCash::Price.where(commodity_guid: commodity.guid, date: date.strftime('%Y%m%d170000'), source: 'user:price-editor').first_or_initialize
  price.guid = SecureRandom.hex(16) if price.guid.nil?
  price.currency_guid = currency.guid
  price.type = 'unknown'
  price.value_num = value.numerator
  price.value_denom = value.denominator
  price.save!
end
