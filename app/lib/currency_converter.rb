class CurrencyConverter

  def convert(value, at, from, to = "EUR")
    if to == from
      value
    else
      value / to_eur_at(at, from) * to_eur_at(at, to)
    end
  end

  private def to_eur_at(at, symbol)
    if symbol == "EUR"
      1
    else
      Currency.where(name: symbol).first.cotation_at(at)
    end
  end

end
