require 'test_helper'

class FrontendCacheRebuildJobTest < ActionController::TestCase

  it 'should process job' do
    orga = create(:orga)

    job = FapiCacheJob.create(
      area: Area.find_by(title: 'dresden'),
      entry: orga,
      translated: true,
      language: 'fr'
    )

    assert_nil job.started_at
    assert_nil job.finished_at

    CacheBuilder.any_instance.expects(:translate_entry).with('orga', orga.id, 'fr')

    perform_enqueued_jobs do
      FrontendCacheRebuildJob.perform_later(job_created: true)
    end

    job.reload
    assert_not_nil job.started_at
    assert_not_nil job.finished_at
  end

  it 'should process jobs one by one' do
    orga = create(:orga)

    FapiCacheJob.create!(
      area: Area.find_by(title: 'dresden'),
      entry: orga,
      translated: true,
      language: 'de'
    )

    FapiCacheJob.create!(
      area: Area.find_by(title: 'dresden'),
      updated: true
    )

    FapiCacheJob.create!(
      area: Area.find_by(title: 'dresden'),
      translated: true,
      language: 'de'
    )

    assert_equal 3, FapiCacheJob.count
    assert_equal 3, FapiCacheJob.not_started.count
    assert_equal 0, FapiCacheJob.running.count
    assert_equal 0, FapiCacheJob.finished.count

    CacheBuilder.any_instance.expects(:translate_entry).with('orga', orga.id, 'de')
    CacheBuilder.any_instance.expects(:build_entries_for_area).with('dresden')
    CacheBuilder.any_instance.expects(:translate_language_for_area).with('dresden', 'de')

    perform_enqueued_jobs do
      FrontendCacheRebuildJob.perform_later(job_created: true)
    end

    assert_equal 0, FapiCacheJob.not_started.count
    assert_equal 0, FapiCacheJob.running.count
    assert_equal 3, FapiCacheJob.finished.count
  end

  it 'should remove old running jobs' do
    FapiCacheJob.create!(
      translated: true,
      updated: true,
      started_at: 10.minutes.ago,
      finished_at: 8.minutes.ago
    )

    FapiCacheJob.create!(
      translated: true,
      updated: true,
      started_at: 5.minutes.ago
    )

    FapiCacheJob.create!(
      translated: true,
      updated: true
    )

    FapiCacheJob.create!(
      translated: true,
      updated: true
    )

    assert_equal 2, FapiCacheJob.not_started.count
    assert_equal 1, FapiCacheJob.running.count
    assert_equal 1, FapiCacheJob.finished.count

    perform_enqueued_jobs do
      FrontendCacheRebuildJob.perform_later(job_created: true)
    end

    assert_equal 0, FapiCacheJob.not_started.count
    assert_equal 0, FapiCacheJob.running.count
    assert_equal 3, FapiCacheJob.finished.count
  end

  it 'rollbacks on error' do
    job = FapiCacheJob.create!(
      translated: true,
      updated: true
    )

    perform_enqueued_jobs do
      FrontendCacheRebuildJob.perform_later(job_created: true)
    end

    job.reload
    assert_not_nil job.created_at
    assert_not_nil job.started_at
    assert_not_nil job.finished_at

    job2 = FapiCacheJob.create!(
      translated: true,
      updated: true
    )

    CacheBuilder.any_instance.stubs(:build_all).with(any_parameters).raises(StandardError)

    exception = assert_raises(StandardError) {
      perform_enqueued_jobs do
        FrontendCacheRebuildJob.perform_later(job_created: true)
      end
    }
    assert_match 'StandardError', exception.message

    job2.reload
    assert_not_nil job2.created_at
    assert_nil job2.started_at
    assert_nil job2.finished_at
  end

  it 'should process update_all job' do
    FapiCacheJob.create!(
      translated: true,
      updated: true
    )

    CacheBuilder.any_instance.expects(:build_all)

    perform_enqueued_jobs do
      FrontendCacheRebuildJob.perform_later(job_created: true)
    end
  end

  it 'should not run multipe times if multipe times notified' do
    FapiCacheJob.create!(
      translated: true,
      updated: true
    )

    CacheBuilder.any_instance.expects(:build_all).once

    perform_enqueued_jobs do
      FrontendCacheRebuildJob.perform_later(job_created: true)
      FrontendCacheRebuildJob.perform_later(job_created: true)
      FrontendCacheRebuildJob.perform_later(job_created: true)
      FrontendCacheRebuildJob.perform_now(job_created: true)
      FrontendCacheRebuildJob.perform_now(job_created: true)
      FrontendCacheRebuildJob.perform_now(job_created: true)
    end
  end

  it 'should process update_entry job' do
    orga = create(:orga)

    FapiCacheJob.create!(
      entry: orga,
      updated: true
    )

    CacheBuilder.any_instance.expects(:update_entry).with('orga', orga.id)

    perform_enqueued_jobs do
      FrontendCacheRebuildJob.perform_later(job_created: true)
    end
  end

  it 'should process translate_entry job' do
    orga = create(:orga)

    FapiCacheJob.create!(
      entry: orga,
      translated: true,
      language: 'du'
    )

    CacheBuilder.any_instance.expects(:translate_entry).with('orga', orga.id, 'du')

    perform_enqueued_jobs do
      FrontendCacheRebuildJob.perform_later(job_created: true)
    end
  end

  it 'should process remove_entry job' do
    orga = create(:orga)

    FapiCacheJob.create!(
      area: Area.find_by(title: 'dresden'),
      entry: orga,
      deleted: true
    )

    CacheBuilder.any_instance.expects(:remove_entry).with('dresden', 'orga', orga.id)

    perform_enqueued_jobs do
      FrontendCacheRebuildJob.perform_later(job_created: true)
    end
  end

  it 'should process build_entries_for_area job' do
    orga = create(:orga)

    FapiCacheJob.create!(
      area: Area.find_by(title: 'dresden'),
      updated: true
    )

    CacheBuilder.any_instance.expects(:build_entries_for_area).with('dresden')

    perform_enqueued_jobs do
      FrontendCacheRebuildJob.perform_later(job_created: true)
    end
  end

  it 'should process translate_language_for_area job' do
    orga = create(:orga)

    FapiCacheJob.create!(
      area: Area.find_by(title: 'dresden'),
      translated: true,
      language: 'fa'
    )

    CacheBuilder.any_instance.expects(:translate_language_for_area).with('dresden', 'fa')

    perform_enqueued_jobs do
      FrontendCacheRebuildJob.perform_later(job_created: true)
    end
  end

  it 'should process translate_area job' do
    orga = create(:orga)

    FapiCacheJob.create!(
      area: Area.find_by(title: 'dresden'),
      translated: true
    )

    CacheBuilder.any_instance.expects(:translate_area).with('dresden')

    perform_enqueued_jobs do
      FrontendCacheRebuildJob.perform_later(job_created: true)
    end
  end
end