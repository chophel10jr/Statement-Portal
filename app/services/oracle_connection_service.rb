# frozen_string_literal: true

require 'ruby-oci8'

class OracleConnectionService < ApplicationService
  attr_accessor :db_user, :db_password, :db_host, :db_port, :db_service_name

  def run
    validate_credentials
    establish_connection
  end

  private

  def validate_credentials
    %w[db_host db_port db_service_name db_user db_password].each do |var|
      raise "Missing environment variable: #{var}" unless var.present?
    end
  end

  def establish_connection
    connection_string = "//#{db_host}:#{db_port}/#{db_service_name}"
    
    connection = OCI8.new(db_user, db_password, connection_string)
    Rails.logger.info "Oracle database connection established"
    
    connection
  rescue OCIError => e
    Rails.logger.error "Oracle connection failed: #{e.message}"
    raise
  end
end
