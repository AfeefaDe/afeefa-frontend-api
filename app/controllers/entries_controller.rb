require 'cache_builder' #TODO: could vanish any time, may be
require 'message_api/client' #TODO: could vanish any time, may be

class EntriesController < ApplicationController

  def create
    case params['marketentry']['type'].to_s
    when '0' #'orga'
      entry_class = Orga
      model_attributes = orga_params
    when '2' #'event'
      entry_class = Event
      model_attributes = event_params
    when '1' #'offer'
      entry_class = DataModules::Offer::Offer
      model_attributes = offer_params
    else
      render plain: 'only orgas and events are supported', status: :unprocessable_entity
      # prevent double rendering
      return
    end

    result =
      entry_class.create_via_frontend(
        model_attributes: model_attributes,
        contact_info_attributes: contact_info_params,
        location_attributes: location_params)
    model = result[:model]
    success = result[:success]

    if success
      response = MessageApi::Client.notify_for_new_entry(model: model)
      unless 201 == response.status
        generate_error_from_api(kind: 'new entry', message_from_api: response.body)
      end
      render plain: 'OK', status: :created
    else
      errors = ''
      errors << model.errors.full_messages.join("\n")
      if model.contacts.first.try(:errors)
        errors << model.contacts.first.errors.full_messages.join("\n")
      end
      if model.contacts.first && model.contacts.first.location.try(:errors)
        errors << model.locations.first.errors.full_messages.join("\n")
      end
      if errors.blank?
        errors = 'internal error'
        render plain: errors, status: :internal_server_error
      else
        render plain: errors, status: :unprocessable_entity
      end
    end
  end

  def contact_entry
    unless model = find_entry(type: contact_entry_params[:type], id: contact_entry_params[:id])
      render plain: 'invalid type', status: :unprocessable_entity
      return
    end
    response = MessageApi::Client.send_contact_message_for_entry(model: model, params: contact_entry_params.to_h)
    if 201 == response.status
      render plain: 'OK', status: :created
    else
      message = generate_error_from_api(kind: 'contact entry', message_from_api: response.body)
      render plain: message, status: :internal_server_error
    end
  end

  def feedback_entry
    unless model = find_entry(type: feedback_entry_params[:type], id: feedback_entry_params[:id])
      render plain: 'invalid type', status: :unprocessable_entity
      return
    end

    feedback_success = model.create_feedback(feedback_params: feedback_entry_params)

    response = MessageApi::Client.send_feedback_message_for_entry(model: model, params: feedback_entry_params.to_h)
    unless 201 == response.status
      generate_error_from_api(kind: 'feedback entry', message_from_api: response.body)
    end

    if feedback_success
      render plain: 'OK', status: :created
    else
      render plain: 'Could not create feedback for entry.', status: :internal_server_error
    end
  end

  private

  def find_entry(type:, id:)
    case type.to_s
    when 'orgas'
      Orga.find(id)
    when 'events'
      Event.find(id)
    else
      nil
    end
  end

  def generate_error_from_api(kind:, message_from_api: nil)
    message = "error during sending message for #{kind}"
    message << ': '
    message << message_from_api if message_from_api
    Rails.logger.warn(message)
    message
  end

  def contact_entry_params
    params.permit(:type, :id, :message, :author, :mail, :phone)
  end

  def feedback_entry_params
    params.permit(:type, :id, :message, :author, :mail, :phone)
  end

  def orga_params
    # params.permit(:title)
    map_marketentry_params(params.fetch(:marketentry, {}).permit!).
      except(:date_start, :date_end)
  end

  def event_params
    # params.permit(:title, :date_start, :date_end)
    map_marketentry_params(params.fetch(:marketentry, {}).permit!)
  end

  def offer_params
    map_marketentry_params(params.fetch(:marketentry, {}).permit!).
      except(:date_start, :date_end, :for_children, :support_wanted)
  end

  def map_marketentry_params(params)
    params.merge!(
      title: params.delete(:name),
      category: DataModules::FeNavigation::FeNavigationItem.find(params.delete(:category)),
      short_description: params.delete(:descriptionShort),
      for_children: params.delete(:forChildren),
      support_wanted: params.delete(:supportWanted),
      # support_wanted_detail: params.delete(:supportWanted),
      date_start:
        if params[:dateFrom] || params[:timeFrom]
          date = params[:dateFrom]
          time = params[:timeFrom]
          parse_date_time(date, time)
        end,
      date_end:
        if params[:dateTo] || params[:timeTo]
          date = params[:dateTo]
          time = params[:timeTo]
          parse_date_time(date, time, fallback_date: params[:dateFrom])
        end,
      # speaker_public: params.delete(:speakerPublic), → migrated to contact_person
      # parent_orga:
      #   if params[:parentOrga] && (orga = Orga.find_by(id: params[:parentOrga]))
      #     orga
      #   else
      #     Orga.root_orga
      #   end
      # for children, ...
    )
    if params[:date_start] && params[:date_start].strftime('%H:%M') != '00:00'
      params.merge!(time_start: true)
    end
    if params[:date_end] && params[:date_end].strftime('%H:%M') != '00:00'
      params.merge!(time_end: true)
    end

    params.slice(
      :title, :category, :short_description,
      :for_children, :support_wanted, :support_wanted_detail,
      :area,
      :date_start, :date_end,
      :time_start, :time_end,
    )
  end

  def contact_info_params
    contact_info_params = params.fetch(:marketentry, {}).permit!
    languages = contact_info_params.delete(:spokenLanguages)
    if languages.is_a?(Array)
      languages = languages.join(',')
    end
    contact_info_params.merge!(
      contact_person: contact_info_params.delete(:speakerPublic),
      social_media: contact_info_params.delete(:facebook),
      spoken_languages: languages,
    ).slice(
      :contact_person, :mail, :phone, :web, :social_media, :spoken_languages
    )
  end

  def location_params
    params.fetch(:location, {}).permit(:placename, :street, :zip, :city)
  end

  def render_data(locale, area)
    cache_file_path = File.join(CacheBuilder::CACHE_PATH, "entries-#{area}.json").to_s
    send_file cache_file_path, type: 'application/json', disposition: 'inline'
  end

  def parse_date_time(date, time, fallback_date: nil)
    zone = 'Berlin'
    # use fallback date (date from) if only end time given
    date = fallback_date if date.blank? && time.present?
    date_time = ActiveSupport::TimeZone[zone].parse("#{date} #{time}") rescue nil
    date = Date.parse("#{date}") rescue nil
    # time = Time.parse("#{time}") rescue nil
    date_time || date
  end

end
