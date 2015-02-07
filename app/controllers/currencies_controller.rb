class CurrenciesController < ApplicationController

  def create

    currency = Currency.new(url: create_params[:url])
    currency.refresh_data
    currency.refresh_cotation_history

    render nothing: true

  end

  def create_params
    params.permit(:url)
  end

end
