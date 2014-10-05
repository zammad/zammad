# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::ActivityStreamBase

=begin

log activity for this object

  article = Ticket::Article.find(123)
  result = article.activity_stream_log( 'created', user_id )

  # force log
  result = article.activity_stream_log( 'created', user_id, true )

returns

  result = true # false

=end

  def activity_stream_log (type, user_id, force = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    role       = self.class.activity_stream_support_config[:role]
    updated_at = self.updated_at
    if force
      updated_at = Time.new
    end
    ActivityStream.add(
      :o_id           => self['id'],
      :type           => type,
      :object         => self.class.name,
      :group_id       => self['group_id'],
      :role           => role,
      :created_at     => updated_at,
      :created_by_id  => user_id,
    )
  end

end
