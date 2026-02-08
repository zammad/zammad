# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Rubocop does not like :: prefix, but Yard throws an error parsing without it
class Ticket::PerformChanges::Action < ::PerformChanges::Action # rubocop:disable Style/RedundantConstantBase
  attr_accessor :article

  def initialize(record, execution_data, perform_changes_data)
    super

    @article = begin
      perform_changes_data[:context_data][:article]
    rescue
      nil
    end
  end

  private

  # articles.last breaks (returns the wrong article)
  # if another email notification trigger preceded this one
  # (see https://github.com/zammad/zammad/issues/1543)
  def notification_factory_template_objects
    @notification_factory_template_objects ||= begin
      {
        user:                     User.lookup(id: user_id),
        ticket:                   record,
        article:                  last_articles[:last_article],
        created_article:          article,
        created_internal_article: article&.internal? ? article : nil,
        created_external_article: article&.internal? ? nil : article,
      }.merge(last_articles)
    end
  end

  def all_articles
    @all_articles ||= record.articles
  end

  def last_articles
    @last_articles ||= article.present? ? from_current_article : from_all_articles
  end

  def from_all_articles
    {
      first_article:          all_articles.first,
      first_internal_article: all_articles.find(&:internal?),
      first_external_article: all_articles.find { |a| !a.internal? },
      last_article:           all_articles.last,
      last_internal_article:  all_articles.reverse.find(&:internal?),
      last_external_article:  all_articles.reverse.find { |a| !a.internal? },
    }
  end

  def from_current_article
    {
      first_article:          all_articles.first,
      first_internal_article: all_articles.find(&:internal?),
      first_external_article: all_articles.find { |a| !a.internal? },
      last_article:           article,
      last_internal_article:  article.internal? ? article : all_articles.reverse.find(&:internal?),
      last_external_article:  article.internal? ? all_articles.reverse.find { |a| !a.internal? } : article,
    }
  end

  def article_clone_attachments(new_article_id)
    NotificationFactory::Renderer::ARTICLE_TAGS.each do |article_key|
      article_template = notification_factory_template_objects[article_key]

      next if !article_template
      next if ActiveModel::Type::Boolean.new.cast(execution_data['include_attachments']) != true || article_template.attachments.blank?

      article_template.clone_attachments('Ticket::Article', new_article_id, only_attached_attachments: true)
    end
  end

  def article_clone_attachments_inline(new_article_id)
    NotificationFactory::Renderer::ARTICLE_TAGS.each do |article_key|
      article_template = notification_factory_template_objects[article_key]

      next if !article_template
      next if !article_template.should_clone_inline_attachments?

      article_template.clone_attachments('Ticket::Article', new_article_id, only_inline_attachments: true)
      article_template.should_clone_inline_attachments = false # cancel the temporary flag after cloning
    end
  end
end
