# frozen_string_literal: true

class StatementMailer < ApplicationMailer
  def statement_generated(statement)
    @statement = statement

    filename = File.basename(statement.file_path)

    @statement_url = statement_url(
      filename: filename,
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )

    mail(
      to: statement.email,
      subject: "Your Statement Has Been Generated"
    )
  end

  def statement_failed(statement, error)
    @statement = statement
    @error = error

    mail(
      to: statement.email,
      subject: "Your Statement Request Failed"
    )
  end
end
