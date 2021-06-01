# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase
  class ServerSnippetNginx < ServerSnippet
    def template_path
      <<-ERB.strip_heredoc
      # Add following lines to "server" directive
      rewrite ^#{path}(.*)$ /help$1 last;
      ERB
    end

    def template_full
      <<-ERB.strip_heredoc
      # Add following lines to "server" directive
      if ($host = #{host} ) {
        rewrite ^/(api|assets)/(.*)$ /$1/$2 last;
        rewrite ^#{path}(.*)$ /help$1 last;
      }
      ERB
    end

    def template_original_url
      <<-ERB.strip_heredoc
      # Add following line to "Location /" directive, before other proxy_set_header
      proxy_set_header X-ORIGINAL-URL $request_uri;
      ERB
    end
  end
end
