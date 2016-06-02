class GnuCash::Commodity < GnuCash::Base
  has_many :prices, foreign_key: :commodity_guid
end
