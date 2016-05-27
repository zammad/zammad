require 'base64'
require 'zendesk_api'

module Import
end
module Import::Zendesk

  module_function

  def start
    Rails.logger.info 'Start import...'

    # check if system is in import mode
    if !Setting.get('import_mode')
      raise 'System is not in import mode!'
    end

    initialize_client

    import_fields

    # TODO
    # import_oauth
    # import_twitter_channel

    import_groups

    import_organizations

    import_users

    import_tickets

    # TODO
    # import_sla_policies

    # import_macros

    # import_schedules

    # import_views

    # import_automations

    Setting.set( 'system_init_done', true )
    Setting.set( 'import_mode', false )

    true
  end

=begin
  start import in background

  Import::Zendesk.start_bg
=end

  def start_bg
    Setting.reload

    Import::Zendesk.connection_test

    # get statistic before starting import
    statistic

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
      Import::Zendesk.start
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

  result = Import::Zendesk.status_bg

=end

  def status_bg
    state = Cache.get('import:state')
    return state if state
    {
      message: 'not running',
    }
  end

=begin

  start get request to backend to check connection

  result = connection_test

  return

     true | false

=end

  def connection_test
    initialize_client

    return true if @client.users.first
    false
  end

  def statistic

    # check cache
    cache = Cache.get('import_zendesk_stats')
    if cache
      return cache
    end

    initialize_client

    # retrive statistic
    result = {
      'Tickets'            => 0,
      'TicketFields'       => 0,
      'UserFields'         => 0,
      'OrganizationFields' => 0,
      'Groups'             => 0,
      'Organizations'      => 0,
      'Users'              => 0,
      'GroupMemberships'   => 0,
      'Macros'             => 0,
      'Views'              => 0,
      'Automations'        => 0,
    }

    result.each { |object, _score|
      result[ object ] = @client.send( object.underscore.to_sym ).count!
    }

    if result
      Cache.write('import_zendesk_stats', result)
    end
    result
  end

=begin

  return current import state

  result = current_state

  return

     {
        Group: {
          total: 1234,
          done: 13,
        },
        Organization: {
          total: 1234,
          done: 13,
        },
        User: {
          total: 1234,
          done: 13,
        },
        Ticket: {
          total: 1234,
          done: 13,
        },
     }

=end

  def current_state

    data = statistic

    {
      Group: {
        done: Group.count,
        total: data['Groups'] || 0,
      },
      Organization: {
        done: Organization.count,
        total: data['Organizations'] || 0,
      },
      User: {
        done: User.count,
        total: data['Users'] || 0,
      },
      Ticket: {
        done: Ticket.count,
        total: data['Tickets'] || 0,
      },
    }
  end

  def initialize_client
    @client = ZendeskAPI::Client.new do |config|
      config.url = Setting.get('import_zendesk_endpoint')

      # Basic / Token Authentication
      config.username = Setting.get('import_zendesk_endpoint_username')
      config.token    = Setting.get('import_zendesk_endpoint_key')

      # when hitting the rate limit, sleep automatically,
      # then retry the request.
      config.retry = true
    end
  end

  def mapping_state(zendesk_state)

    mapping = {
      'pending' => 'pending reminder',
      'solved'  => 'closed',
    }
    return zendesk_state if !mapping[zendesk_state]
    mapping[zendesk_state]
  end

  def mapping_priority(zendesk_priority)

    mapping = {
      'low'    => '1 low',
      nil      => '2 normal',
      'normal' => '2 normal',
      'high'   => '3 high',
      'urgent' => '3 high',
    }
    mapping[zendesk_priority]
  end

  # NOT IMPLEMENTED YET
  def mapping_type(zendesk_type)

    mapping = {
      nil        => '',
      'question' => '',
      'incident' => '',
      'problem'  => '',
      'task'     => '',
    }
    return zendesk_type if !mapping[zendesk_type]
    mapping[zendesk_type]
  end

  def mapping_ticket_field(zendesk_field)

    mapping = {
      'subject'     => 'title',
      'description' => 'note',
      'status'      => 'state_id',
      'tickettype'  => 'type',
      'priority'    => 'priority_id',
      'group'       => 'group_id',
      'assignee'    => 'owner_id',
    }
    return zendesk_field if !mapping[zendesk_field]
    mapping[zendesk_field]
  end

  # FILTER:
  # TODO:
  # https://developer.zendesk.com/rest_api/docs/core/views#conditions-reference
  def mapping_filter(zendesk_filter)

  end

  # Ticket Fields
  # User Fields
  # Organization Fields
  # TODO:
  # https://developer.zendesk.com/rest_api/docs/core/ticket_fields
  # https://developer.zendesk.com/rest_api/docs/core/user_fields
  # https://developer.zendesk.com/rest_api/docs/core/organization_fields
  def import_fields

    %w(Ticket User Organization).each { |local_object|

      local_fields = local_object.constantize.column_names

      @client.send("#{local_object.downcase}_fields").all! { |zendesk_object_field|

        if local_object == 'Ticket'
          mapped_object_field = method("mapping_#{local_object.downcase}_field").call( zendesk_object_field.type )

          next if local_fields.include?( mapped_object_field )
        end

        import_field(local_object, zendesk_object_field)
      }
    }
  end

  def import_field(local_object, zendesk_field)

    name = ''
    name = if local_object == 'Ticket'
             zendesk_field.title
           else
             zendesk_field['key'] # TODO: y?!
           end

    @zendesk_field_mapping ||= {}
    @zendesk_field_mapping[ zendesk_field.id ] = name

    data_type   = zendesk_field.type
    data_option = {
      null: !zendesk_field.required,
      note: zendesk_field.description,
    }

    if zendesk_field.type == 'date'
      data_option = {
        future: true,
        past:   true,
        diff:   0,
      }.merge(data_option)
    elsif zendesk_field.type == 'checkbox'
      data_type   = 'boolean'
      data_option = {
        default: false,
        options: {
          true  => 'yes',
          false => 'no',
        },
      }.merge(data_option)
    elsif zendesk_field.type == 'regexp'
      data_type   = 'input'
      data_option = {
        type:  'text',
        maxlength: 255,
        regex: zendesk_field.regexp_for_validation,
      }.merge(data_option)
    elsif zendesk_field.type == 'decimal'
      data_type   = 'input'
      data_option = {
        type:  'text',
        maxlength: 255,
      }.merge(data_option)
    elsif zendesk_field.type == 'integer'
      data_type   = 'integer'
      data_option = {
        min:     0,
        max:     999_999_999,
      }.merge(data_option)
    elsif zendesk_field.type == 'text'
      data_type   = 'input'
      data_option = {
        type: zendesk_field.type,
        maxlength: 255,
      }.merge(data_option)
    elsif zendesk_field.type == 'textarea'
      data_type   = 'input'
      data_option = {
        type: zendesk_field.type,
        maxlength: 255,
      }.merge(data_option)
    elsif zendesk_field.type == 'tagger' || zendesk_field.type == 'dropdown'

      # \"custom_field_options\"=>[{\"id\"=>28353445
      # \"name\"=>\"Another Value\"
      # \"raw_name\"=>\"Another Value\"
      # \"value\"=>\"anotherkey\"}
      # {\"id\"=>28353425
      #   \"name\"=>\"Value 1\"
      # \"raw_name\"=>\"Value 1\"
      # \"value\"=>\"key1\"}
      # {\"id\"=>28353435
      #   \"name\"=>\"Value 2\"
      # \"raw_name\"=>\"Value 2\"
      # \"value\"=>\"key2\"}]}>
      # "

      options = {}
      @zendesk_ticket_field_value_mapping ||= {}
      zendesk_field.custom_field_options.each { |entry|

        if local_object == 'Ticket'
          @zendesk_ticket_field_value_mapping[ name ] ||= {}
          @zendesk_ticket_field_value_mapping[ name ][ entry['id'] ] = entry['value']
        end

        options[ entry['value'] ] = entry['name']
      }

      data_type   = 'select'
      data_option = {
        default: '',
        options: options,
      }.merge(data_option)
    end

    screens = {
      view: {
        '-all-' => {
          shown: true,
        },
      }
    }

    if zendesk_field.visible_in_portal || !zendesk_field.required_in_portal
      screens = {
        edit: {
          Customer: {
            shown: zendesk_field.visible_in_portal,
            null: !zendesk_field.required_in_portal,
          },
        }.merge(screens)
      }
    end
    name.gsub!(/\s/, '_')

    ObjectManager::Attribute.add(
      object:            local_object,
      name:              name,
      display:           zendesk_field.title,
      data_type:         data_type,
      data_option:       data_option,
      editable:          !zendesk_field.removable,
      active:            zendesk_field.active,
      screens:           screens,
      position:          zendesk_field.position,
      created_by_id:     1,
      updated_by_id:     1,
    )
    ObjectManager::Attribute.migration_execute(false)
  end

  # OAuth
  # TODO:
  # https://developer.zendesk.com/rest_api/docs/core/oauth_tokens
  # https://developer.zendesk.com/rest_api/docs/core/oauth_clients
  def import_oauth

  end

  # Twitter
  # TODO:
  # https://developer.zendesk.com/rest_api/docs/core/twitter_channel
  def import_twitter

  end

  # Groups
  # https://developer.zendesk.com/rest_api/docs/core/groups
  def import_groups

    @zendesk_group_mapping = {}
    @client.groups.all! { |zendesk_group|
      local_group = Group.create_if_not_exists(
        name:          zendesk_group.name,
        active:        !zendesk_group.deleted,
        updated_by_id: 1,
        created_by_id: 1
      )

      @zendesk_group_mapping[ zendesk_group.id ] = local_group.id
    }
  end

  # Organizations
  # https://developer.zendesk.com/rest_api/docs/core/organizations
  def import_organizations

    @zendesk_organization_mapping = {}

    @client.organizations.each { |zendesk_organization|
      custom_fields = get_fields(zendesk_organization.organization_fields)

      local_organization_fields = {
        name:          zendesk_organization.name,
        note:          zendesk_organization.note,
        shared:        zendesk_organization.shared_tickets,
        # shared: zendesk_organization.shared_comments, # TODO, not yet implemented
        # }.merge(zendesk_organization.organization_fields) # TODO
        updated_by_id: 1,
        created_by_id: 1
      }.merge(custom_fields)

      local_organization = Organization.create_if_not_exists(local_organization_fields)
      @zendesk_organization_mapping[ zendesk_organization.id ] = local_organization.id
    }
  end

  # Users
  # https://developer.zendesk.com/rest_api/docs/core/users
  def import_users
    import_group_memberships
    import_custom_roles

    @zendesk_user_mapping = {}

    role_admin    = Role.lookup(name: 'Admin')
    role_agent    = Role.lookup(name: 'Agent')
    role_customer = Role.lookup(name: 'Customer')

    @client.users.all! { |zendesk_user|
      custom_fields = get_fields(zendesk_user.user_fields)
      local_user_fields = {
        login:           zendesk_user.id.to_s, # Zendesk users may have no other identifier than the ID, e.g. twitter users
        firstname:       zendesk_user.name,
        email:           zendesk_user.email,
        phone:           zendesk_user.phone,
        password:        '',
        active:          !zendesk_user.suspended,
        groups:          [],
        roles:           [],
        note:            zendesk_user.notes,
        verified:        zendesk_user.verified,
        organization_id: @zendesk_organization_mapping[ zendesk_user.organization_id ],
        last_login:      zendesk_user.last_login_at,
        updated_by_id:   1,
        created_by_id:   1
      }.merge(custom_fields)

      if @zendesk_user_group_mapping[ zendesk_user.id ]

        @zendesk_user_group_mapping[ zendesk_user.id ].each { |zendesk_group_id|

          local_group_id = @zendesk_group_mapping[ zendesk_group_id ]

          next if !local_group_id

          group = Group.find( local_group_id )

          local_user_fields[:groups].push group
        }
      end

      if zendesk_user.role.name == 'end-user'
        local_user_fields[:roles].push role_customer

      elsif zendesk_user.role.name == 'agent'

        local_user_fields[:roles].push role_agent

        if !zendesk_user.restricted_agent
          local_user_fields[:roles].push role_admin
        end

      elsif zendesk_user.role.name == 'admin'
        local_user_fields[:roles].push role_agent
        local_user_fields[:roles].push role_admin
      end

      if zendesk_user.photo && zendesk_user.photo.content_url
        local_user_fields[:image_source] = zendesk_user.photo.content_url
      end

      # TODO
      # local_user_fields = local_user_fields.merge( user.user_fields )

      # TODO
      # user.custom_role_id (Enterprise only)
      local_user = User.create_or_update( local_user_fields )

      @zendesk_user_mapping[ zendesk_user.id ] = local_user.id
    }
  end

  # Group Memberships
  # TODO:
  # https://developer.zendesk.com/rest_api/docs/core/group_memberships
  def import_group_memberships

    @zendesk_user_group_mapping = {}

    @client.group_memberships.all! { |zendesk_group_membership|

      @zendesk_user_group_mapping[ zendesk_group_membership.user_id ] ||= []
      @zendesk_user_group_mapping[ zendesk_group_membership.user_id ].push( zendesk_group_membership.group_id )
    }
  end

  # Custom Roles (Enterprise only)
  # TODO:
  # https://developer.zendesk.com/rest_api/docs/core/custom_roles
  def import_custom_roles

  end

  # Tickets
  # https://developer.zendesk.com/rest_api/docs/core/tickets
  # https://developer.zendesk.com/rest_api/docs/core/ticket_comments#ticket-comments
  # https://developer.zendesk.com/rest_api/docs/core/ticket_audits#the-via-object
  # https://developer.zendesk.com/rest_api/docs/help_center/article_attachments
  # https://developer.zendesk.com/rest_api/docs/core/ticket_audits # v2
  def import_tickets

    article_sender_customer = Ticket::Article::Sender.lookup(name: 'Customer')
    article_sender_agent    = Ticket::Article::Sender.lookup(name: 'Agent')
    article_sender_system   = Ticket::Article::Sender.lookup(name: 'System')

    article_type_web                   = Ticket::Article::Type.lookup(name: 'web')
    article_type_note                  = Ticket::Article::Type.lookup(name: 'note')
    article_type_email                 = Ticket::Article::Type.lookup(name: 'email')
    article_type_twitter_status        = Ticket::Article::Type.lookup(name: 'twitter status')
    article_type_twitter_dm            = Ticket::Article::Type.lookup(name: 'twitter direct-message')
    article_type_facebook_feed_post    = Ticket::Article::Type.lookup(name: 'facebook feed post')
    article_type_facebook_feed_comment = Ticket::Article::Type.lookup(name: 'facebook feed comment')

    @client.tickets.all! { |zendesk_ticket|
      custom_fields = get_custom_fields(zendesk_ticket.custom_fields)
      local_ticket_fields = {
        id:              zendesk_ticket.id,
        title:           zendesk_ticket.subject,
        note:            zendesk_ticket.description,
        group_id:        @zendesk_group_mapping[ zendesk_ticket.group_id ] || 1,
        customer_id:     @zendesk_user_mapping[ zendesk_ticket.requester_id ] || 1,
        organization_id: @zendesk_organization_mapping[ zendesk_ticket.organization_id ],
        state:           Ticket::State.lookup( name: mapping_state( zendesk_ticket.status ) ),
        priority:        Ticket::Priority.lookup( name: mapping_priority( zendesk_ticket.priority ) ),
        pending_time:    zendesk_ticket.due_at,
        updated_at:      zendesk_ticket.updated_at,
        created_at:      zendesk_ticket.created_at,
        updated_by_id:   @zendesk_user_mapping[ zendesk_ticket.requester_id ] || 1,
        created_by_id:   @zendesk_user_mapping[ zendesk_ticket.requester_id ] || 1,
      }.merge(custom_fields)
      ticket_author = User.find( @zendesk_user_mapping[ zendesk_ticket.requester_id ] || 1 )

      local_ticket_fields[:create_article_sender_id] = if ticket_author.role?('Customer')
                                                         article_sender_customer.id
                                                       elsif ticket_author.role?('Agent')
                                                         article_sender_agent.id
                                                       else
                                                         article_sender_system.id
                                                       end

      if zendesk_ticket.via.channel == 'web'
        local_ticket_fields[:create_article_type_id] = article_type_web.id
      elsif zendesk_ticket.via.channel == 'email'
        local_ticket_fields[:create_article_type_id] = article_type_email.id
      elsif zendesk_ticket.via.channel == 'sample_ticket'
        local_ticket_fields[:create_article_type_id] = article_type_note.id
      elsif zendesk_ticket.via.channel == 'twitter'

        local_ticket_fields[:create_article_type_id] = if zendesk_ticket.via.source.rel == 'mention'
                                                         article_type_twitter_status.id
                                                       else
                                                         article_type_twitter_dm.id
                                                       end

      elsif zendesk_ticket.via.channel == 'facebook'

        local_ticket_fields[:create_article_type_id] = if zendesk_ticket.via.source.rel == 'post'
                                                         article_type_facebook_feed_post.id
                                                       else
                                                         article_type_facebook_feed_comment.id
                                                       end
      end

      local_ticket = Ticket.find_by(id: local_ticket_fields[:id])
      if local_ticket
        local_ticket.update_attributes(local_ticket_fields)
      else
        local_ticket = Ticket.create(local_ticket_fields)
        _reset_pk('tickets')
      end

      zendesk_ticket_tags = []
      zendesk_ticket.tags.each { |tag|
        zendesk_ticket_tags.push(tag)
      }

      zendesk_ticket_tags.each { |tag|
        Tag.tag_add(
          object:        'Ticket',
          o_id:          local_ticket.id,
          item:          tag.id,
          created_by_id: @zendesk_user_mapping[ zendesk_ticket.requester_id ] || 1,
        )
      }

      zendesk_ticket_articles = []
      zendesk_ticket.comments.each { |zendesk_article|
        zendesk_ticket_articles.push(zendesk_article)
      }

      zendesk_ticket_articles.each { |zendesk_article|

        local_article_fields = {
          ticket_id:     local_ticket.id,
          body:          zendesk_article.html_body,
          internal:      !zendesk_article.public,
          message_id:    zendesk_article.id,
          updated_by_id: @zendesk_user_mapping[ zendesk_article.author_id ] || 1,
          created_by_id: @zendesk_user_mapping[ zendesk_article.author_id ] || 1,
        }

        article_author = User.find( @zendesk_user_mapping[ zendesk_article.author_id ] || 1 )

        local_article_fields[:sender_id] = if article_author.role?('Customer')
                                             article_sender_customer.id
                                           elsif article_author.role?('Agent')
                                             article_sender_agent.id
                                           else
                                             article_sender_system.id
                                           end

        if zendesk_article.via.channel == 'web'
          local_article_fields[:type_id]    = article_type_web.id
        elsif zendesk_article.via.channel == 'email'
          local_article_fields[:from]       = zendesk_article.via.source.from.address
          local_article_fields[:to]         = zendesk_article.via.source.to.address # Notice zendesk_article.via.from.original_recipients=[\"another@gmail.com\", \"support@example.zendesk.com\"]
          local_article_fields[:type_id]    = article_type_email.id
        elsif zendesk_article.via.channel == 'sample_ticket'
          local_article_fields[:type_id]    = article_type_note.id
        elsif zendesk_article.via.channel == 'twitter'
          local_article_fields[:type_id] = if zendesk_article.via.source.rel == 'mention'
                                             article_type_twitter_status.id
                                           else
                                             article_type_twitter_dm.id
                                           end

        elsif zendesk_article.via.channel == 'facebook'

          local_article_fields[:from] = zendesk_article.via.source.from.facebook_id
          local_article_fields[:to]   = zendesk_article.via.source.to.facebook_id

          local_article_fields[:type_id] = if zendesk_article.via.source.rel == 'post'
                                             article_type_facebook_feed_post.id
                                           else
                                             article_type_facebook_feed_comment.id
                                           end
        end

        # create article
        local_article = Ticket::Article.find_by(message_id: local_article_fields[:message_id])
        if local_article
          local_article.update_attributes(local_article_fields)
        else
          local_article = Ticket::Article.create( local_article_fields )
        end

        zendesk_attachments = zendesk_article.attachments

        next if zendesk_attachments.size.zero?

        local_attachments = local_article.attachments

        zendesk_ticket_attachments = []
        zendesk_attachments.each { |zendesk_attachment|
          zendesk_ticket_attachments.push(zendesk_attachment)
        }

        zendesk_ticket_attachments.each { |zendesk_attachment|

          response = UserAgent.get(
            zendesk_attachment.content_url,
            {},
            {
              open_timeout: 10,
              read_timeout: 60,
            },
          )

          if !response.success?
            Rails.logger.error response.error
            next
          end

          local_attachment = Store.add(
            object:      'Ticket::Article',
            o_id:        local_article.id,
            data:        response.body,
            filename:    zendesk_attachment.file_name,
            preferences: {
              'Content-Type' => zendesk_attachment.content_type
            },
            created_by_id: 1
          )
        }
      }
    }
  end

  # SLA Policies
  # TODO:
  # https://github.com/zendesk/zendesk_api_client_rb/issues/271
  # https://developer.zendesk.com/rest_api/docs/core/sla_policies
  def import_sla_policies

  end

  # Macros
  # TODO:
  # https://developer.zendesk.com/rest_api/docs/core/macros
  def import_macros

    @client.macros.all! { |zendesk_macro|

      # TODO
      next if !zendesk_macro.active

      # "url"=>"https://example.zendesk.com/api/v2/macros/59511191.json"
      # "id"=>59511191
      # "title"=>"Herabstufen und informieren"
      # "active"=>true
      # "updated_at"=>2015-08-03 13:51:14 UTC
      # "created_at"=>2015-07-19 22:41:42 UTC
      # "restriction"=>nil
      # "actions"=>[
      #   {
      #   "field"=>"priority"
      #   "value"=>"low"
      #   }
      #   {
      #     "field"=>"comment_value"
      #     "value"=>"Das Verkehrsaufkommen ist g....."
      #   }
      # ]

      perform = {}
      zendesk_macro.actions.each { |action|

        # TODO: ID fields
        perform["ticket.#{action.field}"] = action.value
      }

      Macro.create_if_not_exists(
        name:    zendesk_macro.title,
        perform: perform,
        note:    '',
        active:  zendesk_macro.active,
      )
    }
  end

  # Schedulers
  # TODO:
  # https://github.com/zendesk/zendesk_api_client_rb/issues/281
  # https://developer.zendesk.com/rest_api/docs/core/schedules
  def import_schedules

  end

  # Views
  # TODO:
  # https://developer.zendesk.com/rest_api/docs/core/views
  def import_views

    @client.views.all! { |zendesk_view|

      # "url"         => "https://example.zendesk.com/api/v2/views/59511071.json"
      # "id"          => 59511071
      # "title"       => "Ihre Tickets"
      # "active"      => true
      # "updated_at"  => 2015-08-03 13:51:14 UTC
      # "created_at"  => 2015-07-19 22:41:42 UTC
      # "restriction" => nil
      # "sla_id"      => nil
      # "execution"   => {
      #   "group_by"    => "status"
      #   "group_order" => "asc"
      #   "sort_by"     => "score"
      #   "sort_order"  => "desc"
      #   "group"       => {
      #     "id"    => "status"
      #     "title" => "Status"
      #     "order" => "asc"
      #   }
      #   "sort"  => {
      #     "id"    => "score"
      #     "title" => "Score"
      #     "order" => "desc"
      #   }
      #   "columns" => [
      #     {
      #       "id"    => "score"
      #       "title" => "Score"
      #     }
      #     {
      #       "id"    => "subject"
      #       "title" => "Subject"
      #     }
      #     {
      #       "id"    => "requester"
      #       "title" => "Requester"
      #     }
      #     {
      #       "id"    => "created"
      #       "title" => "Requested"
      #     }
      #     {
      #       "id"    => "type"
      #       "title" => "Type"
      #     }
      #     {
      #       "id"    => "priority"
      #       "title" => "Priority"
      #     }
      #   ]
      #   "fields" => [
      #     {
      #       "id"    => "score"
      #       "title" => "Score"
      #     }
      #     {
      #       "id"    => "subject"
      #       "title" => "Subject"
      #     }
      #     {
      #       "id"    => "requester"
      #       "title" => "Requester"
      #     }
      #     {
      #       "id"    => "created"
      #       "title" => "Requested"
      #     }
      #     {
      #       "id"    => "type"
      #       "title" => "Type"
      #     }
      #     {
      #       "id"    => "priority"
      #       "title" => "Priority"
      #     }
      #   ]
      #   "custom_fields" => []
      # }
      # "conditions" => {
      #   "all" => [
      #     {
      #       "field"    => "status"
      #       "operator" => "less_than"
      #       "value"    => "solved"
      #     }
      #     {
      #       "field"    => "assignee_id"
      #       "operator" => "is"
      #       "value"    => "current_user"
      #     }
      #   ]
      #   "any" => []
      # }

      Overview.create_if_not_exists(
        name:      zendesk_view.title,
        link:      'my_assigned', # TODO
        prio:      1000,
        role_id:   overview_role.id,
        condition: {
          'ticket.state_id' => {
            operator: 'is',
            value:    [ 1, 2, 3, 7 ],
          },
          'ticket.owner_id' => {
            operator:      'is',
            pre_condition: 'current_user.id',
          },
        },
        order: {
          by:        'created_at',
          direction: 'ASC',
        },
        view: {
          d:                 %w(title customer group created_at),
          s:                 %w(title customer group created_at),
          m:                 %w(number title customer group created_at),
          view_mode_default: 's',
        },
      )
    }
  end

  # Automations
  # TODO:
  # https://developer.zendesk.com/rest_api/docs/core/automations
  def import_automations

    @client.automations.all! { |_zendesk_automation|

      # "url"        => "https://example.zendesk.com/api/v2/automations/60037892.json"
      # "id"         => 60037892
      # "title"      => "Ticket aus Facebook-Nachricht 1 ..."
      # "active"     => true
      # "updated_at" => 2015-08-03 13:51:15 UTC
      # "created_at" => 2015-07-28 11:27:50 UTC
      # "actions"    => [
      #   {
      #   "field" => "status"
      #   "value" => "closed"
      #   }
      # ]
      # "conditions" => {
      #   "all" => [
      #     {
      #       "field"    => "status"
      #       "operator" => "is"
      #       "value"    => "solved"
      #     }
      #     {
      #       "field"    => "SOLVED"
      #       "operator" => "is"
      #       "value"    => "24"
      #     }
      #     {
      #       "field"    => "via_type"
      #       "operator" => "is"
      #       "value"    => "facebook"
      #     }
      #   ]
      #   "any" => []
      # }
      # "position" => 10000

    }
  end

  # reset primary key sequences
  def self._reset_pk(table)
    return if ActiveRecord::Base.connection_config[:adapter] != 'postgresql'
    ActiveRecord::Base.connection.reset_pk_sequence!(table)
  end

  def get_custom_fields(custom_fields)
    return {} if !custom_fields
    fields = {}
    custom_fields.each { |custom_field|
      field_name  = @zendesk_field_mapping[ custom_field['id'] ].gsub(/\s/, '_')
      field_value = custom_field['value']
      next if field_value.nil? # ignore nil values
      if @zendesk_ticket_field_value_mapping[ field_name ]
        field_value = @zendesk_ticket_field_value_mapping[ field_name ][ field_value ]
      end
      fields[ field_name.to_sym ] = field_value
    }
    fields
  end

  def get_fields(user_fields)
    return {} if !user_fields
    fields = {}
    user_fields.each {|key, value|
      fields[key] = value
    }
    fields
  end

end
