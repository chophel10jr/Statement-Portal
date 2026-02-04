# frozen_string_literal: true

class StatementMailer < ApplicationMailer
  def statement_generated(statement)
    @statement = statement
    mail(to: statement.email, subject: "Your Statement Has Been Generated")
  end

  def statement_failed(statement, error)
    @statement = statement
    @error = error
    mail(to: statement.email, subject: "Your Statement Request Failed")
  end
end
