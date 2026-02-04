class CreateVerifications < ActiveRecord::Migration[8.0]
  def change
    create_table :verifications do |t|
      t.string :otp_code
      t.datetime :otp_sent_at
      t.integer :attempts, default: 0
      t.integer :otp_resend_count, default: 0
      t.boolean :verified
      t.references :statement, null: false, foreign_key: true

      t.timestamps
    end
  end
end
