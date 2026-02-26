# frozen_string_literal: true

class GenerateStatementJob < ApplicationJob
  queue_as :default

  retry_on ExternalServiceError, wait: 10.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(statement_id)
    statement = Statement.find(statement_id)
    return unless statement.ready_for_generation?

    result = fetch_statement_from_core(statement)
    unless core_success?(result)
      return fail_with(statement, result[:error])
    end

    dcn = extract_dcn(result)
    pdf_path = generate_pdf(statement, dcn)

    finalize_success!(statement, pdf_path, dcn)
  rescue ExternalServiceError, IOError => e
    log_error(statement_id, e)
    fail_with(statement, e.message)
  end

  private

  def fetch_statement_from_core(statement)
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

  def generate_pdf(statement, dcn)
    statement_text = FetchStatementService.new(dcn: dcn).run

    GeneratePdfService.new(
      statement_text: statement_text,
      pdf_password: pdf_password(statement)
    ).run
  end

  def finalize_success!(statement, pdf_path, dcn)
    Statement.transaction do
      statement.update!(
        status: :generated,
        file_path: pdf_path,
        core_reference_id: dcn
      )
    end

    StatementMailer.statement_generated(statement).deliver_later

    DeleteStatementPdfJob
      .set(wait: 5.days)
      .perform_later(pdf_path)
  end

  def fail_with(statement, error)
    Rails.logger.warn(
      "[GenerateStatementJob] statement_id=#{statement.id} failed: #{error}"
    )

    statement.update!(status: :failed)

    StatementMailer
      .statement_failed(statement, error)
      .deliver_later
  end

  def pdf_password(statement)
    account_part = statement.account_number.to_s.last(4)
    email_part = statement.email.to_s.split("@").first.to_s.first(4).ljust(4, "x")

    "#{account_part}#{email_part}"
  end

  def log_error(statement_id, error)
    Rails.logger.error(
      "[GenerateStatementJob] statement_id=#{statement_id} error=#{error.message}"
    )
  end
end
