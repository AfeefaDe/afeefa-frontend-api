class EntriesController < ApplicationController

  def index
    area =
      if params['area'].present? && ['leipzig', 'bautzen'].include?(params['area'])
        params['area']
      else
        'dresden'
      end

    locale =
      if params['locale'].present? && Translation::TRANSLATABLE_LOCALES.include?(params['locale'])
        params['locale']
      else
        Translation::DEFAULT_LOCALE
      end

    render_data(locale, area)
  end

  def create
    model = nil

    case params[:type].to_s
      when 'orga'
        model = Orga.new(orga_params)
      when 'event'
        model = Event.new(event_params)
      else
        render plain: 'only orgas and events are supported', status: :unprocessable_entity
        # prevent double rendering
        return
    end

    model.parent_orga = Orga.root_orga
    model.state = :inactive

    unless model.valid?
      title_modified = false
      tries = 1
      while model.errors[:title].any? && (messages = model.errors[:title].join("\n")) &&
          messages.include?('bereits vergeben') && (tries += 1) <= 10
        title_modified = true
        model.title << "_#{Time.current.to_i}"
        model.valid?
      end
      if title_modified
        annotation_category = AnnotationCategory.find_by(title: 'Titel ist bereits vergeben')
        Annotation.create(entry: model, annotation_category: annotation_category,
          detail: annotation_category.title)
      end
    end

    if model.save
      render plain: 'OK', status: :created
    else
      render plain: model.errors.full_messages.join("\n").presence || 'internal error',
        status: :unprocessable_entity
    end
  end

  private

  def orga_params
    params.permit(:title)
  end

  def event_params
    params.permit(:title, :date_start, :date_end)
  end

  def render_data(locale, area)
    cache_file_path = File.join(CacheBuilder::CACHE_PATH, "#{area}-#{locale}.json").to_s
    send_file cache_file_path, type: 'application/json', disposition: 'inline'
  end

end
