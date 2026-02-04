# frozen_string_literal: true

class Statement < ApplicationRecord
  has_one :verification, dependent: :destroy

  enum :status, {
    pending: 'pending',
    generated: 'generated',
    sent: 'sent',
    failed: 'failed'
  }

  scope :by_account, ->(acc_no) { where(account_number: acc_no) }
  scope :latest_first, -> { order(created_at: :desc) }
  scope :pending_for_account, ->(acc_no) { by_account(acc_no).where(status: :pending) }

  def self.latest_for_account(acc_no)
    by_account(acc_no).latest_first.first
  end

  validates :account_number, presence: true
  validates :branch_code, presence: true
  validates :phone_number, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true
  validates :file_path, length: { maximum: 255 }, allow_blank: true

  validate :validate_date_range
  validate :prevent_pending_statement_overlap, on: :create
  validate :limit_one_request_per_day, on: :create

  private

  def validate_date_range
    if from_date.blank? || to_date.blank?
      errors.add(:base, "Start date and end date must be present")
      return
    end

    today = Date.current

    errors.add(:to_date, "must be after the start date") if to_date <= from_date
    errors.add(:from_date, "cannot be in the future") if from_date > today
    errors.add(:to_date, "cannot be in the future") if to_date > today
    errors.add(:to_date, "range cannot exceed 1 years") if to_date > from_date + 1.years
  end

  def prevent_pending_statement_overlap
    existing = Statement.pending_for_account(account_number)
    existing = existing.where.not(id: id) if persisted?

    if existing.exists?
      errors.add(:base, "A statement is already being processed for this account. Please wait until it completes.")
    end
  end

  def limit_one_request_per_day
    last = Statement.latest_for_account(account_number)
    return unless last.present?

    if last.created_at >= 1.day.ago
      errors.add(:base, "You can only request one statement per day for this account.")
    end
  end
end
