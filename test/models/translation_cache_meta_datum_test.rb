require 'test_helper'

class TranslationCacheMetaDatumTest < ActiveSupport::TestCase

  test 'validate cache timestamp' do
    FileUtils.rm_rf(TranslationCacheMetaDatum::CACHE_PATH)
    TranslationCacheMetaDatum.delete_all
    translation = init_translation_cache('de')

    meta = TranslationCacheMetaDatum.new(locale: 'de')
    assert_not meta.cache_valid?
    assert_not TranslationCacheMetaDatum.cache_valid?('de')

    assert meta.save
    assert meta.reload.cache_valid?
    assert TranslationCacheMetaDatum.cache_valid?('de'),
      "#{meta.updated_at.to_i} | #{TranslationCacheMetaDatum.where(locale: 'de').maximum(:updated_at).to_i}"

    sleep 0.1
    assert meta.reload.cache_valid?
    assert TranslationCacheMetaDatum.cache_valid?('de')

    new_datetime = 1.year.from_now
    assert translation.update(updated_at: new_datetime)
    assert_not meta.cache_valid?
    assert_not TranslationCacheMetaDatum.cache_valid?('de')

    assert meta.update(updated_at: new_datetime)
    assert meta.cache_valid?
    assert TranslationCacheMetaDatum.cache_valid?('de')
  end

end
