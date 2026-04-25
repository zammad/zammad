# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Ticket::PerformChanges::Action::ArticleNote < Ticket::PerformChanges::Action

  def self.phase
    :after_save
  end

  def execute(...)
    add_note
  end

  private

  def add_note
    rendered_subject = NotificationFactory::Mailer.template(
      templateInline: execution_data[:subject],
      objects:        notification_factory_template_objects,
      quote:          true,
      locale:         locale,
      timezone:       timezone,
    )

    (body, attachments_inline) = article_body

    new_article = Ticket::Article.new(
      ticket_id:     id,
      subject:       rendered_subject,
      content_type:  'text/html',
      body:          body,
      internal:      execution_data[:internal],
      sender:        Ticket::Article::Sender.find_by(name: 'System'),
      type:          Ticket::Article::Type.find_by(name: 'note'),
      preferences:   {
        perform_origin: origin,
        notification:   true,
      },
      updated_by_id: 1,
      created_by_id: 1,
    )
    new_article.history_change_source_attribute(performable, 'created')
    new_article.save!

    attachments_inline.each do |attachment|
      Store.create!(
        object:      'Ticket::Article',
        o_id:        new_article.id,
        data:        attachment[:data],
        filename:    attachment[:filename],
        preferences: attachment[:preferences],
      )
    end

    article_clone_attachments(new_article.id)
    article_clone_attachments_inline(new_article.id)
  end

  def article_body
    body = NotificationFactory::Mailer.template(
      templateInline: execution_data['body'],
      objects:        notification_factory_template_objects,
      quote:          true,
      locale:         locale,
      timezone:       timezone,
    )

    HtmlSanitizer.replace_inline_images(body, id)
  end
end
