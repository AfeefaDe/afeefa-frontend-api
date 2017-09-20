require 'test_helper'

class TranslationCacheMetaDatumTest < ActiveSupport::TestCase

  test 'validate cache timestamp' do
    FileUtils.rm_rf(TranslationCacheMetaDatum::CACHE_PATH)
    TranslationCacheMetaDatum.delete_all
    locale = 'en'
    Timecop.travel 1.second.ago do
      init_translation_cache(locale)
    end

    meta = TranslationCacheMetaDatum.new(locale: locale)
    assert_not meta.cache_valid?

    assert meta.save
    # stub json file is available
    TranslationCacheMetaDatum.any_instance.stubs(:cached_file_available?).returns(true)
    assert meta.reload.cache_valid?, cache_validation_output(meta)

    Timecop.travel 1.second.from_now do
      assert meta.reload.cache_valid?
    end

    new_datetime = 1.year.from_now
    assert TranslationCache.where(language: locale).update_all(updated_at: new_datetime)
    assert_not meta.cache_valid?, cache_validation_output(meta)

    assert meta.update(updated_at: new_datetime + 1.second)
    assert meta.cache_valid?, cache_validation_output(meta)

    # stub json file is not available
    TranslationCacheMetaDatum.any_instance.stubs(:cached_file_available?).returns(false)
    assert_not meta.cache_valid?, cache_validation_output(meta)
  end

end
