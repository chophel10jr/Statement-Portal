# frozen_string_literal: true

class StatementRequest < ApplicationRecord
  TOKEN_TTL = 15.minutes

  has_one :statement, dependent: :destroy
  has_one :verification, through: :statement

  before_validation :generate_public_token, on: :create
  before_validation :set_token_expiry, on: :create

  enum :status, {
    pending: "pending",
    otp_pending: "otp_pending",
    failed: "failed",
    completed: "completed"
  }

  validates :public_token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def expired?
    expires_at.nil? || expires_at <= Time.current
  end

  def active?
    !expired?
  end

  private

  def generate_public_token
    self.public_token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_token_expiry
    self.expires_at ||= TOKEN_TTL.from_now
  end
end
