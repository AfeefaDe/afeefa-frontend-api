require 'cache_builder' #TODO: could vanish any time, may be

class EntriesController < ApplicationController

  def create
    case params['marketentry']['type'].to_s
    when '0' #'orga'
      entry_class = Orga
      model_attributes = orga_params
    when '2' #'event'
      entry_class = Event
      model_attributes = event_params
    else
      render plain: 'only orgas and events are supported', status: :unprocessable_entity
      # prevent double rendering
      return
    end

    result =
      entry_class.create_via_frontend(
        model_atrtibtues: model_attributes,
        contact_info_attributes: contact_info_params,
        location_attributes: location_params)
    model = result[:model]
    success = result[:success]

    if success
      render plain: 'OK', status: :created
    else
      errors = ''
      errors << model.errors.full_messages.join("\n")
      if model.locations.first.try(:errors)
        errors << model.locations.first.errors.full_messages.join("\n")
      end
      if model.contact_infos.first.try(:errors)
        errors << model.contact_infos.first.errors.full_messages.join("\n")
      end
      errors = 'internal error' if errors.blank?

      render plain: errors, status: :unprocessable_entity
    end
  end

  private

  def orga_params
    # params.permit(:title)
    map_marketentry_params(params.fetch(:marketentry, {}).permit!).
      except(:date_start, :date_end)
  end

  def event_params
    # params.permit(:title, :date_start, :date_end)
    map_marketentry_params(params.fetch(:marketentry, {}).permit!)
  end

  def map_marketentry_params(params)
    params.merge!(
      title: params.delete(:name),
      category_id: params.delete(:category),
      short_description: params.delete(:descriptionShort),
      for_children: params.delete(:forChildren),
      support_wanted: params.delete(:supportWanted),
      # support_wanted_detail: params.delete(:supportWanted),
      date_start:
        if params[:dateFrom] || params[:timeFrom]
          date = params.delete(:dateFrom)
          time = params.delete(:timeFrom)
          parse_date_time(date, time)
        end,
      date_end:
        if params[:dateTo] || params[:timeTo]
          date = params.delete(:dateTo)
          time = params.delete(:timeTo)
          parse_date_time(date, time)
        end,
      # speaker_public: params.delete(:speakerPublic), → migrated to contact_person
      # parent_orga:
      #   if params[:parentOrga] && (orga = Orga.find_by(id: params[:parentOrga]))
      #     orga
      #   else
      #     Orga.root_orga
      #   end
      # for children, ...
    ).slice(
      :title, :category, :short_description,
      :for_children, :support_wanted, :support_wanted_detail,
      :area,
      :date_start, :date_end, #:parent_orga
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
    cache_file_path = File.join(CacheBuilder::CACHE_PATH, "#{area}-#{locale}.json").to_s
    send_file cache_file_path, type: 'application/json', disposition: 'inline'
  end

  def parse_date_time(date, time)
    date_time = DateTime.parse("#{date} #{time}") rescue nil
    date = Date.parse("#{date}") rescue nil
    # time = Time.parse("#{time}") rescue nil
    date_time || date
  end

end
