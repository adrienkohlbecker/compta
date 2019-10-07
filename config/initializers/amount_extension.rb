# frozen_string_literal: true
class BigDecimal
  def in_currency(symbol, at)
    Amount.new(self, symbol, at)
  end
end

class Fixnum
  def in_currency(symbol, at)
    Amount.new(self, symbol, at)
  end
end

class AwesomePrint::Formatter
  CORE = [:array, :bigdecimal, :class, :dir, :file, :hash, :method, :rational, :set, :struct, :unboundmethod, :amount].freeze

  def awesome_amount(n)
    colorize(n.to_s('F'), :bigdecimal)
  end
end
