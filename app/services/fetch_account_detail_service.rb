# frozen_string_literal: true

class FetchAccountDetailService < ApplicationService
  attr_accessor :account_number

  def run
    connection = connect_to_oracle

    cursor = connection.exec(query, account_number)
    cursor.fetch_hash || {}
  rescue StandardError => e
    Rails.logger.error("FetchAccountDetailService failed: #{e.message}")
    raise ExternalServiceError, "Unable to fetch account details"
  ensure
    cursor&.close
    connection&.logoff
  end

  private

  attr_reader :account_number

  def query
    <<~SQL
      SELECT *
      FROM vw_Account_details
      WHERE CUST_aC_NO = :account_number
    SQL
  end

  def connect_to_oracle
    OracleConnectionService.new(
      db_user: ENV.fetch('DB_USER'),
      db_password: ENV.fetch('DB_PASSWORD'),
      db_host: ENV.fetch('DB_HOST'),
      db_port: ENV.fetch('DB_PORT'),
      db_service_name: ENV.fetch('DB_SERVICE_NAME')
    ).run
  end
end
