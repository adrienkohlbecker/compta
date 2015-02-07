class Portfolio < ActiveRecord::Base
  has_many :transactions, class_name: 'PortfolioTransaction'

  def currency
    "EUR"
  end

  def invested_amount
    acc = 0

    transactions.map(&:amount).each do |amount|
      acc += amount.to_currency(currency).value
    end

    Amount.new(acc, currency, Date.today)
  end

  def current_amount
    acc = 0

    transactions.includes(:fund).map(&:current_value).each do |amount|
      acc += amount.to_currency(currency).value
    end

    Amount.new(acc, currency, Date.today)
  end

  def performance
    (current_amount / invested_amount).to_f - 1
  end

  def annualized_performance
    transactions.includes(:fund).each do |transaction|

      current_value = transaction.current_value.to_currency(currency).value
      invested_value = transaction.amount.to_currency(currency).value

      acc += (current_value - invested_value) / (Date.today - transaction.done_at)
    end

    365 * (acc / invested_amount.value).to_f
  end
end
