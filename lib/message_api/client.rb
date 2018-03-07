require 'http'

module MessageApi
  module Client
    class << self
      def notify_for_new_entry(model:)
        params = {
          title: model.title,
          description: model.short_description,
          backend_link: backend_link(model)
        }

        if contact_data = get_contact_data(model)
          params.reverse_merge!(contact_data)
        end

        payload = {
          key: api_key,
          area: model.area || 'dresden'
        }.merge(params)

        http_client.send_new_entry_info(payload)
      end

      def send_contact_message(model:, params:)
        params ||= {}

        if contact_data = get_contact_data(model)
          params.reverse_merge!(to: contact_data[:email])
        else
          raise ActiveRecord::RecordNotFound,
            "Could not find contact_data for model '#{model.try(:title) rescue nil}'"
        end

        payload = {
          key: api_key,
          area: model.area || 'dresden'
        }.merge(params.except(:type, :id))

        http_client.send_contact_mail(payload)
      end

      private

      def http_client
        HttpClient
      end

      def api_key
        Settings.message_api.key || 'test123'
      end

      def backend_link(model)
        "#{Settings.backend_api.path}/#{model.class.name.underscore.pluralize}/#{model.id}/edit"
      end

      def get_contact_data(model)
        # TODO: This needs to be migrated for new data structure and plugin structure
        contact_info = ContactInfo.where(contactable: model).first
        if contact_info
          {
            name: contact_info.contact_person,
            email: contact_info.mail
          }
        end
      rescue => exc
        Rails.logger.error exc.message
        Rails.logger.error exc.backtrace.join("\n")
        nil
      end
    end
  end

  # module for encapsulation of http requests
  module HttpClient
    class << self
      def send_new_entry_info(payload)
        HTTP.post("#{base_path}/send/newEntryInfo",
          headers: { 'Content-Type' => 'application/json' },
          body: payload.to_json)
      end

      def send_contact_mail(payload)
        HTTP.post("#{base_path}/send/messageFromUserToOwner",
          headers: { 'Content-Type' => 'application/json' },
          body: payload.to_json)
      end

      private

      def base_path
        Settings.message_api.path || 'http://localhost:3015'
      end
    end
  end
end
