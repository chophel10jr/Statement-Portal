# frozen_string_literal: true

class OtpMailer < ApplicationMailer
  def send_otp(email, otp)
    @otp = otp
    mail(to: email, subject: "OTP for Statement Request")
  end
end
