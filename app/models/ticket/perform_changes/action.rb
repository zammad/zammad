# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
      last_article:          all_articles.last,
      last_internal_article: all_articles.reverse.find(&:internal?),
      last_external_article: all_articles.reverse.find { |a| !a.internal? },
    }
  end

  def from_current_article
    {
      last_article:          article,
      last_internal_article: article.internal? ? article : all_articles.reverse.find(&:internal?),
      last_external_article: article.internal? ? all_articles.reverse.find { |a| !a.internal? } : article,
    }
  end
end
