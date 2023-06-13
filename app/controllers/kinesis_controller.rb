# frozen_string_literal: true

class KinesisController < ApplicationController
  def create
    kinesis_stream.create_events(params['payload'])
    head :no_content
  end

  private

  def kinesis_stream
    KinesisStream.new
  end
end
