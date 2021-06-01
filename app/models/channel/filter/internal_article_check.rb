# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::InternalArticleCheck
  def self.run(_channel, mail, _transaction_params)
    return if mail[ :'x-zammad-ticket-id' ].blank?

    ticket = Ticket.find_by(id: mail[ :'x-zammad-ticket-id' ])
    return if ticket.blank?

    return if !in_reply_to_is_internal?(mail, ticket) &&
              !last_outgoing_mail_is_internal?(mail, ticket)

    mail[ :'x-zammad-article-internal' ] = true
    true
  end

  def self.in_reply_to_is_internal?(mail, ticket)
    return false if mail[:'in-reply-to'].blank?

    message_id_md5 = Digest::MD5.hexdigest(mail[:'in-reply-to'])
    ticket.articles.exists?(message_id_md5: message_id_md5, internal: true)
  end

  def self.last_outgoing_mail_is_internal?(mail, ticket)
    return false if mail[:'in-reply-to'].present?

    from_email = parse_email(mail[:from_email])
    return false if from_email.blank?

    last_outgoing_mail = ticket.articles
      .where("ticket_articles.to #{Rails.application.config.db_like} ?", "%#{from_email}%")
      .order(created_at: :desc).first

    last_outgoing_mail&.internal.present?
  end

  def self.parse_email(email)
    Mail::AddressList.new(email)&.addresses&.first&.address
  rescue
    Rails.logger.error "Can not parse email: #{email}"
    nil
  end
end
