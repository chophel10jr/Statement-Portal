class FetchStatementService < ApplicationService
  attr_accessor :dcn

  def run
    connection = oracle_connection
    row = fetch_row(connection)
    message_clob = row['MESSAGE']
    statement_text = message_clob.read
  ensure
    @cursor&.close
    connection&.logoff
  end

  private

  attr_reader :dcn, :cursor

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
    query = <<~SQL.strip
      SELECT * FROM MSTB_DLY_MSG_OUT WHERE DCN = '#{dcn}'
    SQL

    @cursor = connection.exec(query)
    @cursor.fetch_hash
  end
end
