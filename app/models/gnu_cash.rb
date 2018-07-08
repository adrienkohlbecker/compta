# frozen_string_literal: true
module GnuCash
  def self.refresh_from_quotations
    GnuCash::Base.connection.execute('CREATE INDEX IF NOT EXISTS compta_index_prices ON prices (date, commodity_guid, source)')
    GnuCash::Price.where.not(source: 'user:price-editor').delete_all

    eur_currency = GnuCash::Commodity.where(mnemonic: 'EUR').first

    # CUC change from Cuba trip (1 EUR = 1.02227786 CUC => 1 CUC = O.97820762 EUR)
    cuc_currency = GnuCash::Commodity.where(mnemonic: 'CUC').first
    p = GnuCash::Price.where(commodity: cuc_currency.guid, currency_guid: eur_currency.guid, date: "20161204170000", source: "user:price-editor").first_or_initialize(type: 'unknown', guid: SecureRandom.hex(16))
    p.update_attributes!(value_num: 97820762, value_denom: 100000000)

    # CUP change from Cuba trip (1 CUC = 24 CUP => 1 CUP = 0.04075865 EUR)
    cup_currency = GnuCash::Commodity.where(mnemonic: 'CUP').first
    p = GnuCash::Price.where(commodity: cup_currency.guid, currency_guid: eur_currency.guid, date: "20161204170000", source: "user:price-editor").first_or_initialize(type: 'unknown', guid: SecureRandom.hex(16))
    p.update_attributes!(value_num: 4075865, value_denom: 100000000)

    OpcvmFund.find_each do |fund|
      commodity = fund.gnucash_commodity
      raise "Could not find commodity for fund #{fund.name}" if commodity.nil?

      GnuCash::Base.transaction do
        Matview::OpcvmQuotationsFilledEur.where(opcvm_fund_id: fund.id).where('date >= ?', Date.new(2007, 08, 31)).where.not(value_original: nil).each do |quotation|
          date = quotation.date.strftime('%Y%m%d170000')
          price = GnuCash::Price.where(commodity: commodity, date: date, source: 'user:price-editor').first_or_initialize
          price.guid = SecureRandom.hex(16) if price.guid.nil?
          price.currency_guid = eur_currency.guid
          price.type = 'unknown'
          value = quotation.value_original.round(6).to_r
          price.value_num = value.numerator
          price.value_denom = value.denominator
          price.save!
        end
      end
    end

    ScpiFund.find_each do |fund|
      commodity = fund.gnucash_commodity
      raise "Could not find commodity for fund #{fund.name}" if commodity.nil?

      GnuCash::Base.transaction do
        Matview::ScpiQuotationsFilledEur.where(scpi_fund_id: fund.id).where('date >= ?', Date.new(2013, 01, 01)).where.not(value_original: nil).each do |quotation|
          date = quotation.date.strftime('%Y%m%d170000')
          price = GnuCash::Price.where(commodity: commodity, date: date, source: 'user:price-editor').first_or_initialize
          price.guid = SecureRandom.hex(16) if price.guid.nil?
          price.currency_guid = eur_currency.guid
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
        Matview::EurToCurrency.where(currency_name: currency.name).where('date >= ?', Date.new(2013, 01, 01)).where.not(value: nil).each do |quotation|
          date = quotation.date.strftime('%Y%m%d170000')
          price = GnuCash::Price.where(commodity: commodity, date: date, source: 'user:price-editor').first_or_initialize
          price.guid = SecureRandom.hex(16) if price.guid.nil?
          price.currency_guid = eur_currency.guid
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
