# frozen_string_literal: true

class GnuCash::Price < GnuCash::Base
  self.inheritance_column = '_type' # there is already a 'type' column in the model
  belongs_to :commodity, foreign_key: :commodity_guid
  belongs_to :currency, foreign_key: :currency_guid, class_name: 'GnuCash::Commodity'
end
