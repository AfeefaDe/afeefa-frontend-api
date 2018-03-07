require 'http'

module MessageApi::Client

  class << self
    def base_path
      Settings.message_api.path || 'http://localhost:3015'
    end

    def api_key
      Settings.message_api.key || 'test123'
    end

    def to(key)
      to = [
        Settings.message_api.templates.send(key).try(:to) || Settings.message_api.to
      ].flatten.compact.first
      Rails.logger.warn("could not find to for template #{key}") unless to
      to || 'team@afeefa.de'
    end

    def reply_to(key)
      reply_to = [
        Settings.message_api.templates.send(key).try(:reply_to) || Settings.message_api.reply_to
      ].flatten.compact.first || 'team@afeefa.de'
      Rails.logger.warn("could not find reply_to for template #{key}") unless reply_to
      reply_to || 'team@afeefa.de'
    end

    def backend_link(model)
      "#{Settings.backend_api.path}/#{model.class.name.underscore.pluralize}/#{model.id}/edit"
    end

    def notify_for_new_entry(model)
      params = {
        title: model.title,
        description: model.description,
        backend_link: backend_link(model)
      }
      payload = {
        key: api_key,
        to: to(:new_entry),
        reply_to: reply_to(:new_entry),
      }.merge(params || {})
      HTTP.post("#{base_path}/send/newEntryInfo",
        headers: { 'Content-Type' => 'application/json' },
        body: payload.to_json)
    end
  end

end
