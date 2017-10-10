class ChangeController < ApplicationController

  before_action :ensure_token

  def update
    render json: { token: Settings.changes.webhook_api_token }
  end

  private
      def ensure_token
        if params.blank? || params[:token].blank? || params[:token] != Settings.changes.webhook_api_token
          head :unauthorized
          return
        end
      end
  end
