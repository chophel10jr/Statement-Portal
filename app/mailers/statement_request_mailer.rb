# frozen_string_literal: true

class StatementRequestMailer < ApplicationMailer
  def pending_request(email)
    mail(
      to: email,
      subject: "Statement Request Already in Progress"
    )
  end

  def request_limit_reached(email, remaining_time)
    @remaining_time = remaining_time

    mail(
      to: email,
      subject: "Statement Request Limit"
    )
  end
end
