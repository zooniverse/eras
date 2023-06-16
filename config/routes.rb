# frozen_string_literal: true

Rails.application.routes.draw do
  post 'kinesis', to: 'kinesis#create'
end
