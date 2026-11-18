
# frozen_string_literal: true

class Verification < ApplicationRecord
  belongs_to :statement

  OTP_EXPIRY_MINUTES = 5
  MAX_ATTEMPTS = 3
  MAX_RESENDS = 3

  validates :statement_id, presence: true, uniqueness: true

  after_commit :send_otp, on: [:create, :update],
                          if: :saved_change_to_otp_code?

  def generate_otp
    return false unless request_active?
    return false unless statement.pending?
    return false if verified?

    self.otp_code = SecureRandom.random_number(1000..9999).to_s
    self.otp_sent_at = Time.current
    self.attempts = 0

    save!
  end

  def send_otp
    return unless request_active?
    return if verified?
    return unless statement.email.present?

    OtpMailer.send_otp(self).deliver_later
  end

  def resend_otp
    return { success: false } unless request_active?
    return { success: false } unless can_resend_otp?
    return { success: false } if verified?

    return { success: false } unless generate_otp

    increment!(:otp_resend_count)

    { success: true }
  end

  def verify(user_otp)
    return { success: false } unless request_active?
    return { success: false } unless statement.pending?
    return { success: false } if verified?
    return { success: false } if expired?
    return { success: false } if attempts >= MAX_ATTEMPTS

    increment!(:attempts)

    if ActiveSupport::SecurityUtils.secure_compare(
      otp_code.to_s,
      user_otp.to_s
    )
      complete_verification
    else
      { success: false }
    end
  end

  private

  def request_active?
    request = statement&.statement_request

    request.present? && !request.expired?
  end

  def complete_verification
    statement_request = statement.statement_request

    transaction do
      update!(verified: true)
      statement_request.update!(status: "completed")
    end

    { success: true }
  end

  def can_resend_otp?
    otp_resend_count < MAX_RESENDS
  end

  def expired?
    otp_sent_at.nil? ||
      otp_sent_at < OTP_EXPIRY_MINUTES.minutes.ago
  end
end
