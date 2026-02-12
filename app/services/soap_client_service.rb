# frozen_string_literal: true

class SoapClientService < ApplicationService
  attr_reader :account_number, :branch_code, :from_date, :to_date

  def initialize(account_number:, branch_code:, from_date:, to_date:)
    @account_number = account_number
    @branch_code = branch_code
    @from_date = from_date
    @to_date = to_date

    @client = Savon.client(
      wsdl: ENV.fetch('SOAP_LINK'),
      log: Rails.env.development?,
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
    response = @client.call(:request_acc_stmt_io, message: build_message)
    response.body
  rescue Savon::SOAPFault => e
    handle_error("SOAP Fault", e)
  rescue Savon::Error => e
    handle_error("SOAP Request Failed", e)
  end

  private

  def build_message
    {
      "fcub:FCUBS_HEADER" => fcubs_header,
      "fcub:FCUBS_BODY"   => fcubs_body
    }
  end

  def fcubs_header
    {
      "fcub:SOURCE"           => ENV.fetch('SOAP_SOURCE', 'FCAT'),
      "fcub:UBSCOMP"          => "FCUBS",
      "fcub:MSGID"            => "",
      "fcub:CORRELID"         => "",
      "fcub:USERID"           => ENV.fetch('SOAP_USERID', 'FCATOP'),
      "fcub:BRANCH"           => branch_code,
      "fcub:SERVICE"          => "FCUBSAccFinService",
      "fcub:OPERATION"        => "RequestAccStmt",
      "fcub:SOURCE_OPERATION" => "RequestAccStmt",
      "fcub:ADDL"             => {
        "fcub:PARAM" => {
          "fcub:NAME"  => "SERVERSTAT",
          "fcub:VALUE" => "HOST"
        }
      }
    }
  end

  def fcubs_body
    {
      "fcub:CustAccStmtAdhocRequest" => {
        "fcub:XREF"      => "",
        "fcub:ACC"       => account_number,
        "fcub:BRN"       => branch_code,
        "fcub:FRMDT"     => format_date(from_date),
        "fcub:TODT"      => format_date(to_date),
        "fcub:STMTTYPE"  => "S"
      }
    }
  end

  def format_date(date)
    date.respond_to?(:strftime) ? date.strftime("%Y-%m-%d") : date.to_s
  end

  def handle_error(prefix, error)
    Rails.logger.error("[SoapClientService] #{prefix}: #{error.message}")
    raise ExternalServiceError, "#{prefix}: #{error.message}"
  end
end
