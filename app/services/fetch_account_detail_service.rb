# frozen_string_literal: true

class FetchAccountDetailService < ApplicationService
  attr_accessor :account_number

  def run
    oracle_connection = connect_to_oracle
    
    query = <<~SQL.strip
      SELECT * FROM vw_Account_details WHERE CUST_aC_NO = #{account_number}
    SQL
    
    cursor = oracle_connection.exec(query)

    cursor.fetch_hash || {}
  ensure
    cursor&.close
    oracle_connection&.logoff
  end

  private

  def connect_to_oracle
    OracleConnectionService.new(
      db_user: ENV['DB_USER'],
      db_password: ENV['DB_PASSWORD'],
      db_host: ENV['DB_HOST'],
      db_port: ENV['DB_PORT'],
      db_service_name: ENV['DB_SERVICE_NAME']
    ).run
  end
end
