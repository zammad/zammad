# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::PerformChanges::Action::ArticleNote < Ticket::PerformChanges::Action

  def self.phase
    :after_save
  end

  def execute(...)
    add_note(execution_data)
  end

  private

  def add_note(note)
    rendered_subject = NotificationFactory::Mailer.template(
      templateInline: note[:subject],
      objects:        notification_factory_template_objects,
      quote:          true,
      locale:         locale,
      timezone:       timezone,
    )

    rendered_body = NotificationFactory::Mailer.template(
      templateInline: note[:body],
      objects:        notification_factory_template_objects,
      quote:          true,
      locale:         locale,
      timezone:       timezone,
    )

    article = Ticket::Article.new(
      ticket_id:     id,
      subject:       rendered_subject,
      content_type:  'text/html',
      body:          rendered_body,
      internal:      note[:internal],
      sender:        Ticket::Article::Sender.find_by(name: 'System'),
      type:          Ticket::Article::Type.find_by(name: 'note'),
      preferences:   {
        perform_origin: origin,
        notification:   true,
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    article.history_change_source_attribute(performable, 'created')
    article.save!
  end
end
