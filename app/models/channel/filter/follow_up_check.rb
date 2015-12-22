# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::FollowUpCheck

  def self.run(_channel, mail)

    return if mail[ 'x-zammad-ticket-id'.to_sym ]

    # get ticket# from subject
    ticket = Ticket::Number.check(mail[:subject])
    if ticket
      Rails.logger.debug "Follow up for '##{ticket.number}' in subject."
      mail[ 'x-zammad-ticket-id'.to_sym ] = ticket.id
      return true
    end

    setting = Setting.get('postmaster_follow_up_search_in')

    # get ticket# from body
    if setting.include?('body')
      ticket = Ticket::Number.check(mail[:body])
      if ticket
        Rails.logger.debug "Follow up for '##{ticket.number}' in body."
        mail[ 'x-zammad-ticket-id'.to_sym ] = ticket.id
        return true
      end
    end

    # get ticket# from attachment
    if setting.include?('attachment') && mail[:attachments]
      mail[:attachments].each {|attachment|
        next if !attachment[:data]
        ticket = Ticket::Number.check(attachment[:data])
        next if !ticket
        Rails.logger.debug "Follow up for '##{ticket.number}' in attachment."
        mail[ 'x-zammad-ticket-id'.to_sym ] = ticket.id
        return true
      }
    end

    # get ticket# from references
    if setting.include?('references') || mail[ 'x-zammad-is-auto-response'.to_sym ] == true

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
        sender_type_agent = Ticket::Article::Sender.lookup(name: 'Agent')
        sender_type_system = Ticket::Article::Sender.lookup(name: 'System')
        message_ids.each {|message_id|
          message_id_md5 = Digest::MD5.hexdigest(message_id)
          article = Ticket::Article.where(message_id_md5: message_id_md5, sender_id: [sender_type_agent.id, sender_type_system.id]).order('created_at DESC, id DESC').limit(1).first
          next if !article
          Rails.logger.debug "Follow up for '##{article.ticket.number}' in references."
          mail[ 'x-zammad-ticket-id'.to_sym ] = article.ticket_id
          return true
        }
      end
    end

  end
end
