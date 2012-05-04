require 'mail'
require 'iconv'
class Channel::EmailParser
  def conv (charset, string)
    if charset == 'US-ASCII' || charset == 'ASCII-8BIT'
      charset = 'LATIN1'
    end
    return string if charset.downcase == 'utf8' || charset.downcase == 'utf-8'
#    puts '-------' + charset
#    puts string
#    string.encode("UTF-8")
    Iconv.conv( 'UTF8', charset, string )
  end
  
  def parse (msg)
    data = {}
    mail = Mail.new( msg )

    # headers
    data[:from_email]        = Mail::Address.new( mail[:from].value ).address
    data[:from_display_name] = Mail::Address.new( mail[:from].value ).display_name
    ['from', 'to', 'cc', 'subject'].each {|key|
      data[key.to_sym] = mail[key] ? mail[key].to_s : nil
    }

    # message id
    data[:message_id] = mail['message_id'] ? mail['message_id'].to_s : nil

    # body
#    plain_part = mail.multipart? ? (mail.text_part ? mail.text_part.body.decoded : nil) : mail.body.decoded
#    html_part = message.html_part ? message.html_part.body.decoded : nil
    if mail.multipart?
      data[:plain_part] = mail.text_part.body.decoded
      data[:plain_part] = conv( mail.text_part.charset || 'LATIN1', data[:plain_part] )
    else
      data[:plain_part] = mail.body.decoded
      data[:plain_part] = conv( mail.body.charset || 'LATIN1', data[:plain_part] )
    end

    # attachments
    if mail.attachments
      data[:attachments] = []
      mail.attachments.each do |attachment|
        
        # get file preferences
        headers = {}
        attachment.header.fields.each do |f|
          headers[f.name] = f.value
        end
        headers_store = {}
        headers_store['Mime-Type'] = attachment.mime_type
        if attachment.charset
          headers_store['Charset'] = attachment.charset
        end
        ['Content-ID', 'Content-Type'].each do |item|
          if headers[item]
            headers_store[item] = headers[item]
          end
        end
        attachment = {
          :data        => attachment.body.decoded,
          :filename    => attachment.filename,
          :preferences => headers_store          
        }
        data[:attachments].push attachment
      end
    end
    return data
  end

  def process(channel, msg)
    mail = parse( msg )

    # use transaction
    ActiveRecord::Base.transaction do

      user = User.where( :email => mail[:from_email] ).first
      if !user then
        puts 'create user...'
        roles = Role.where( :name => 'Customer' )
        user = User.create(
          :login          => mail[:from_email],
          :firstname      => mail[:from_display_name],
          :lastname       => '',
          :email          => mail[:from_email],
          :password       => '',
          :active         => true,
          :roles          => roles,
          :created_by_id  => 1 
        )
      end
      
      # set current user
      UserInfo.current_user_id = user.id
  
      # get ticket# from subject
      ticket = Ticket.number_check( mail[:subject] )

      # set ticket state to open if not new
      if ticket
        ticket_state      = Ticket::State.find( ticket.ticket_state_id )
        ticket_state_type = Ticket::StateType.find( ticket_state.ticket_state_type_id )
        if ticket_state_type.name != 'new'
          ticket.ticket_state = Ticket::State.where( :name => 'open' ).first
          ticket.save
        end
      end

      # create new ticket
      if !ticket then
        ticket = Ticket.create(
          :group_id           => channel[:group_id] || 1,
          :customer_id        => user.id,
          :title              => mail[:subject],
          :ticket_state_id    => Ticket::State.where(:name => 'new').first.id,
          :ticket_priority_id => Ticket::Priority.where(:name => '2 normal').first.id,
          :created_by_id      => user.id
        )
      end
  
      # import mail
      article = Ticket::Article.create(
        :created_by_id            => user.id,
        :ticket_id                => ticket.id, 
        :ticket_article_type_id   => Ticket::Article::Type.where(:name => 'email').first.id,
        :ticket_article_sender_id => Ticket::Article::Sender.where(:name => 'Customer').first.id,
        :body                     => mail[:plain_part], 
        :from                     => mail[:from],
        :to                       => mail[:to],
        :cc                       => mail[:cc],
        :subject                  => mail[:subject],
        :message_id               => mail[:message_id],
        :internal                 => false 
      )

      # store mail plain
      Store.add(
        :object      => 'Ticket::Article::Mail',
        :o_id        => article.id,
        :data        => msg,
        :filename    => 'plain.msg',
        :preferences => {}
      )

      # store attachments
      if mail[:attachments]
        mail[:attachments].each do |attachment|
          Store.add(
            :object      => 'Ticket::Article',
            :o_id        => article.id,
            :data        => attachment[:data],
            :filename    => attachment[:filename],
            :preferences => attachment[:preferences]
          )
        end
      end
      return ticket, article, user
    end

    # execute ticket events      
    Ticket::Observer::Notification.transaction
  end
end