# frozen_string_literal: true
Rails.application.routes.draw do
  post '/funds' => 'funds#create'
  post '/currencies' => 'currencies#create'
end
