class FrontendCacheRebuildJob < ApplicationJob
  queue_as :default

  def perform(params)
    # translate an entry
    # type, id, locale, !deleted
    if params[:type].present? && params[:id].present? && params[:locale].present? && params[:deleted].blank?
      cache_builder.translate_entry(params[:type], params[:id], params[:locale])
    end

    # update an entry
    # type, id, !locale, !deleted
    if params[:type].present? && params[:id].present? && params[:locale].blank? && params[:deleted].blank?
      cache_builder.update_entry(params[:type], params[:id])
    end

    # remove an entry
    # type, id, !locale, deleted
    if params[:type].present? && params[:id].present? && params[:locale].blank? && params[:deleted].present?
      cache_builder.remove_entry(params[:area], params[:type], params[:id])
    end

    # rebuild entire cache
    # !type, !id, !locale, !deleted
    if params[:type].blank? && params[:id].blank? && params[:locale].blank? && params[:deleted].blank?
      cache_builder.build_all
    end
  end

  private

  def cache_builder
    @cache_builder ||= CacheBuilder.new
  end

end
