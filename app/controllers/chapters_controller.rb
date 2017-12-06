require 'http'

class ChaptersController < ApplicationController

  # respond_to :json

  # before_action :authenticate_api_v1_user!

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do
    head :unprocessable_entity
  end

  def initialize
    super
    @api_path = Settings.chapters_api_path || 'http://localhost:3010/chapters'
  end

  def index
    response = HTTP.get(@api_path)
    render status: response.status, json: response.body.to_s
  end

  def show
    response = HTTP.get("#{@api_path}/#{params[:id]}")
    render status: response.status, json: response.body.to_s
  end

end
