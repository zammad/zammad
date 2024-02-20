# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message
  include Mixin::RequiredSubPaths

  attr_reader :data, :channel

  def initialize(data:, channel:)
    @data = data
    @channel = channel
  end

  def process
    user = create_or_update_user

    UserInfo.current_user_id = user.id
    ticket = create_or_update_ticket(user:)
    create_or_update_article(user:, ticket:)
  end

  private

  def body
    raise NotImplementedError
  end

  def content_type
    raise NotImplementedError
  end

  def create_or_update_user
    auth = Authorization.find_by(uid: user_info[:mobile], provider: 'whatsapp_business')
    user = auth.present? ? update_user(auth:) : create_user
    authorize_user(user:, auth:)

    user
  end

  def create_or_update_ticket(user:)
    ticket = find_ticket(user:)
    return update_ticket(user:, ticket:) if ticket.present?

    create_ticket(user:)
  end

  def create_ticket(user:)
    title = Translation.translate(Setting.get('locale_default') || 'en-us', __('New WhatsApp message from %s'), "#{profile_name} (#{user.mobile})")

    Ticket.create!(
      group_id:    @channel.group_id,
      title:,
      state_id:    Ticket::State.find_by(default_create: true).id,
      priority_id: Ticket::Priority.find_by(default_create: true).id,
      customer_id: user.id,
      preferences: {
        channel_id: @channel.id,
      },
    )
  end

  def update_ticket(user:, ticket:)
    new_state_id = ticket.state_id == default_create_ticket_state.id ? ticket.state_id : default_follow_up_ticket_state.id
    ticket.update!(state_id: new_state_id)

    ticket
  end

  def find_ticket(user:)
    state_ids        = Ticket::State.where(name: %w[closed merged removed]).pluck(:id)
    possible_tickets = Ticket.where(customer_id: user.id).where.not(state_id: state_ids).reorder(:updated_at)

    possible_tickets.find_each.find { |possible_ticket| possible_ticket.preferences[:channel_id] == @channel.id }
  end

  def default_create_ticket_state
    Ticket::State.find_by(default_create: true)
  end

  def default_follow_up_ticket_state
    Ticket::State.find_by(default_follow_up: true)
  end

  def create_or_update_article(user:, ticket:)
    # Editing messages results in being an unsupported type in the Cloud API. Nothing to do here!

    create_article(user:, ticket:)
  end

  def create_article(user:, ticket:)
    Ticket::Article.create!(
      ticket_id:     ticket.id,
      type_id:       Ticket::Article::Type.find_by(name: 'whatsapp message').id,
      sender_id:     Ticket::Article::Sender.find_by(name: 'Customer').id,
      from:          "#{profile_name} (#{user.mobile})",
      to:            "#{@channel.options[:name]} (#{@channel.options[:phone_number]})",
      message_id:    article_preferences[:message_id],
      internal:      false,
      body:          body,
      content_type:  content_type,
      created_by_id: user.id,
      preferences:   {
        whatsapp: article_preferences,
      },
    )
  end

  def create_user
    user_data = user_info

    user_data[:active]   = true
    user_data[:role_ids] = Role.signup_role_ids

    User.create(user_data)
  end

  def update_user(auth:)
    user = User.find(auth.user_id)
    user.update!(user_info)

    user
  end

  def authorize_user(user:, auth: nil)
    auth_data = {
      uid:      user.mobile,
      username: user.login,
      user_id:  user.id,
      provider: 'whatsapp_business'
    }

    return auth.update!(auth_data) if auth.present?

    Authorization.create(auth_data)
  end

  def user_info
    firstname, lastname = User.name_guess(profile_name)

    # Fallback to profile name if no firstname or lastname is found
    if firstname.blank? || lastname.blank?
      firstname, lastname = profile_name.split(%r{\s|\.|,|,\s}, 2)
    end

    {
      firstname: firstname&.strip,
      lastname:  lastname&.strip,
      mobile:    "+#{phone}",
      login:     phone,
    }
  end

  def profile_name
    data[:entry].first[:changes].first[:value][:contacts].first[:profile][:name]
  end

  def phone
    data[:entry].first[:changes].first[:value][:messages].first[:from]
  end

  def article_preferences
    {
      entry_id:   @data[:entry].first[:id],
      message_id: @data[:entry].first[:changes].first[:value][:messages].first[:id],
    }
  end
end
