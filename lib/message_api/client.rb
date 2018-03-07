require 'http'

module MessageApi::Client

  class << self
    def base_path
      Settings.message_api.path || 'http://localhost:3015'
    end

    def api_key
      Settings.message_api.key || 'test123'
    end

    def get_config(config:, key:, default: nil)
      value = [
        Settings.message_api.try(:templates).try(:send, key).try(:area).try(area).try(:to) ||
          Settings.message_api.send(config)
      ].flatten.compact.first
      Rails.logger.warn("could not find #{config} for template #{key} for area #{area}") unless value
      value || default
    end

    def to(key:)
      get_config(config: :to, key: key, default: 'team@afeefa.de')
    end

    def reply_to(key:)
      get_config(config: :reply_to, key: key, default: 'team@afeefa.de')
    end

    def backend_link(model)
      "#{Settings.backend_api.path}/#{model.class.name.underscore.pluralize}/#{model.id}/edit"
    end

    def notify_for_new_entry(model:, area:)
      params = {
        title: model.title,
        description: model.short_description,
        backend_link: backend_link(model)
      }

      if contact_data = get_contact_data(model)
        params.reverse_merge!(contact_data || {})
      end

      payload = {
        key: api_key,
        area: area,
        to: to(:new_entry),
        reply_to: reply_to(:new_entry),
      }.merge(params || {})

      HTTP.post("#{base_path}/send/newEntryInfo",
        headers: { 'Content-Type' => 'application/json' },
        body: payload.to_json)
    end

    private

    def get_contact_data(model)
      contact_info = ContactInfo.where(contactable: model).first
      if contact_info
        params.reverse_merge!(
          name: contact_info.contact_person || 'nicht angegeben',
          email: contact_info.mail || 'nicht angegeben'
        )
      end
    rescue => exc
      Rails.logger.error exc.message
      Rails.logger.error exc.backtrace.join("\n")
      nil
    end
  end

end
