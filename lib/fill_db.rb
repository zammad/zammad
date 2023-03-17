# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# rubocop:disable Rails/Output
module FillDb

=begin

fill your database with demo records

  FillDb.load(
    object_manager_attributes: {
      user: {
        'input': 1,
        'multiselect': 1,
      },
      ticket: {
        'textarea': 1,
        'multiselect': 1,
      },
    },
    agents: 50,
    customers: 1000,
    groups: 20,
    organizations: 40,
    overviews: 5,
    tickets: 100,
    knowledge_base_answers: 100,
    knowledge_base_categories: 20,
    public_links: 2,
    nice: 0,
  )

or if you only want to create 100 tickets

  FillDb.load(tickets: 100, nice: 0)
  FillDb.load(tickets: 100, nice: 1, log: true)
  FillDb.load(agents: 20, nice: 0)
  FillDb.load(overviews: 20, nice: 0)
  FillDb.load(tickets: 10000, nice: 0)
  FillDb.load(knowledge_base_answers: 100, nice: 0)
  FillDb.load(knowledge_base_categories: 20, nice: 0)
  FillDb.load(public_links: 2, nice: 0)

=end

  def self.load(params)
    params[:log] = params[:log] || false
    return load_data(params) if params[:log]

    Rails.logger.silence { load_data(params) }
  end

  def self.load_data(params)
    nice = params[:nice] || 0.5

    object_manager_attributes = params[:object_manager_attributes]
    agents                    = params[:agents] || 0
    customers                 = params[:customers] || 0
    groups                    = params[:groups] || 0
    organizations             = params[:organizations] || 0
    overviews                 = params[:overviews] || 0
    tickets                   = params[:tickets] || 0
    knowledge_base_answers    = params[:knowledge_base_answers] || 0
    knowledge_base_categories = params[:knowledge_base_categories] || 0
    public_links              = params[:public_links] || 0

    puts 'load db with:'
    puts " object_manager_attributes: #{object_manager_attributes}"
    puts " agents: #{agents}"
    puts " customers: #{customers}"
    puts " groups: #{groups}"
    puts " organizations: #{organizations}"
    puts " overviews: #{overviews}"
    puts " tickets: #{tickets}"
    puts " knowledge_base_answers: #{knowledge_base_answers}"
    puts " knowledge_base_categories: #{knowledge_base_categories}"
    puts " public_links: #{public_links}"

    # set current user
    UserInfo.current_user_id = 1

    # create object attributes
    object_manager_attributes_value_lookup = {}
    if object_manager_attributes.present?
      ActiveRecord::Base.transaction do
        object_manager_attributes.each do |object, attribute_types|
          attribute_types.each do |attribute_type, amount|
            next if amount.zero?

            object_manager_attributes_value_lookup[object] ||= {}

            amount.times do |index|
              name = "#{attribute_type}_#{counter}"

              object_attribute_creation = public_send("create_object_attribute_type_#{attribute_type}",
                                                      object:     object,
                                                      name:       name,
                                                      display:    name,
                                                      editable:   true,
                                                      active:     true,
                                                      screens:    {
                                                        create_middle: {
                                                          '-all-' => {
                                                            shown:    true,
                                                            required: false,
                                                          },
                                                        },
                                                        create:        {
                                                          '-all-' => {
                                                            shown:    true,
                                                            required: false,
                                                          },
                                                        },
                                                        edit:          {
                                                          '-all-' => {
                                                            shown:    true,
                                                            required: false,
                                                          },
                                                        },
                                                      },
                                                      to_migrate: true,
                                                      to_delete:  false,
                                                      to_config:  false,
                                                      position:   index + 1000)

              ObjectManager::Attribute.add(object_attribute_creation[:attribute_params])

              object_manager_attributes_value_lookup[object][name] = object_attribute_creation[:value]
            end
          end
        end
        ObjectManager::Attribute.migration_execute(false)
      end
    end

    # organizations
    organization_pool = []
    if organizations.zero?
      organization_pool = Organization.where(active: true)
      puts " take #{organization_pool.length} organizations"
    else
      (1..organizations).each do
        ActiveRecord::Base.transaction do
          create_params = {
            name:   "FillOrganization::#{counter}",
            active: true
          }

          if object_manager_attributes_value_lookup[:organization].present?
            create_params = create_params.merge(object_manager_attributes_value_lookup[:organization])
          end

          organization = Organization.create!(create_params)
          organization_pool.push organization
        end
      end
    end

    # create agents
    agent_pool = []
    if agents.zero?
      agent_pool = Role.where(name: 'Agent').first.users.where(active: true)
      puts " take #{agent_pool.length} agents"
    else
      roles = Role.where(name: [ 'Agent'])
      groups_all = Group.all

      (1..agents).each do
        ActiveRecord::Base.transaction do
          suffix = counter.to_s

          create_params = {
            login:     "filldb-agent-#{suffix}",
            firstname: "agent #{suffix}",
            lastname:  "agent #{suffix}",
            email:     "filldb-agent-#{suffix}@example.com",
            password:  'agentpw',
            active:    true,
            roles:     roles,
            groups:    groups_all,
          }

          if object_manager_attributes_value_lookup[:user].present?
            create_params = create_params.merge(object_manager_attributes_value_lookup[:user])
          end

          user = User.create_or_update(create_params)

          sleep nice
          agent_pool.push user
        end
      end
    end

    # create customer
    customer_pool = []
    if customers.zero?
      customer_pool = Role.where(name: 'Customer').first.users.where(active: true)
      puts " take #{customer_pool.length} customers"
    else
      roles = Role.where(name: [ 'Customer'])
      groups_all = Group.all

      true_or_false = [true, false]

      (1..customers).each do
        ActiveRecord::Base.transaction do
          suffix = counter.to_s
          organization = nil
          if organization_pool.present? && true_or_false.sample
            organization = organization_pool.sample
          end

          create_params = {
            login:        "filldb-customer-#{suffix}",
            firstname:    "customer #{suffix}",
            lastname:     "customer #{suffix}",
            email:        "filldb-customer-#{suffix}@example.com",
            password:     'customerpw',
            active:       true,
            organization: organization,
            roles:        roles,
          }

          if object_manager_attributes_value_lookup[:user].present?
            create_params = create_params.merge(object_manager_attributes_value_lookup[:user])
          end

          user = User.create_or_update(create_params)

          sleep nice
          customer_pool.push user
        end
      end
    end

    # create groups
    group_pool = []
    if groups.zero?

      group_pool = Group.where(active: true)
      puts " take #{group_pool.length} groups"
    else
      (1..groups).each do
        ActiveRecord::Base.transaction do

          create_params = {
            name:   "FillGroup::#{counter}",
            active: true,
          }

          if object_manager_attributes_value_lookup[:group].present?
            create_params = create_params.merge(object_manager_attributes_value_lookup[:group])
          end

          group = Group.create!(create_params)
          group_pool.push group
          Role.where(name: 'Agent').first.users.where(active: true).each do |user|
            user_groups = user.groups
            user_groups.push group
            user.groups = user_groups
            user.save!
          end
          sleep nice
        end
      end
    end

    # create overviews
    if !overviews.zero?
      (1..overviews).each do
        ActiveRecord::Base.transaction do
          Overview.create!(
            name:      "Filloverview::#{counter}",
            role_ids:  [Role.find_by(name: 'Agent').id],
            condition: {
              'ticket.state_id' => {
                operator: 'is',
                value:    Ticket::State.by_category(:work_on_all).pluck(:id),
              },
            },
            order:     {
              by:        'created_at',
              direction: 'ASC',
            },
            view:      {
              d:                 %w[title customer group state owner created_at],
              s:                 %w[title customer group state owner created_at],
              m:                 %w[number title customer group state owner created_at],
              view_mode_default: 's',
            },
            active:    true
          )
        end
      end
    end

    # create tickets
    if tickets.positive?
      priority_pool = Ticket::Priority.all
      state_pool = Ticket::State.all

      tickets.times do
        ActiveRecord::Base.transaction do
          customer = customer_pool.sample
          agent    = agent_pool.sample

          create_params = {
            title:         "some title äöüß#{counter}",
            group:         group_pool.sample,
            customer:      customer,
            owner:         agent,
            state:         state_pool.sample,
            priority:      priority_pool.sample,
            updated_by_id: agent.id,
            created_by_id: agent.id,
          }

          if object_manager_attributes_value_lookup[:ticket].present?
            create_params = create_params.merge(object_manager_attributes_value_lookup[:ticket])
          end

          ticket = Ticket.create!(create_params)

          # create article
          Ticket::Article.create!(
            ticket_id:     ticket.id,
            from:          customer.email,
            to:            'some_recipient@example.com',
            subject:       "some subject#{counter}",
            message_id:    "some@id-#{counter}",
            body:          'some message ...',
            internal:      false,
            sender:        Ticket::Article::Sender.where(name: 'Customer').first,
            type:          Ticket::Article::Type.where(name: 'phone').first,
            updated_by_id: agent.id,
            created_by_id: agent.id,
          )
          puts " Ticket #{ticket.number} created"
          sleep nice
        end
      end
    end

    knowledge_base = nil
    knowledge_base_categories_created = nil
    if knowledge_base_categories.positive?
      ActiveRecord::Base.transaction do
        knowledge_base = create_knowledge_base
        knowledge_base_categories_created = create_knowledge_base_categories(
          amount:            knowledge_base_categories,
          knowledge_base_id: knowledge_base.id,
          locale_id:         knowledge_base.kb_locales.first.id,
          sleep_time:        nice,
        )
      end
    end

    if knowledge_base_answers.positive?
      ActiveRecord::Base.transaction do
        create_knowledge_base_answers(
          amount:            knowledge_base_answers,
          categories_amount: knowledge_base_categories,
          categories:        knowledge_base_categories_created,
          knowledge_base:    knowledge_base,
          agents:            agent_pool,
          sleep_time:        nice,
        )
      end
    end

    return if public_links.zero?

    ActiveRecord::Base.transaction do
      create_public_links(
        amount:     public_links,
        sleep_time: nice,
      )
    end

  end

  def self.counter
    @counter ||= SecureRandom.random_number(1_000_000)
    @counter += 1
  end

  def self.create_knowledge_base
    return KnowledgeBase.first if KnowledgeBase.count.positive?

    params = {
      iconset:               'FontAwesome',
      color_highlight:       '#38ae6a',
      color_header:          '#f9fafb',
      color_header_link:     'hsl(206,8%,50%)',
      homepage_layout:       'grid',
      category_layout:       'grid',
      active:                true,
      kb_locales_attributes: [
        {
          system_locale_id: Locale.first.id,
          primary:          true,
        },
      ],
    }

    clean_params   = KnowledgeBase.association_name_to_id_convert(params)
    clean_params   = KnowledgeBase.param_cleanup(clean_params, true)
    knowledge_base = KnowledgeBase.new(clean_params)
    knowledge_base.associations_from_param(params)

    knowledge_base.save!

    puts " KnowledgeBase #{knowledge_base.id} created"

    knowledge_base
  end

  def self.create_knowledge_base_categories(params)
    amount            = params[:amount]
    knowledge_base_id = params[:knowledge_base_id]
    locale_id         = params[:locale_id]
    sleep_time        = params[:sleep_time]

    category_icons = %w[f1eb f143 f17c f109 f011 f275 f26c f0eb f2a3 f299 f0d0 f14e f26b f249 f108 f17a f09b f2a0 f20e f233]

    category_pool = []

    amount.times do |index|
      category = KnowledgeBase::Category.create!(
        knowledge_base_id: knowledge_base_id,
        category_icon:     category_icons.sample,
        position:          index
      )
      puts " KnowledgeBase::Category #{category.id} created"

      category_pool.push category

      category_translation = KnowledgeBase::Category::Translation.create!(
        title:        "some title#{counter}",
        kb_locale_id: locale_id,
        category_id:  category.id,
      )
      puts " KnowledgeBase::Category::Translation #{category_translation.title} created"

      sleep sleep_time
    end

    category_pool
  end

  def self.create_knowledge_base_answers(params)
    answers_amount    = params[:amount]
    categories_amount = params[:categories_amount]
    categories        = params[:categories]
    knowledge_base    = params[:knowledge_base]
    agents            = params[:agents]
    sleep_time        = params[:sleep_time]

    if knowledge_base.blank?
      knowledge_base = create_knowledge_base
    end

    locale = knowledge_base.kb_locales.first

    category_pool = categories.presence || create_knowledge_base_categories(categories_amount, knowledge_base.id, locale.id, sleep_time)
    if category_pool.blank?
      puts " Found #{category_pool.count} categories, aborting!"
      return
    end

    answers_amount.times do |index|
      answer = KnowledgeBase::Answer.create!(
        category_id: category_pool.sample.id,
        promoted:    false,
        position:    index,
      )

      content = KnowledgeBase::Answer::Translation::Content.create!(
        body: '<div style="color:rgb(63, 63, 63);">
          <p>some content...</p>
          </div>'
      )

      agent = agents.sample
      KnowledgeBase::Answer::Translation.create!(
        title:         "some title#{counter}",
        kb_locale_id:  locale.id,
        answer_id:     answer.id,
        content_id:    content.id,
        created_by_id: agent.id,
        updated_by_id: agent.id,
      )

      puts " KnowledgeBase::Answer #{answer.id} created"

      sleep sleep_time
    end
  end

  def self.create_public_links(params)
    public_links_amount = params[:amount]
    sleep_time = params[:sleep_time]

    public_links_amount.times do |index|
      public_link = PublicLink.create!(
        title:         "Example#{counter}",
        screen:        %w[login signup],
        link:          "https://zammad#{counter}.com",
        new_tab:       true,
        prio:          index,
        updated_by_id: 1,
        created_by_id: 1,
      )

      puts " PublicLink #{public_link.id} created"

      sleep sleep_time
    end
  end

  def self.create_object_attribute_type_input(params)
    {
      attribute_params: params.merge(
        data_type:   'input',
        data_option: {
          type:      'text',
          maxlength: 200,
          null:      true,
          translate: false,
        }
      ),
      value:            'example value',
    }
  end

  def self.create_object_attribute_type_textarea(params)
    {
      attribute_params: params.merge(
        data_type:   'textarea',
        data_option: {
          type:      'textarea',
          maxlength: 200,
          rows:      4,
          null:      true,
          translate: false,
        }
      ),
      value:            "example value\nwith line break",
    }
  end

  def self.create_object_attribute_type_integer(params)
    {
      attribute_params: params.merge(
        data_type:   'integer',
        data_option: {
          default: 0,
          null:    true,
          min:     0,
          max:     9999,
        }
      ),
      value:            99,
    }
  end

  def self.create_object_attribute_type_boolean(params)
    {
      attribute_params: params.merge(
        data_type:   'boolean',
        data_option: {
          default: false,
          null:    true,
          options: {
            true  => 'yes',
            false => 'no',
          }
        }
      ),
      value:            true,
    }
  end

  def self.create_object_attribute_type_date(params)
    {
      attribute_params: params.merge(
        data_type:   'date',
        data_option: {
          diff: 24,
          null: true,
        }
      ),
      value:            '2022-12-01',
    }
  end

  def self.create_object_attribute_type_datettime(params)
    {
      attribute_params: params.merge(
        data_type:   'datetime',
        data_option: {
          diff:   24,
          future: true,
          past:   true,
          null:   true,
        }
      ),
      value:            '2022-10-01 12:00:00',
    }
  end

  def self.create_object_attribute_type_select(params)
    multiple = params[:data_type] == 'multiselect'

    {
      attribute_params: params.merge(
        data_type:   params[:data_type] || 'select',
        data_option: {
          default:    multiple ? [] : '',
          options:    {
            'key_1' => 'value_1',
            'key_2' => 'value_2',
            'key_3' => 'value_3',
            'key_4' => 'value_4',
          },
          multiple:   multiple,
          translate:  true,
          nulloption: true,
          null:       true,
        }
      ),
      value:            multiple ? %w[key_1 key_3] : 'key_3',
    }
  end

  def self.create_object_attribute_type_multiselect(params)
    create_object_attribute_type_select(
      params.merge(
        data_type: 'multiselect',
      )
    )
  end

  def self.create_object_attribute_type_tree_select(params)
    multiple = params[:data_type] == 'multi_tree_select'

    {
      attribute_params: params.merge(
        data_type:   params[:data_type] || 'tree_select',
        data_option: {
          default:    multiple ? [] : '',
          options:    [
            {
              'name'     => 'Incident',
              'value'    => 'Incident',
              'children' => [
                {
                  'name'     => 'Hardware',
                  'value'    => 'Incident::Hardware',
                  'children' => [
                    {
                      'name'  => 'Monitor',
                      'value' => 'Incident::Hardware::Monitor'
                    },
                    {
                      'name'  => 'Mouse',
                      'value' => 'Incident::Hardware::Mouse'
                    },
                    {
                      'name'  => 'Keyboard',
                      'value' => 'Incident::Hardware::Keyboard'
                    }
                  ]
                },
                {
                  'name'     => 'Softwareproblem',
                  'value'    => 'Incident::Softwareproblem',
                  'children' => [
                    {
                      'name'  => 'CRM',
                      'value' => 'Incident::Softwareproblem::CRM'
                    },
                    {
                      'name'  => 'EDI',
                      'value' => 'Incident::Softwareproblem::EDI'
                    },
                    {
                      'name'     => 'SAP',
                      'value'    => 'Incident::Softwareproblem::SAP',
                      'children' => [
                        {
                          'name'  => 'Authentication',
                          'value' => 'Incident::Softwareproblem::SAP::Authentication'
                        },
                        {
                          'name'  => 'Not reachable',
                          'value' => 'Incident::Softwareproblem::SAP::Not reachable'
                        }
                      ]
                    },
                    {
                      'name'     => 'MS Office',
                      'value'    => 'Incident::Softwareproblem::MS Office',
                      'children' => [
                        {
                          'name'  => 'Excel',
                          'value' => 'Incident::Softwareproblem::MS Office::Excel'
                        },
                        {
                          'name'  => 'PowerPoint',
                          'value' => 'Incident::Softwareproblem::MS Office::PowerPoint'
                        },
                        {
                          'name'  => 'Word',
                          'value' => 'Incident::Softwareproblem::MS Office::Word'
                        },
                        {
                          'name'  => 'Outlook',
                          'value' => 'Incident::Softwareproblem::MS Office::Outlook'
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              'name'     => 'Service request',
              'value'    => 'Service request',
              'children' => [
                {
                  'name'  => 'New software requirement',
                  'value' => 'Service request::New software requirement'
                },
                {
                  'name'  => 'New hardware',
                  'value' => 'Service request::New hardware'
                },
                {
                  'name'  => 'Consulting',
                  'value' => 'Service request::Consulting'
                }
              ]
            },
            {
              'name'  => 'Change request',
              'value' => 'Change request'
            }
          ],
          multiple:   multiple,
          translate:  true,
          nulloption: true,
          null:       true,
        }
      ),
      value:            multiple ? ['Change request', 'Incident::Hardware::Monitor', 'Incident::Softwareproblem::MS Office::Word'] : 'Incident::Hardware::Monitor',
    }
  end

  def self.create_object_attribute_type_multi_tree_select(params)
    create_object_attribute_type_tree_select(
      params.merge(
        data_type: 'multi_tree_select',
      )
    )
  end
end
# rubocop:enable Rails/Output
