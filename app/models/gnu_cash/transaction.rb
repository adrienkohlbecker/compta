# frozen_string_literal: true
class GnuCash::Transaction < GnuCash::Base
  has_many :splits, foreign_key: :tx_guid
  belongs_to :currency, foreign_key: :currency_guid, class_name: 'GnuCash::Commodity'
end
