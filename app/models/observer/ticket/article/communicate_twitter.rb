# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

# http://stem.ps/rails/2015/01/25/ruby-gotcha-toplevel-constant-referenced-by.html
require 'channel/twitter'

class Observer::Ticket::Article::CommunicateTwitter < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # if sender is customer, do not communication
    sender = Ticket::Article::Sender.lookup( id: record.sender_id )
    return if sender.nil?
    return if sender['name'] == 'Customer'

    # only apply on tweets
    type = Ticket::Article::Type.lookup( id: record.type_id )
    return if type['name'] !~ /\Atwitter/

    twitter = Channel::Twitter.new
    tweet   = twitter.send({
                             type:        type['name'],
                             to:          record.to,
                             body:        record.body,
                             in_reply_to: record.in_reply_to
                           })
    record.message_id = tweet.id
    record.save
  end
end
