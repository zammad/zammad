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

    # set all headers
    mail.header.fields.each { |field|
      data[field.name.downcase.to_sym] = field.to_s
    }

    # set extra headers
    data[:from_email]        = Mail::Address.new( mail[:from].value ).address
    data[:from_local]        = Mail::Address.new( mail[:from].value ).local
    data[:from_domain]       = Mail::Address.new( mail[:from].value ).domain
    data[:from_display_name] = Mail::Address.new( mail[:from].value ).display_name

    # do extra decoding because we needed to use field.value
    data[:from_display_name] = Mail::Field.new( 'X-From', data[:from_display_name] ).to_s

    # compat headers
    data[:message_id] = data['message-id'.to_sym]

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

    # check if trust x-headers
    if !channel[:trusted]
      mail.each {|key, value|
        if key =~ /^x-zammad/i
          mail.delete(key)
        end
      }
    end

    # check ignore header
    return true if mail[ 'x-zammad-ignore'.to_sym ] == 'true' || mail[ 'x-zammad-ignore'.to_sym ] == true

    ticket  = nil
    article = nil
    user    = nil

    # use transaction
    ActiveRecord::Base.transaction do

      if mail[ 'x-zammad-customer-login'.to_sym ]
        user = User.where( :login => mail[ 'x-zammad-customer-login'.to_sym ] ).first
      end
      if !user
        user = User.where( :email => mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email] ).first
      end
      if !user
        puts 'create user...'
        roles = Role.where( :name => 'Customer' )
        user = User.create(
          :login          => mail[ 'x-zammad-customer-login'.to_sym ] || mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email],
          :firstname      => mail[ 'x-zammad-customer-firstname'.to_sym ] || mail[:from_display_name],
          :lastname       => mail[ 'x-zammad-customer-lastname'.to_sym ],
          :email          => mail[ 'x-zammad-customer-email'.to_sym ] || mail[:from_email],
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
      if !ticket

        # set attributes
        ticket_attributes = {
          :group_id           => channel[:group_id] || 1,
          :customer_id        => user.id,
          :title              => mail[:subject],
          :ticket_state_id    => Ticket::State.where( :name => 'new' ).first.id,
          :ticket_priority_id => Ticket::Priority.where( :name => '2 normal' ).first.id,
          :created_by_id      => user.id,
        }

        # x-headers lookup
        map = [
          [ 'x-zammad-group',    Group,            'group_id',           'name'  ],
          [ 'x-zammad-state',    Ticket::State,    'ticket_state_id',    'name'  ],
          [ 'x-zammad-priority', Ticket::Priority, 'ticket_priority_id', 'name'  ],
          [ 'x-zammad-owner',    User,             'owner_id',           'login' ],
        ]
        map.each { |item|
          if mail[ item[0].to_sym ]
            if item[1].where( item[3].to_sym => mail[ item[0].to_sym ] ).first
              ticket_attributes[ item[2].to_sym ] = item[1].where( item[3].to_sym => mail[ item[0].to_sym ] ).first.id
            end
          end
        }

        # create ticket
        ticket = Ticket.create( ticket_attributes )
      end
  
      # import mail
  
      # set attributes
      internal = false
      if mail[ 'X-Zammad-Article-Visability'.to_sym ] && mail[ 'X-Zammad-Article-Visability'.to_sym ] == 'internal'
        internal = true
      end
      article_attributes = {
        :created_by_id            => user.id,
        :ticket_id                => ticket.id, 
        :ticket_article_type_id   => Ticket::Article::Type.where( :name => 'email' ).first.id,
        :ticket_article_sender_id => Ticket::Article::Sender.where( :name => 'Customer' ).first.id,
        :body                     => mail[:plain_part], 
        :from                     => mail[:from],
        :to                       => mail[:to],
        :cc                       => mail[:cc],
        :subject                  => mail[:subject],
        :message_id               => mail[:message_id],
        :internal                 => internal,
      }

      # x-headers lookup
      map = [
        [ 'x-zammad-article-type',    Ticket::Article::Type,   'ticket_article_type_id',   'name' ],
        [ 'x-zammad-article-sender',  Ticket::Article::Sender, 'ticket_article_sender_id', 'name' ],
      ]
      map.each { |item|
        if mail[ item[0].to_sym ]
          if item[1].where( item[3].to_sym => mail[ item[0].to_sym ] ).first
            article_attributes[ item[2].to_sym ] = item[1].where( item[3].to_sym => mail[ item[0].to_sym ] ).first.id
          end
        end
      }

      # create article
      article = Ticket::Article.create(article_attributes)

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
    end

    # execute ticket events      
    Ticket::Observer::Notification.transaction

    # return new objects
    return ticket, article, user
  end
end