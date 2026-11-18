# frozen_string_literal: true

class StatementController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid, ArgumentError,
              with: :handle_invalid_request
  rescue_from ExternalServiceError,
              with: :handle_external_service_error

  GENERIC_NOTICE = "If your request is eligible, you will receive an OTP and verification link at your registered email address."

  def new; end

  def create
    CreateStatementService.new(statement_params).run

    redirect_to root_path, notice: GENERIC_NOTICE
  end

  def show
    file = statement_file(params[:filename], params[:format])

    unless File.exist?(file)
      return render plain: "Statement no longer available",
                    status: :gone
    end

    send_file file,
              type: "application/pdf",
              disposition: "inline"
  end

  private

  def handle_invalid_request(exception)
    log_invalid_request(exception)

    redirect_to new_statement_path, notice: GENERIC_NOTICE
  end

  def handle_external_service_error(exception)
    Rails.logger.error(
      "Statement service error: #{exception.class} - #{exception.message}"
    )

    redirect_to new_statement_path, notice: GENERIC_NOTICE
  end

  def log_invalid_request(exception)
    if exception.respond_to?(:record)
      Rails.logger.warn(
        "Statement validation errors: #{exception.record.errors.full_messages}"
      )
    else
      Rails.logger.warn("Invalid request: #{exception.message}")
    end
  end

  def statement_params
    params.require(:statement).permit(
      :account_number,
      :from_date,
      :to_date
    )
  end

  def statement_file(filename, format)
    safe_name = File.basename(filename.to_s)
    safe_name += ".#{format}" if format.present?

    Rails.root.join("storage", "statements", safe_name)
  end
end
