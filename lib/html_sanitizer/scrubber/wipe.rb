# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    class Wipe < Base

      # Allowed paths for Zammad API endpoints that can be used in <img src> or srcset attributes.
      ALLOWED_ZAMMAD_API_PATHS = %w[
        api/v1/attachments/
        api/v1/ticket_attachment/
      ].freeze

      attr_reader :remote_content_removed

      def initialize # rubocop:disable Lint/MissingSuper
        @direction = :bottom_up

        @remote_content_removed = false
      end

      def scrub(node)
        return STOP if clear_tags_allowlist(node)
        return STOP if remove_unsafe_src(node)
        return STOP if remove_unsafe_srcset(node)

        clear_css_classes(node)
        move_attrs_to_css(node)
        clear_style(node)
        remove_invalid_links(node)
        remove_attributes_not_in_allowlist(node)
      end

      private

      def remove_attributes_not_in_allowlist(node)
        node.each do |attribute, _value| # rubocop:disable Style/HashEachMethods
          attribute_name = attribute.downcase
          next if attributes_allowlist[:all].include?(attribute_name) || attributes_allowlist[node.name]&.include?(attribute_name)

          node.delete(attribute)
        end
      end

      def remove_invalid_links(node)
        %w[href style].each do |attribute_name|
          next if !node[attribute_name]

          href = cleanup_target(node[attribute_name])
          next if !unsafe_link_protocol?(href)

          node.delete(attribute_name)
        end
      end

      def clear_style(node)
        return if !node['style']

        style = clear_style_pairs(node)
          .each_with_object(+'') do |elem, memo|
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

          value = node[key]
          node.delete(key)
          next if value.blank?
          next if node_has_css?(node, key)

          node_set_style(node, key, value)
        end
      end

      def node_has_css?(node, key)
        return false if node['style'].blank?

        node['style'].split(';').any? { |attr| attr.split(':').first&.strip == key }
      end

      def node_set_style(node, key, value)
        node['style'] = node['style'].blank? ? '' : "#{node['style']};"

        value += 'px' if !value.match?(%r{%|px|em}i)
        node['style'] += "#{key}:#{value}"
      end

      def clear_css_classes(node)
        return if !node['class']

        kept = node['class'].gsub(%r{\t|\n|\r}, '').split
                            .select { |c| classes_allowlist.include?(c.strip) }

        if kept.empty?
          node.delete('class')
        else
          node['class'] = kept.join(' ')
        end
      end

      def remove_unsafe_src(node)
        return if !node['src']

        src = cleanup_target(CGI.unescape(node['src']))

        return if !unsafe_protocol?(src) && !remote_url?(src) && !unsafe_api_path?(src)

        node.remove
        @remote_content_removed = true if remote_url?(src)
        true
      end

      def remove_unsafe_srcset(node)
        return if !node['srcset']

        remote_removed  = false
        candidates      = parse_srcset_candidates(node['srcset'])
        safe_candidates = candidates.select do |candidate|
          url = cleanup_target(CGI.unescape(candidate[:url]))
          next if unsafe_protocol?(url) || unsafe_api_path?(url)

          if remote_url?(url)
            remote_removed = true
            next
          end

          true
        end

        return if safe_candidates.length == candidates.length

        @remote_content_removed = true if remote_removed

        if safe_candidates.empty?
          node.delete('srcset')

          if !node['src']
            node.remove
            return true
          end
        else
          node['srcset'] = safe_candidates.map { |c| ([c[:url]] + c[:descriptors]).join(' ') }.join(', ')
        end

        nil
      end

      # Parses a srcset attribute per the HTML spec state machine.
      # https://html.spec.whatwg.org/multipage/images.html#parse-a-srcset-attribute
      def parse_srcset_candidates(srcset)
        candidates = []
        pos        = 0
        len        = srcset.length

        loop do
          # Skip separators (whitespace and commas) between candidates
          pos += 1 while pos < len && (srcset[pos] == ',' || srcset[pos].match?(%r{[[:space:]]}))
          break if pos >= len

          # Collect URL token - runs until whitespace (so commas inside, e.g. data: URLs, are kept)
          url_start = pos
          pos += 1 while pos < len && !srcset[pos].match?(%r{[[:space:]]})
          url = srcset[url_start...pos]

          descriptors, pos = srcset_descriptors(srcset, url, pos, len)
          url = url.sub(%r{,+\z}, '') if url.end_with?(',')

          candidates << { url: url, descriptors: descriptors } if url.present?
        end

        candidates
      end

      def srcset_descriptors(input, url, pos, len)
        # A URL token ending with a comma has no descriptors; the comma is stripped by the caller
        return [[], pos] if url.end_with?(',')

        pos += 1 while pos < len && input[pos].match?(%r{[[:space:]]})

        descriptors = []
        token       = +''

        while pos < len
          c    = input[pos]
          pos += 1

          if c == ','
            descriptors << token if token.present?
            return [descriptors, pos]
          elsif c.match?(%r{[[:space:]]})
            descriptors << token if token.present?
            token = +''
          else
            token << c
          end
        end

        descriptors << token if token.present?
        [descriptors, pos]
      end

      def clear_tags_allowlist(node)
        return if tags_allowlist.include?(node.name)

        node.before(node.children)
        node.remove
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

      # We allow usage of certain class names:
      # - `js-signatureMarker` - because it is used to identify Zammad signature markers
      # - `yahoo_quoted` - because Yahoo Mail marks quoted email content using <div class='yahoo_quoted'> and we rely
      #   on  this class to identify quoted messages
      # - `zammad-table` - because it is used to style Zammad internal tables
      def classes_allowlist
        %w[js-signatureMarker yahoo_quoted zammad-table]
      end

      def attributes_2_css
        %w[width height]
      end

      def unsafe_protocol?(string)
        string.match?(%r{(javascript|livescript|vbscript):}i)
      end

      def unsafe_link_protocol?(string)
        string.match?(%r{(javascript|livescript|vbscript|data):}i)
      end

      def remote_url?(string)
        string.downcase.start_with?('http://', 'https://', 'ftp://', '//')
      end

      def unsafe_api_path?(string)

        # block path traversal (../, ./)
        normalized = string.sub(%r{\A(?:\./|\.\./)+}, '')
        return true if normalized != string

        # only /api/... paths are in scope; non-API paths pass through
        return false if !normalized.match?(%r{\A/?api/}i)

        stripped = normalized.delete_prefix('/')

        # allowlist: prefix match for sub-paths, equality for exact bare paths
        return false if ALLOWED_ZAMMAD_API_PATHS.any? { |path| stripped.start_with?(path) || stripped == path.delete_suffix('/') }

        true
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
