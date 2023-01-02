# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module HasSearchIndexBackend
  extend ActiveSupport::Concern

  included do
    after_commit  :search_index_update, if: :persisted?
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

    return true if previous_changes.blank?

    SearchIndexJob.perform_later(self.class.to_s, id)
    SearchIndexAssociationsJob.perform_later(self.class.to_s, id)
    true
  end

  def search_index_indexable
    Models.indexable.reject { |local_class| local_class == self.class }
  end

  def search_index_indexable_attributes(index_class)
    result = []
    index_class.new.attributes.each do |key, _value|
      attribute_name = key.to_s
      next if attribute_name.blank?

      # due to performance reasons, we only want to process some attributes for specific classes (e.g. tickets)
      next if !index_class.search_index_attribute_relevant?(attribute_name)

      attribute_ref_name = index_class.search_index_attribute_ref_name(attribute_name)
      next if attribute_ref_name.blank?

      association = index_class.reflect_on_association(attribute_ref_name)
      next if association.blank?
      next if association.options[:polymorphic]

      attribute_class = association.klass
      next if attribute_class.blank?
      next if attribute_class != self.class

      result << {
        name:     attribute_name,
        ref_name: attribute_ref_name,
      }
    end
    result
  end

  def search_index_update_delta(index_class:, value:, attribute:)
    data = {
      attribute[:ref_name] => value,
    }
    where = {
      attribute[:name] => id
    }
    SearchIndexBackend.update_by_query(index_class.to_s, data, where)
  end

=begin

update search index, if configured - will be executed automatically

  model = Organizations.find(123)
  result = model.search_index_update_associations

returns

  # Updates asscociation data for users and tickets of the organization in this example
  result = true

=end

  def search_index_update_associations

    # start background job to transfer data to search index
    return true if !SearchIndexBackend.enabled?

    new_search_index_value = search_index_attribute_lookup(include_references: false)
    return if new_search_index_value.blank?

    search_index_indexable.each do |index_class|
      search_index_indexable_attributes(index_class).each do |attribute|
        search_index_update_delta(index_class: index_class, value: new_search_index_value, attribute: attribute)
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

    def search_index_attributes_relevant(*attributes)
      @search_index_attributes_relevant = attributes
    end

=begin

reload search index with full data

  Model.search_index_reload

=end

    def search_index_reload(silent: false)
      tolerance       = 10
      tolerance_count = 0
      query           = order(created_at: :desc)
      total           = query.count
      record_count    = 0
      batch_size      = 100
      query.as_batches(size: batch_size) do |record|
        if !record.ignore_search_indexing?(:destroy)
          begin
            record.search_index_update_backend
          rescue => e
            logger.error "Unable to send #{record.class}.find(#{record.id}).search_index_update_backend backend: #{e.inspect}"
            tolerance_count += 1
            sleep 15
            raise "Unable to send #{record.class}.find(#{record.id}).search_index_update_backend backend: #{e.inspect}" if tolerance_count == tolerance
          end
        end

        next if silent

        record_count += 1
        if (record_count % batch_size).zero? || record_count == total
          print "\r    #{record_count}/#{total}" # rubocop:disable Rails/Output
        end
      end
    end
  end
end
