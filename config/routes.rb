# frozen_string_literal: true

Rails.application.routes.draw do
  get '/', to: 'status#show'

  post 'kinesis', to: 'kinesis#create'

  get '/comments', action: :query, controller: 'comment_count'
  get '/classifications/users/:id', action: :query, controller: 'user_classification_count', constraints: { id: /\d+/ }
  get '/classifications/user_groups/:id', action: :query, controller: 'user_group_classification_count', constraints: { id: /\d+/ }
  get '/classifications', action: :query, controller: 'classification_count'
end
