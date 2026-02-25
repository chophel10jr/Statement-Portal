# app/jobs/delete_statement_pdf_job.rb
class DeleteStatementPdfJob < ApplicationJob
  queue_as :default

  def perform(file_path)
    return if file_path.blank?

    if File.exist?(file_path)
      File.delete(file_path)
    end

    Statement.where(file_path: file_path).update_all(file_path: nil)
  end
end
