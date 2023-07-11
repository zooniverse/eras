# frozen_string_literal: true

Rails.application.routes.draw do
  get '/', to: 'status#show'

  post 'kinesis', to: 'kinesis#create'

  get '/comments', action: :query, controller: 'comment_count'
  get '/classifications', action: :query, controller: 'classification_count'
  # get '/classifications/users/:id', action: :query_by_user controller: 'user_classification_count'
  # get '/classifications/user_groups/:id, action: :query_by_user_group, controller: 'user_group_classification_count'
end
