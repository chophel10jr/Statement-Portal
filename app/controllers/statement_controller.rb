# frozen_string_literal: true

class StatementController < ApplicationController
  before_action :fetch_account_detail, only: :create
  before_action :ensure_account_exists, only: :create

  def new; end

  def create
    @statement = Statement.new(statement_attributes)

    if @statement.save
      verification = create_verification(@statement)
      redirect_to verify_otp_verification_index_path(id: verification.id),
                  notice: "OTP sent to your registered email/phone."
    else
      render :new,
             status: :unprocessable_entity,
             alert: @statement.errors.full_messages.to_sentence
    end
  end

  private

  def statement_params
    params.require(:statement).permit(:account_number, :from_date, :to_date)
  end

  def fetch_account_detail
    return if statement_params[:account_number].blank?

    @account_detail =
      FetchAccountDetailService
        .new(account_number: statement_params[:account_number])
        .run
  rescue ExternalServiceError => e
    redirect_to root_path, alert: e.message
  end

  def ensure_account_exists
    return if @account_detail.present?

    redirect_to root_path, alert: "You don't have an account with BNB."
  end

  def statement_attributes
    statement_params.merge(
      branch_code: @account_detail['BRANCH_CODE'],
      email: @account_detail['E_MAIL'],
      phone_number: @account_detail['MOBILE']
    )
  end

  def create_verification(statement)
    verification = statement.create_verification
    verification.generate_otp
    verification
  end
end
