class CreateStatements < ActiveRecord::Migration[8.0]
  def change
    create_table :statements do |t|
      t.string :account_number
      t.string :phone_number
      t.string :email
      t.string :branch_code
      t.string :status, default: 'pending'
      t.string :file_path
      t.date :from_date
      t.date :to_date
      t.string :core_reference_id

      t.timestamps
    end
  end
end
