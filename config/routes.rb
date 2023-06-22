# frozen_string_literal: true

Rails.application.routes.draw do
  get '/', to: 'status#show'

  post 'kinesis', to: 'kinesis#create'

  get '/classifications', action: :query, controller: 'classification_count'
  #get '/classifications/users', action: :query_by_user, controller: 'classification_count'
end
