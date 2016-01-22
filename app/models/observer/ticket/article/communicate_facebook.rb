# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'channel/driver/facebook'

class Observer::Ticket::Article::CommunicateFacebook < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # if sender is customer, do not communication
    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    return 1 if sender.nil?
    return 1 if sender['name'] == 'Customer'

    # only apply for facebook
    type = Ticket::Article::Type.lookup(id: record.type_id)
    return if type['name'] !~ /\Afacebook/

    ticket = Ticket.lookup(id: record.ticket_id)
    fail "Can't find ticket.preferences for Ticket.find(#{record.ticket_id})" if !ticket.preferences
    fail "Can't find ticket.preferences['channel_id'] for Ticket.find(#{record.ticket_id})" if !ticket.preferences['channel_id']
    channel = Channel.lookup(id: ticket.preferences['channel_id'])
    fail "Channel.find(#{channel.id}) isn't a twitter channel!" if channel.options[:adapter] !~ /\Afacebook/i

    # check source object id
    ticket = record.ticket
    if !ticket.preferences['channel_fb_object_id']
      fail "fb object id is missing in ticket.preferences['channel_fb_object_id'] for Ticket.find(#{ticket.id})"
    end

    # fill in_reply_to
    if !record.in_reply_to || record.in_reply_to.empty?
      record.in_reply_to = ticket.articles.first.message_id
    end

    facebook = Channel::Driver::Facebook.new
    post     = facebook.send(
      channel.options,
      ticket.preferences[:channel_fb_object_id],
      {
        type:        type['name'],
        to:          record.to,
        body:        record.body,
        in_reply_to: record.in_reply_to,
      }
    )
    record.from       = post['from']['name']
    record.message_id = post['id']
    record.save
  end
end
