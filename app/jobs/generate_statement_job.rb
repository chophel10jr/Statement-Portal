class GenerateStatementJob < ApplicationJob
  queue_as :default

  def perform(statement_id)
    statement = Statement.find(statement_id)

    return unless statement.pending?

    result = fetch_statement_from_core(statement)

    unless success?(result)
      return handle_failure(statement, result)
    end

    dcn = extract_dcn(result)
    statement_text = FetchStatementService.new(dcn: dcn).run
    binding.pry

    begin
      pdf_path = GeneratePdfService.new(
        statement_text: statement_text,
        pdf_password: generate_pdf_password(statement)
      ).run

      statement.update!(
        status: :generated,
        file_path: pdf_path,
        core_reference_id: dcn
      )

      # Send success email after PDF is generated
      StatementMailer
        .statement_generated(statement)
        .deliver_later
    rescue StandardError => e
      handle_failure(statement, error: e.message)
    end
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

  def success?(result)
    result.dig(
      :requestaccstmt_iofs_res,
      :fcubs_header,
      :msgstat
    ) == "SUCCESS"
  end

  def extract_dcn(result)
    result.dig(
      :requestaccstmt_iofs_res,
      :fcubs_body,
      :cust_acc_stmt_adhoc_request,
      :dcn
    )
  end

  def handle_failure(statement, error: "Unknown error")
    statement.update!(status: :failed)

    StatementMailer
      .statement_failed(statement, error)
      .deliver_later
  end

  def generate_pdf_password(statement)
    account_part = statement.account_number.to_s[-4, 4] || "2026"
    email_part = statement.email.to_s.split("@").first.ljust(4, "x")[0, 4] || "BNBL"

    "#{account_part}#{email_part}"
  end
end
