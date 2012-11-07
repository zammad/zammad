# encoding: utf-8

require 'mail'
require 'iconv'
class Channel::EmailParser
  def conv (charset, string)
    if !charset || charset == 'US-ASCII' || charset == 'ASCII-8BIT'
      charset = 'LATIN1'
    end
    return string if charset.downcase == 'utf8' || charset.downcase == 'utf-8'
#    puts '-------' + charset
#    puts string
#    string.encode("UTF-8")
    Iconv.conv( 'UTF8', charset, string )
  end

=begin

  mail = parse( msg_as_string )

  mail = {
    :from               => 'Some Name <some@example.com>',
    :from_email         => 'some@example.com',
    :from_local         => 'some',
    :from_domain        => 'example.com',
    :from_display_name  => 'Some Name',
    :message_id         => 'some_message_id@example.com',
    :to                 => 'Some System <system@example.com>',
    :cc                 => 'Somebody <somebody@example.com>',
    :subject            => 'some message subject',
    :body               => 'some message body',
    :attachments        => [
      {
        :data        => 'binary of attachment',
        :filename    => 'file_name_of_attachment.txt',
        :preferences => {
          :content-alternative => true,
          :Mime-Type           => 'text/plain',
          :Charset             => 'iso-8859-1',
        },
      },
    ],

    # ignore email header
    :x-zammad-ignore => 'false',

    # customer headers
    :x-zammad-customer-login     => '',
    :x-zammad-customer-email     => '',
    :x-zammad-customer-firstname => '',
    :x-zammad-customer-lastname  => '',

    # ticket headers
    :x-zammad-group    => 'some_group',
    :x-zammad-state    => 'some_state',
    :x-zammad-priority => 'some_priority',
    :x-zammad-owner    => 'some_owner_login',

    # article headers
    :x-zammad-article-visability => 'internal',
    :x-zammad-article-type       => 'agent',
    :x-zammad-article-sender     => 'customer',

    # all other email headers
    :some-header => 'some_value',
  }

=end

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
    data[:from_display_name] = Mail::Address.new( mail[:from].value ).display_name ||
      ( Mail::Address.new( mail[:from].value ).comments && Mail::Address.new( mail[:from].value ).comments[0] )

    # do extra decoding because we needed to use field.value
    data[:from_display_name] = Mail::Field.new( 'X-From', data[:from_display_name] ).to_s

    # compat headers
    data[:message_id] = data['message-id'.to_sym]

    # body
#    plain_part = mail.multipart? ? (mail.text_part ? mail.text_part.body.decoded : nil) : mail.body.decoded
#    html_part = message.html_part ? message.html_part.body.decoded : nil
    data[:attachments] = []

    # multi part email
    if mail.multipart?

      # text attachment/body exists
      if mail.text_part
        data[:body] = mail.text_part.body.decoded
        data[:body] = conv( mail.text_part.charset, data[:body] )

      # html attachment/body may exists and will be converted to text
      else
        filename = '-no name-'
        if mail.html_part.body
          filename = 'html-email'
          data[:body] = mail.html_part.body.to_s
          data[:body] = conv( mail.html_part.charset.to_s, data[:body] )
          data[:body] = html2ascii( data[:body] )

        # any other attachments
        else
          data[:body] = 'no visible content'
        end
      end

      # add html attachment/body as real attachment
      if mail.html_part
        filename = 'message.html'
        headers_store = {
          'content-alternative' => true,
        }
        if mail.mime_type
          headers_store['Mime-Type'] = mail.html_part.mime_type
        end
        if mail.charset
          headers_store['Charset'] = mail.html_part.charset
        end
        attachment = {
          :data        => mail.html_part.body.to_s,
          :filename    => mail.html_part.filename || filename,
          :preferences => headers_store
        }
        data[:attachments].push attachment
      end

      # get attachments
      if mail.has_attachments?
        mail.attachments.each { |file|

          # get file preferences
          headers_store = {}
          file.header.fields.each { |field|
            headers_store[field.name.to_s] = field.value.to_s
          }

          # get filename from content-disposition
          filename = nil
          if file.header[:content_disposition] && file.header[:content_disposition].filename
            filename = file.header[:content_disposition].filename
          end

          # for some broken sm mail clients (X-MimeOLE: Produced By Microsoft Exchange V6.5)
          if !filename
            filename = file.header[:content_location].to_s
          end

          # get mime type
          if file.header[:content_type] && file.header[:content_type].string
            headers_store['Mime-Type'] = file.header[:content_type].string
          end

          # get charset
          if file.header && file.header.charset
            headers_store['Charset'] = file.header.charset
          end

          # remove not needed header
          headers_store.delete('Content-Transfer-Encoding')
          headers_store.delete('Content-Disposition')

          attach = {
            :data        => file.body.to_s,
            :filename    => filename,
            :preferences => headers_store,
          }

          data[:attachments].push attach
        }
      end

    # not multipart email
    else

      # text part
      if !mail.mime_type || mail.mime_type.to_s ==  '' || mail.mime_type.to_s.downcase == 'text/plain'
        data[:body] = mail.body.decoded
        data[:body] = conv( mail.charset, data[:body] )

      # html part
      else
        filename = '-no name-'
        if mail.mime_type.to_s.downcase == 'text/html'
          filename = 'html-email'
          data[:body] = mail.body.decoded
          data[:body] = conv( mail.charset, data[:body] )
          data[:body] = html2ascii( data[:body] )

        # any other attachments
        else
          data[:body] = 'no visible content'
        end

        # add body as attachment
        headers_store = {
          'content-alternative' => true,
        }
        if mail.mime_type
          headers_store['Mime-Type'] = mail.mime_type
        end
        if mail.charset
          headers_store['Charset'] = mail.charset
        end
        attachment = {
          :data        => mail.body.decoded,
          :filename    => mail.filename || filename,
          :preferences => headers_store
        }
        data[:attachments].push attachment
      end
    end

    # strip not wanted chars
    data[:body].gsub!( /\r\n/, "\n" )
    data[:body].gsub!( /\r/, "\n" )

    return data
  end

  def process(channel, msg)
    mail = parse( msg )

    # run postmaster pre filter
    filters = {
      '0010' => Channel::Filter::Trusted,
      '1000' => Channel::Filter::Database,
    }

    # filter( channel, mail )
    filters.each {|prio, backend|
      begin
        backend.run( channel, mail )
      rescue Exception => e
        puts "can't run postmaster pre filter #{backend}"
        puts e.inspect
        return false
      end
    }

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
          :updated_by_id  => 1,
          :created_by_id  => 1,
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

        # if tickte is merged, find linked ticket
        if ticket_state_type.name == 'merged'

        end

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
          :title              => mail[:subject] || '',
          :ticket_state_id    => Ticket::State.where( :name => 'new' ).first.id,
          :ticket_priority_id => Ticket::Priority.where( :name => '2 normal' ).first.id,
          :updated_by_id      => user.id,
          :created_by_id      => user.id,
        }

        # x-headers lookup
        map = [
          [ 'x-zammad-group',    Group,            'group_id',           'name'  ],
          [ 'x-zammad-state',    Ticket::State,    'ticket_state_id',    'name'  ],
          [ 'x-zammad-priority', Ticket::Priority, 'ticket_priority_id', 'name'  ],
          [ 'x-zammad-owner',    User,             'owner_id',           'login' ],
        ]
        object_lookup( ticket_attributes, map, mail )

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
        :updated_by_id            => user.id,
        :ticket_id                => ticket.id, 
        :ticket_article_type_id   => Ticket::Article::Type.where( :name => 'email' ).first.id,
        :ticket_article_sender_id => Ticket::Article::Sender.where( :name => 'Customer' ).first.id,
        :body                     => mail[:body], 
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
      object_lookup( article_attributes, map, mail )

      # create article
      article = Ticket::Article.create(article_attributes)

      # store mail plain
      Store.add(
        :object      => 'Ticket::Article::Mail',
        :o_id        => article.id,
        :data        => msg,
        :filename    => "ticket-#{ticket.number}-#{article.id}.eml",
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

    # run postmaster post filter
    filters = {
#      '0010' => Channel::Filter::Trusted,
    }

    # filter( channel, mail )
    filters.each {|prio, backend|
      begin
        backend.run( channel, mail, ticket, article, user )
      rescue Exception => e
        puts "can't run postmaster post filter #{backend}"
        puts e.inspect
      end
    }

    # return new objects
    return ticket, article, user
  end

  def object_lookup( attributes, map, mail )
    map.each { |item|
      if mail[ item[0].to_sym ]
        new_object = item[1].where( "lower(#{item[3]}) = ?", mail[ item[0].to_sym ].downcase ).first
        if new_object
          attributes[ item[2].to_sym ] = new_object.id
        end
      end
    }
  end

  def html2ascii(string)

    # find <a href=....> and replace it with [x]
    link_list = ''
    counter   = 0
    string.gsub!( /<a\s.*?href=("|')(.+?)("|').*?>/ix ) { |item|
      link = $2
      counter   = counter + 1
      link_list += "[#{counter}] #{link}\n"
      "[#{counter}]"
    }

    # remove empty lines
    string.gsub!( /^\s*/m, '' )

    # fix some bad stuff from opera and others
    string.gsub!( /(\n\r|\r\r\n|\r\n)/, "\n" )

    # strip all other tags
    string.gsub!( /\<(br|br\/|br\s\/)\>/, "\n" )

    # strip all other tags
    string.gsub!( /\<.+?\>/, '' )

    # encode html entities like "&#8211;"
    string.gsub!( /(&\#(\d+);?)/x ) { |item|
      $2.chr
    }

    # encode html entities like "&#3d;"
    string.gsub!( /(&\#[xX]([0-9a-fA-F]+);?)/x ) { |item|
      chr_orig = $1
      hex      = $2.hex
      if hex
        chr = hex.chr
        if chr
          chr
        else
          chr_orig
        end
      else
        chr_orig
      end
    }

    # remove empty lines
    string.gsub!( /^\s*\n\s*\n/m, "\n" )

    # add extracted links
    if link_list
      string += "\n\n" + link_list
    end

    return string
  end
end

# workaround to parse subjects with 2 different encodings correctly (e. g. quoted-printable see test/fixtures/mail9.box)
module Mail
  module Encodings
    def Encodings.value_decode(str)
      # Optimization: If there's no encoded-words in the string, just return it
      return str unless str.index("=?")

      str = str.gsub(/\?=(\s*)=\?/, '?==?') # Remove whitespaces between 'encoded-word's

      # Split on white-space boundaries with capture, so we capture the white-space as well
      str.split(/([ \t])/).map do |text|
        if text.index('=?') .nil?
          text
        else
          # Join QP encoded-words that are adjacent to avoid decoding partial chars
#          text.gsub!(/\?\=\=\?.+?\?[Qq]\?/m, '') if text =~ /\?==\?/

          # Search for occurences of quoted strings or plain strings
          text.scan(/(                                  # Group around entire regex to include it in matches
                       \=\?[^?]+\?([QB])\?[^?]+?\?\=  # Quoted String with subgroup for encoding method
                       |                                # or
                       .+?(?=\=\?|$)                    # Plain String
                     )/xmi).map do |matches|
            string, method = *matches
            if    method == 'b' || method == 'B'
              b_value_decode(string)
            elsif method == 'q' || method == 'Q'
              q_value_decode(string)
            else
              string
            end
          end
        end
      end.join("")
    end
  end
end