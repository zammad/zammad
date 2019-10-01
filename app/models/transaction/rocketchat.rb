# Copyright (C) 2019 Olivier Sallou <olivier.sallou@irisa.fr>
require 'net/http'
require 'json'
require 'uri'

class Transaction::Rocketchat

=begin
    
      backend = Transaction::Rocketchat.new(
        object: 'Ticket',
        type: 'update',
        object_id: 123,
        interface_handle: 'application_server', # application_server|websocket|scheduler
        changes: {
          'attribute1' => [before, now],
          'attribute2' => [before, now],
        },
        created_at: Time.zone.now,
        user_id: 123,
      )
      backend.perform
    
=end
    
      def initialize(item, params = {})
        @item = item
        @params = params
      end
    
      def perform
        # return if we run import mode
        return if Setting.get('import_mode')
    
        return if @item[:object] != 'Ticket'
        return if !Setting.get('rocketchat_integration')
    
        config = Setting.get('rocketchat_config')
        return if !config
        return if !config['items']
    
        ticket = Ticket.find_by(id: @item[:object_id])
        return if !ticket
    
        if @item[:article_id]
          article = Ticket::Article.find(@item[:article_id])    
          # ignore notifications
          sender = Ticket::Article::Sender.lookup(id: article.sender_id)
          if sender&.name == 'System'
            return if @item[:changes].blank?
    
            article = nil
          end
        end
    
        # ignore if no changes has been done
        changes = human_changes(ticket)
        return if @item[:type] == 'update' && !article && changes.blank?
        
    
        # get user based notification template
        # if create, send create message / block update messages
        template = nil
        sent_value = nil
        if @item[:type] == 'create'
          template = 'ticket_create'
        elsif @item[:type] == 'update'
          template = 'ticket_update'
        elsif @item[:type] == 'reminder_reached'
          template = 'ticket_reminder_reached'
          sent_value = ticket.pending_time
        elsif @item[:type] == 'escalation'
          template = 'ticket_escalation'
          sent_value = ticket.escalation_at
        elsif @item[:type] == 'escalation_warning'
          template = 'ticket_escalation_warning'
          sent_value = ticket.escalation_at
        else
          raise "unknown type for notification #{@item[:type]}"
        end
    
        user = User.find(1)
    
        current_user = User.lookup(id: @item[:user_id])
        if !current_user
          current_user = User.lookup(id: 1)
        end
    
        result = NotificationFactory::Rocketchat.template(
          template: template,
          locale:   user[:preferences][:locale] || Setting.get('locale_default'),
          timezone: user[:preferences][:timezone] || Setting.get('timezone_default'),
          objects:  {
            ticket:       ticket,
            article:      article,
            current_user: current_user,
            changes:      changes,
          },
        )
    
        # good, warning, danger
        color = '#000000'
        ticket_state_type = ticket.state.state_type.name
        if ticket.escalation_at && ticket.escalation_at < Time.zone.now
          color = '#f35912'
        elsif ticket_state_type == 'pending reminder'
          if ticket.pending_time && ticket.pending_time < Time.zone.now
            color = '#faab00'
          end
        elsif ticket_state_type.match?(/^(new|open)$/)
          color = '#faab00'
        elsif ticket_state_type == 'closed'
          color = '#38ad69'
        end
    
        config['items'].each do |local_config|
          next if local_config['webhook'].blank?
    
          # check if reminder_reached/escalation/escalation_warning is already sent today
          md5_webhook = Digest::MD5.hexdigest(local_config['webhook'])
          cache_key = "rocketchat::backend::#{@item[:type]}::#{ticket.id}::#{md5_webhook}"
          if sent_value
            value = Cache.get(cache_key)
            if value == sent_value
              Rails.logger.debug { "did not send webhook, already sent (#{@item[:type]}/#{ticket.id}/#{local_config['webhook']})" }
              next
            end
            Cache.write(
              cache_key,
              sent_value,
              {
                expires_in: 24.hours
              },
            )
          end
    
          logo_url = 'https://zammad.com/assets/images/logo-200x200.png'
          if local_config['logo_url'].present?
            logo_url = local_config['logo_url']
          end
        
          notifier = Transaction::Rocketchat::Notifier.new(
            local_config['webhook'],
            channel:     local_config['channel'],
            username:    local_config['username'],
            password:    local_config['password'],
            icon_url:    logo_url,
            mrkdwn:      true,
            http_client: Transaction::Rocketchat::Client,
          )

          token, uid = notifier.login
          if token == nil
            Rails.logger.debug { "failed to login to Rocketchat" }
            next
          end

          matches = article.body.scan(/@(\w+)/)
          if matches != nil &&  matches.length > 0
            result_mentioned = NotificationFactory::Rocketchat.template(
              template: 'ticket_mentioned',
              locale:   user[:preferences][:locale] || Setting.get('locale_default'),
              timezone: user[:preferences][:timezone] || Setting.get('timezone_default'),
              objects:  {
                ticket:       ticket,
                article:      article,
                current_user: current_user,
                changes:      changes,
              },
            )
            message = "#{result_mentioned[:subject]}\n#{result_mentioned[:body]}"
            # message = "You've been mentioned in a ticket: #{result[:subject]}\n#{result[:body]}"
            matches.each do |notif|
              notif_res = notifier.notify notif[0].to_s, message
              if !notif_res
                Rails.logger.error "Unable to notify webhook: #{local_config['webhook']}"
              end
            end
          end

          # check action
          if local_config['types'].class == Array
            hit = false
            local_config['types'].each do |type|
              next if type.to_s != @item[:type].to_s
    
              hit = true
              break
            end
            next if !hit
          elsif local_config['types']
            next if local_config['types'].to_s != @item[:type].to_s
          end

          Rails.logger.debug { "sent webhook (#{@item[:type]}/#{ticket.id}/#{local_config['webhook']})" }

          body = "#{result[:subject]}\n#{result[:body]}"
          ping_res = notifier.ping body
          if !ping_res
            if sent_value
              Cache.delete(cache_key)
            end
            Rails.logger.error "Unable to post ping webhook: #{local_config['webhook']}"
            next
          end
          Rails.logger.debug { "sent webhook (#{@item[:type]}/#{ticket.id}/#{local_config['webhook']})" }
        end
    
      end
    
      def human_changes(record)
    
        return {} if !@item[:changes]
    
        user = User.find(1)
        locale = user.preferences[:locale] || Setting.get('locale_default') || 'en-us'
    
        # only show allowed attributes
        attribute_list = ObjectManager::Attribute.by_object_as_hash('Ticket', user)
        #puts "AL #{attribute_list.inspect}"
        user_related_changes = {}
        @item[:changes].each do |key, value|
    
          # if no config exists, use all attributes
          if attribute_list.blank?
            user_related_changes[key] = value
    
          # if config exists, just use existing attributes for user
          elsif attribute_list[key.to_s]
            user_related_changes[key] = value
          end
        end
    
        changes = {}
        user_related_changes.each do |key, value|
    
          # get attribute name
          attribute_name           = key.to_s
          object_manager_attribute = attribute_list[attribute_name]
          if attribute_name[-3, 3] == '_id'
            attribute_name = attribute_name[ 0, attribute_name.length - 3 ].to_s
          end
    
          # add item to changes hash
          if key.to_s == attribute_name
            changes[attribute_name] = value
          end
    
          # if changed item is an _id field/reference, do an lookup for the realy values
          value_id  = []
          value_str = [ value[0], value[1] ]
          if key.to_s[-3, 3] == '_id'
            value_id[0] = value[0]
            value_id[1] = value[1]
    
            if record.respond_to?(attribute_name) && record.send(attribute_name)
              relation_class = record.send(attribute_name).class
              if relation_class && value_id[0]
                relation_model = relation_class.lookup(id: value_id[0])
                if relation_model
                  if relation_model['name']
                    value_str[0] = relation_model['name']
                  elsif relation_model.respond_to?('fullname')
                    value_str[0] = relation_model.send('fullname')
                  end
                end
              end
              if relation_class && value_id[1]
                relation_model = relation_class.lookup(id: value_id[1])
                if relation_model
                  if relation_model['name']
                    value_str[1] = relation_model['name']
                  elsif relation_model.respond_to?('fullname')
                    value_str[1] = relation_model.send('fullname')
                  end
                end
              end
            end
          end
    
          # check if we have an dedcated display name for it
          display = attribute_name
          if object_manager_attribute && object_manager_attribute[:display]
    
            # delete old key
            changes.delete(display)
    
            # set new key
            display = object_manager_attribute[:display].to_s
          end
          changes[display] = if object_manager_attribute && object_manager_attribute[:translate]
                               from = Translation.translate(locale, value_str[0])
                               to = Translation.translate(locale, value_str[1])
                               [from, to]
                             else
                               [value_str[0].to_s, value_str[1].to_s]
                             end
        end
        changes
      end
    
      class Transaction::Rocketchat::Client
        def self.post(uri, params = {})
          UserAgent.post(
            uri.to_s,
            params,
            {
              open_timeout:  4,
              read_timeout:  10,
              total_timeout: 20,
              log:           {
                facility: 'rocketchat_webhook',
              }
            },
          )
        end
      end

      class Transaction::Rocketchat::Notifier
        def initialize url, options={}

          @url = url
          @options = options
        end

        def login
            uri = URI.parse(@url + '/api/v1/login')
            header = {'Accept': 'application/json'}
            req = Net::HTTP::Post.new(uri.request_uri, header)
            req.set_form_data({"user" => @options[:username], "password" => @options[:password]})
            res = Net::HTTP.start(uri.host, uri.port, 
                :use_ssl => uri.scheme == 'https') {|http| http.request req}
            if res.code != '200'
                return nil, nil
            end
            data = JSON.parse(res.body)
            @token = data['data']['authToken']
            @uid = data['data']['userId']
            return @token, @uid
        end

        def ping message
            uri = URI(@url + '/api/v1/chat.postMessage')
            message = {'channel': @options[:channel], 'text': message}
            loggedheader = {'X-Auth-Token': @token, 'X-User-Id': @uid}
            req = Net::HTTP::Post.new(uri.request_uri, loggedheader)
            req.set_form_data(message)
            res = Net::HTTP.start(uri.host, uri.port, 
                :use_ssl => uri.scheme == 'https') {|http| http.request req}
            if res.code != '200'
              return false
            end
            return true
        end

        def notify user, message
            uri = URI(@url + '/api/v1/chat.postMessage')
            message = {'channel': '@' + user, 'text': message}
            loggedheader = {'X-Auth-Token': @token, 'X-User-Id': @uid}
            req = Net::HTTP::Post.new(uri.request_uri, loggedheader)
            req.set_form_data(message)
            res = Net::HTTP.start(uri.host, uri.port, 
                  :use_ssl => uri.scheme == 'https') {|http| http.request req}
            if res.code != '200'
              return false
            end
            return true
        end
    
    end
end