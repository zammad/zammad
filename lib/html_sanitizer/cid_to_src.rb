# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class HtmlSanitizer
  class CidToSrc < Loofah::Scrubber
    def scrub(node)
      return CONTINUE if node.name != 'img'
      return CONTINUE if !(cid = node.delete 'cid')

      node['src'] = "cid:#{cid}"
    end
  end
end
