class TranslationCacheHandler

  DEFAULT_LOCALE = 'de'
  SUPPORTED_LOCALES = %w(ar de en es fa fr ku ps ru sq sr ti tr ur)
  CACHE_PATH = Rails.root.join('public', 'cache')

  def self.valid_cache?(languages: nil)
    languages = [languages || SUPPORTED_LOCALES].flatten

    languages.each do |language|

    end
  end

end
