# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    class Queue
      include Import::Helper
      include Import::OTRS::Helper

      MAPPING = {
        ChangeTime: :updated_at,
        CreateTime: :created_at,
        CreateBy:   :created_by_id,
        ChangeBy:   :updated_by_id,
        Name:       :name,
        QueueID:    :id,
        Comment:    :note,
      }.freeze

      def initialize(queue)
        import(queue)
      end

      private

      def import(queue)
        create_or_update(map(queue))
      end

      def create_or_update(queue)
        return if updated?(queue)

        create(queue)
      end

      def updated?(queue)
        @local_queue = Group.find_by(id: queue[:id])
        return false if !@local_queue

        log "update Group.find_by(id: #{queue[:id]})"
        @local_queue.update!(queue)
        true
      end

      def create(queue)
        log "add Group.find_by(id: #{queue[:id]})"
        @local_queue    = Group.new(queue)
        @local_queue.id = queue[:id]
        @local_queue.save
        reset_primary_key_sequence('groups')
      end

      def map(queue)
        {
          created_by_id: 1,
          updated_by_id: 1,
          active:        active?(queue),
        }
          .merge(from_mapping(queue))
      end
    end
  end
end
