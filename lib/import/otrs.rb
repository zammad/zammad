require 'base64'

module Import
end
module Import::OTRS

=begin

  result = request_json(Subaction: 'List', 1)

  return

   { some json structure }

  result = request_json(Subaction: 'List')

  return

     "some data string"

=end

  def self.request_json(data, data_only = false)
    response = post(data)
    if !response
      raise "Can't connect to Zammad Migrator"
    end
    if !response.success?
      raise "Can't connect to Zammad Migrator"
    end
    result = json(response)
    if !result
      raise 'Invalid response'
    end
    if data_only
      result['Result']
    else
      result
    end
  end

=begin

  start get request to backend, add auth data automatically

  result = request('Subaction=List')

  return

     "some data string"

=end

  def self.request(part)
    url = Setting.get('import_otrs_endpoint') + part + ';Key=' + Setting.get('import_otrs_endpoint_key')
    log 'GET: ' + url
    response = UserAgent.get(
      url,
      {},
      {
        open_timeout: 10,
        read_timeout: 60,
        total_timeout: 180,
        user: Setting.get('import_otrs_user'),
        password: Setting.get('import_otrs_password'),
      },
    )
    if !response.success?
      log "ERROR: #{response.error}"
      return
    end
    response
  end

=begin

  start post request to backend, add auth data automatically

  result = request('Subaction=List')

  return

     "some data string"

=end

  def self.post(data, url = nil)
    if !url
      url            = Setting.get('import_otrs_endpoint')
      data['Action'] = 'ZammadMigrator'
    end
    data['Key'] = Setting.get('import_otrs_endpoint_key')
    log 'POST: ' + url
    log 'PARAMS: ' + data.inspect
    open_timeout = 10
    read_timeout = 120
    total_timeout = 360
    if data.empty?
      open_timeout = 6
      read_timeout = 20
      total_timeout = 120
    end
    response = UserAgent.post(
      url,
      data,
      {
        open_timeout: open_timeout,
        read_timeout: read_timeout,
        total_timeout: total_timeout,
        user: Setting.get('import_otrs_user'),
        password: Setting.get('import_otrs_password'),
      },
    )
    if !response.success?
      log "ERROR: #{response.error}"
      return
    end
    response
  end

=begin

  start post request to backend, add auth data automatically

  result = json('some response string')

  return

     {}

=end

  def self.json(response)
    data = Encode.conv('utf8', response.body.to_s)
    JSON.parse(data)
  end

=begin

  start auth on OTRS - just for experimental reasons

  result = auth(username, password)

  return

     { ..user structure.. }

=end

  def self.auth(username, password)
    url = Setting.get('import_otrs_endpoint')
    url.gsub!('ZammadMigrator', 'ZammadSSO')
    response = post( { Action: 'ZammadSSO', Subaction: 'Auth', User: username, Pw: password }, url )
    return if !response
    return if !response.success?

    result = json(response)
    result
  end

=begin

  request session data - just for experimental reasons

  result = session(session_id)

  return

     { ..session structure.. }

=end

  def self.session(session_id)
    url = Setting.get('import_otrs_endpoint')
    url.gsub!('ZammadMigrator', 'ZammadSSO')
    response = post( { Action: 'ZammadSSO', Subaction: 'SessionCheck', SessionID: session_id }, url )
    return if !response
    return if !response.success?
    result = json(response)
    result
  end

=begin

  load objects from otrs

  result = load('SysConfig')

  return

    [
      { ..object1.. },
      { ..object2.. },
      { ..object3.. },
    ]

=end

  def self.load( object, limit = '', offset = '', diff = 0 )
    request_json( { Subaction: 'Export', Object: object, Limit: limit, Offset: offset, Diff: diff }, 1 )
  end

=begin

  start get request to backend to check connection

  result = connection_test

  return

     true | false

=end

  def self.connection_test
    request_json({})
  end

=begin

  get object statistic from remote server ans save it in cache

  result = statistic('Subaction=List')

  return

     {
        'Ticket'     => 1234,
        'User'       => 123,
        'SomeObject' => 999,
     }

=end

  def self.statistic

    # check cache
    cache = Cache.get('import_otrs_stats')
    if cache
      return cache
    end

    # retrive statistic
    statistic = request_json( { Subaction: 'List' }, 1)
    if statistic
      Cache.write('import_otrs_stats', statistic)
    end
    statistic
  end

=begin

  return current import state

  result = current_state

  return

     {
        Ticket: {
          total: 1234,
          done: 13,
        },
        Base: {
          total: 1234,
          done: 13,
        },
     }

=end

  def self.current_state
    data = statistic
    base = Group.count + Ticket::State.count + Ticket::Priority.count
    base_total = data['Queue'] + data['State'] + data['Priority']
    user = User.count
    user_total = data['User'] + data['CustomerUser']
    data = {
      Base: {
        done: base,
        total: base_total || 0,
      },
      User: {
        done: user,
        total: user_total || 0,
      },
      Ticket: {
        done: Ticket.count,
        total: data['Ticket'] || 0,
      },
    }
    data
  end

  #
  # start import
  #
  # Import::OTRS.start
  #

  def self.start
    log 'Start import...'

    # check if system is in import mode
    if !Setting.get('import_mode')
      raise 'System is not in import mode!'
    end

    result = request_json({})
    if !result['Success']
      raise 'API key not valid!'
    end

    # set settings
    settings = load('SysConfig')
    setting(settings)

    # dynamic fields
    dynamic_fields = load('DynamicField')
    object_manager(dynamic_fields)

    # email accounts
    #accounts = load('PostMasterAccount')
    #account(accounts)

    # email filter
    #filters = load('PostMasterFilter')
    #filter(filters)

    # create states
    states = load('State')
    ActiveRecord::Base.transaction do
      state(states)
    end

    # create priorities
    priorities = load('Priority')
    ActiveRecord::Base.transaction do
      priority(priorities)
    end

    # create groups
    queues = load('Queue')
    ActiveRecord::Base.transaction do
      ticket_group(queues)
    end

    # get agents groups
    groups = load('Group')

    # get agents roles
    roles = load('Role')

    # create agents
    users = load('User')
    ActiveRecord::Base.transaction do
      user(users, groups, roles, queues)
    end

    # create organizations
    organizations = load('Customer')
    ActiveRecord::Base.transaction do
      organization(organizations)
    end

    # create customers
    count = 0
    steps = 50
    run   = true
    while run
      count += steps
      records = load('CustomerUser', steps, count - steps)
      if !records || !records[0]
        log 'all customers imported.'
        run = false
        next
      end
      customer(records, organizations)
    end

    Thread.abort_on_exception = true
    thread_count              = 8
    threads                   = {}
    steps                     = 20
    (1..thread_count).each { |thread|

      threads[thread] = Thread.new {

        log "Started import thread# #{thread} ..."
        Thread.current[:thread_no]  = thread
        Thread.current[:loop_count] = 0

        loop do
          # get the offset for the current thread and loop count
          thread_offset_base = (Thread.current[:thread_no] - 1) * steps
          thread_step        = thread_count * steps
          offset             = Thread.current[:loop_count] * thread_step + thread_offset_base

          log "loading... thread# #{thread} ..."
          records = load( 'Ticket', steps, offset)
          if !records || !records[0]
            log "... thread# #{thread}, no more work."
            break
          end
          _ticket_result(records, thread)

          Thread.current[:loop_count] += 1
        end
        ActiveRecord::Base.connection.close
      }
    }
    (1..thread_count).each { |thread|
      threads[thread].join
    }

    true
  end

=begin
  start import in background

  Import::OTRS.start_bg
=end

  def self.start_bg
    Setting.reload

    Import::OTRS.connection_test

    # start thread to observe current state
    status_update_thread = Thread.new {
      loop do
        result = {
          data: current_state,
          result: 'in_progress',
        }
        Cache.write('import:state', result, expires_in: 10.minutes)
        sleep 8
      end
    }
    sleep 2

    # start import data
    begin
      Import::OTRS.start
    rescue => e
      status_update_thread.exit
      status_update_thread.join
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.inspect
      result = {
        message: e.message,
        result: 'error',
      }
      Cache.write('import:state', result, expires_in: 10.hours)
      return false
    end
    sleep 16 # wait until new finished import state is on client
    status_update_thread.exit
    status_update_thread.join

    result = {
      result: 'import_done',
    }
    Cache.write('import:state', result, expires_in: 10.hours)

    Setting.set('system_init_done', true)
    Setting.set('import_mode', false)
  end

=begin

  get import state from background process

  result = Import::OTRS.status_bg

=end

  def self.status_bg
    state = Cache.get('import:state')
    return state if state
    {
      message: 'not running',
    }
  end

  def self.diff_worker
    return if !Setting.get('import_mode')
    return if Setting.get('import_otrs_endpoint') == 'http://otrs_host/otrs'
    diff
  end

  def self.diff
    log 'Start diff...'

    # check if system is in import mode
    if !Setting.get('import_mode')
      raise 'System is not in import mode!'
    end

    # create states
    states = load('State')
    state(states)

    # create priorities
    priorities = load('Priority')
    priority(priorities)

    # create groups
    queues = load('Queue')
    ticket_group(queues)

    # get agents groups
    groups = load('Group')

    # get agents roles
    roles = load('Role')

    # create agents
    users = load('User')
    user(users, groups, roles, queues)

    # create organizations
    organizations = load('Customer')
    organization(organizations)

    # get changed tickets
    ticket_diff

  end

  def self.ticket_diff
    count = 0
    run   = true
    steps = 20
    while run
      count += steps
      log 'loading... diff ...'
      records = load( 'Ticket', steps, count - steps, 1 )
      if !records || !records[0]
        log '... no more work.'
        run = false
        next
      end
      _ticket_result(records)
    end

  end

  def self._ticket_result(result, _thread = '-')
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
        FirstResponse: :first_response_at,
        #FirstResponseTimeDestinationDate: :first_response_escalation_at,
        #FirstResponseInMin: :first_response_in_min,
        #FirstResponseDiffInMin: :first_response_diff_in_min,
        Closed: :close_at,
        #SoltutionTimeDestinationDate: :close_escalation_at,
        #CloseTimeInMin: :close_in_min,
        #CloseTimeDiffInMin: :close_diff_in_min,
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
        #ReplyTo: :reply_to,
        References: :references,
        Changed: :updated_at,
        Created: :created_at,
        ChangedBy: :updated_by_id,
        CreatedBy: :created_by_id,
      },
    }

    result.each { |record|

      # cleanup values
      _cleanup(record)

      _utf8_encode(record)

      ticket_new = {
        title: '',
        created_by_id: 1,
        updated_by_id: 1,
      }
      map[:Ticket].each { |key, value|
        next if !record.key?(key.to_s)
        ticket_new[value] = record[key.to_s]
      }

      record.keys.each { |key|

        key_string = key.to_s

        next if !key_string.start_with?('DynamicField_')
        dynamic_field_name = key_string[13, key_string.length]

        next if skip_fields.include?( dynamic_field_name )
        dynamic_field_name = convert_df_name(dynamic_field_name)

        ticket_new[dynamic_field_name.to_sym] = record[key_string]
      }

      # find owner
      if ticket_new[:owner]
        user = User.find_by(login: ticket_new[:owner].downcase)
        ticket_new[:owner_id] = if user
                                  user.id
                                else
                                  1
                                end
        ticket_new.delete(:owner)
      end

      record['Articles'].each { |article|
        # utf8 encode
        _utf8_encode(article)
        # lookup customers to create first
        _article_based_customers(article)
      }

      # find customer
      if ticket_new[:customer]
        user = User.lookup(login: ticket_new[:customer].downcase)
        ticket_new[:customer_id] = if user
                                     user.id
                                   else
                                     _first_customer_id(record['Articles'])
                                   end
        ticket_new.delete(:customer)
      else
        ticket_new[:customer_id] = 1
      end

      # update or create ticket
      ticket_old = Ticket.find_by(id: ticket_new[:id])
      if ticket_old
        log "update Ticket.find(#{ticket_new[:id]})"
        ticket_old.update_attributes(ticket_new)
      else
        log "add Ticket.find(#{ticket_new[:id]})"

        begin
          ticket    = Ticket.new(ticket_new)
          ticket.id = ticket_new[:id]
          ticket.save
          _reset_pk('tickets')
        rescue ActiveRecord::RecordNotUnique
          log "Ticket #{ticket_new[:id]} is handled by another thead, skipping."
          next
        end
      end

      record['Articles'].each do |article|

        retries = 3
        begin

          ActiveRecord::Base.transaction do

            # get article values
            article_new = {
              created_by_id: 1,
              updated_by_id: 1,
            }

            map[:Article].each { |key, value|
              next if !article.key?(key.to_s)
              article_new[value] = article[key.to_s]
            }

            if article_new[:sender] == 'customer'
              article_new[:sender_id] = Ticket::Article::Sender.lookup(name: 'Customer').id
              article_new.delete(:sender)
            end
            if article_new[:sender] == 'agent'
              article_new[:sender_id] = Ticket::Article::Sender.lookup(name: 'Agent').id
              article_new.delete(:sender)
            end
            if article_new[:sender] == 'system'
              article_new[:sender_id] = Ticket::Article::Sender.lookup(name: 'System').id
              article_new.delete(:sender)
            end

            if article_new[:type] == 'email-external'
              article_new[:type_id] = Ticket::Article::Type.lookup(name: 'email').id
              article_new[:internal] = false
            elsif article_new[:type] == 'email-internal'
              article_new[:type_id] = Ticket::Article::Type.lookup(name: 'email').id
              article_new[:internal] = true
            elsif article_new[:type] == 'note-external'
              article_new[:type_id] = Ticket::Article::Type.lookup(name: 'note').id
              article_new[:internal] = false
            elsif article_new[:type] == 'note-internal'
              article_new[:type_id] = Ticket::Article::Type.lookup(name: 'note').id
              article_new[:internal] = true
            elsif article_new[:type] == 'phone'
              article_new[:type_id] = Ticket::Article::Type.lookup(name: 'phone').id
              article_new[:internal] = false
            elsif article_new[:type] == 'webrequest'
              article_new[:type_id] = Ticket::Article::Type.lookup(name: 'web').id
              article_new[:internal] = false
            else
              article_new[:type_id] = 9
            end
            article_new.delete(:type)
            article_object = Ticket::Article.find_by(id: article_new[:id])

            # set state types
            if article_object
              log "update Ticket::Article.find(#{article_new[:id]})"
              article_object.update_attributes(article_new)
            else
              log "add Ticket::Article.find(#{article_new[:id]})"
              begin
                article_object    = Ticket::Article.new(article_new)
                article_object.id = article_new[:id]
                article_object.save
                _reset_pk('ticket_articles')
              rescue ActiveRecord::RecordNotUnique
                log "Ticket #{ticket_new[:id]} (article #{article_new[:id]}) is handled by another thead, skipping."
                next
              end
            end

            next if !article['Attachments']
            next if article['Attachments'].empty?

            # TODO: refactor
            # check if there are attachments present
            if !article_object.attachments.empty?

              # skip attachments if count is equal
              next if article_object.attachments.count == article['Attachments'].count

              # if the count differs delete all so we
              # can have a fresh start
              article_object.attachments.each(&:delete)
            end

            # import article attachments
            article['Attachments'].each { |attachment|

              filename = Base64.decode64(attachment['Filename'])

              Store.add(
                object:      'Ticket::Article',
                o_id:        article_object.id,
                filename:    filename,
                data:        Base64.decode64(attachment['Content']),
                preferences: {
                  'Mime-Type'           => attachment['ContentType'],
                  'Content-ID'          => attachment['ContentID'],
                  'content-alternative' => attachment['ContentAlternative'],
                },
                created_by_id: 1,
              )
            }
          end
        rescue ActiveRecord::RecordNotUnique => e
          log "Ticket #{ticket_new[:id]} - RecordNotUnique: #{e}"
          sleep rand 3
          retry if !(retries -= 1).zero?
          raise
        end
      end

      #puts "HS: #{record['History'].inspect}"
      record['History'].each { |history|

        begin
          if history['HistoryType'] == 'NewTicket'
            History.add(
              id: history['HistoryID'],
              o_id: history['TicketID'],
              history_type: 'created',
              history_object: 'Ticket',
              created_at: history['CreateTime'],
              created_by_id: history['CreateBy']
            )
          elsif history['HistoryType'] == 'StateUpdate'
            data = history['Name']
            # "%%new%%open%%"
            from = nil
            to   = nil
            if data =~ /%%(.+?)%%(.+?)%%/
              from    = $1
              to      = $2
              state_from = Ticket::State.lookup(name: from)
              state_to   = Ticket::State.lookup(name: to)
              if state_from
                from_id = state_from.id
              end
              if state_to
                to_id = state_to.id
              end
            end
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
          elsif history['HistoryType'] == 'Move'
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
          elsif history['HistoryType'] == 'PriorityUpdate'
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
          elsif history['ArticleID'] && !history['ArticleID'].to_i.zero?
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
          end

        rescue ActiveRecord::RecordNotUnique
          log "Ticket #{ticket_new[:id]} (history #{history['HistoryID']}) is handled by another thead, skipping."
          next
        end
      }
    }
  end

  # sync ticket states
  def self.state(records)
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

    # rename states to handle not uniq issues
    Ticket::State.all.each { |state|
      state.name = state.name + '_tmp'
      state.save
    }

    records.each { |state|
      _set_valid(state)

      # get new attributes
      state_new = {
        created_by_id: 1,
        updated_by_id: 1,
      }
      map.each { |key, value|
        next if !state.key?(key.to_s)
        state_new[value] = state[key.to_s]
      }

      # check if state already exists
      state_old = Ticket::State.lookup(id: state_new[:id])

      # set state types
      if state['TypeName'] == 'pending auto'
        state['TypeName'] = 'pending action'
      end
      state_type = Ticket::StateType.lookup(name: state['TypeName'])
      state_new[:state_type_id] = state_type.id
      if state_old
        state_old.update_attributes(state_new)
      else
        state = Ticket::State.new(state_new)
        state.id = state_new[:id]
        state.save
        _reset_pk('ticket_states')
      end
    }
  end

  # sync ticket priorities
  def self.priority(records)

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

    records.each { |priority|
      _set_valid(priority)

      # get new attributes
      priority_new = {
        created_by_id: 1,
        updated_by_id: 1,
      }
      map.each { |key, value|
        next if !priority.key?(key.to_s)
        priority_new[value] = priority[key.to_s]
      }

      # check if state already exists
      priority_old = Ticket::Priority.lookup(id: priority_new[:id])

      # set state types
      if priority_old
        priority_old.update_attributes(priority_new)
      else
        priority = Ticket::Priority.new(priority_new)
        priority.id = priority_new[:id]
        priority.save
        _reset_pk('ticket_priorities')
      end
    }
  end

  # sync ticket groups / queues
  def self.ticket_group(records)
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

    records.each { |group|
      _set_valid(group)

      # get new attributes
      group_new = {
        created_by_id: 1,
        updated_by_id: 1,
      }
      map.each { |key, value|
        next if !group.key?(key.to_s)
        group_new[value] = group[key.to_s]
      }

      # check if state already exists
      group_old = Group.lookup(id: group_new[:id])

      # set state types
      if group_old
        group_old.update_attributes(group_new)
      else
        group = Group.new(group_new)
        group.id = group_new[:id]
        group.save
        _reset_pk('groups')
      end
    }
  end

  # sync agents
  def self.user(records, groups, roles, queues)

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

    records.each { |user|
      _set_valid(user)

      # get roles
      role_ids = get_roles_ids(user, groups, roles, queues)

      # get groups
      group_ids = get_queue_ids(user, groups, roles, queues)

      # get new attributes
      user_new = {
        created_by_id: 1,
        updated_by_id: 1,
        source: 'OTRS Import',
        role_ids: role_ids,
        group_ids: group_ids,
      }
      map.each { |key, value|
        next if !user.key?(key.to_s)
        user_new[value] = user[key.to_s]
      }

      # set pw
      if user_new[:password]
        user_new[:password] = "{sha2}#{user_new[:password]}"
      end

      # check if agent already exists
      user_old = User.lookup(id: user_new[:id])

      # check if login is already used
      login_in_use = User.where( "login = ? AND id != #{user_new[:id]}", user_new[:login].downcase ).count
      if login_in_use.positive?
        user_new[:login] = "#{user_new[:login]}_#{user_new[:id]}"
      end

      # create / update agent
      if user_old
        log "update User.find(#{user_old[:id]})"

        # only update roles if different (reduce sql statements)
        if user_old.role_ids == user_new[:role_ids]
          user_new.delete(:role_ids)
        end

        user_old.update_attributes(user_new)
      else
        log "add User.find(#{user_new[:id]})"
        user = User.new(user_new)
        user.id = user_new[:id]
        user.save
        _reset_pk('users')
      end
    }
  end

  def self.get_queue_ids(user, _groups, _roles, queues)
    queue_ids = []

    # lookup by groups
    user['GroupIDs'].each { |group_id, permissions|
      queues.each { |queue_lookup|

        next if queue_lookup['GroupID'] != group_id
        next if !permissions
        next if !permissions.include?('rw')

        queue_ids.push queue_lookup['QueueID']
      }
    }

    # lookup by roles

    # roles of user
    #   groups of roles
    #     queues of group

    queue_ids
  end

  def self.get_roles_ids(user, groups, roles, _queues)
    local_roles    = ['Agent']
    local_role_ids = []

    # apply group permissions
    user['GroupIDs'].each { |group_id, permissions|
      groups.each { |group_lookup|

        next if group_id != group_lookup['ID']
        next if !permissions

        if group_lookup['Name'] == 'admin' && permissions.include?('rw')
          local_roles.push 'Admin'
        end

        next if group_lookup['Name'] !~ /^(stats|report)/
        next if !( permissions.include?('ro') || permissions.include?('rw') )

        local_roles.push 'Report'
      }
    }

    # apply role permissions
    user['RoleIDs'].each { |role_id|

      # get groups of role
      roles.each { |role|
        next if role['ID'] != role_id

        # verify group names
        role['GroupIDs'].each { |group_id, permissions|
          groups.each { |group_lookup|

            next if group_id != group_lookup['ID']
            next if !permissions

            if group_lookup['Name'] == 'admin' && permissions.include?('rw')
              local_roles.push 'Admin'
            end

            next if group_lookup['Name'] !~ /^(stats|report)/
            next if !( permissions.include?('ro') || permissions.include?('rw') )

            local_roles.push 'Report'
          }
        }
      }
    }

    local_roles.each { |role|
      role_lookup = Role.lookup(name: role)
      next if !role_lookup
      local_role_ids.push role_lookup.id
    }
    local_role_ids
  end

  # sync customers

  def self.customer(records, organizations)
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

    role_agent    = Role.lookup(name: 'Agent')
    role_customer = Role.lookup(name: 'Customer')

    records.each { |user|
      _set_valid(user)

      # get new attributes
      user_new = {
        created_by_id: 1,
        updated_by_id: 1,
        source: 'OTRS Import',
        organization_id: get_organization_id(user, organizations),
        role_ids: [ role_customer.id ],
      }
      map.each { |key, value|
        next if !user.key?(key.to_s)
        user_new[value] = user[key.to_s]
      }

      # check if customer already exists
      user_old = User.lookup(login: user_new[:login])

      # create / update agent
      if user_old

        # do not update user if it is already agent
        if !user_old.role_ids.include?(role_agent.id)

          # only update roles if different (reduce sql statements)
          if user_old.role_ids == user_new[:role_ids]
            user_new.delete(:role_ids)
          end
          log "update User.find(#{user_old[:id]})"
          user_old.update_attributes(user_new)
        end
      else
        log "add User.find(#{user_new[:id]})"
        user = User.new(user_new)
        user.save
        _reset_pk('users')
      end
    }
  end

  def self.get_organization_id(user, organizations)
    organization_id = nil
    if user['UserCustomerID']
      organizations.each { |organization|
        next if user['UserCustomerID'] != organization['CustomerID']
        organization    = Organization.lookup(name: organization['CustomerCompanyName'])
        organization_id = organization.id
      }
    end
    organization_id
  end

  # sync organizations
  def self.organization(records)
    map = {
      ChangeTime: :updated_at,
      CreateTime: :created_at,
      CreateBy: :created_by_id,
      ChangeBy: :updated_by_id,
      CustomerCompanyName: :name,
      ValidID: :active,
      CustomerCompanyComment: :note,
    }

    records.each { |organization|
      _set_valid(organization)

      # get new attributes
      organization_new = {
        created_by_id: 1,
        updated_by_id: 1,
      }
      map.each { |key, value|
        next if !organization.key?(key.to_s)
        organization_new[value] = organization[key.to_s]
      }

      # check if state already exists
      organization_old = Organization.lookup(name: organization_new[:name])

      # set state types
      if organization_old
        organization_old.update_attributes(organization_new)
      else
        organization = Organization.new(organization_new)
        organization.id = organization_new[:id]
        organization.save
        _reset_pk('organizations')
      end
    }
  end

  # sync settings
  def self.setting(records)

    records.each { |setting|

      # fqdn
      if setting['Key'] == 'FQDN'
        Setting.set('fqdn', setting['Value'])
      end

      # http type
      if setting['Key'] == 'HttpType'
        Setting.set('http_type', setting['Value'])
      end

      # system id
      if setting['Key'] == 'SystemID'
        Setting.set('system_id', setting['Value'])
      end

      # organization
      if setting['Key'] == 'Organization'
        Setting.set('organization', setting['Value'])
      end

      # sending emails
      if setting['Key'] == 'SendmailModule'
        # TODO
      end

      # number generater
      if setting['Key'] == 'Ticket::NumberGenerator'
        if setting['Value'] == 'Kernel::System::Ticket::Number::DateChecksum'
          Setting.set('ticket_number', 'Ticket::Number::Date')
          Setting.set('ticket_number_date', { checksum: true })
        elsif setting['Value'] == 'Kernel::System::Ticket::Number::Date'
          Setting.set('ticket_number', 'Ticket::Number::Date')
          Setting.set('ticket_number_date', { checksum: false })
        end
      end

      # ticket hook
      if setting['Key'] == 'Ticket::Hook'
        Setting.set('ticket_hook', setting['Value'])
      end
    }
  end

  # dynamic fields
  def self.object_manager(dynamic_fields)

    dynamic_fields.each { |dynamic_field|

      if dynamic_field['ObjectType'] != 'Ticket'
        log "ERROR: Unsupported dynamic field object type '#{dynamic_field['ObjectType']}' for dynamic field '#{dynamic_field['Name']}'"
        next
      end

      next if skip_fields.include?( dynamic_field['Name'] )

      internal_name = convert_df_name(dynamic_field['Name'])

      attribute = ObjectManager::Attribute.get(
        object: dynamic_field['ObjectType'],
        name:   internal_name,
      )
      next if !attribute.nil?

      object_manager_config = {
        object:  dynamic_field['ObjectType'],
        name:    internal_name,
        display: dynamic_field['Label'],
        screens: {
          view: {
            '-all-' => {
              shown: true,
            },
          },
        },
        active:        true,
        editable:      dynamic_field['InternalField'] == '0',
        position:      dynamic_field['FieldOrder'],
        created_by_id: 1,
        updated_by_id: 1,
      }

      if dynamic_field['FieldType'] == 'Text'

        object_manager_config[:data_type]   = 'input'
        object_manager_config[:data_option] = {
          default:   dynamic_field['Config']['DefaultValue'],
          type:      'text',
          maxlength: 255,
          null:      false,
        }
      elsif dynamic_field['FieldType'] == 'TextArea'

        object_manager_config[:data_type]   = 'textarea'
        object_manager_config[:data_option] = {
          default: dynamic_field['Config']['DefaultValue'],
          rows:    dynamic_field['Config']['Rows'],
          null:    false,
        }
      elsif dynamic_field['FieldType'] == 'Checkbox'

        object_manager_config[:data_type]   = 'boolean'
        object_manager_config[:data_option] = {
          default: dynamic_field['Config']['DefaultValue'] == '1',
          options: {
            true  => 'Yes',
            false => 'No',
          },
          null:      false,
          translate: true,
        }
      elsif dynamic_field['FieldType'] == 'DateTime'

        object_manager_config[:data_type]   = 'datetime'
        object_manager_config[:data_option] = {
          future: dynamic_field['Config']['YearsInFuture'] != '0',
          past:   dynamic_field['Config']['YearsInPast'] != '0',
          diff:   dynamic_field['Config']['DefaultValue'].to_i / 60 / 60,
          null:   false,
        }
      elsif dynamic_field['FieldType'] == 'Date'

        object_manager_config[:data_type]   = 'date'
        object_manager_config[:data_option] = {
          future: dynamic_field['Config']['YearsInFuture'] != '0',
          past:   dynamic_field['Config']['YearsInPast'] != '0',
          diff:   dynamic_field['Config']['DefaultValue'].to_i / 60 / 60 / 24,
          null:   false,
        }
      elsif dynamic_field['FieldType'] == 'Dropdown'

        object_manager_config[:data_type]   = 'select'
        object_manager_config[:data_option] = {
          default:   '',
          multiple:  false,
          options:   dynamic_field['Config']['PossibleValues'],
          null:      dynamic_field['Config']['PossibleNone'] == '1',
          translate: dynamic_field['Config']['TranslatableValues'] == '1',
        }
      elsif dynamic_field['FieldType'] == 'Multiselect'

        object_manager_config[:data_type]   = 'select'
        object_manager_config[:data_option] = {
          default:   '',
          multiple:  true,
          options:   dynamic_field['Config']['PossibleValues'],
          null:      dynamic_field['Config']['PossibleNone'] == '1',
          translate: dynamic_field['Config']['TranslatableValues'] == '1',
        }
      else
        log "ERROR: Unsupported dynamic field field type '#{dynamic_field['FieldType']}' for dynamic field '#{dynamic_field['Name']}'"
        next
      end

      ObjectManager::Attribute.add( object_manager_config )
      ObjectManager::Attribute.migration_execute(false)
    }

  end

  def self.convert_df_name(dynamic_field_name)
    new_name = dynamic_field_name.underscore
    new_name.sub(/\_id(s)?\z/, "_no#{$1}")
  end

  # log
  def self.log(message)
    thread_no = Thread.current[:thread_no] || '-'
    Rails.logger.info "thread##{thread_no}: #{message}"
  end

  # set translate valid ids to active = true|false
  def self._set_valid(record)

    # map
    record['ValidID'] = if record['ValidID'].to_s == '3'
                          false
                        elsif record['ValidID'].to_s == '2'
                          false
                        elsif record['ValidID'].to_s == '1'
                          true
                        elsif record['ValidID'].to_s == '0'
                          false

                        # fallback
                        else
                          true
                        end
  end

  # cleanup invalid values
  def self._cleanup(record)
    record.each { |key, value|
      if value == '0000-00-00 00:00:00'
        record[key] = nil
      end
    }

    # fix OTRS 3.1 bug, no close time if ticket is created
    if record['StateType'] == 'closed' && (!record['Closed'] || record['Closed'].empty?)
      record['Closed'] = record['Created']
    end
  end

  # utf8 convert
  def self._utf8_encode(data)
    data.each { |key, value|
      next if !value
      next if value.class != String
      data[key] = Encode.conv('utf8', value)
    }
  end

  # reset primary key sequences
  def self._reset_pk(table)
    return if ActiveRecord::Base.connection_config[:adapter] != 'postgresql'
    ActiveRecord::Base.connection.reset_pk_sequence!(table)
  end

  # create customers for article
  def self._article_based_customers(article)

    # create customer/sender if needed
    return if article['sender'] != 'customer'
    return if article['created_by_id'].to_i != 1
    return if article['from'].empty?

    email = nil
    begin
      email = Mail::Address.new(article['from']).address
    rescue
      email = article['from']
      if article['from'] =~ /<(.+?)>/
        email = $1
      end
    end

    user = User.lookup(email: email)
    if !user
      user = User.lookup(login: email)
    end
    if !user
      begin
        display_name = Mail::Address.new( article['from'] ).display_name ||
                       ( Mail::Address.new( article['from'] ).comments && Mail::Address.new( article['from'] ).comments[0] )
      rescue
        display_name = article['from']
      end

      # do extra decoding because we needed to use field.value
      display_name = Mail::Field.new('X-From', display_name).to_s

      roles = Role.lookup(name: 'Customer')
      begin
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
      rescue ActiveRecord::RecordNotUnique
        log "User #{email} was handled by another thread, taking this."
        user = User.lookup(login: email)
        if !user
          log "User #{email} wasn't created sleep and retry."
          sleep rand 3
          retry
        end
      end
    end
    article['created_by_id'] = user.id

    true
  end

  def self.skip_fields
    %w(ProcessManagementProcessID ProcessManagementActivityID ZammadMigratorChanged ZammadMigratorChangedOld)
  end

  def self._first_customer_id(articles)
    user_id = 1
    articles.each { |article|
      next if article['sender'] != 'customer'
      next if article['created_by_id'].to_i != 1
      next if article['from'].empty?

      user_id = article['created_by_id']
      break
    }

    user_id
  end
end
