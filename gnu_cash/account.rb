# frozen_string_literal: true

module GnuCash
  class Account < GnuCash::Base
    has_many :splits, foreign_key: :account_guid
    belongs_to :parent, foreign_key: :parent_guid, class_name: 'GnuCash::Account'
    has_many :children, foreign_key: :parent_guid, class_name: 'GnuCash::Account'
    belongs_to :commodity, foreign_key: :commodity_guid, class_name: 'GnuCash::Commodity'

    def self.root_account
      @root_account ||= GnuCash::Account.where(parent_guid: nil).first
    end

    def self.find_by_identifier(identifier)
      @query_index ||= {}

      return root_account if identifier == ''
      return @query_index[identifier] if @query_index.key?(identifier)

      parts = identifier.split(':')
      result = where(name: parts.last, parent_guid: find_by_identifier(parts[0...-1].join('::'))).first

      @query_index[identifier] = result

      result
    end

    def identifier
      @@identifier_index ||= {}

      # make a copy otherwise this is passed by reference
      return @@identifier_index[guid].dup if @@identifier_index.key?(guid)
      return '' if account_type == 'ROOT'

      result = "#{parent.identifier}:#{name}".sub(/^:/, '')

      @@identifier_index[guid] = result

      # make a copy otherwise this is passed by reference
      result.dup
    end

    def deep_children
      children.map { |c| [c, c.deep_children] }.flatten
    end

    def value_tuples
      eur_funds = {}
      splits = GnuCash::Split.where(account: deep_children + [self]).includes(account: :commodity)
      commodities_and_values = splits.map do |s|
        commodity = if s.account.identifier.include?(':Fonds Euro:')
                      eur_funds[s.account.name] ||= GnuCash::Commodity.new(mnemonic: 'EUR', fullname: s.account.name, quote_source: 'currency')
                    else
                      s.account.commodity
                    end
        [commodity, Rational(s.quantity_num, s.quantity_denom)]
      end

      commodity_to_values = commodities_and_values.group_by { |item| item[0] }
      commodity_to_value = commodity_to_values.map { |commodity, tuples| [commodity, tuples.map { |tuple| tuple[1] }.reduce(:+)] }
      nonzero_commodities = commodity_to_value.select { |tuple| tuple[1].abs > 0.1 }

      eur_currency = GnuCash::Commodity.where(mnemonic: 'EUR').first

      nonzero_commodities.map do |c, v|
        price = if c.mnemonic == 'EUR'
                  1
                else
                  price = c.prices.where(source: 'user:price-editor').order('date DESC').limit(1).first
                  raise "can't find #{c.to_json}" if price.nil?

                  change = if price.currency_guid != eur_currency.guid
                            currency_price = GnuCash::Price.where(commodity_guid: price.currency_guid, currency_guid: eur_currency.guid).where(source: 'user:price-editor').order('date DESC').limit(1).first
                            raise "can't find #{price.to_json}" if currency_price.nil?

                            Rational(currency_price.value_num, currency_price.value_denom)
                          else
                            1
                          end
                  Rational(price.value_num, price.value_denom) * change
                end

        isin = c.quote_source == 'currency' ? c.mnemonic : c.cusip
        [identifier, c.fullname, isin, v.to_f.round(5), price.to_f.round(2), v * price.to_f.round(2)]
      end
    end
  end
end
