class FrontendCacheRebuildJob < ApplicationJob
  queue_as :default

  def perform(params)
    begin
      ActiveRecord::Base.transaction do # fail if one fails
        if params[:job_created].present?

          # delete jobs that run for longer than 3 min
          FapiCacheJob.running.where("started_at < ?", 3.minutes.ago).delete_all

          return if FapiCacheJob.running.any?
          return unless FapiCacheJob.not_started.any?

          next_job = FapiCacheJob.not_started.first
          process_job(next_job)
        end
      end
    end

    # next job
    FrontendCacheRebuildJob.perform_later(params)
  end

  private

  def process_job(job)
    job.update!(started_at: Time.now)

    # update all
    if !job.area && !job.entry && job.updated && job.translated
      cache_builder.build_all

    # update entry
    elsif job.entry && job.updated
      entry_type = job.entry.class.name.to_s.split('::').last.downcase.underscore
      cache_builder.update_entry(entry_type, job.entry.id)

    # translate entry
    elsif job.entry && job.translated && job.language
      entry_type = job.entry.class.name.to_s.split('::').last.downcase.underscore
      cache_builder.translate_entry(entry_type, job.entry.id, job.language)

    # delete entry
    elsif job.area && job.entry && job.deleted
      entry_type = job.entry.class.name.to_s.split('::').last.downcase.underscore
      cache_builder.remove_entry(job.area.title, entry_type, job.entry.id)

    # update all entries for area
    elsif job.area && job.updated
      cache_builder.build_entries_for_area(job.area.title)

    # update translation for area
    elsif job.area && job.translated && job.language
      cache_builder.translate_language_for_area(job.area.title, job.language)

    # update all translations for area
    elsif job.area && job.translated
      cache_builder.translate_area(job.area.title)
    end

    job.update!(finished_at: Time.now)
  end

  def cache_builder
    @cache_builder ||= CacheBuilder.new
  end

end
