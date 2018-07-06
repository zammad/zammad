# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::FollowUpCheck

  def self.run(_channel, mail)

    return if mail['x-zammad-ticket-id'.to_sym]

    # get ticket# from subject
    ticket = Ticket::Number.check(mail[:subject])
    if ticket
      Rails.logger.debug { "Follow up for '##{ticket.number}' in subject." }
      mail['x-zammad-ticket-id'.to_sym] = ticket.id
      return true
    end

    setting = Setting.get('postmaster_follow_up_search_in') || []

    # get ticket# from body
    if setting.include?('body')
      ticket = Ticket::Number.check(mail[:body].html2text)
      if ticket
        Rails.logger.debug { "Follow up for '##{ticket.number}' in body." }
        mail['x-zammad-ticket-id'.to_sym] = ticket.id
        return true
      end
    end

    # get ticket# from attachment
    if setting.include?('attachment') && mail[:attachments]
      mail[:attachments].each do |attachment|
        next if !attachment[:data]
        ticket = Ticket::Number.check(attachment[:data].html2text)
        next if !ticket
        Rails.logger.debug { "Follow up for '##{ticket.number}' in attachment." }
        mail['x-zammad-ticket-id'.to_sym] = ticket.id
        return true
      end
    end

    # get ticket# from references
    if setting.include?('references') || (mail['x-zammad-is-auto-response'.to_sym] == true || Setting.get('ticket_hook_position') == 'none')

      # get all references 'References' + 'In-Reply-To'
      references = ''
      if mail[:references]
        references += mail[:references]
      end
      if mail['in-reply-to'.to_sym]
        if references != ''
          references += ' '
        end
        references += mail['in-reply-to'.to_sym]
      end
      if references != ''
        message_ids = references.split(/\s+/)
        message_ids.each do |message_id|
          message_id_md5 = Digest::MD5.hexdigest(message_id)
          article = Ticket::Article.where(message_id_md5: message_id_md5).order('created_at DESC, id DESC').limit(1).first
          next if !article
          Rails.logger.debug { "Follow up for '##{article.ticket.number}' in references." }
          mail['x-zammad-ticket-id'.to_sym] = article.ticket_id
          return true
        end
      end
    end

    # get ticket# from references current email has same subject as inital article
    if mail[:subject].present?

      # get all references 'References' + 'In-Reply-To'
      references = ''
      if mail[:references]
        references += mail[:references]
      end
      if mail['in-reply-to'.to_sym]
        if references != ''
          references += ' '
        end
        references += mail['in-reply-to'.to_sym]
      end
      if references != ''
        message_ids = references.split(/\s+/)
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
          subject_to_check.gsub!(/^(..(\[\d+\])?:\s+)+/, '')

          # if subject is different, it's no followup
          next if subject_to_check != article_first.subject

          Rails.logger.debug { "Follow up for '##{article.ticket.number}' in references with same subject as inital article." }
          mail['x-zammad-ticket-id'.to_sym] = article_first.ticket_id
          return true
        end
      end
    end

    true
  end
end
