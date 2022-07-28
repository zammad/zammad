# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

# rubocop:disable Rails/Output
module FillDb

=begin

fill your database with demo records

  FillDb.load(
    agents: 50,
    customers: 1000,
    groups: 20,
    organizations: 40,
    overviews: 5,
    tickets: 100,
    knowledge_base_answers: 100,
    knowledge_base_categories: 20,
  )

or if you only want to create 100 tickets

  FillDb.load(tickets: 100)
  FillDb.load(agents: 20)
  FillDb.load(overviews: 20)
  FillDb.load(tickets: 10000)
  FillDb.load(knowledge_base_answers: 100)
  FillDb.load(knowledge_base_categories: 20)

=end

  def self.load(params)
    nice                      = params[:nice] || 0.5
    agents                    = params[:agents] || 0
    customers                 = params[:customers] || 0
    groups                    = params[:groups] || 0
    organizations             = params[:organizations] || 0
    overviews                 = params[:overviews] || 0
    tickets                   = params[:tickets] || 0
    knowledge_base_answers    = params[:knowledge_base_answers] || 0
    knowledge_base_categories = params[:knowledge_base_categories] || 0

    puts 'load db with:'
    puts " agents: #{agents}"
    puts " customers: #{customers}"
    puts " groups: #{groups}"
    puts " organizations: #{organizations}"
    puts " overviews: #{overviews}"
    puts " tickets: #{tickets}"
    puts " knowledge_base_answers: #{knowledge_base_answers}"
    puts " knowledge_base_categories: #{knowledge_base_categories}"

    # set current user
    UserInfo.current_user_id = 1

    # organizations
    organization_pool = []
    if organizations.zero?
      organization_pool = Organization.where(active: true)
      puts " take #{organization_pool.length} organizations"
    else
      (1..organizations).each do
        ActiveRecord::Base.transaction do
          organization = Organization.create!(name: "FillOrganization::#{counter}", active: true)
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
          user = User.create_or_update(
            login:     "filldb-agent-#{suffix}",
            firstname: "agent #{suffix}",
            lastname:  "agent #{suffix}",
            email:     "filldb-agent-#{suffix}@example.com",
            password:  'agentpw',
            active:    true,
            roles:     roles,
            groups:    groups_all,
          )
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
          user = User.create_or_update(
            login:        "filldb-customer-#{suffix}",
            firstname:    "customer #{suffix}",
            lastname:     "customer #{suffix}",
            email:        "filldb-customer-#{suffix}@example.com",
            password:     'customerpw',
            active:       true,
            organization: organization,
            roles:        roles,
          )
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
          group = Group.create!(name: "FillGroup::#{counter}", active: true)
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
          ticket = Ticket.create!(
            title:         "some title äöüß#{counter}",
            group:         group_pool.sample,
            customer:      customer,
            owner:         agent,
            state:         state_pool.sample,
            priority:      priority_pool.sample,
            updated_by_id: agent.id,
            created_by_id: agent.id,
          )

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

    return if knowledge_base_answers.zero?

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
end
# rubocop:enable Rails/Output
