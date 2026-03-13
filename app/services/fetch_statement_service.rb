# frozen_string_literal: true

class FetchStatementService < ApplicationService
  attr_accessor :dcn

  def run
    connection = oracle_connection
    rows = fetch_row(connection)

    raise ExternalServiceError, "Statement not found for DCN #{dcn}" if rows.empty?

    combined_message = rows.map do |row|
      row['MESSAGE']&.read.to_s
    end.join

    combined_message

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
      ORDER BY RUNNING_NO ASC
    SQL

    @cursor = connection.parse(query)
    @cursor.bind_param(':dcn', dcn.to_s)
    @cursor.exec

    rows = []
    while row = @cursor.fetch_hash
      rows << row
    end

    rows
  end
end
