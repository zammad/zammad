module Import
end
module Import::OTRS
  def self.request(part)
    url = Setting.get('import_otrs_endpoint') + '/' + part + ';Key=' + Setting.get('import_otrs_endpoint_key')
    Rails.logger.info 'GET: ' + url
    response = UserAgent.request(
      url,
      {
        user: Setting.get('import_otrs_user'),
        password: Setting.get('import_otrs_password'),
      },
    )
    if !response.success?
      Rails.logger.info "ERROR: #{response.error}"
      return
    end
    response
  end
  def self.post(base, data)
    url = Setting.get('import_otrs_endpoint') + '/' + base
    data['Key'] = Setting.get('import_otrs_endpoint_key')
    Rails.logger.info 'POST: ' + url
    response = UserAgent.request(
      url,
      {
        method: 'post',
        data: data,
        user: Setting.get('import_otrs_user'),
        password: Setting.get('import_otrs_password'),
      },
    )
    if !response.success?
      Rails.logger.info "ERROR: #{response.error}"
      return
    end
    response
  end

  def self.json(response)
    data = Encode.conv( 'utf8', response.body.to_s )
    JSON.parse( data )
  end

  def self.auth(username, password)
    response = post( 'public.pl', { Action: 'Export', Type: 'Auth', User: username, Pw: password } )
    return if !response
    return if !response.success?

    result = json(response)
    result
  end

  def self.session(session_id)
    response = post( 'public.pl', { Action: 'Export', Type: 'SessionCheck', SessionID: session_id } )
    return if !response
    return if !response.success?

    result = json(response)
    result
  end

  def self.permission_sync(user, result, config)

    # check if required OTRS group exists
    types = {
      required_group_ro: 'groups_ro',
      required_group_rw: 'groups_rw',
    }
    types.each {|config_key, result_key|
      if config[config_key]
        return false if !result[result_key].value?( config[config_key] )
      end
    }

    # sync roles / groups
    if config[:group_ro_role_map] || config[:group_rw_role_map]
      user.role_ids = []
      user.save
    end
    types = {
      group_ro_role_map: 'groups_ro',
      group_rw_role_map: 'groups_rw',
    }
    types.each {|config_key, result_key|
      next if !config[config_key]
      config[config_key].each {|otrs_group, role|
        next if !result[result_key].value?( otrs_group )
        role_ids = user.role_ids
        role = Role.where( name: role ).first
        next if !role
        role_ids.push role.id
        user.role_ids = role_ids
        user.save
      }
    }

    if config[:always_role]
      config[:always_role].each {|role, active|
        next if !active
        role_ids = user.role_ids
        role = Role.where( name: role ).first
        next if !role
        role_ids.push role.id
        user.role_ids = role_ids
        user.save
      }
    end

  end

  def self.start
    Rails.logger.info 'Start import...'

#    # set system in import mode
#    Setting.set('import_mode', true)

    # check if system is in import mode
    if !Setting.get('import_mode')
      fail 'System is not in import mode!'
    end

    response = request('public.pl?Action=Export')
    return if !response
    return if !response.success?

#self.ticket('156115')
#return
    # create states
    state

    # create priorities
    priority

    # create groups
    ticket_group

    # create agents
    user

    # create customers
#    customer

    result = JSON.parse( response.body )
    result = result.reverse

    Thread.abort_on_exception = true
    thread_count = 4
    threads = {}
    (1..thread_count).each {|thread|
      threads[thread] = Thread.new {
        sleep thread * 3
        Rails.logger.info "Started import thread# #{thread} ..."
        run = true
        while run
          ticket_ids = result.pop(20)
          if !ticket_ids.empty?
            self.ticket(ticket_ids)
          else
            Rails.logger.info "... thread# #{thread}, no more work."
            run = false
          end
        end
      }
    }
    (1..thread_count).each {|thread|
      threads[thread].join
    }

  end

  def self.diff_worker
    return if !Setting.get('import_mode')
    return if Setting.get('import_otrs_endpoint') == 'http://otrs_host/otrs'
    self.diff
  end

  def self.diff
    Rails.logger.info 'Start diff...'

    # check if system is in import mode
    if !Setting.get('import_mode')
      fail 'System is not in import mode!'
    end

    # create states
    state

    # create priorities
    priority

    # create groups
    ticket_group

    # create agents
    user

    self.ticket_diff()

  end

  def self.ticket_diff()
    url = 'public.pl?Action=Export;Type=TicketDiff;Limit=30'
    response = request( url )
    return if !response
    return if !response.success?
    result = json(response)
    self._ticket_result(result)
  end

  def self.ticket(ticket_ids)
    url = 'public.pl?Action=Export;Type=Ticket;'
    ticket_ids.each {|ticket_id|
      url = url + "TicketID=#{CGI.escape ticket_id};"
    }
    response = request( url )
    return if !response
    return if !response.success?

    result = json(response)
    self._ticket_result(result)
  end

  def self._ticket_result(result)
#    Rails.logger.info result.inspect
    map = {
      Ticket: {
        Changed: :updated_at,
        Created: :created_at,
        CreateBy: :created_by_id,
        TicketNumber: :number,
        QueueID: :group_id,
        StateID: :state_id,
        PriorityID: :priority_id,
        Owner: :owner,
        CustomerUserID: :customer,
        Title: :title,
        TicketID: :id,
        FirstResponse: :first_response,
#        :FirstResponseTimeDestinationDate => :first_response_escal_date,
#        :FirstResponseInMin               => :first_response_in_min,
#        :FirstResponseDiffInMin           => :first_response_diff_in_min,
        Closed: :close_time,
#        :SoltutionTimeDestinationDate     => :close_time_escal_date,
#        :CloseTimeInMin                   => :close_time_in_min,
#        :CloseTimeDiffInMin               => :close_time_diff_in_min,
      },
      Article: {
        SenderType: :sender,
        ArticleType: :type,
        TicketID: :ticket_id,
        ArticleID: :id,
        Body: :body,
        From: :from,
        To: :to,
        Cc: :cc,
        Subject: :subject,
        InReplyTo: :in_reply_to,
        MessageID: :message_id,
#        :ReplyTo    => :reply_to,
        References: :references,
        Changed: :updated_at,
        Created: :created_at,
        ChangedBy: :updated_by_id,
        CreatedBy: :created_by_id,
      },
    }

    result.each {|record|

      # use transaction
      ActiveRecord::Base.transaction do

        ticket_new = {
          title: '',
          created_by_id: 1,
          updated_by_id: 1,
        }
        map[:Ticket].each { |key, value|
          if record['Ticket'][key.to_s] && record['Ticket'][key.to_s].class == String
            ticket_new[value] = Encode.conv( 'utf8', record['Ticket'][key.to_s] )
          else
            ticket_new[value] = record['Ticket'][key.to_s]
          end
        }
#      Rails.logger.info key.to_s
#      Rails.logger.info value.to_s
#Rails.logger.info 'new ticket data ' + ticket_new.inspect
    # check if state already exists
        ticket_old = Ticket.where( id: ticket_new[:id] ).first
#Rails.logger.info 'TICKET OLD ' + ticket_old.inspect
    # find user
        if ticket_new[:owner]
          user = User.lookup( login: ticket_new[:owner] )
          if user
            ticket_new[:owner_id] = user.id
          else
            ticket_new[:owner_id] = 1
          end
          ticket_new.delete(:owner)
        end
        if ticket_new[:customer]
          user = User.lookup( login: ticket_new[:customer] )
          if user
            ticket_new[:customer_id] = user.id
          else
            ticket_new[:customer_id] =  1
          end
          ticket_new.delete(:customer)
        else
          ticket_new[:customer_id] = 1
        end
#    Rails.logger.info 'ttt' + ticket_new.inspect
        # set state types
        if ticket_old
          Rails.logger.info "update Ticket.find(#{ticket_new[:id]})"
          ticket_old.update_attributes(ticket_new)
        else
          Rails.logger.info "add Ticket.find(#{ticket_new[:id]})"
          ticket = Ticket.new(ticket_new)
          ticket.id = ticket_new[:id]
          ticket.save
        end

        record['Articles'].each { |article|

          # get article values
          article_new = {
            created_by_id: 1,
            updated_by_id: 1,
          }
          map[:Article].each { |key, value|
            if article[key.to_s]
              article_new[value] = Encode.conv( 'utf8', article[key.to_s] )
            end
          }
          # create customer/sender if needed
          if article_new[:sender] == 'customer' && article_new[:created_by_id].to_i == 1 && !article_new[:from].empty?
            # set extra headers
            begin
              email = Mail::Address.new( article_new[:from] ).address
            rescue
              email = article_new[:from]
              if article_new[:from] =~ /<(.+?)>/
                email = $1
              end
            end
            user = User.where( email: email ).first
            if !user
              user = User.where( login: email ).first
            end
            if !user
              begin
                display_name = Mail::Address.new( article_new[:from] ).display_name ||
                               ( Mail::Address.new( article_new[:from] ).comments && Mail::Address.new( article_new[:from] ).comments[0] )
              rescue
                display_name = article_new[:from]
              end

              # do extra decoding because we needed to use field.value
              display_name = Mail::Field.new( 'X-From', display_name ).to_s

              roles = Role.lookup( name: 'Customer' )
              user = User.create(
                login: email,
                firstname: display_name,
                lastname: '',
                email: email,
                password: '',
                active: true,
                role_ids: [roles.id],
                updated_by_id: 1,
                created_by_id: 1,
              )
            end
            article_new[:created_by_id] = user.id
          end

          if article_new[:sender] == 'customer'
            article_new[:sender_id] = Ticket::Article::Sender.lookup( name: 'Customer' ).id
            article_new.delete( :sender )
          end
          if article_new[:sender] == 'agent'
            article_new[:sender_id] = Ticket::Article::Sender.lookup( name: 'Agent' ).id
            article_new.delete( :sender )
          end
          if article_new[:sender] == 'system'
            article_new[:sender_id] = Ticket::Article::Sender.lookup( name: 'System' ).id
            article_new.delete( :sender )
          end

          if article_new[:type] == 'email-external'
            article_new[:type_id] = Ticket::Article::Type.lookup( name: 'email' ).id
            article_new[:internal] = false
          elsif article_new[:type] == 'email-internal'
            article_new[:type_id] = Ticket::Article::Type.lookup( name: 'email' ).id
            article_new[:internal] = true
          elsif article_new[:type] == 'note-external'
            article_new[:type_id] = Ticket::Article::Type.lookup( name: 'note' ).id
            article_new[:internal] = false
          elsif article_new[:type] == 'note-internal'
            article_new[:type_id] = Ticket::Article::Type.lookup( name: 'note' ).id
            article_new[:internal] = true
          elsif article_new[:type] == 'phone'
            article_new[:type_id] = Ticket::Article::Type.lookup( name: 'phone' ).id
            article_new[:internal] = false
          elsif article_new[:type] == 'webrequest'
            article_new[:type_id] = Ticket::Article::Type.lookup( name: 'web' ).id
            article_new[:internal] = false
          else
            article_new[:type_id] = 9
          end
          article_new.delete( :type )
          article_old = Ticket::Article.where( id: article_new[:id] ).first
    #Rails.logger.info 'ARTICLE OLD ' + article_old.inspect
          # set state types
          if article_old
            Rails.logger.info "update Ticket::Article.find(#{article_new[:id]})"
    #        Rails.logger.info article_new.inspect
            article_old.update_attributes(article_new)
          else
            Rails.logger.info "add Ticket::Article.find(#{article_new[:id]})"
            article = Ticket::Article.new(article_new)
            article.id = article_new[:id]
            article.save
          end

        }

        record['History'].each { |history|
    #      Rails.logger.info '-------'
    #      Rails.logger.info history.inspect
          if history['HistoryType'] == 'NewTicket'
            History.add(
              id: history['HistoryID'],
              o_id: history['TicketID'],
              history_type: 'created',
              history_object: 'Ticket',
              created_at: history['CreateTime'],
              created_by_id: history['CreateBy']
            )
          end
          if history['HistoryType'] == 'StateUpdate'
            data = history['Name']
            # "%%new%%open%%"
            from = nil
            to   = nil
            if data =~ /%%(.+?)%%(.+?)%%/
              from    = $1
              to      = $2
              state_from = Ticket::State.lookup( name: from )
              state_to   = Ticket::State.lookup( name: to )
              if state_from
                from_id = state_from.id
              end
              if state_to
                to_id = state_to.id
              end
            end
    #        Rails.logger.info "STATE UPDATE (#{history['HistoryID']}): -> #{from}->#{to}"
            History.add(
              id: history['HistoryID'],
              o_id: history['TicketID'],
              history_type: 'updated',
              history_object: 'Ticket',
              history_attribute: 'state',
              value_from: from,
              id_from: from_id,
              value_to: to,
              id_to: to_id,
              created_at: history['CreateTime'],
              created_by_id: history['CreateBy']
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
            History.add(
              id: history['HistoryID'],
              o_id: history['TicketID'],
              history_type: 'updated',
              history_object: 'Ticket',
              history_attribute: 'group',
              value_from: from,
              value_to: to,
              id_from: from_id,
              id_to: to_id,
              created_at: history['CreateTime'],
              created_by_id: history['CreateBy']
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
            History.add(
              id: history['HistoryID'],
              o_id: history['TicketID'],
              history_type: 'updated',
              history_object: 'Ticket',
              history_attribute: 'priority',
              value_from: from,
              value_to: to,
              id_from: from_id,
              id_to: to_id,
              created_at: history['CreateTime'],
              created_by_id: history['CreateBy']
            )
          end

          next if !history['ArticleID']
          next if history['ArticleID'] == 0

          History.add(
            id: history['HistoryID'],
            o_id: history['ArticleID'],
            history_type: 'created',
            history_object: 'Ticket::Article',
            related_o_id: history['TicketID'],
            related_history_object: 'Ticket',
            created_at: history['CreateTime'],
            created_by_id: history['CreateBy']
          )
        }
      end
    }
  end

  def self.state
    response = request( 'public.pl?Action=Export;Type=State' )
    return if !response
    return if !response.success?

    result = json(response)
#    Rails.logger.info result.inspect
    map = {
      ChangeTime: :updated_at,
      CreateTime: :created_at,
      CreateBy: :created_by_id,
      ChangeBy: :updated_by_id,
      Name: :name,
      ID: :id,
      ValidID: :active,
      Comment: :note,
    }

    Ticket::State.all.each {|state|
      state.name = state.name + '_tmp'
      state.save
    }

    result.each { |state|
      _set_valid(state)

      # get new attributes
      state_new = {
        created_by_id: 1,
        updated_by_id: 1,
      }
      map.each { |key, value|
        if state[key.to_s]
          state_new[value] = state[key.to_s]
        end
      }

      # check if state already exists
      state_old = Ticket::State.where( id: state_new[:id] ).first
#      Rails.logger.info 'st: ' + state['TypeName']

      # set state types
      if state['TypeName'] == 'pending auto'
        state['TypeName'] = 'pending action'
      end
      state_type = Ticket::StateType.where( name: state['TypeName'] ).first
      state_new[:state_type_id] = state_type.id
      if state_old
#        Rails.logger.info 'TS: ' + state_new.inspect
        state_old.update_attributes(state_new)
      else
        state = Ticket::State.new(state_new)
        state.id = state_new[:id]
        state.save
      end
    }
  end
  def self.priority
    response = request( 'public.pl?Action=Export;Type=Priority' )
    return if !response
    return if !response.success?

    result = json(response)
    map = {
      ChangeTime: :updated_at,
      CreateTime: :created_at,
      CreateBy: :created_by_id,
      ChangeBy: :updated_by_id,
      Name: :name,
      ID: :id,
      ValidID: :active,
      Comment: :note,
    }

    result.each { |priority|
      _set_valid(priority)

      # get new attributes
      priority_new = {
        created_by_id: 1,
        updated_by_id: 1,
      }
      map.each { |key, value|
        if priority[key.to_s]
          priority_new[value] = priority[key.to_s]
        end
      }

      # check if state already exists
      priority_old = Ticket::Priority.where( id: priority_new[:id] ).first

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
    response = request( 'public.pl?Action=Export;Type=Queue' )
    return if !response
    return if !response.success?

    result = json(response)
    map = {
      ChangeTime: :updated_at,
      CreateTime: :created_at,
      CreateBy: :created_by_id,
      ChangeBy: :updated_by_id,
      Name: :name,
      QueueID: :id,
      ValidID: :active,
      Comment: :note,
    }

    result.each { |group|
      _set_valid(group)

      # get new attributes
      group_new = {
        created_by_id: 1,
        updated_by_id: 1,
      }
      map.each { |key, value|
        if group[key.to_s]
          group_new[value] = group[key.to_s]
        end
      }

      # check if state already exists
      group_old = Group.where( id: group_new[:id] ).first

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
    response = request( 'public.pl?Action=Export;Type=User' )
    return if !response
    return if !response.success?
    result = json(response)
    map = {
      ChangeTime: :updated_at,
      CreateTime: :created_at,
      CreateBy: :created_by_id,
      ChangeBy: :updated_by_id,
      UserID: :id,
      ValidID: :active,
      Comment: :note,
      UserEmail: :email,
      UserFirstname: :firstname,
      UserLastname: :lastname,
      UserLogin: :login,
      UserPw: :password,
    }

    result.each { |user|
#      Rails.logger.info 'USER: ' + user.inspect
      _set_valid(user)

      role = Role.lookup( name: 'Agent' )
      # get new attributes
      user_new = {
        created_by_id: 1,
        updated_by_id: 1,
        source: 'OTRS Import',
        role_ids: [ role.id ],
      }
      map.each { |key, value|
        if user[key.to_s]
          user_new[value] = user[key.to_s]
        end
      }

      # check if state already exists
      user_old = User.where( id: user_new[:id] ).first

        # set state types
      if user_old
        Rails.logger.info "update User.find(#{user_new[:id]})"
#        Rails.logger.info 'Update User' + user_new.inspect
        user_new.delete( :role_ids )
        user_old.update_attributes(user_new)
      else
        Rails.logger.info "add User.find(#{user_new[:id]})"
#        Rails.logger.info 'Add User' + user_new.inspect
        user = User.new(user_new)
        user.id = user_new[:id]
        user.save
      end
    }
  end
  def self.customer
    done = false
    count = 0
    while done == false
      sleep 2
      Rails.logger.info "Count=#{count};Offset=#{count}"
      response = request( "public.pl?Action=Export;Type=Customer;Count=100;Offset=#{count}" )
      return if !response
      count = count + 3000
      return if !response.success?
      result = json(response)
      map = {
        ChangeTime: :updated_at,
        CreateTime: :created_at,
        CreateBy: :created_by_id,
        ChangeBy: :updated_by_id,
        ValidID: :active,
        UserComment: :note,
        UserEmail: :email,
        UserFirstname: :firstname,
        UserLastname: :lastname,
        UserLogin: :login,
        UserPassword: :password,
        UserPhone: :phone,
        UserFax: :fax,
        UserMobile: :mobile,
        UserStreet: :street,
        UserZip: :zip,
        UserCity: :city,
        UserCountry: :country,
      }

      done = true
      result.each { |user|
        done = false
        _set_valid(user)

        role = Role.lookup( name: 'Customer' )

        # get new attributes
        user_new = {
          created_by_id: 1,
          updated_by_id: 1,
          source: 'OTRS Import',
          role_ids: [role.id],
        }
        map.each { |key, value|
          if user[key.to_s]
            user_new[value] = user[key.to_s]
          end
        }

        # check if state already exists
#        user_old = User.where( :login => user_new[:login] ).first
        user_old = User.where( login: user_new[:login] ).first

        # set state types
        if user_old
          Rails.logger.info "update User.find(#{user_new[:id]})"
#          Rails.logger.info 'Update User' + user_new.inspect
          user_old.update_attributes(user_new)
        else
#          Rails.logger.info 'Add User' + user_new.inspect
          Rails.logger.info "add User.find(#{user_new[:id]})"
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
