# frozen_string_literal: true

class FetchStatementService < ApplicationService
  attr_accessor :dcn

  def run
    connection = oracle_connection
    row = fetch_row(connection)

    raise ExternalServiceError, "Statement not found for DCN #{dcn}" if row.nil?

    message_clob = row['MESSAGE']
    raise ExternalServiceError, "Empty statement message for DCN #{dcn}" if message_clob.nil?

    message_clob.read
  rescue OCIError => e
    Rails.logger.error("[FetchStatementService] Oracle error: #{e.message}")
    raise ExternalServiceError, "Core database unavailable"
  ensure
    @cursor&.close
    connection&.logoff
  end

  private

  attr_reader :cursor

  def oracle_connection
    @oracle_connection ||= OracleConnectionService.new(
      db_user: ENV.fetch('DB_USER'),
      db_password: ENV.fetch('DB_PASSWORD'),
      db_host: ENV.fetch('DB_HOST'),
      db_port: ENV.fetch('DB_PORT'),
      db_service_name: ENV.fetch('DB_SERVICE_NAME')
    ).run
  end

  def fetch_row(connection)
    query = <<~SQL
      SELECT *
      FROM MSTB_DLY_MSG_OUT
      WHERE DCN = :dcn
    SQL

    @cursor = connection.parse(query)
    @cursor.bind_param(':dcn', dcn.to_s)
    @cursor.exec
    @cursor.fetch_hash
  end
end
