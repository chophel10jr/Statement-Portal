class CreateStatementRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :statement_requests do |t|
      t.string :public_token, null: false
      t.string :status, default: "pending", null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :statement_requests, :public_token, unique: true
    add_index :statement_requests, :expires_at
  end
end
