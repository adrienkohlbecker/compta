class Amount < BigDecimal

  attr_accessor :value, :currency, :at

  def initialize(value, currency, at)
    super(value)
    @value = value
    @currency = currency
    @at = at
  end

  def ==(other)

    a = self
    b = other

    if other.class == Amount
      a = a.to_eur
      b = b.to_eur
      a.value == b.value
    else
      a.value == b
    end

  end

  def *(other)

    a = self
    b = other

    if b.class == Amount
      a = a.to_eur
      b = b.to_eur
      (a.value * b.value).in_currency('EUR', a.at).to_currency(a.currency)
    else
      Amount.new(a.value * b, a.currency, a.at)
    end

  end

  def /(other)

    a = self
    b = other

    if b.class == Amount
      a = a.to_eur
      b = b.to_eur
      (a.value / b.value).in_currency('EUR', a.at).to_currency(a.currency)
    else
      Amount.new(a.value / b, a.currency, a.at)
    end

  end

  def +(other)

    a = self
    b = other

    if b.class == Amount
      a = a.to_eur
      b = b.to_eur
      (a.value + b.value).in_currency('EUR', a.at).to_currency(a.currency)
    else
      Amount.new(a.value + b, a.currency, a.at)
    end

  end

  def -(other)

    a = self
    b = other

    if b.class == Amount
      a = a.to_eur
      b = b.to_eur
      (a.value - b.value).in_currency('EUR', a.at).to_currency(a.currency)
    else
      Amount.new(a.value - b, a.currency, a.at)
    end

  end

  def to_eur
    to_currency('EUR')
  end

  def to_currency(symbol)
    converted_value = CurrencyConverter.new.convert(value, at, currency, symbol)
    Amount.new(converted_value, symbol, at)
  end

  alias_method :original_to_s, :to_s

  def to_s(arg = nil)
    "#{round(2).to_s(arg)} #{currency}"
  end

end
