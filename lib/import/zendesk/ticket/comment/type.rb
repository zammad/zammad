module Import
  module Zendesk
    class Ticket
      class Comment
        module Type

          # rubocop:disable Style/ModuleFunction
          extend self

          def local_id(object)
            case object.via.channel
            when 'web'
              article_type_id[:web]
            when 'email'
              article_type_id[:email]
            when 'sample_ticket'
              article_type_id[:note]
            when 'twitter'
              if object.via.source.rel == 'mention'
                article_type_id[:twitter_status]
              else
                article_type_id[:twitter_direct_message]
              end
            when 'facebook'
              if object.via.source.rel == 'post'
                article_type_id[:facebook_feed_post]
              else
                article_type_id[:facebook_feed_comment]
              end
            # fallback for other not (yet) supported article types
            # See:
            # https://support.zendesk.com/hc/en-us/articles/203661746-Zendesk-Glossary#topic_zie_aqe_tf
            # https://support.zendesk.com/hc/en-us/articles/203661596-About-Zendesk-Support-channels
            else
              article_type_id[:web]
            end
          end

          private

          def article_type_id
            return @article_type_id if @article_type_id

            article_types = ['web', 'note', 'email', 'twitter status',
                             'twitter direct-message', 'facebook feed post',
                             'facebook feed comment']
            @article_type_id = {}
            article_types.each do |article_type|

              article_type_key = article_type.gsub(/\s|\-/, '_').to_sym

              @article_type_id[article_type_key] = ::Ticket::Article::Type.lookup(name: article_type).id
            end
            @article_type_id
          end
        end
      end
    end
  end
end
