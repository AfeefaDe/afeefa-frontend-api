class ApplicationController < ActionController::API

  def index
    area =
      if params['area'].present? && ['leipzig', 'bautzen', 'leipzig-landkreis'].include?(params['area'])
        params['area']
      else
        'dresden'
      end

    locale =
      if params['locale'].present? &&
        Translation::TRANSLATABLE_LOCALES.include?(params['locale'])
        params['locale']
      else
        Translation::DEFAULT_LOCALE
      end

    render_data(locale, area)
  end

  def render_data(locale, area)
    raise ActiveRecord::RecordNotFound
  end

end
