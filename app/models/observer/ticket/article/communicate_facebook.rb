class Observer::Ticket::Article::CommunicateFacebook < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # if sender is customer, do not communication
    sender = Ticket::Article::Sender.where( :id => record.ticket_article_sender_id ).first
    return 1 if sender == nil
    return 1 if sender['name'] == 'Customer'

    # only apply on emails
    type = Ticket::Article::Type.where( :id => record.ticket_article_type_id ).first
    return if type['name'] != 'facebook'

    a = Channel::Facebook.new
    a.send(
      {
        :from    => 'me@znuny.com',
        :to      => 'medenhofer',
        :body    => record.body
      }
    )
  end
end