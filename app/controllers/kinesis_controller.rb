# frozen_string_literal: true

class KinesisController < ApplicationController
  def create
    Kinesis::Create.run!(params)
    head :no_content
  end
end
