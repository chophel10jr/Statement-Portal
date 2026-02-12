# frozen_string_literal: true

class GenerateStatementJob < ApplicationJob
  queue_as :default

  retry_on ExternalServiceError, wait: 10.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(statement_id)
    @statement = Statement.find(statement_id)
    return unless @statement.ready_for_generation?

    core_result = fetch_statement_from_core
    return fail_with(core_result[:error]) unless core_success?(core_result)

    dcn = extract_dcn(core_result)
    generate_and_finalize_statement(dcn)
  end

  private

  attr_reader :statement

  def fetch_statement_from_core
    SoapClientService.new(
      account_number: statement.account_number,
      branch_code: statement.branch_code,
      from_date: statement.from_date,
      to_date: statement.to_date
    ).run
  end

  def core_success?(result)
    result.dig(:requestaccstmt_iofs_res, :fcubs_header, :msgstat) == "SUCCESS"
  end

  def extract_dcn(result)
    result.dig(
      :requestaccstmt_iofs_res,
      :fcubs_body,
      :cust_acc_stmt_adhoc_request,
      :dcn
    )
  end

  def generate_and_finalize_statement(dcn)
    statement_text = FetchStatementService.new(dcn: dcn).run

    pdf_path = GeneratePdfService.new(
      statement_text: statement_text,
      pdf_password: pdf_password
    ).run
    binding.pry

    finalize_success!(pdf_path, dcn)
  rescue ExternalServiceError, IOError => e
    log_error(e)
    fail_with(e.message)
  end

  def finalize_success!(pdf_path, dcn)
    Statement.transaction do
      statement.update!(
        status: :generated,
        file_path: pdf_path,
        core_reference_id: dcn
      )
    end

    StatementMailer.statement_generated(statement).deliver_later
  end

  def fail_with(error)
    statement.update!(status: :failed)
    StatementMailer.statement_failed(statement, error).deliver_later
  end

  def pdf_password
    account_part = statement.account_number.to_s.last(4)
    email_part = statement.email.to_s.split("@").first.to_s[0, 4].ljust(4, "x")

    "#{account_part}#{email_part}"
  end

  def log_error(error)
    Rails.logger.error(
      "[GenerateStatementJob] Statement##{statement.id}: #{error.message}"
    )
  end
end
