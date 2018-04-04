require 'message_api/client' #TODO: could vanish any time, may be

class FeedbacksController < ApplicationController

  def general_feedback
    response = MessageApi::Client.send_general_feedback(params: general_feedback_params.to_h)
    if 201 == response.status
      render plain: 'OK', status: :created
    else
      message = generate_error_from_api(kind: 'general feedback', message_from_api: response.body)
      render plain: message, status: :internal_server_error
    end
  end

  private

  def generate_error_from_api(kind:, message_from_api: nil)
    message = "error during sending message for #{kind}"
    message << ': '
    message << message_from_api if message_from_api
    Rails.logger.warn(message)
    message
  end

  def general_feedback_params
    params.permit(:area, :message, :author, :mail)
  end

end
