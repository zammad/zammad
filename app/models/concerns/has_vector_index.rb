# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module HasVectorIndex
  extend ActiveSupport::Concern

  # TODO: Currently this is in a similar way implemented like the search index handling. But for the future we need maybe to go in a different direction.
  # The stuff is more specific and we also have not only models which are related to that. Better way would maybe to create an service layer which handles the stuff
  # and in the model context we only executing some services which can then handle the needed logic.
  # For example one thing which needs to be handled in the future is the metadata handling without new embedding generation.

  included do
    # TODO: We are disabling any automatic handling until we have a real feature which is using the vector index.
    # after_commit  :vector_index_update_later, if: :persisted?
    # after_destroy :vector_index_destroy
  end

  def vector_index_update_later
    return true if !Service::AI::VectorDB::Available.new(ping: false).execute

    return true if previous_changes.blank?

    return true if respond_to?(:vector_indexing_for_record?) && !vector_indexing_for_record?

    VectorIndexJob.perform_later(self.class.to_s, id)

    true
  end

  def vector_index_update
    data = vector_index_data

    object_id = data[:object_id] || id
    object_name = data[:object_name] || self.class.to_s

    Service::AI::VectorDB::Item::Upsert.new(object_name:, object_id:, content: data[:content], metadata: data[:metadata]).execute
  end

  def vector_index_destroy
    # TODO: as an addition to destory, we need also something for update, when it's no longer "visible" or also category changes...
    return true if !Service::AI::VectorDB::Available.new(ping: false).execute

    Service::AI::VectorDB::Item::Destroy.new(object_name: self.class.to_s, object_id: id).execute
  end

  class_methods do
    def vector_index_reload(silent: false, worker: 0)
      return if !Service::AI::VectorDB::Available.new.execute

      # TODO: Currently this function is hardcoded for knowledge base answer translations.
      # Because we want to move this stuff to a service layer, it make currently no sense to find a more generic solution here.
      relevant_categorie_ids = ENV.fetch('VECTOR_INDEX_FOR_KNOWLEDGE_BASE_CATEGORY_IDS', nil)

      scope = if relevant_categorie_ids.blank?
                KnowledgeBase::Answer
              else
                KnowledgeBase::Answer.where(category: relevant_categorie_ids.split(','))
              end

      scope.internal.include_contents.in_batches do |batch|
        translations = batch.flat_map(&:translations)

        Parallel.map(translations, { in_processes: worker }) do |record|
          begin
            record.vector_index_update
          rescue => e
            raise "Unable to update vector index for #{record.class}.find(#{record.id}): #{e.inspect}"
          end
        end
      end
    end
  end

  private

  def vector_index_data
    raise 'not implemented'
  end
end
