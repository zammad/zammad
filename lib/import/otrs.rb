module Import::OTRS
  @@url = 'http://vz109.demo.znuny.com/'
  @@key = 'KFWUKfasdjuiU3424k212mALGJU3591KFE'

  def self.request(part)
    url = @@url + part
    puts 'GET:' + url
#    response = Net::HTTP.get_response( URI.parse(url), { :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE } )
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if url =~ /https/i
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
#    puts 'R:' + response.body.to_s
    return response
  end

  def self.json(response)
    data = Encode.conv( 'utf8', response.body.to_s )
    JSON.parse( data )
  end

  def self.start
    puts 'Start import...'

    # set system in import mode
    Setting.set('import_mode', true)

    # check if system is in import mode
    if !Setting.get('import_mode')
        raise "System is not in import mode!"
    end

    response = request("/otrs/public.pl?Key=#{@@key};Action=Export")
    return if response.code.to_s != '200'

#self.ticket('156115')
#return
    # create states
    ticket_state

    # create priorities
    ticket_priority

    # create groups
    ticket_group

    # create agents
    user

    # create customers
#    customer

    result = JSON.parse( response.body )
    while true
      ticket_ids = result.pop(10)
      return if ticket_ids.empty?
      self.ticket(ticket_ids)
    end
    return
#    result.reverse.each { |ticket_id|
    result.each { |ticket_id|
#      sleep 0.1
      ticket = self.ticket(ticket_id)
    }
  end

  def self.ticket(ticket_ids)
    url = "/otrs/public.pl?Key=#{@@key};Action=Export;Type=Ticket;"
    ticket_ids.each {|ticket_id|
      url = url + "TicketID=#{CGI::escape ticket_id};"
    }
    response = request( url )
    return if response.code.to_s != '200'

    result = json(response)
#    puts result.inspect
    map = {
      :Ticket => {
        :Changed                => :updated_at,
        :Created                => :created_at,
        :CreateBy               => :created_by_id,
        :TicketNumber           => :number,
        :QueueID                => :group_id,
        :StateID                => :ticket_state_id,
        :PriorityID             => :ticket_priority_id,
        :Owner                  => :owner,
        :CustomerUserID         => :customer,
        :Title                  => :title,
        :TicketID               => :id,
        :FirstResponse          => :first_response,
#        :FirstResponseInMin     => ?,
#        :FirstResponseDiffInMin => ?,
        :Closed                 => :close_time,
#        :CloseTimeInMin         => ?,
#        :CloseTimeDiffInMin     => ?,
      },
      :Article => {
        :SenderType  => :ticket_article_sender,
        :ArticleType => :ticket_article_type,
        :TicketID    => :ticket_id,
        :ArticleID   => :id,
        :Body        => :body,
        :From        => :from,
        :To          => :to,
        :Cc          => :cc,
        :Subject     => :subject,
        :InReplyTo   => :in_reply_to,
        :MessageID   => :message_id,
#        :ReplyTo    => :reply_to,
        :References  => :references,
        :Changed      => :updated_at,
        :Created      => :created_at,
        :ChangedBy    => :updated_by_id,
        :CreatedBy    => :created_by_id,
      },
    }

    result.each {|record|
        ticket_new = {
          :created_by_id => 1,
          :updated_by_id => 1,
        }
        map[:Ticket].each { |key,value|
          if record['Ticket'][key.to_s]
            ticket_new[value] = Encode.conv( 'utf8', record['Ticket'][key.to_s] )
          end
        }
#      puts key.to_s
#      puts value.to_s
#puts 'new ticket data ' + ticket_new.inspect
    # check if state already exists
        ticket_old = Ticket.where( :id => ticket_new[:id] ).first
#puts 'TICKET OLD ' + ticket_old.inspect
    # find user
        if ticket_new[:owner]
          user = User.where( :login => ticket_new[:owner] ).first
          if user
            ticket_new[:owner_id] = user.id
          else
            ticket_new[:owner_id] = 1
          end
          ticket_new.delete(:owner)
        end
    if ticket_new[:customer]
      user = User.where( :login => ticket_new[:customer] ).first
      if user
        ticket_new[:customer_id] = user.id
      else
        ticket_new[:customer_id] =  1
      end
      ticket_new.delete(:customer)
    else
      ticket_new[:customer_id] = 1
    end
#    puts 'ttt' + ticket_new.inspect
    # set state types
    if ticket_old
      puts "update Ticket.find(#{ticket_new[:id]})"
      ticket_old.update_attributes(ticket_new)
    else
      puts "add Ticket.find(#{ticket_new[:id]})"
      ticket = Ticket.new(ticket_new)
      ticket.id = ticket_new[:id]
      ticket.save
    end

    record['Articles'].each { |article|

      # get article values
      article_new = {
        :created_by_id => 1,
        :updated_by_id => 1,
      }
      map[:Article].each { |key,value|
        if article[key.to_s]
          article_new[value] = Encode.conv( 'utf8', article[key.to_s] )
        end
      }
      # create customer/sender if needed
      if article_new[:ticket_article_sender] == 'customer' && article_new[:created_by_id].to_i == 1 && !article_new[:from].empty?
        # set extra headers
        begin
          email = Mail::Address.new( article_new[:from] ).address
        rescue
          email = article_new[:from]
          if article_new[:from] =~ /<(.+?)>/
            email = $1
          end
        end
        user = User.where( :email => email ).first
        if !user
          begin
            display_name = Mail::Address.new( article_new[:from] ).display_name ||
              ( Mail::Address.new( article_new[:from] ).comments && Mail::Address.new( article_new[:from] ).comments[0] )
          rescue
            display_name = article_new[:from]
          end

          # do extra decoding because we needed to use field.value
          display_name = Mail::Field.new( 'X-From', display_name ).to_s

          roles = Role.where( :name => 'Customer' )
          user = User.create(
            :login          => email,
            :firstname      => display_name,
            :lastname       => '',
            :email          => email,
            :password       => '',
            :active         => true,
            :roles          => roles,
            :updated_by_id  => 1,
            :created_by_id  => 1,
          )
        end
        article_new[:created_by_id] = user.id
      end

      if article_new[:ticket_article_sender] == 'customer'
        article_new[:ticket_article_sender_id] = Ticket::Article::Sender.lookup( :name => 'Customer' ).id
        article_new.delete( :ticket_article_sender )
      end
      if article_new[:ticket_article_sender] == 'agent'
        article_new[:ticket_article_sender_id] = Ticket::Article::Sender.lookup( :name => 'Agent' ).id
        article_new.delete( :ticket_article_sender )
      end
      if article_new[:ticket_article_sender] == 'system'
        article_new[:ticket_article_sender_id] = Ticket::Article::Sender.lookup( :name => 'System' ).id
        article_new.delete( :ticket_article_sender )
      end

      if article_new[:ticket_article_type] == 'email-external'
        article_new[:ticket_article_type_id] = Ticket::Article::Type.lookup( :name => 'email' ).id
        article_new[:internal] = false
      elsif article_new[:ticket_article_type] == 'email-internal'
        article_new[:ticket_article_type_id] = Ticket::Article::Type.lookup( :name => 'email' ).id
        article_new[:internal] = true
      elsif article_new[:ticket_article_type] == 'note-external'
        article_new[:ticket_article_type_id] = Ticket::Article::Type.lookup( :name => 'note' ).id
        article_new[:internal] = false
      elsif article_new[:ticket_article_type] == 'note-internal'
        article_new[:ticket_article_type_id] = Ticket::Article::Type.lookup( :name => 'note' ).id
        article_new[:internal] = true
      elsif article_new[:ticket_article_type] == 'phone'
        article_new[:ticket_article_type_id] = Ticket::Article::Type.lookup( :name => 'phone' ).id
        article_new[:internal] = false
      elsif article_new[:ticket_article_type] == 'webrequest'
        article_new[:ticket_article_type_id] = Ticket::Article::Type.lookup( :name => 'web' ).id
        article_new[:internal] = false
      else
        article_new[:ticket_article_type_id] = 9
      end
      article_new.delete( :ticket_article_type )
      article_old = Ticket::Article.where( :id => article_new[:id] ).first
#puts 'ARTICLE OLD ' + article_old.inspect
      # set state types
      if article_old
        puts "update Ticket::Article.find(#{article_new[:id]})"
#        puts article_new.inspect
        article_old.update_attributes(article_new)
      else
        puts "add Ticket::Article.find(#{article_new[:id]})"
        article = Ticket::Article.new(article_new)
        article.id = article_new[:id]
        article.save
      end

    }

    record['History'].each { |history|
#      puts '-------'
#      puts history.inspect
      if history['HistoryType'] == 'NewTicket'
        History.history_create(
          :id                 => history['HistoryID'],
          :o_id               => history['TicketID'],
          :history_type       => 'created',
          :history_object     => 'Ticket',
          :created_at         => history['CreateTime'],
          :created_by_id      => history['CreateBy']
        )
      end
      if history['HistoryType'] == 'StateUpdate'
        data = history['Name']
        # "%%new%%open%%"
        from = nil
        to   = nil
        if data =~ /%%(.+?)%%(.+?)%%/
          from = $1
          to   = $2
        end
        History.history_create(
          :id                 => history['HistoryID'],
          :o_id               => history['TicketID'],
          :history_type       => 'updated',
          :history_object     => 'Ticket',
          :history_attribute  => 'ticket_state',
          :value_from         => from,
          :value_to           => to,
          :created_at         => history['CreateTime'],
          :created_by_id      => history['CreateBy']
        )
      end
      if history['HistoryType'] == 'Move'
        data = history['Name']
        # "%%Queue1%%5%%Postmaster%%1"
        from = nil
        to   = nil
        if data =~ /%%(.+?)%%(.+?)%%(.+?)%%(.+?)$/
          from    = $1
          from_id = $2
          to      = $3
          to_id   = $4
        end
        History.history_create(
          :id                 => history['HistoryID'],
          :o_id               => history['TicketID'],
          :history_type       => 'updated',
          :history_object     => 'Ticket',
          :history_attribute  => 'group',
          :value_from         => from,
          :value_to           => to,
          :id_from            => from_id,
          :id_to              => to_id,
          :created_at         => history['CreateTime'],
          :created_by_id      => history['CreateBy']
        )
      end
      if history['HistoryType'] == 'Move'
        data = history['Name']
        # "%%Queue1%%5%%Postmaster%%1"
        from = nil
        to   = nil
        if data =~ /%%(.+?)%%(.+?)%%(.+?)%%(.+?)$/
          from    = $1
          from_id = $2
          to      = $3
          to_id   = $4
        end
        History.history_create(
          :id                 => history['HistoryID'],
          :o_id               => history['TicketID'],
          :history_type       => 'updated',
          :history_object     => 'Ticket',
          :history_attribute  => 'group',
          :value_from         => from,
          :value_to           => to,
          :id_from            => from_id,
          :id_to              => to_id,
          :created_at         => history['CreateTime'],
          :created_by_id      => history['CreateBy']
        )
      end
      if history['HistoryType'] == 'PriorityUpdate'
        data = history['Name']
        # "%%3 normal%%3%%5 very high%%5"
        from = nil
        to   = nil
        if data =~ /%%(.+?)%%(.+?)%%(.+?)%%(.+?)$/
          from    = $1
          from_id = $2
          to      = $3
          to_id   = $4
        end
        History.history_create(
          :id                 => history['HistoryID'],
          :o_id               => history['TicketID'],
          :history_type       => 'updated',
          :history_object     => 'Ticket',
          :history_attribute  => 'ticket_priority',
          :value_from         => from,
          :value_to           => to,
          :id_from            => from_id,
          :id_to              => to_id,
          :created_at         => history['CreateTime'],
          :created_by_id      => history['CreateBy']
        )
      end
      if history['ArticleID'] && history['ArticleID'] != 0
        History.history_create(
          :id                 => history['HistoryID'],
          :o_id               => history['ArticleID'],
          :history_type       => 'created',
          :history_object     => 'Ticket::Article',
          :related_o_id       => history['TicketID'],
          :related_history_object => 'Ticket',
          :created_at         => history['CreateTime'],
          :created_by_id      => history['CreateBy']
        )
      end
    }
    }
  end

  def self.ticket_state
    response = request( "/otrs/public.pl?Key=#{@@key};Action=Export;Type=State" )
    return if response.code.to_s != '200'

    result = json(response)
#    puts result.inspect
    map = {
      :ChangeTime   => :updated_at,
      :CreateTime   => :created_at,
      :CreateBy     => :created_by_id,
      :ChangeBy     => :updated_by_id,
      :Name         => :name,
      :ID           => :id,
      :ValidID      => :active,
      :Comment      => :note,
    };

    Ticket::State.all.each {|state|
      state.name = state.name + '_tmp'
      state.save
    }

    result.each { |state|
      _set_valid(state)

      # get new attributes
      state_new = {
        :created_by_id => 1,
        :updated_by_id => 1,
      }
      map.each { |key,value|
        if state[key.to_s]
          state_new[value] = state[key.to_s]
        end
      }

      # check if state already exists
      state_old = Ticket::State.where( :id => state_new[:id] ).first
#      puts 'st: ' + state['TypeName']

      # set state types
      if state['TypeName'] == 'pending auto'
        state['TypeName'] = 'pending action'
      end
      ticket_state_type = Ticket::StateType.where( :name =>  state['TypeName'] ).first
      state_new[:state_type_id] = ticket_state_type.id
      if state_old
        state_old.update_attributes(state_new)
      else
        state = Ticket::State.new(state_new)
        state.id = state_new[:id]
        state.save
      end
    }
  end
  def self.ticket_priority
    response = request( "/otrs/public.pl?Key=#{@@key};Action=Export;Type=Priority" )
    return if response.code.to_s != '200'

    result = json(response)
    map = {
      :ChangeTime   => :updated_at,
      :CreateTime   => :created_at,
      :CreateBy     => :created_by_id,
      :ChangeBy     => :updated_by_id,
      :Name         => :name,
      :ID           => :id,
      :ValidID      => :active,
      :Comment      => :note,
    };

    result.each { |priority|
      _set_valid(priority)

      # get new attributes
      priority_new = {
        :created_by_id => 1,
        :updated_by_id => 1,
      }
      map.each { |key,value|
        if priority[key.to_s]
          priority_new[value] = priority[key.to_s]
        end
      }

      # check if state already exists
      priority_old = Ticket::Priority.where( :id => priority_new[:id] ).first

      # set state types
      if priority_old
        priority_old.update_attributes(priority_new)
      else
        priority = Ticket::Priority.new(priority_new)
        priority.id = priority_new[:id]
        priority.save
      end
    }
  end
  def self.ticket_group
    response = request( "/otrs/public.pl?Key=#{@@key};Action=Export;Type=Queue" )
    return if response.code.to_s != '200'

    result = json(response)
    map = {
      :ChangeTime   => :updated_at,
      :CreateTime   => :created_at,
      :CreateBy     => :created_by_id,
      :ChangeBy     => :updated_by_id,
      :Name         => :name,
      :QueueID      => :id,
      :ValidID      => :active,
      :Comment      => :note,
    };

    result.each { |group|
      _set_valid(group)

      # get new attributes
      group_new = {
        :created_by_id => 1,
        :updated_by_id => 1,
      }
      map.each { |key,value|
        if group[key.to_s]
          group_new[value] = group[key.to_s]
        end
      }

      # check if state already exists
      group_old = Group.where( :id => group_new[:id] ).first

      # set state types
      if group_old
        group_old.update_attributes(group_new)
      else
        group = Group.new(group_new)
        group.id = group_new[:id]
        group.save
      end
    }
  end
  def self.user
    response = request( "/otrs/public.pl?Key=#{@@key};Action=Export;Type=User" )
    return if response.code.to_s != '200'
    result = json(response)
    map = {
      :ChangeTime    => :updated_at,
      :CreateTime    => :created_at,
      :CreateBy      => :created_by_id,
      :ChangeBy      => :updated_by_id,
      :UserID        => :id,
      :ValidID       => :active,
      :Comment       => :note,
      :UserEmail     => :email,
      :UserFirstname => :firstname,
      :UserLastname  => :lastname,
#      :UserTitle     => 
      :UserLogin     => :login,
      :UserPw        => :password, 
    };

    result.each { |user|
#      puts 'USER: ' + user.inspect
#      if user['UserID'] != 1
        _set_valid(user)
#      puts 'USER: ' + user.inspect

        # get new attributes
        user_new = {
          :created_by_id => 1,
          :updated_by_id => 1,
          :source        => 'OTRS Import',
          :role_ids      => [1,2],
        }
        map.each { |key,value|
          if user[key.to_s]
            user_new[value] = user[key.to_s]
          end
        }

        # check if state already exists
#        user_old = User.where( :login => user_new[:login] ).first
        user_old = User.where( :id => user_new[:id] ).first

        # set state types
        if user_old
          puts "update User.find(#{user_new[:id]})"
#          puts 'Update User' + user_new.inspect
          user_old.update_attributes(user_new)
        else
          puts "add User.find(#{user_new[:id]})"
#          puts 'Add User' + user_new.inspect
          user = User.new(user_new)
          user.id = user_new[:id]
          user.save
        end

#      end
    }
  end
  def self.customer
    done = false
    count = 0
    while done == false
      sleep 2
      puts "Count=#{count};Offset=#{count}"
      response = request( "/otrs/public.pl?Key=#{@@key};Action=Export;Type=Customer;Count=100;Offset=#{count}" )
      count = count + 3000
      return if response.code.to_s != '200'
      result = json(response)
      map = {
        :ChangeTime    => :updated_at,
        :CreateTime    => :created_at,
        :CreateBy      => :created_by_id,
        :ChangeBy      => :updated_by_id,
        :ValidID       => :active,
        :UserComment   => :note,
        :UserEmail     => :email,
        :UserFirstname => :firstname,
        :UserLastname  => :lastname,
  #      :UserTitle     => 
        :UserLogin     => :login,
        :UserPassword  => :password,
        :UserPhone     => :phone,
        :UserFax       => :fax,
        :UserMobile    => :mobile,
        :UserStreet    => :street,
        :UserZip       => :zip,
        :UserCity      => :city,
        :UserCountry   => :country,
      };

      done = true
      result.each { |user|
        done = false
        _set_valid(user)

        # get new attributes
        user_new = {
          :created_by_id => 1,
          :updated_by_id => 1,
          :source        => 'OTRS Import',
          :role_ids      => [3],
        }
        map.each { |key,value|
          if user[key.to_s]
            user_new[value] = user[key.to_s]
          end
        }

        # check if state already exists
  #        user_old = User.where( :login => user_new[:login] ).first
        user_old = User.where( :login => user_new[:login] ).first

        # set state types
        if user_old
          puts "update User.find(#{user_new[:id]})"
#          puts 'Update User' + user_new.inspect
          user_old.update_attributes(user_new)
        else
#          puts 'Add User' + user_new.inspect
          puts "add User.find(#{user_new[:id]})"
          user = User.new(user_new)
          user.save
        end
      }
    end
  end
  def self._set_valid(record)
      # map
      if record['ValidID'] == '3'
        record['ValidID'] = '2'
      end
      if record['ValidID'] == '2'
        record['ValidID'] = false
      end
      if record['ValidID'] == '1'
        record['ValidID'] = true
      end
      if record['ValidID'] == '0'
        record['ValidID'] = false
      end
  end
end
