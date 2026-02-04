# frozen_string_literal: true

class VerificationController < ApplicationController
  before_action :set_verification
  before_action :set_statement
  before_action :ensure_not_verified, only: %i[verify_otp_form verify_otp resend_otp]

  def verify_otp_form
  end

  def verify_otp
    result = @verification.verify(params[:otp])

    if result[:success]
      GenerateStatementJob.perform_later(@statement.id)
      redirect_with_notice("Your statement is being generated and will be shared soon.")
    else
      flash[:alert] = result[:error]
      redirect_to verify_otp_verification_index_path(id: @verification.id)
    end
  end

  def resend_otp
    result = @verification.resend_otp

    flash[result[:success] ? :notice : :alert] =
      result[:success] ? result[:message] : result[:error]

    redirect_to verify_otp_verification_index_path(id: @verification.id)
  end

  private

  def set_verification
    @verification = Verification.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_with_alert("Verification not found.")
  end

  def set_statement
    @statement = @verification.statement
    redirect_with_alert("Statement not found.") unless @statement
  end

  def ensure_not_verified
    return unless @verification.verified?

    redirect_with_notice("This account has already been verified.")
  end

  def redirect_with_alert(message)
    flash[:alert] = message
    redirect_to root_path
  end

  def redirect_with_notice(message)
    flash[:notice] = message
    redirect_to root_path
  end
end
