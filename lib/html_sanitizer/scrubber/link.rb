# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  module Scrubber
    class Link < Base
      LINKABLE_URL_SCHEMES = URI.scheme_list.keys.map(&:downcase) - ['mailto'] + ['tel']

      attr_reader :external, :web_app_url_prefix

      def initialize(web_app_url_prefix:, external: false) # rubocop:disable Lint/MissingSuper
        @direction = :top_down

        @external = external
        @web_app_url_prefix = web_app_url_prefix
      end

      def scrub(node)
        if (urls = node_urls(node))
          return if urls.blank?

          add_link(node.content, urls, node)
        end

        # prepare links
        return if href_cleanup(node)

        return STOP if ensure_href_present(node)

        update_node_title(node)
      end

      private

      def href_cleanup(node)
        return if !node['href']

        href                = cleanup_target(node['href'], keep_spaces: true)
        href_without_spaces = href.gsub(%r{[[:space:]]}, '')

        if href_retry_protocol?(href_without_spaces)
          node['href']        = "http://#{node['href']}"
          href                = node['href']
          href_without_spaces = href.gsub(%r{[[:space:]]}, '')
        end

        return true if !href_starts_with_protocol?(href_without_spaces)

        href_set_values(node, href)

        false
      end

      def href_retry_protocol?(href_without_spaces)
        return if !external
        return if href_without_spaces.blank?
        return if href_without_spaces.downcase.start_with?('mailto:')
        return if href_without_spaces.downcase.start_with?('tel:')
        return if href_without_spaces.downcase.start_with?('//')
        return if href_without_spaces.downcase.match? %r{^.{1,6}://.+?}

        true
      end

      def href_starts_with_protocol?(href_without_spaces)
        CGI
          .unescape(href_without_spaces)
          .utf8_encode(fallback: :read_as_sanitized_binary)
          .gsub(%r{[[:space:]]}, '')
          .downcase
          .start_with?('http', 'ftp', '//')
      end

      def href_set_values(node, value)
        node.set_attribute('href', value)
        node.set_attribute('rel', 'nofollow noreferrer noopener')

        # do not "target=_blank" WebApp URLs (e.g. mentions)
        return if value.downcase.start_with?(web_app_url_prefix)

        node.set_attribute('target', '_blank')
      end

      def node_urls(node)
        return if !node.is_a?(Nokogiri::XML::Text)
        return if node.content.blank?
        return if node.content.exclude?(':')
        return if node.ancestors.map(&:name).intersect?(%w[a pre])

        URI.extract(node.content, LINKABLE_URL_SCHEMES)
          .map { |u| u.sub(%r{[,.]$}, '') } # URI::extract captures trailing dots/commas
          .grep_v(%r{^[^:]+:$}) # URI::extract will match, e.g., 'tel:'
      end

      def ensure_href_present(node)
        return if node.name != 'a'
        return if node['href'].present?

        node.replace node.children.to_s

        true
      end

      def update_node_title(node)
        return if node.name != 'a'
        return if url_same?(node['href'], node.text)
        return if node['title'].present?

        node['title'] = node['href']
      end

      def add_link(content, urls, node)
        return if add_link_blank_text(content, urls, node)

        url = urls.shift

        return if content !~ %r{^(.*)#{Regexp.quote(url)}(.*)$}mx

        pre  = $1
        post = $2

        a_elem = add_link_build_node(node, url)

        if node.class != Nokogiri::XML::Text
          text = Nokogiri::XML::Text.new(pre, node.document)
          node.add_next_sibling(text).add_next_sibling(a_elem)
          return if post.blank?

          add_link(post, urls, a_elem)
          return
        end

        add_link_apply_to_node(node, pre, a_elem)
        return if post.blank?

        add_link(post, urls, a_elem)
      end

      def add_link_apply_to_node(node, pre, a_elem)
        node.content = pre
        node.add_next_sibling(a_elem)
      end

      def add_link_blank_text(content, urls, node)
        return false if urls.present?

        text = Nokogiri::XML::Text.new(content, node.document)
        node.add_next_sibling(text)

        true
      end

      def add_link_build_node(node, url)
        if url.match?(%r{^www}i)
          url = "http://#{url}"
        end

        a = Nokogiri::XML::Node.new 'a', node.document
        a['href'] = url
        a['rel'] = 'nofollow noreferrer noopener'
        a['target'] = '_blank'
        a.content = url

        a
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

      def url_same?(url_new, url_old)
        url_new = url_same_build(url_new)
        url_old = url_same_build(url_old)

        return true if url_new == url_old
        return true if url_old == "http://#{url_new}"
        return true if url_new == "http://#{url_old}"
        return true if url_old == "https://#{url_new}"
        return true if url_new == "https://#{url_old}"

        false
      end

      def url_same_build(input)
        url = CGI
          .unescape(input.to_s)
          .utf8_encode(fallback: :read_as_sanitized_binary)
          .downcase
          .delete_suffix('/')
          .gsub(%r{[[:space:]]|\t|\n|\r}, '')
          .strip

        html_decode(url)
          .sub('/?', '?')
      end
    end
  end
end
