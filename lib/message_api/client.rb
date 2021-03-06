require 'http'

module MessageApi
  module Client
    class << self
      def notify_for_new_entry(model:)
        payload = {
          key: api_key,
          area: model.area || 'dresden',

          title: model.title,
          description: model.short_description,
          backend_link: backend_link(model)
        }.merge(get_contact_data(model) || {})

        http_client.send_new_entry_info(payload)
      end

      def send_contact_message_for_entry(model:, params:)
        params ||= {}

        if contact_data = get_contact_data(model)
          params.reverse_merge!(to: contact_data[:email])
        else
          raise ActiveRecord::RecordNotFound,
            "Could not find contact_data for model '#{model.try(:title) rescue nil}'"
        end

        payload = {
          key: api_key,
          area: model.area || 'dresden',

          title: model.title,
          frontend_link: frontend_link(model)
        }.merge(params.except(:type, :id))

        http_client.send_entry_contact_message(payload)
      end

      def send_feedback_message_for_entry(model:, params:)
        params ||= {}

        payload = {
          key: api_key,
          area: model.area || 'dresden',

          title: model.title,
          backend_link: backend_link(model),
          frontend_link: frontend_link(model)
        }.merge(params.except(:type, :id))

        http_client.send_entry_feedback_info(payload)
      end

      private

      def http_client
        HttpClient
      end

      def api_key
        Settings.message_api.key || 'test123'
      end

      def backend_link(model)
        type =
          case model.class.to_s
          when 'Orga'
            'orgas'
          when 'Event'
            'events'
          when 'DataModules::Offer::Offer'
            'offers'
          end
        path = Settings.backend_ui.path || 'https://backend.afeefa.de'
        "#{path}/#{type}/#{model.id}"
      end

      def frontend_link(model)
        type =
          case model.class.to_s
          when 'Orga'
            'project'
          when 'Event'
            'event'
          when 'DataModules::Offer::Offer'
            'offer'
          end
        path = Settings.frontend_ui.path || 'https://afeefa.de'
        "#{path}/#{type}/#{model.id}"
      end

      def get_contact_data(model)
        contact = DataPlugins::Contact::Contact.where(owner: model).first
        if contact
          {
            name: contact.contact_persons.first.try(:name) || '',
            email: contact.contact_persons.first.try(:mail) || '',
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

      def send_entry_contact_message(payload)
        HTTP.post("#{base_path}/send/messageFromUserToOwner",
          headers: { 'Content-Type' => 'application/json' },
          body: payload.to_json)
      end

      def send_entry_feedback_info(payload)
        HTTP.post("#{base_path}/send/feedbackFromUserToAdmins",
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
