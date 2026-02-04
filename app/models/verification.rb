# frozen_string_literal: true

class Verification < ApplicationRecord
  belongs_to :statement

  OTP_EXPIRY_MINUTES = 5
  MAX_ATTEMPTS = 3
  MAX_RESENDS = 3

  validates :statement_id, presence: true, uniqueness: true

  after_commit :send_otp, on: [:create, :update], if: :saved_change_to_otp_code?

  def generate_otp
    self.otp_code = SecureRandom.random_number(1000..9999).to_s
    self.otp_sent_at = Time.current
    self.attempts = 0
    self.verified = false
    save!
  end

  def send_otp
    if statement.email.present?
      OtpMailer.send_otp(statement.email, otp_code).deliver_later
    elsif statement.phone_number.present?
      message = "Your BNB statement request OTP is #{otp_code}. It expires in 5 minutes."
      SmsService.new(number: statement.phone_number, message: message).run
    end
  end

  def resend_otp
    return { success: false, error: "Maximum resend attempts (#{MAX_RESENDS}) reached" } unless can_resend_otp?

    generate_otp
    increment!(:otp_resend_count)
    
    { 
      success: true,
      message: "OTP has been resent",
      remaining_resends: MAX_RESENDS - otp_resend_count
    }
  end

  def verify(user_otp)
    return { success: false, error: "OTP expired", retry: false } if expired?
    return { success: false, error: "Too many attempts. Please request a new OTP.", retry: false } if attempts >= MAX_ATTEMPTS

    increment!(:attempts)

    if otp_code == user_otp
      update!(verified: true)
      { success: true }
    else
      remaining_attempts = MAX_ATTEMPTS - attempts
      { 
        success: false,
        error: "Invalid OTP. Please try again.",
        retry: true,
        remaining_attempts: remaining_attempts
      }
    end
  end

  private
  
  def can_resend_otp?
    otp_resend_count <= MAX_RESENDS
  end

  def expired?
    otp_sent_at.nil? || otp_sent_at < OTP_EXPIRY_MINUTES.minutes.ago
  end
end
