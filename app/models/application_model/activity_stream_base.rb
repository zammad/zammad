# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::ActivityStreamBase

=begin

log activity for this object

  article = Ticket::Article.find(123)
  result = article.activity_stream_log( 'created', user_id )

returns

  result = true # false

=end

  def activity_stream_log (type, user_id)
    return if !self.class.activity_stream_support_config
    ActivityStream.add(
      :o_id           => self['id'],
      :type           => type,
      :object         => self.class.name,
#      :role           => self.activity_stream_role,
      :created_at     => self.updated_at,
      :created_by_id  => user_id,
    )
  end

end