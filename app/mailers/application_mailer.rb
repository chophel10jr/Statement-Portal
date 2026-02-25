# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "bnb@bnb.bt"
  layout "mailer"
end
