ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def init_translation_cache(locale)
    assert TranslationCache.where(language: locale).delete_all

    orga = Orga.new(state: :active)
    assert orga.save, orga.errors.messages
    translation = TranslationCache.new(language: locale, cacheable: orga)
    assert translation.save, translation.errors.messages
    assert_equal orga, Orga.last
    assert_equal translation, TranslationCache.where(language: locale).last
    translation
  end

end
