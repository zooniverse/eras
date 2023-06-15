# frozen_string_literal: true

Rails.application.routes.draw do
  get '/', to: 'status#show'

  post 'kinesis', to: 'kinesis#create'
end
