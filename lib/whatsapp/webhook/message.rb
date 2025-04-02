# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message
  include Mixin::RequiredSubPaths

  attr_reader :data, :channel, :user, :ticket, :article

  def initialize(data:, channel:)
    @data = data
    @channel = channel
  end

  def process
    @user = create_or_update_user

    UserInfo.current_user_id = user.id
    @ticket = create_or_update_ticket
    @article = create_or_update_article

    schedule_reminder_job
  end

  private

  def attachment?
    false
  end

  def attachment
    raise NotImplementedError
  end

  def body
    raise NotImplementedError
  end

  def content_type
    raise NotImplementedError
  end

  def create_or_update_user
    User.by_mobile(number: user_info[:mobile]) || create_user
  end

  def create_or_update_ticket
    ticket = find_ticket
    return update_ticket(ticket:) if ticket.present?

    create_ticket
  end

  def create_ticket
    title = Translation.translate(Setting.get('locale_default') || 'en-us', __('%s via WhatsApp'), "#{profile_name} (#{@user.mobile})")

    Ticket.create!(
      group_id:    @channel.group_id,
      title:,
      state_id:    Ticket::State.find_by(default_create: true).id,
      priority_id: Ticket::Priority.find_by(default_create: true).id,
      customer_id: @user.id,
      preferences: {
        channel_id:   @channel.id,
        channel_area: @channel.area,
        whatsapp:     ticket_preferences,
      },
    )
  end

  def update_ticket(ticket:)
    new_state_id = ticket.state_id == default_create_ticket_state.id ? ticket.state_id : default_follow_up_ticket_state.id

    preferences = ticket.preferences
    preferences[:whatsapp] ||= {}
    preferences[:whatsapp][:timestamp_incoming] = @data[:entry].first[:changes].first[:value][:messages].first[:timestamp]

    ticket.update!(
      preferences:,
      state_id:    new_state_id,
    )

    ticket
  end

  def find_ticket
    state_ids        = Ticket::State.where(name: %w[closed merged removed]).pluck(:id)
    possible_tickets = Ticket.where(customer_id: @user.id).where.not(state_id: state_ids).reorder(:updated_at)

    possible_tickets.find_each.find { |possible_ticket| possible_ticket.preferences[:channel_id] == @channel.id }
  end

  def default_create_ticket_state
    Ticket::State.find_by(default_create: true)
  end

  def default_follow_up_ticket_state
    Ticket::State.find_by(default_follow_up: true)
  end

  def create_or_update_article
    # Editing messages results in being an unsupported type in the Cloud API. Nothing to do here!

    create_article
  end

  def create_article
    is_first_article = @ticket.articles.count.zero?

    article = Ticket::Article.create!(
      ticket_id:    @ticket.id,
      type_id:      Ticket::Article::Type.lookup(name: 'whatsapp message').id,
      sender_id:    Ticket::Article::Sender.lookup(name: 'Customer').id,
      from:         "#{profile_name} (#{@user.mobile})",
      to:           "#{@channel.options[:name]} (#{@channel.options[:phone_number]})",
      message_id:   article_preferences[:message_id],
      internal:     false,
      body:         body,
      content_type: content_type,
      preferences:  {
        whatsapp: article_preferences,
      },
    )

    create_attachment(article: article) if attachment?

    create_welcome_article if is_first_article

    article
  end

  def create_attachment(article:)
    data, filename, mime_type = attachment

    Store.create!(
      object:      'Ticket::Article',
      o_id:        article.id,
      data:        data,
      filename:    filename,
      preferences: {
        'Mime-Type' => mime_type,
      },
    )
  rescue Whatsapp::Client::CloudAPIError
    preferences = article.preferences
    preferences[:whatsapp] ||= {}
    preferences[:whatsapp][:media_error] = true
    article.update!(preferences:)
  rescue Whatsapp::Incoming::Media::InvalidMediaTypeError => e
    article.update!(
      body:     e.message,
      internal: true,
    )
  end

  def create_welcome_article

    return if @channel.options[:welcome].blank?

    translated_welcome_message = Translation.translate(user_locale, @channel.options[:welcome])

    Ticket::Article.create!(
      ticket_id:    @ticket.id,
      type_id:      Ticket::Article::Type.lookup(name: 'whatsapp message').id,
      sender_id:    Ticket::Article::Sender.lookup(name: 'System').id,
      from:         "#{@channel.options[:name]} (#{@channel.options[:phone_number]})",
      to:           "#{profile_name} (#{@user.mobile})",
      subject:      translated_welcome_message.truncate(100, omission: '…'),
      internal:     false,
      body:         translated_welcome_message,
      content_type: 'text/plain',
    )
  end

  def create_user
    user_data = user_info

    user_data[:active]   = true
    user_data[:role_ids] = Role.signup_role_ids

    User.create(user_data)
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

  def user_locale
    @user.preferences[:locale] || Locale.default
  end

  def profile_name
    data[:entry].first[:changes].first[:value][:contacts].first[:profile][:name]
  end

  def phone
    data[:entry].first[:changes].first[:value][:messages].first[:from]
  end

  def ticket_preferences
    {
      from:               {
        phone_number: phone,
        display_name: profile_name,
      },
      timestamp_incoming: @data[:entry].first[:changes].first[:value][:messages].first[:timestamp],
    }
  end

  def article_preferences
    {
      entry_id:   @data[:entry].first[:id],
      message_id: @data[:entry].first[:changes].first[:value][:messages].first[:id],
      type:       @data[:entry].first[:changes].first[:value][:messages].first[:type],
    }
  end

  def type
    raise NotImplementedError
  end

  def message
    @message ||= @data[:entry]
      .first[:changes]
      .first[:value][:messages]
      .first[type]
  end

  def schedule_reminder_job
    # Automatic reminders are an optional feature.
    return if !@channel.options[:reminder_active]

    # Do not schedule the job in case the service window has not been opened yet.
    timestamp_incoming = @ticket.preferences.dig(:whatsapp, :timestamp_incoming)
    return if timestamp_incoming.nil?

    cleanup_last_reminder_job

    # Calculate the end of the service window, based on the message timestamp.
    end_service_time = Time.zone.at(timestamp_incoming.to_i) + 24.hours
    return if end_service_time <= Time.zone.now

    # Set the reminder time to 1 hour before the service window closes and schedule a delayed job.
    reminder_time = end_service_time - 1.hour
    job = ScheduledWhatsappReminderJob.perform_at(reminder_time, @ticket, user_locale)

    # Remember reminder job information for subsequent runs.
    preferences = @ticket.preferences
    preferences[:whatsapp][:last_reminder_job_id] = job.provider_job_id
    ticket.update!(preferences:)
  end

  def cleanup_last_reminder_job
    last_job_id = @ticket.preferences.dig(:whatsapp, :last_reminder_job_id)
    return if last_job_id.nil?

    ::Delayed::Job.find_by(id: last_job_id)&.destroy!
  end
end
