# frozen_string_literal: true

module GnuCash
  class Commodity < GnuCash::Base
    has_many :prices, foreign_key: :commodity_guid
  end
end
