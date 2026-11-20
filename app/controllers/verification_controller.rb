# frozen_string_literal: true

class VerificationController < ApplicationController
  include RateLimitable

  rate_limit to: 15,
            within: 1.minute,
            name: "verification_by_ip",
            by: -> { request.remote_ip },
            only: %i[verify_otp resend_otp],
            with: -> { handle_rate_limit(redirect_path: root_path, retry_after: 60) }

  rate_limit to: 5,
            within: 5.minutes,
            name: "verification_verify_by_token",
            by: -> { params[:token].to_s.strip.presence || request.remote_ip },
            only: :verify_otp,
            with: -> { handle_rate_limit(redirect_path: root_path, message: "Too many verification attempts. Please request a new statement.", retry_after: 300) }

  rate_limit to: 3,
            within: 5.minutes,
            name: "verification_resend_by_token",
            by: -> { params[:token].to_s.strip.presence || request.remote_ip },
            only: :resend_otp,
            with: -> { handle_rate_limit(redirect_path: verify_otp_form_verification_index_path(token: params[:token]), message: "Please wait before requesting another OTP.", retry_after: 60) }

  before_action :set_statement_request
  before_action :set_verification
  before_action :ensure_request_active,
                only: %i[verify_otp_form verify_otp resend_otp]

  def verify_otp_form; end

  def verify_otp
    unless @verification
      return redirect_back_with_alert(
        "OTP verification failed. Invalid, expired, or 3 attempts exceeded."
      )
    end

    result = @verification.verify(otp_param)

    if result[:success]
      GenerateStatementJob.perform_later(@statement.id)

      redirect_with_notice(
        "Your statement is being generated and will be shared soon."
      )
    else
      redirect_back_with_alert(
        "OTP verification failed. Invalid, expired, or 3 attempts exceeded."
      )
    end
  end

  def resend_otp
    @verification&.resend_otp

    flash[:notice] =
      "If eligible and within the 3-resend limit, an OTP will be sent to your email."

    redirect_back_to_verification
  end

  private

  def set_statement_request
    @statement_request =
      StatementRequest.find_by(public_token: params[:token])

    if @statement_request.nil? || @statement_request.expired?
      redirect_to new_statement_path,
                  alert: "Invalid or expired request. Please try again."
    end
  end

  def set_verification
    return if performed?

    @statement = @statement_request.statement
    @verification = @statement_request.verification
  end

  def ensure_request_active
    return if performed?

    if @statement_request.expired?
      redirect_to root_path,
                  alert: "This request has expired. Please submit a new request."
      return
    end

    if @statement_request.status == "completed" || @statement_request.status == "failed" || @verification&.verified?
      redirect_to root_path,
                  notice: "This request has already been verified."
    end
  end

  def otp_param
    params.require(:otp)
  end

  def redirect_back_to_verification
    redirect_to verify_otp_form_verification_index_path(
      token: @statement_request.public_token
    )
  end

  def redirect_back_with_alert(message)
    flash[:alert] = message
    redirect_back_to_verification
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
