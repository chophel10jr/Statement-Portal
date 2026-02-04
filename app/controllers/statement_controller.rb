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
      flash[:alert] = @statement.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def statement_params
    params.require(:statement).permit(:account_number, :from_date, :to_date)
  rescue ActionController::ParameterMissing
    params.permit(:account_number, :from_date, :to_date)
  end

  def fetch_account_detail
    acc_num = statement_params[:account_number]
    return if acc_num.blank?

    @account_detail = FetchAccountDetailService
                        .new(account_number: acc_num)
                        .run
  end

  def ensure_account_exists
    return if @account_detail.present?

    redirect_to root_path, alert: "You don't have an account with BNB."
  end

  def statement_attributes
    {
      account_number: statement_params[:account_number],
      branch_code: @account_detail['BRANCH_CODE'],
      email: @account_detail['E_MAIL'],
      phone_number: @account_detail['MOBILE'],
      from_date: statement_params[:from_date],
      to_date: statement_params[:to_date]
    }
  end

  def create_verification(statement)
    verification = @statement.create_verification
    verification.generate_otp
  end
end
