class ChangeController < ApplicationController

  before_action :ensure_token

  def update
    permitted_params = params.permit(:type, :id, :locale, :deleted, :area)
    FrontendCacheRebuildJob.perform_later(permitted_params.to_h)
    render json: { status: 'ok' }, status: :ok
  end

  private
      def ensure_token
        if params.blank? || params[:token].blank? || params[:token] != Settings.changes.webhook_api_token
          head :unauthorized
          return
        end
      end
  end
