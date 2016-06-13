module GnuCash
  def self.refresh_from_quotations
    GnuCash::Base.connection.execute('CREATE INDEX IF NOT EXISTS compta_index_prices ON prices (date, commodity_guid, source)')
    GnuCash::Price.where.not(source: 'user:price-editor').delete_all

    gnucash_currency = GnuCash::Commodity.where(mnemonic: 'EUR').first

    OpcvmFund.find_each do |fund|
      commodity = fund.gnucash_commodity
      raise "Could not find commodity for fund #{fund.name}" if commodity.nil?

      GnuCash::Base.transaction do

        Matview::OpcvmQuotationsFilledEur.where(opcvm_fund_id: fund.id).where('date >= ?', Date.new(2015, 01, 01)).where.not(value_original: nil).each do |quotation|
          date = quotation.date.strftime('%Y%m%d170000')
          price = GnuCash::Price.where(commodity: commodity, date: date, source: 'user:price-editor').first_or_initialize
          price.guid = SecureRandom.hex(16) if price.guid.nil?
          price.currency_guid = gnucash_currency.guid
          price.type = 'unknown'
          value = quotation.value_original.round(6).to_r
          price.value_num = value.numerator
          price.value_denom = value.denominator
          price.save!
        end

      end
    end

    Currency.find_each do |currency|
      commodity = currency.gnucash_commodity
      raise "Could not find commodity for currency #{currency.name}" if commodity.nil?

      GnuCash::Base.transaction do

        Matview::EurToCurrency.where(currency_name: currency.name).where('date >= ?', Date.new(2015, 01, 01)).where.not(value: nil).each do |quotation|
          date = quotation.date.strftime('%Y%m%d170000')
          price = GnuCash::Price.where(commodity: commodity, date: date, source: 'user:price-editor').first_or_initialize
          price.guid = SecureRandom.hex(16) if price.guid.nil?
          price.currency_guid = gnucash_currency.guid
          price.type = 'unknown'
          # gnucash stores the currencies in reverse
          value = (1 / quotation.value).round(6).to_r
          price.value_num = value.numerator
          price.value_denom = value.denominator
          price.save!
        end

      end
    end
  end
end
