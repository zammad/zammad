module Import
end
module Import::OTRS2

  def self.request_json(part)
    response = request(part)
    if !response
      raise "Can't connect to Zammad Migrator"
    end
    if !response.success?
      raise "Can't connect to Zammad Migrator"
    end
    result = json(response)
    if !result
      raise "Invalid response"
    end
    result
  end

  def self.request(part)
    url = Setting.get('import_otrs_endpoint') + part + ';Key=' + Setting.get('import_otrs_endpoint_key')
    puts 'GET: ' + url
    response = UserAgent.request(
      url,
      {
        :user     => Setting.get('import_otrs_user'),
        :password => Setting.get('import_otrs_password'),
      },
    )
    if !response.success?
      puts "ERROR: #{response.error}"
      return
    end
    return response
  end

  def self.connection_test
    return self.request_json('')
  end

  def self.save_statisitic
    statistic = self.request_json(';Subaction=List')
    # save process
    if statistic
      Cache.write('import_otrs_stats', statistic)
    end
    statistic
  end

  def self.get_statisitic
    cache = Cache.get('import_otrs_stats')
    if cache
      return cache
    end
    self.save_statisitic
  end

  def self.get_current_state
    total = self.get_statisitic
    base = Group.count + Ticket::State.count + Ticket::Priority.count
    data = {
      :Base   => {
        :done  => base,
        :total => total['Base'] || 0,
      },
      :User   => {
        :done  => User.count,
        :total => total['User'] || 0,
      },
      :Ticket => {
        :done  => Ticket.count,
        :total => total['Ticket'] || 0,
      },
    }
    data
  end

  def self.post(data)
    url = Setting.get('import_otrs_endpoint')
    data['Key'] = Setting.get('import_otrs_endpoint_key')
    puts 'POST: ' + url
    response = UserAgent.request(
      url,
      {
        :method   => 'post',
        :data     => data,
        :user     => Setting.get('import_otrs_user'),
        :password => Setting.get('import_otrs_password'),
      },
    )
    if !response.success?
      puts "ERROR: #{response.error}"
      return
    end
    return response
  end

  def self.json(response)
    data = Encode.conv( 'utf8', response.body.to_s )
    JSON.parse( data )
  end

  #
  # start import
  # 
  # Import::OTRS2.start
  #

  def self.start
    puts 'Start import...'

#    # set system in import mode
#    Setting.set('import_mode', true)

    # check if system is in import mode
    if !Setting.get('import_mode')
      raise "System is not in import mode!"
    end

    result = request_json('')
    if !result['Success']
      "API key not valid!"
    end

    # get objects to import
    object_list = request_json(";Subaction=List")
    #puts "r #{result.inspect}"
    #if !result['Success']
    #  "API key not valid!"
    #end
    object_list.each {|object, object_count|
      puts "#{object} - #{object_count}"
      relations = request_json(";Subaction=List;Object=#{object}")
      relations.each {|relation, relation_count|
        #puts "lll #{relation}/#{relation_count}"
        records = request_json(";Subaction=Export;Object=#{object};Attribute=#{relation}")
        #puts "--- #{recoords.inspect}"
        if object == 'Ticket'
          if relation == 'State'
            state(records)
          elsif relation == 'Priority'
            priority(records)
          elsif relation == 'Queue'
            ticket_group(records)
          elsif relation == 'CustomerUser'
            #customer(records)
            customer
          elsif relation == 'User'
            user(records)
          end
        end
      }
      if object == 'Ticket'
        ticket_fetch
      elsif object == 'TicketArticle'
        ticket_article_fetch
      end
    }

    puts "aaaa #{result.inspect}"
    return

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
        puts "Started import thread# #{thread} ..."
        run = true
        steps = 100
        count = 0
        while run
          sleep 2
          puts "Count=#{count};Offset=#{count}"
          result = request_json( ";Subaction=Export;Object=Ticket;Limit=#{steps};Offset=#{count}") #;Count=100;Offset=#{count}" )
          if !result
            run = false
          end
          count = count + steps
            run = false
          end


        while run
          ticket_ids = result.pop(20)
          if !ticket_ids.empty?
            self.ticket(ticket_ids)
          else
            puts "... thread# #{thread}, no more work."
            run = false
          end
        end
      }
    }
    (1..thread_count).each {|thread|
      threads[thread].join
    }

    return
  end

  def self.diff_worker
    return if !Setting.get('import_mode')
    return if Setting.get('import_otrs_endpoint') == 'http://otrs_host/otrs'
    self.diff
  end

  def self.diff
    puts 'Start diff...'

    # check if system is in import mode
    if !Setting.get('import_mode')
        raise "System is not in import mode!"
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

    return
  end


  def self.ticket_diff()
    url = "public.pl?Action=Export;Type=TicketDiff;Limit=30"
    response = request( url )
    return if !response
    return if !response.success?
    result = json(response)
    self._ticket_result(result)
  end

  def self.ticket(ticket_ids)
    url = "public.pl?Action=Export;Type=Ticket;"
    ticket_ids.each {|ticket_id|
      url = url + "TicketID=#{CGI::escape ticket_id};"
    }
    response = request( url )
    return if !response
    return if !response.success?

    result = json(response)
    self._ticket_result(result)
  end

  def self.ticket_fetch
    done = false
    count = 0
    steps = 100
    while done == false
      sleep 2
      puts "Count=#{count};Offset=#{count}"
      result = request_json( ";Subaction=Export;Object=Ticket;Limit=#{steps};Offset=#{count}") #;Count=100;Offset=#{count}" )
      return if !result
      count = count + steps
      if result.empty?
        done = true
      end
      puts "aa #{result}"
      _ticket_result(result)
    end
  end

  def self._ticket_result(result)
#    puts result.inspect
    map = {
      :Ticket => {
        :Changed                          => :updated_at,
        :Created                          => :created_at,
        :CreateBy                         => :created_by_id,
        :TicketNumber                     => :number,
        :QueueID                          => :group_id,
        :StateID                          => :state_id,
        :PriorityID                       => :priority_id,
        :Owner                            => :owner,
        :CustomerUserID                   => :customer,
        :Title                            => :title,
        :TicketID                         => :id,
        :FirstResponse                    => :first_response,
#        :FirstResponseTimeDestinationDate => :first_response_escal_date,
#        :FirstResponseInMin               => :first_response_in_min,
#        :FirstResponseDiffInMin           => :first_response_diff_in_min,
        :Closed                           => :close_time,
#        :SoltutionTimeDestinationDate     => :close_time_escal_date,
#        :CloseTimeInMin                   => :close_time_in_min,
#        :CloseTimeDiffInMin               => :close_time_diff_in_min,
      },
      :Article => {
        :SenderType  => :sender,
        :ArticleType => :type,
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

      # use transaction
      ActiveRecord::Base.transaction do

        ticket_new = {
          :title         => '',
          :created_by_id => 1,
          :updated_by_id => 1,
        }
        map[:Ticket].each { |key,value|
          if record[key.to_s] && record[key.to_s].class == String
            ticket_new[value] = Encode.conv( 'utf8', record[key.to_s] )
          else
            ticket_new[value] = record[key.to_s]
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
          user = User.lookup( :login => ticket_new[:owner] )
          if user
            ticket_new[:owner_id] = user.id
          else
            ticket_new[:owner_id] = 1
          end
          ticket_new.delete(:owner)
        end
        if ticket_new[:customer]
          user = User.lookup( :login => ticket_new[:customer] )
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
      end
    }
  end

  def self.ticket_article_fetch
    done = false
    count = 0
    steps = 100
    while done == false
      sleep 2
      puts "Count=#{count};Offset=#{count}"
      result = request_json( ";Subaction=Export;Object=TicketArticle;Limit=#{steps};Offset=#{count}") #;Count=100;Offset=#{count}" )
      return if !result
      count = count + steps
      if result.empty?
        done = true
      end
      puts "aa #{result}"
      _ticket_article_result(result)
    end
  end

  def self._ticket_article_result(record)


    map = {
      :Ticket => {
        :Changed                          => :updated_at,
        :Created                          => :created_at,
        :CreateBy                         => :created_by_id,
        :TicketNumber                     => :number,
        :QueueID                          => :group_id,
        :StateID                          => :state_id,
        :PriorityID                       => :priority_id,
        :Owner                            => :owner,
        :CustomerUserID                   => :customer,
        :Title                            => :title,
        :TicketID                         => :id,
        :FirstResponse                    => :first_response,
#        :FirstResponseTimeDestinationDate => :first_response_escal_date,
#        :FirstResponseInMin               => :first_response_in_min,
#        :FirstResponseDiffInMin           => :first_response_diff_in_min,
        :Closed                           => :close_time,
#        :SoltutionTimeDestinationDate     => :close_time_escal_date,
#        :CloseTimeInMin                   => :close_time_in_min,
#        :CloseTimeDiffInMin               => :close_time_diff_in_min,
      },
      :Article => {
        :SenderType  => :sender,
        :ArticleType => :type,
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


        record.each { |article|

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
            user = User.where( :email => email ).first
            if !user
              user = User.where( :login => email ).first
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

              roles = Role.lookup( :name => 'Customer' )
              user = User.create(
                :login          => email,
                :firstname      => display_name,
                :lastname       => '',
                :email          => email,
                :password       => '',
                :active         => true,
                :role_ids       => [roles.id],
                :updated_by_id  => 1,
                :created_by_id  => 1,
              )
            end
            article_new[:created_by_id] = user.id
          end

          if article_new[:sender] == 'customer'
            article_new[:sender_id] = Ticket::Article::Sender.lookup( :name => 'Customer' ).id
            article_new.delete( :sender )
          end
          if article_new[:sender] == 'agent'
            article_new[:sender_id] = Ticket::Article::Sender.lookup( :name => 'Agent' ).id
            article_new.delete( :sender )
          end
          if article_new[:sender] == 'system'
            article_new[:sender_id] = Ticket::Article::Sender.lookup( :name => 'System' ).id
            article_new.delete( :sender )
          end

          if article_new[:type] == 'email-external'
            article_new[:type_id] = Ticket::Article::Type.lookup( :name => 'email' ).id
            article_new[:internal] = false
          elsif article_new[:type] == 'email-internal'
            article_new[:type_id] = Ticket::Article::Type.lookup( :name => 'email' ).id
            article_new[:internal] = true
          elsif article_new[:type] == 'note-external'
            article_new[:type_id] = Ticket::Article::Type.lookup( :name => 'note' ).id
            article_new[:internal] = false
          elsif article_new[:type] == 'note-internal'
            article_new[:type_id] = Ticket::Article::Type.lookup( :name => 'note' ).id
            article_new[:internal] = true
          elsif article_new[:type] == 'phone'
            article_new[:type_id] = Ticket::Article::Type.lookup( :name => 'phone' ).id
            article_new[:internal] = false
          elsif article_new[:type] == 'webrequest'
            article_new[:type_id] = Ticket::Article::Type.lookup( :name => 'web' ).id
            article_new[:internal] = false
          else
            article_new[:type_id] = 9
          end
          article_new.delete( :type )
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

          if article['Attachments']
            article['Attachments'].each {|file|
              headers_store = {
                'Content-Type'        => file['ContentType'],
                'Content-Alternative' => file['ContentAlternative'],
                'Content-ID'          => file['ContentID'],
              }
              Store.add(
                :object      => 'TicketArticle',
                :o_id        => article_new[:id],
                :data        => file['Content'],
                :filename    => file['Filename'],
                :preferences => headers_store
              )
            }

            puts "---- #{article['Attachments'].inspect}"
          end
        }

  end
  def self._ticket_history_result(result)


        record['History'].each { |history|
    #      puts '-------'
    #      puts history.inspect
          if history['HistoryType'] == 'NewTicket'
            History.add(
              :id             => history['HistoryID'],
              :o_id           => history['TicketID'],
              :history_type   => 'created',
              :history_object => 'Ticket',
              :created_at     => history['CreateTime'],
              :created_by_id  => history['CreateBy']
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
              state_from = Ticket::State.lookup( :name => from )
              state_to   = Ticket::State.lookup( :name => to )
              if state_from
                from_id = state_from.id
              end
              if state_to
                to_id = state_to.id
              end
            end
    #        puts "STATE UPDATE (#{history['HistoryID']}): -> #{from}->#{to}"
            History.add(
              :id                 => history['HistoryID'],
              :o_id               => history['TicketID'],
              :history_type       => 'updated',
              :history_object     => 'Ticket',
              :history_attribute  => 'state',
              :value_from         => from,
              :id_from            => from_id,
              :value_to           => to,
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
            History.add(
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
            History.add(
              :id                 => history['HistoryID'],
              :o_id               => history['TicketID'],
              :history_type       => 'updated',
              :history_object     => 'Ticket',
              :history_attribute  => 'priority',
              :value_from         => from,
              :value_to           => to,
              :id_from            => from_id,
              :id_to              => to_id,
              :created_at         => history['CreateTime'],
              :created_by_id      => history['CreateBy']
            )
          end
          if history['ArticleID'] && history['ArticleID'] != 0
            History.add(
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
      #end
    #}
  end

  def self.state(records)

#    puts records.inspect
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

    # rename states to get not uniq issues
    Ticket::State.all.each {|state|
      state.name = state.name + '_tmp'
      state.save
    }

    records.each { |state|
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
      state_type = Ticket::StateType.where( :name =>  state['TypeName'] ).first
      state_new[:state_type_id] = state_type.id
      if state_old
#        puts 'TS: ' + state_new.inspect
        state_old.update_attributes(state_new)
      else
        state = Ticket::State.new(state_new)
        state.id = state_new[:id]
        state.save
      end
    }
  end
  def self.priority(records)

    map = {
      :ChangeTime => :updated_at,
      :CreateTime => :created_at,
      :CreateBy   => :created_by_id,
      :ChangeBy   => :updated_by_id,
      :Name       => :name,
      :ID         => :id,
      :ValidID    => :active,
      :Comment    => :note,
    };

    records.each { |priority|
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
  def self.ticket_group(records)
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

    records.each { |group|
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
  def self.user(records)

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

    records.each { |user|
#      puts 'USER: ' + user.inspect
        _set_valid(user)

        role = Role.lookup( :name => 'Agent' )
        # get new attributes
        user_new = {
          :created_by_id => 1,
          :updated_by_id => 1,
          :source        => 'OTRS Import',
          :role_ids      => [ role.id ],
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
          user_new.delete( :role_ids )
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
    steps = 100
    while done == false
      sleep 2
      puts "Count=#{count};Offset=#{count}"
      result = request_json( ";Subaction=Export;Object=Ticket;Attribute=CustomerUser;Limit=#{steps};Offset=#{count}") #;Count=100;Offset=#{count}" )
      return if !result
      count = count + steps
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

        role = Role.lookup( :name => 'Customer' )

        # get new attributes
        user_new = {
          :created_by_id => 1,
          :updated_by_id => 1,
          :source        => 'OTRS Import',
          :role_ids      => [role.id],
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
