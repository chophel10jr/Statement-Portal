# frozen_string_literal: true

require 'savon'

class SoapClientService < ApplicationService
  attr_accessor :account_number, :branch_code, :from_date, :to_date

  def initialize(attrs = {})
    super
    @client = Savon.client(
      wsdl: ENV.fetch('SOAP_LINK'),
      log: true,
      log_level: :debug,
      pretty_print_xml: true,
      namespace: 'http://fcubs.ofss.com/service/FCUBSAccFinService',
      namespace_identifier: :fcub,
      env_namespace: :soapenv,
      convert_request_keys_to: :none,
      adapter: :net_http
    )
  end

  def run
    message = build_message(account_number, branch_code, from_date, to_date)

    response = @client.call(:request_acc_stmt_io, message: message)
    response.body
  rescue Savon::SOAPFault => e
    Rails.logger.error "SOAP Fault: #{e.message}"
    { error: e.message }
  rescue Savon::Error => e
    Rails.logger.error "SOAP request failed: #{e.message}"
    { error: e.message }
  end

  private

  def build_message(account_number, branch_code, from_date, to_date)
    {
      "fcub:FCUBS_HEADER" => {
        "fcub:SOURCE" => "FCAT",
        "fcub:UBSCOMP" => "FCUBS",
        "fcub:MSGID" => "",
        "fcub:CORRELID" => "",
        "fcub:USERID" => "FCATOP",
        "fcub:BRANCH" => branch_code,
        "fcub:SERVICE" => "FCUBSAccFinService",
        "fcub:OPERATION" => "RequestAccStmt",
        "fcub:SOURCE_OPERATION" => "RequestAccStmt",
        "fcub:ADDL" => {
          "fcub:PARAM" => {
            "fcub:NAME" => "SERVERSTAT",
            "fcub:VALUE" => "HOST"
          }
        }
      },
      "fcub:FCUBS_BODY" => {
        "fcub:CustAccStmtAdhocRequest" => {
          "fcub:XREF" => "",
          "fcub:ACC" => account_number,
          "fcub:BRN" => branch_code,
          "fcub:FRMDT" => from_date,
          "fcub:TODT" => to_date,
          "fcub:STMTTYPE" => "S"
        }
      }
    }
  end
end