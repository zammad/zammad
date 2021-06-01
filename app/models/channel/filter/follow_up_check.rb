# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::FollowUpCheck

  def self.run(_channel, mail, _transaction_params)

    return if mail[:'x-zammad-ticket-id']

    # get ticket# from subject
    ticket = Ticket::Number.check(mail[:subject])
    if ticket
      Rails.logger.debug { "Follow-up for '##{ticket.number}' in subject." }
      mail[:'x-zammad-ticket-id'] = ticket.id
      return true
    end

    setting = Setting.get('postmaster_follow_up_search_in') || []

    # get ticket# from body
    if setting.include?('body')
      ticket = Ticket::Number.check(mail[:body].html2text)
      if ticket
        Rails.logger.debug { "Follow-up for '##{ticket.number}' in body." }
        mail[:'x-zammad-ticket-id'] = ticket.id
        return true
      end
    end

    # get ticket# from attachment
    if setting.include?('attachment') && mail[:attachments]
      mail[:attachments].each do |attachment|
        next if attachment[:data].blank?
        next if attachment[:preferences].blank?
        next if attachment[:preferences]['Mime-Type'].blank?

        if %r{text/html}i.match?(attachment[:preferences]['Mime-Type'])
          begin
            text = attachment[:data].html2text
            ticket = Ticket::Number.check(text)
          rescue => e
            Rails.logger.error e
          end
        end

        if %r{text/plain}i.match?(attachment[:preferences]['Mime-Type'])
          ticket = Ticket::Number.check(attachment[:data])
        end

        next if !ticket

        Rails.logger.debug { "Follow-up for '##{ticket.number}' in attachment." }
        mail[:'x-zammad-ticket-id'] = ticket.id
        return true
      end
    end

    # get ticket# from references
    return true if ( setting.include?('references') || (mail[:'x-zammad-is-auto-response'] == true || Setting.get('ticket_hook_position') == 'none') ) && follow_up_by_md5(mail)

    # get ticket# from references current email has same subject as initial article
    if mail[:subject].present?

      # get all references 'References' + 'In-Reply-To'
      references = ''
      if mail[:references]
        references += mail[:references]
      end
      if mail[:'in-reply-to']
        if references != ''
          references += ' '
        end
        references += mail[:'in-reply-to']
      end
      if references != ''
        message_ids = references.split(%r{\s+})
        message_ids.each do |message_id|
          message_id_md5 = Digest::MD5.hexdigest(message_id)
          article = Ticket::Article.where(message_id_md5: message_id_md5).order('created_at DESC, id DESC').limit(1).first
          next if !article

          ticket = article.ticket
          next if !ticket

          article_first = ticket.articles.first
          next if !article_first

          # remove leading "..:\s" and "..[\d+]:\s" e. g. "Re: " or "Re[5]: "
          subject_to_check = mail[:subject]
          subject_to_check.gsub!(%r{^(..(\[\d+\])?:\s+)+}, '')

          # if subject is different, it's no followup
          next if subject_to_check != article_first.subject

          Rails.logger.debug { "Follow-up for '##{article.ticket.number}' in references with same subject as inital article." }
          mail[:'x-zammad-ticket-id'] = article_first.ticket_id
          return true
        end
      end
    end

    true
  end

  def self.mail_references(mail)
    references = []
    %i[references in-reply-to].each do |key|
      next if mail[key].blank?

      references.push(mail[key])
    end
    references.join(' ')
  end

  def self.message_id_article(message_id)
    message_id_md5 = Digest::MD5.hexdigest(message_id)
    Ticket::Article.where(message_id_md5: message_id_md5).order('created_at DESC, id DESC').limit(1).first
  end

  def self.follow_up_by_md5(mail)
    return if mail[:'x-zammad-ticket-id']

    mail_references(mail).split(%r{\s+}).each do |message_id|
      article = message_id_article(message_id)
      next if article.blank?

      Rails.logger.debug "Follow up for '##{article.ticket.number}' in references."
      mail[:'x-zammad-ticket-id'] = article.ticket_id
      return true
    end
  end
end
