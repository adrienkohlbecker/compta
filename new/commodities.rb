require 'active_model'
require 'csv'

class Commodity
  include ActiveModel::Serialization

  attr_accessor :isin, :name, :currency, :closed_date, :boursorama_id, :boursorama_type

  class << self

    def load(path)
      ::CSV.read(path, col_sep: "\t", headers: true, converters: [->(v) { v.strip rescue v }], header_converters: [->(v) { v.strip.to_sym rescue v }]).map{|h| self.new(h)}
    end

  end

  def initialize(options = {})
    attributes.keys.each do |attr|
      self.send "#{attr}=", options.fetch(attr, nil)
    end
  end

  def attributes
    %i(isin name currency closed_date boursorama_id boursorama_type).to_h { |a| [a, nil] }
  end
end
