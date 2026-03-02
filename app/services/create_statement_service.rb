# frozen_string_literal: true

class CreateStatementService < ApplicationService
  attr_accessor :statement_params

  def run
    ActiveRecord::Base.transaction do
      account_detail = fetch_account_detail!
      statement      = create_statement!(account_detail)
      create_verification!(statement)

      statement
    end
  end

  private

  def fetch_account_detail!
    account_detail =
      FetchAccountDetailService
        .new(account_number: statement_params[:account_number])
        .run
    raise ExternalServiceError, "You don't have an account with BNB." unless account_detail.present?

    account_detail
  end

  def create_statement!(account_detail)
    Statement.create!(
      @statement_params.merge(
        branch_code:  account_detail["BRANCH_CODE"],
        email:        account_detail["E_MAIL"],
        phone_number: account_detail["MOBILE"]
      )
    )
  end

  def create_verification!(statement)
    verification = statement.create_verification!
    verification.generate_otp
  end
end
