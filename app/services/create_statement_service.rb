# frozen_string_literal: true

class CreateStatementService < ApplicationService
  def initialize(statement_params)
    @statement_params = statement_params.to_h.symbolize_keys
  end

  def run
    account_detail = fetch_account_detail
    return create_failed_request if account_detail.blank?

    ActiveRecord::Base.transaction do
      statement_request = StatementRequest.create!(status: :otp_pending)
      statement = create_statement!(statement_request, account_detail)
      initiate_verification!(statement)
    end
  end

  private

  attr_reader :statement_params

  def fetch_account_detail
    FetchAccountDetailService
      .new(account_number: statement_params[:account_number])
      .run
  end

  def create_failed_request
    StatementRequest.create!(status: :failed)
  end

  def create_statement!(request, account_detail)
    request.create_statement!(
      statement_params.merge(
        branch_code: account_detail["BRANCH_CODE"],
        email: account_detail["E_MAIL"],
        phone_number: account_detail["MOBILE"],
        status: :pending
      )
    )
  end

  def initiate_verification!(statement)
    verification = statement.create_verification!
    verification.generate_otp
  end
end
