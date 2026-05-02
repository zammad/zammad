# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run::Context::Entity
  attr_reader :entity_object, :entity_object_attributes, :entity_articles, :entity_article, :entity_tags

  def initialize(entity_object:, entity_context: {}, entity_article: nil)
    @entity_object = entity_object
    @entity_object_attributes = entity_context['object_attributes'] || ['title']
    @entity_articles = entity_context['articles'] || 'all'
    @entity_article = entity_article
    @entity_tags = entity_context['tags'] || false
  end

  def prepare
    result = {}

    if entity_object_attributes.present?
      result[:object_attributes] = prepare_entity_object_attributes
    end

    if entity_articles.present?
      result[:articles] = prepare_entity_articles
    end

    if entity_tags
      result[:tags] = prepare_entity_tags
    end

    result
  end

  private

  def prepare_entity_object_attributes
    entity_object_attributes.each_with_object({}) do |name, memo|
      object_attribute = get_object_attribute(name)
      next if object_attribute.blank?

      # Get the raw value from the entity object
      raw_value = entity_object.send(name.to_sym)
      next if raw_value.blank?

      # Determine the appropriate class to handle this attribute type
      field_class = determine_object_attribute_class(object_attribute)
      next if field_class.blank?

      prepared_item = field_class.new(
        object_attribute:,
        entity_value:     raw_value,
      ).prepare

      memo[name] = prepared_item if prepared_item.present?
    end
  end

  def prepare_entity_articles
    articles_to_process = determine_articles_to_process

    articles_to_process.filter_map do |article|
      processed_body = process_article_body(article, skip_quote_removal: skip_quote_removal?(article))
      next if processed_body.blank?

      {
        article:,
        processed_body:,
      }
    end
  end

  def prepare_entity_tags
    entity_object.tag_list
  end

  def skip_quote_removal?(article)
    return true if entity_articles == 'first'
    return false if entity_articles == 'last'

    # For 'all': skip quote removal only for the first article.
    first_article_id == article.id
  end

  def determine_articles_to_process
    return last_articles if entity_articles == 'last'
    return first_article if entity_articles == 'first'

    all_articles
  end

  def last_articles
    Array(entity_article.presence || all_articles.last).compact
  end

  def first_article
    Array(all_articles.first)
  end

  def all_articles
    @all_articles ||= entity_object.articles.without_system_notifications
  end

  def process_article_body(article, skip_quote_removal: false)
    return if article.body.blank?

    result = if article.type.name == 'email' && !skip_quote_removal
               Text::QuoteRemover
               .new(text: article.body_as_text(link_style: :markdown))
               .remove
             else
               article.body_as_text(link_style: :markdown)
             end

    return if result.blank?

    result
  end

  def first_article_id
    @first_article_id ||= all_articles.first&.id
  end

  def get_object_attribute(name)
    ObjectManager::Attribute.get(
      object: 'Ticket',
      name:   name
    )
  end

  def determine_object_attribute_class(object_attribute)
    object_attribute_classes.find do |klass|
      klass.applicable?(object_attribute)
    end
  end

  def object_attribute_classes
    [
      Service::AI::Agent::Run::Context::Entity::ObjectAttributes::Relation,
      Service::AI::Agent::Run::Context::Entity::ObjectAttributes::Options,
      Service::AI::Agent::Run::Context::Entity::ObjectAttributes::Default,
    ]
  end
end
