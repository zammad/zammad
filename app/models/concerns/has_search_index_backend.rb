# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasSearchIndexBackend
  extend ActiveSupport::Concern

  included do
    after_create  :search_index_update
    after_update  :search_index_update
    after_touch   :search_index_update_touch
    after_destroy :search_index_destroy
  end

=begin

update search index, if configured - will be executed automatically

  model = Model.find(123)
  model.search_index_update

=end

  def search_index_update
    return true if ignore_search_indexing?(:update)

    # start background job to transfer data to search index
    return true if !SearchIndexBackend.enabled?

    SearchIndexAssociationsJob.perform_later(self.class.to_s, id)
    true
  end

=begin

update search index, if configured - will be executed automatically

  model = Model.find(123)
  model.search_index_update_touch

=end

  def search_index_update_touch
    return true if ignore_search_indexing?(:update)

    # start background job to transfer data to search index
    return true if !SearchIndexBackend.enabled?

    SearchIndexJob.perform_later(self.class.to_s, id)
    true
  end

=begin

update search index, if configured - will be executed automatically

  model = Organizations.find(123)
  result = model.search_index_update_associations_full

returns

  # Updates asscociation data for users and tickets of the organization in this example
  result = true

=end

  def search_index_update_associations_full
    update_class = {
      'Organization'     => :organization_id,
      'Group'            => :group_id,
      'Ticket::State'    => :state_id,
      'Ticket::Priority' => :priority_id,
    }
    update_column = update_class[self.class.to_s]
    return if update_column.blank?

    # reindex all object related tickets for the given object id
    # we can not use the delta function for this because of the excluded
    # ticket article attachments. see explain in delta function
    Ticket.select('id').where(update_column => id).order(id: :desc).limit(10_000).pluck(:id).each do |ticket_id|
      SearchIndexJob.perform_later('Ticket', ticket_id)
    end

    true
  end

=begin

update search index, if configured - will be executed automatically

  model = Organizations.find(123)
  result = model.search_index_update_associations_delta

returns

  # Updates asscociation data for users and tickets of the organization in this example
  result = true

=end

  def search_index_update_associations_delta

    # start background job to transfer data to search index
    return true if !SearchIndexBackend.enabled?

    new_search_index_value = search_index_attribute_lookup(include_references: false)
    return if new_search_index_value.blank?

    Models.indexable.each do |local_object|
      next if local_object == self.class

      # delta update of associations is only possible for
      # objects which are not containing modifications of the source
      # https://github.com/zammad/zammad/blob/264853dcbe4e53addaf0f8e6df3735ceddc9de63/lib/tasks/search_index_es.rake#L266
      # because of the exlusion of the article attachments for the ticket
      # we dont have the attachment data available in the json store of the object.
      # so the search index would lose the attachment information on the _update_by_query function
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-source-field.html
      next if local_object.to_s == 'Ticket'

      local_object.new.attributes.each do |key, _value|
        attribute_name = key.to_s
        next if attribute_name.blank?

        attribute_ref_name = local_object.search_index_attribute_ref_name(attribute_name)
        next if attribute_ref_name.blank?

        association = local_object.reflect_on_association(attribute_ref_name)
        next if association.blank?
        next if association.options[:polymorphic]

        attribute_class = association.klass
        next if attribute_class.blank?
        next if attribute_class != self.class

        data = {
          attribute_ref_name => new_search_index_value,
        }
        where = {
          attribute_name => id
        }
        SearchIndexBackend.update_by_query(local_object.to_s, data, where)
      end
    end

    true
  end

=begin

delete search index object, will be executed automatically

  model = Model.find(123)
  model.search_index_destroy

=end

  def search_index_destroy
    return true if ignore_search_indexing?(:destroy)

    SearchIndexBackend.remove(self.class.to_s, id)
    true
  end

=begin

collect data to index and send to backend

  ticket = Ticket.find(123)
  result = ticket.search_index_update_backend

returns

  result = true # false

=end

  def search_index_update_backend
    # fill up with search data
    attributes = search_index_attribute_lookup
    return true if !attributes

    # update backend
    SearchIndexBackend.add(self.class.to_s, attributes)
    true
  end

  def ignore_search_indexing?(_action)
    false
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do # rubocop:disable Metrics/BlockLength

=begin

serve method to ignore model attributes in search index

class Model < ApplicationModel
  include HasSearchIndexBackend
  search_index_attributes_ignored :password, :image
end

=end

    def search_index_attributes_ignored(*attributes)
      @search_index_attributes_ignored = attributes
    end

=begin

reload search index with full data

  Model.search_index_reload

=end

    def search_index_reload
      tolerance       = 10
      tolerance_count = 0
      batch_size      = 100
      query           = all.order(created_at: :desc)
      total           = query.count
      query.find_in_batches(batch_size: batch_size).with_index do |group, batch|
        group.each do |item|
          next if item.ignore_search_indexing?(:destroy)

          begin
            item.search_index_update_backend
          rescue => e
            logger.error "Unable to send #{item.class}.find(#{item.id}).search_index_update_backend backend: #{e.inspect}"
            tolerance_count += 1
            sleep 15
            raise "Unable to send #{item.class}.find(#{item.id}).search_index_update_backend backend: #{e.inspect}" if tolerance_count == tolerance
          end
        end
        puts "\t#{[(batch + 1) * batch_size, total].min}/#{total}" # rubocop:disable Rails/Output
      end
    end
  end
end
