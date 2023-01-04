# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::Sms::Base
  def user_by_cti(mobile)
    _from_comment, preferences = Cti::CallerId.get_comment_preferences(mobile, 'from')
    user = nil
    if preferences && preferences['from'] && preferences['from'][0] && preferences['from'][0]['level'] == 'known' && preferences['from'][0]['object'] == 'User'
      user = User.find_by(id: preferences['from'][0]['o_id'])
    end
    user
  end

  def user_by_mobile(mobile)
    User.where(mobile: mobile).order(:updated_at).first || user_by_cti(mobile) || User.create!(
      firstname: mobile,
      mobile:    mobile,
    )
  end

  def article_type_sms
    Ticket::Article::Type.find_by(name: 'sms')
  end

  def closed_ids
    Ticket::State.where(name: %w[closed merged removed]).pluck(:id)
  end

  def ensure_ticket_followup_state(ticket)
    return if !ticket

    new_state = Ticket::State.find_by(default_create: true)
    return if ticket.state_id == new_state.id

    ticket.state = Ticket::State.find_by(default_follow_up: true)
    ticket.save!
  end

  def find_open_sms_ticket(user)
    ticket = Ticket.where(customer_id: user.id, create_article_type_id: article_type_sms.id).where.not(state_id: closed_ids).order(:updated_at).first
    ensure_ticket_followup_state(ticket)
    ticket
  end

  def ensure_group!(channel)
    raise Exceptions::UnprocessableEntity, __('Group needed in channel definition!') if channel.group_id.blank?

    group = Group.find_by(id: channel.group_id)
    raise Exceptions::UnprocessableEntity, __('Group is invalid!') if !group
  end

  def cut_title(title)
    if title.length > 40
      title = "#{title[0, 40]}..."
    end
    title
  end

  def process_ticket(attr, channel, user)
    ticket = find_open_sms_ticket(user)
    if !ticket
      ensure_group!(channel)

      ticket = create_ticket(attr, channel, user)
    end

    create_article(attr, channel, ticket)
  end
end
