# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase
  class ServerSnippet
    def initialize(knowledge_base)
      @kb = knowledge_base
    end

    def render
      raise Exceptions::UnprocessableEntity, 'Custom address is not set' if @kb.custom_address_uri.nil?

      template_rewrite = host.present? ? template_full : template_path
      "#{template_rewrite}\n#{template_original_url}"
    end

    def host
      @kb.custom_address_uri&.host
    end

    def path
      @kb.custom_address_uri&.path || ''
    end

    def template_path; end

    def template_full; end

    def template_original_url; end
  end
end
