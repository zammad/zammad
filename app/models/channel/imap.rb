require 'mail'
require 'net/imap'

class Channel::IMAP
  include UserInfo

  def fetch (account)
    puts 'fetching imap'

    imap = Net::IMAP.new(account[:options][:host], 993, true )
    imap.authenticate('LOGIN', account[:options][:user], account[:options][:password])
    imap.select('INBOX')
    imap.search(['ALL']).each do |message_id|
      msg = imap.fetch(message_id,'RFC822')[0].attr['RFC822']
      puts '--------------------'
#      puts msg.to_s

      mail = Mail.new( msg )
      from_email        = Mail::Address.new( mail[:from].value ).address
      from_display_name = Mail::Address.new( mail[:from].value ).display_name
  
      # use transaction
      ActiveRecord::Base.transaction do

        user = User.where( :email => from_email ).first
        if !user then
          puts 'create user...'
          roles = Role.where( :name => 'Customer' )
          user = User.create(
            :login          => from_email,
            :firstname      => from_display_name,
            :lastname       => '',
            :email          => from_email,
            :password       => '',
            :active         => true,
            :roles          => roles,
            :created_by_id  => 1 
          )
        end
        
        # set current user
        UserInfo.current_user_id = user.id
    
        def conv (charset, string)
          if charset == 'US-ASCII' then
            charset = 'LATIN1'
          end
          Iconv.conv("UTF8", charset, string)
        end
  
        # get ticket# from subject
        ticket = Ticket.number_check( mail[:subject].value )
        
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
            :group_id           => account[:group_id],
            :customer_id        => user.id,
            :title              => conv(mail['subject'].charset || 'LATIN1', mail['subject'].to_s),
            :ticket_state_id    => Ticket::State.where(:name => 'new').first.id,
            :ticket_priority_id => Ticket::Priority.where(:name => '2 normal').first.id,
            :created_by_id      => user.id
          )
        end
    
        # import mail
        plain_part = mail.multipart? ? (mail.text_part ? mail.text_part.body.decoded : nil) : mail.body.decoded
    #    html_part = message.html_part ? message.html_part.body.decoded : nil
        article = Ticket::Article.create(
          :created_by_id            => user.id,
          :ticket_id                => ticket.id, 
          :ticket_article_type_id   => Ticket::Article::Type.where(:name => 'email').first.id,
          :ticket_article_sender_id => Ticket::Article::Sender.where(:name => 'Customer').first.id,
          :body                     => conv(mail.body.charset || 'LATIN1', plain_part), 
          :from                     => mail['from']       ? conv(mail['from'].charset    || 'LATIN1', mail['from'].to_s) : nil,
          :to                       => mail['to']         ? conv(mail['to'].charset      || 'LATIN1', mail['to'].to_s) : nil,
          :cc                       => mail['cc']         ? conv(mail['cc'].charset      || 'LATIN1', mail['cc'].to_s) : nil,
          :subject                  => mail['subject']    ? conv(mail['subject'].charset || 'LATIN1', mail['subject'].to_s) : nil,
          :message_id               => mail['message_id'] ? mail['message_id'].to_s : nil,
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
        if mail.attachments
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
            
            # store file
            Store.add(
              :object      => 'Ticket::Article',
              :o_id        => article.id,
              :data        => attachment.body.decoded,
              :filename    => attachment.filename,
              :preferences => headers_store
            )
          end
        end
  
        # delete email from server after article was created      
        if article
          imap.store(message_id, "+FLAGS", [:Deleted])
        end
      
      end

      # execute ticket events      
      Ticket::Observer::Notification.transaction
    end
    imap.expunge()
    imap.disconnect()
    puts 'done'
  end
  def send(attr, notification = false)
    channel = Channel.where( :area => 'Email::Outbound', :active => true ).first
    begin
      c = eval 'Channel::' + channel[:adapter] + '.new'
      c.send(attr, channel, notification)
    rescue Exception => e
      puts "can't use " + 'Channel::' + channel[:adapter]
      puts e.inspect
    end
  end
end