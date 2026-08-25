# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Article::EmailForwardReply < BaseMutation
    include Gql::Mutations::Form::UploadCache::Concerns::HandlesAuthorization

    requires_permission 'ticket.agent'

    description 'Prepare for a new forward or reply email article'

    argument :article_id, GraphQL::Types::ID, loads: Gql::Types::Ticket::ArticleType, description: 'The article to be forwarded or replied to'
    argument :form_id, Gql::Types::FormIdType, required: false, description: 'Form identifier of the form for the new article to copy attachments to (forward only)'

    field :quotable_from, String, description: "'From' information of the original email to be inserted in the quoted email block"
    field :quotable_to, String, description: "'To' information of the original email to be inserted in the quoted email block"
    field :quotable_cc, String, description: "'Cc' information of the original email to be inserted in the quoted email block"
    field :quotable_author_name, String, description: "Author name for the reply citation ('On ..., X wrote:'), following the configured email sender format"

    field :attachments, [Gql::Types::StoredFileType, { null: false }], null: false, description: 'Cloned attachments for the new article.'

    def resolve(article:, form_id: nil)
      # present? matches the blank? guard of the upload cache authorization -
      #   a blank form_id must not clone either.
      result = { attachments: form_id.present? ? clone_attachments(article:, form_id:) : [] }

      return result if !Setting.get('ui_ticket_zoom_article_email_full_quote_header')

      email_address = quoted_from_email_address(article)

      result.merge(
        {
          quotable_from:        from(article, email_address),
          quotable_to:          to(article),
          quotable_cc:          cc(article),
          quotable_author_name: author_name(article.author, email_address),
        }
      )
    end

    def from(article, email_address)
      [
        article.author,
        find_user_by_raw_email(article.from)
      ].compact.each do |user|
        result = filtered_user_info(user, sender_email_address: email_address)
        return result if result.present?
      end
      nil
    end

    # Name for the reply citation: follows the sender format for agent authored
    #   articles - names only, never an address. Customers keep their bare name
    #   parts, like the legacy reply citation.
    def author_name(user, email_address)
      return if !user

      return user.display_name_from_parts.presence if !user.permissions?('ticket.agent')

      return agent_display_name(user) if !email_address

      email_address.sender_display_name(user)
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

      filtered_multi_user_info(article.to)
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
      filtered_multi_user_info(article.cc)
    end

    def clone_attachments(article:, form_id:)
      article.clone_attachments('UploadCache', form_id, only_attached_attachments: true)
    end

    private

    # Mirrors the per-recipient handling of the legacy quote header: scrub each
    #   comma separated recipient on its own, unknown recipients keep their raw
    #   value. Reducing the line to a single lookup instead would drop the other
    #   recipients - or expose them raw when the first one is unknown.
    def filtered_multi_user_info(input)
      return if input.blank?

      input
        .split(',')
        .map(&:strip)
        .map { |element| filtered_user_info(find_user_by_raw_email(element)) || element }
        .join(', ')
    end

    # Prefer the address the mail was actually sent from (stored at send time) -
    #   the ticket may have been moved or the group address changed since.
    def quoted_from_email_address(article)
      ::EmailAddress.find_by(id: article.preferences['email_address_id']) || article.ticket.group.email_address
    end

    # Do not allow whitespace, quotes or commas inside the address: display names
    #   can contain email addresses themselves - for users without a name Zammad
    #   builds headers like '"user@example.com" <user@example.com>' - and a match
    #   bleeding into those characters would extract garbage, skip the user
    #   lookup and expose the raw header field.
    def find_user_by_raw_email(string)
      if string =~ %r{<?([^\s"<,]+@[^>\s",]+)(>?)}
        return ::User.find_by(email: $1)
      end

      nil
    end

    # Pass sender_email_address only for the quoted From line: it pairs agents
    #   with the configured sender format and the group address, mirroring the
    #   original outbound mail. Recipient (To/CC) lines must not use it - the
    #   mail was never received at the group address.
    def filtered_user_info(user, sender_email_address: nil)
      return if !user

      if !user.permissions?('ticket.agent')
        return ::Channel::EmailBuild.recipient_line(user.fullname, user.email) if user.email

        return user.fullname.presence
      end

      return agent_display_name(user) if !sender_email_address

      ::Channel::EmailBuild.recipient_line(sender_email_address.sender_display_name(user), sender_email_address.email)
    end

    # Agents must not fall back to personal data (email, phone) when only their
    #   name may be shown. The '-' also prevents the fallthrough to the raw
    #   header field, which would expose the address again. The part ordering
    #   follows user_name_format, like displayNameFromParts() in the legacy
    #   quote header does.
    def agent_display_name(user)
      user.display_name_from_parts.presence || '-'
    end

  end
end
