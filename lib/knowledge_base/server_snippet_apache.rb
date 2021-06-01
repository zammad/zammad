# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# rubocop:disable Style/FormatStringToken, Lint/MissingCopEnableDirective
class KnowledgeBase
  class ServerSnippetApache < ServerSnippet
    def template_path
      <<-ERB.strip_heredoc
      # Add following lines to <VirtualHost> directive
      RewriteEngine On
      RewriteRule ^#{path}(.*) /help$1 [PT]
      ERB
    end

    def template_full
      <<-ERB.strip_heredoc
      # Add following lines to <VirtualHost> directive
      RewriteEngine On
      RewriteCond %{HTTP_HOST} #{host}
      RewriteRule (assets|api)/(.*) /$1/$2 [PT]
      RewriteCond %{HTTP_HOST} #{host}
      RewriteRule #{path}(.*) /help$1 [PT]
      ERB
    end

    def template_original_url
      <<-ERB.strip_heredoc
      # Add following lines to <VirtualHost> directive, before ProxyPass
      SetEnvIf Request_URI "(.*)" ORIGINAL_URL=$1
      RequestHeader add X-ORIGINAL-URL %{ORIGINAL_URL}e
      ERB
    end
  end
end
