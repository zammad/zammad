# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    class Wipe < Base
      def scrub(node)
        return STOP if clear_tags_allowlist(node)
        return STOP if remove_unsafe_src(node)

        clear_css_classes(node)
        move_attrs_to_css(node)
        clear_style(node)
        remove_invalid_links(node)
        remove_attributes_not_in_allowlist(node)
      end

      private

      def remove_attributes_not_in_allowlist(node)
        node.each do |attribute, _value|
          attribute_name = attribute.downcase
          next if attributes_allowlist[:all].include?(attribute_name) || attributes_allowlist[node.name]&.include?(attribute_name)

          node.delete(attribute)
        end
      end

      def remove_invalid_links(node)
        %w[href style].each do |attribute_name|
          next if !node[attribute_name]

          href = cleanup_target(node[attribute_name])
          next if !href.match?(%r{(javascript|livescript|vbscript):}i)

          node.delete(attribute_name)
        end
      end

      def clear_style(node)
        return if !node['style']

        style = clear_style_pairs(node)
          .each_with_object('') do |elem, memo|
            memo << "#{elem};" if clear_style_pair_valid?(node, elem)
          end

        node['style'] = style

        node.delete('style') if style.blank?
      end

      def clear_style_pairs(node)
        node['style'].downcase.gsub(%r{\t|\n|\r}, '').split(';')
      end

      def clear_style_pair_valid?(node, pair)
        prop = pair.split(':')
        return if prop.first.blank?

        return if !clear_style_allowed?(node, prop)
        return if clear_style_blocked?(node, pair)

        true
      end

      def clear_style_allowed?(node, prop)
        return if css_properties_allowlist.exclude?(node.name)
        return if css_properties_allowlist[node.name].exclude?(prop.first.strip)

        true
      end

      def clear_style_blocked?(node, pair)
        css_values_blocklist[node.name]&.include?(pair.gsub(%r{[[:space:]]}, '').strip)
      end

      def move_attrs_to_css(node)
        attributes_2_css.each do |key|
          next if !node[key]

          if node['style'].blank?
            node['style'] = ''
          else
            node['style'] += ';'
          end
          value = node[key]
          node.delete(key)
          next if value.blank?

          value += 'px' if !value.match?(%r{%|px|em}i)
          node['style'] += "#{key}:#{value}"
        end
      end

      def clear_css_classes(node)
        return if !node['class']

        classes = node['class'].gsub(%r{\t|\n|\r}, '').split
        class_new = ''
        classes.each do |local_class|
          next if classes_allowlist.exclude?(local_class.to_s.strip)

          if class_new != ''
            class_new += ' '
          end
          class_new += local_class
        end
        if class_new == ''
          node.delete('class')
        else
          node['class'] = class_new
        end
      end

      def remove_unsafe_src(node)
        return if !node['src']

        src = cleanup_target(CGI.unescape(node['src']))

        return if src !~ %r{(javascript|livescript|vbscript):}i && !src.downcase.start_with?('http', 'ftp', '//')

        node.remove
        true
      end

      def clear_tags_allowlist(node)
        return if tags_allowlist.include?(node.name)

        node.replace node.children.to_s
        true
      end

      def tags_allowlist
        @tags_allowlist ||= Rails.configuration.html_sanitizer_tags_allowlist
      end

      def attributes_allowlist
        @attributes_allowlist ||= Rails.configuration.html_sanitizer_attributes_allowlist
      end

      def css_properties_allowlist
        @css_properties_allowlist ||= Rails.configuration.html_sanitizer_css_properties_allowlist
      end

      def css_values_blocklist
        @css_values_blocklist ||= Rails.application.config.html_sanitizer_css_values_blocklist
      end

      # We allowlist yahoo_quoted because Yahoo Mail marks quoted email content using
      # <div class='yahoo_quoted'> and we rely on this class to identify quoted messages
      def classes_allowlist
        %w[js-signatureMarker yahoo_quoted]
      end

      def attributes_2_css
        %w[width height]
      end

      def cleanup_target(string, **options)
        cleaned_string = string.utf8_encode(fallback: :read_as_sanitized_binary)
        cleaned_string = cleaned_string.gsub(%r{[[:space:]]}, '') if !options[:keep_spaces]
        cleaned_string = cleaned_string.strip
                                       .delete("\t\n\r\u0000")
                                       .gsub(%r{/\*.*?\*/}, '')
                                       .gsub(%r{<!--.*?-->}, '')

        sanitize_attachment_disposition(cleaned_string)
      end

      def sanitize_attachment_disposition(url)
        @fqdn ||= Setting.get('fqdn')
        uri = URI(url)

        if uri.host == @fqdn && uri.query.present?
          params = CGI.parse(uri.query || '')
                      .tap { |p| p.merge!('disposition' => 'attachment') if p.include?('disposition') }
          uri.query = URI.encode_www_form(params)
        end

        uri.to_s
      rescue
        url
      end
    end
  end
end
