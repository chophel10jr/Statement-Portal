class OtpMailer < ApplicationMailer
  def send_otp(verification)
    @verification = verification
    @otp = verification.otp_code

    statement_request = verification.statement.statement_request

    @verification_url = verify_otp_form_verification_index_url(
      token: statement_request.public_token
    )

    mail(
      to: verification.statement.email,
      subject: "Statement Request Verification"
    )
  end
end
