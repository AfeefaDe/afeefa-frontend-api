class EntriesController < ApplicationController

  DEFAULT_LOCALE = 'de'
  SUPPORTED_LOCALES = %w(ar en es fa fr ku ps ru sq sr ti tr ur)

  def index
    area = if params['area'].present? && ['leipzig', 'bautzen'].include?(params['area']) then params['area'] else 'dresden' end

    if !params['locale'].present? || (params['locale'].present? && params['locale'] == DEFAULT_LOCALE)
      orgas = get_entries(Orga, area)
      events = get_entries(Event, area)
    else
      if params['locale'].in?(SUPPORTED_LOCALES)
        orgas = get_entries(Orga, area, with_translations: true)
        events = get_entries(Event, area, with_translations: true)
      else
        raise 'locale is not supported'
      end
    end

    render(
        json: {
            marketentries: orgas + events
        },
        status: :ok,
        language: params['locale'] || DEFAULT_LOCALE
    )
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

  def get_entries(klazz, area, with_translations: false)
    entries =
        klazz.
            includes(:category, :sub_category, :locations, :contact_infos, :parent_orga, parent_orga: :contact_infos).
            where(state: 'active').
            where(area: area)
    if with_translations
      entries = entries.includes(:translation_caches)
    end
    entries
  end

  def orga_params
    params.permit(:title)
  end

  def event_params
    params.permit(:title, :date_start, :date_end)
  end

end
