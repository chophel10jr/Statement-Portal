# frozen_string_literal: true

class FetchAccountDetailService < ApplicationService
  attr_accessor :account_number

  def run
    connection = connect_to_oracle
    cursor     = connection.parse(query)

    cursor.bind_param(':account_number', account_number.to_s)
    cursor.exec
    cursor.fetch_hash
  rescue StandardError => e
    Rails.logger.error(
      "[FetchAccountDetailService] account_number=#{account_number} error=#{e.class}: #{e.message}"
    )
    raise ExternalServiceError, "Unable to fetch account details"
  ensure
    cursor&.close
    connection&.logoff
  end

  private

  def query
    <<~SQL
      SELECT *
      FROM vw_Account_details
      WHERE CUST_aC_NO = :account_number
    SQL
  end

  def connect_to_oracle
    OracleConnectionService.new(
      db_user: ENV.fetch("DB_USER"),
      db_password: ENV.fetch("DB_PASSWORD"),
      db_host: ENV.fetch("DB_HOST"),
      db_port: ENV.fetch("DB_PORT"),
      db_service_name: ENV.fetch("DB_SERVICE_NAME")
    ).run
  end
end
