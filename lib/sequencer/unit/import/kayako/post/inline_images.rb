# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Post
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

            def self.inline_data(kayako_url)
              @cache ||= {}
              return @cache[kayako_url] if @cache[kayako_url]

              image_data = download(kayako_url)
              return if image_data.blank?

              @cache[kayako_url] = "data:image/png;base64,#{Base64.strict_encode64(image_data)}"
              @cache[kayako_url]
            end

            def self.download(kayako_url)
              logger.debug { "Downloading inline image from #{kayako_url}" }

              response = UserAgent.get(
                kayako_url,
                {},
                {
                  open_timeout: 20,
                  read_timeout: 240,
                  verify_ssl:   true,
                },
              )

              return response.body if response.success?

              logger.error response.error
              nil
            end

            private

            def contains_inline_image?(string)
              return false if string.blank?

              string.include?('kayako.com/media/url')
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
