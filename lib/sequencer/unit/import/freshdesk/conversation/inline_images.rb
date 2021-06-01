# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Freshdesk
        module Conversation
          class InlineImages < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

            uses :mapped

            def process
              return if !contains_inline_image?(mapped[:body])

              provide_mapped do
                {
                  body: replaced_inline_images,
                }
              end
            end

            def self.inline_data(freshdesk_url)
              @cache ||= {}
              return @cache[freshdesk_url] if @cache[freshdesk_url]

              image_data = download(freshdesk_url)
              return if image_data.blank?

              @cache[freshdesk_url] = "data:image/png;base64,#{Base64.strict_encode64(image_data)}"
              @cache[freshdesk_url]
            end

            def self.download(freshdesk_url)
              logger.debug { "Downloading inline image from #{freshdesk_url}" }

              response = UserAgent.get(
                freshdesk_url,
                {},
                {
                  open_timeout: 20,
                  read_timeout: 240,
                },
              )

              return response.body if response.success?

              logger.error response.error
              nil
            end

            private

            def contains_inline_image?(string)
              return false if string.blank?

              string.include?('freshdesk.com/inline/attachment')
            end

            def replaced_inline_images
              body_html = Nokogiri::HTML(mapped[:body])

              body_html.css('img').each do |node|
                next if !contains_inline_image?(node['src'])

                node.attributes['src'].value = self.class.inline_data(node['src'])
              end

              body_html.to_html
            end
          end
        end
      end
    end
  end
end
