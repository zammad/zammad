# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Article::EmailForwardReply < BaseMutation
    description 'Prepare for a new forward or reply email article'

    argument :article_id, GraphQL::Types::ID, loads: Gql::Types::Ticket::ArticleType, description: 'The article to be forwarded or replied to'
    argument :form_id, Gql::Types::FormIdType, 'Form identifier of the form for the new article to copy attachments to'

    field :quotable_from, String, description: "'From' information of the original email to be inserted in the quoted email block"
    field :quotable_to, String, description: "'To' information of the original email to be inserted in the quoted email block"
    field :quotable_cc, String, description: "'Cc' information of the original email to be inserted in the quoted email block"

    field :attachments, [Gql::Types::StoredFileType, { null: false }], null: false, description: 'Cloned attachments for the new article.'

    def resolve(article:, form_id:)
      result = { attachments: clone_attachments(article:, form_id:) }

      return result if !Setting.get('ui_ticket_zoom_article_email_full_quote_header')

      result.merge(
        {
          quotable_from: from(article),
          quotable_to:   to(article),
          quotable_cc:   cc(article),
        }
      )
    end

    def from(article)
      [
        ::User.find_by(id: article.origin_by_id || article.created_by_id),
        find_user_by_raw_email(article.from)
      ].compact.each do |user|
        result = filtered_user_info(user)
        return result if result.present?
      end
      nil
    end

    def to(article)
      %i[to_email_web to_customer to_agent to_default].each do |func|
        result = send(func, article)
        return result if result.present?
      end

      nil
    end

    def to_email_web(article)
      return if article.type.name != 'email' && article.type.name != 'web'

      filtered_user_info(find_user_by_raw_email(article.to))
    end

    def to_customer(article)
      return if article.sender.name != 'Customer' || article.type.name != 'phone'

      group = Group.find_by(name: find_user_by_raw_email(article.to))
      return article.to if !group

      ::Channel::EmailBuild.recipient_line(group.fullname, group.email)
    end

    def to_agent(article)
      return if article.sender.name != 'Agent' || article.type.name != 'phone'

      customer = ::User.find_by(id: article.ticket.customer_id)
      filtered_user_info(customer) || filtered_user_info(find_user_by_raw_email(article.to))
    end

    def to_default(article)
      article.to
    end

    def cc(article)
      filtered_user_info(find_user_by_raw_email(article.cc))
    end

    def clone_attachments(article:, form_id:)
      article.clone_attachments('UploadCache', form_id, only_attached_attachments: true)
    end

    private

    def find_user_by_raw_email(string)
      if string =~ %r{<?(\S+@\S[^>]+)(>?)}
        return ::User.find_by(email: $1)
      end

      nil
    end

    def filtered_user_info(user)
      return if !user

      if !user.permissions?('ticket.agent') && user.email
        ::Channel::EmailBuild.recipient_line(user.fullname, user.email)
      else
        user.fullname.presence
      end
    end

  end
end
