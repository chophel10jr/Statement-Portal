# frozen_string_literal: true

require 'net/http'
require 'uri'

class SmsService < ApplicationService
  attr_accessor :number, :message

  def run
    uri = URI(ENV['SMS_URL'])
    uri.query = URI.encode_www_form({
      app: ENV['SMS_APP'],
      u: ENV['SMS_USER'],
      h: ENV['SMS_HASH'],
      op: ENV['SMS_OPERATION'],
      to: number,
      msg: message
    })

    begin
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        Rails.logger.info("Message sent to #{@number}: #{response.code}")
      else
        Rails.logger.error("Failed to send message to #{@number}: #{response.code}")
      end

    rescue Net::OpenTimeout, Net::ReadTimeout
      Rails.logger.error("Request to #{@number} timed out")

    rescue StandardError => e
      Rails.logger.error("An error occurred with #{@number}: #{e.message}")
    end
  end
end
