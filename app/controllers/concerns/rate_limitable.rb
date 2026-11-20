# app/controllers/concerns/rate_limitable.rb
module RateLimitable
  extend ActiveSupport::Concern

  private

  def handle_rate_limit(redirect_path: root_path, message: "Too many requests. Please wait a moment and try again.", retry_after: 60)
    response.set_header("Retry-After", retry_after.to_s)

    respond_to do |format|
      format.json do
        render json: { error: message, retry_after: retry_after }, status: :too_many_requests
      end
      format.any do
        render plain: message, status: :too_many_requests
      end
    end
  end
end