# frozen_string_literal: true

class StatementController < ApplicationController
  def new; end

  def create
    statement = CreateStatementService
                  .new(statement_params: statement_params)
                  .run

    redirect_to(
      verify_otp_verification_index_path(id: statement.verification.id),
      notice: "OTP sent to your registered email/phone."
    )

  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :new, status: :unprocessable_entity

  rescue ExternalServiceError, ArgumentError => e
    redirect_to root_path, alert: e.message
  end

  def show
    file = statement_file(params[:filename], params[:format])

    unless File.exist?(file)
      return render plain: "Statement no longer available", status: :gone
    end

    send_file file, type: "application/pdf", disposition: "inline"
  end

  private

  def statement_params
    params.require(:statement).permit(:account_number, :from_date, :to_date)
  end

  def statement_file(filename, format)
    safe_name = File.basename(filename.to_s)
    safe_name += ".#{format}" if format.present?

    Rails.root.join("storage", "statements", safe_name)
  end
end
