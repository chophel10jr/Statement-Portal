class AddStatementRequestReferencesToStatementsAndVerifications < ActiveRecord::Migration[8.0]
  def change
    add_reference :statements, :statement_request, foreign_key: true
    add_reference :verifications, :statement_request, foreign_key: true
  end
end
