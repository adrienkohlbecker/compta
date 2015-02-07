class FundsController < ApplicationController

  def create

    fund = Fund.new(url: create_params[:url])
    fund.refresh_data
    fund.refresh_cotation_history

    render nothing: true

  end

  def create_params
    params.permit(:url)
  end

end
