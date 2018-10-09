module Import
  module OTRS
    class Priority
      include Import::Helper
      include Import::OTRS::Helper

      MAPPING = {
        ChangeTime: :updated_at,
        CreateTime: :created_at,
        CreateBy:   :created_by_id,
        ChangeBy:   :updated_by_id,
        Name:       :name,
        ID:         :id,
        Comment:    :note,
      }.freeze

      def initialize(priority)
        import(priority)
      end

      private

      def import(priority)
        create_or_update(map(priority))
      end

      def create_or_update(priority)
        return if updated?(priority)

        create(priority)
      end

      def updated?(priority)
        @local_priority = ::Ticket::Priority.find_by(id: priority[:id])
        return false if !@local_priority

        log "update Ticket::Priority.find_by(id: #{priority[:id]})"
        @local_priority.update!(priority)
        true
      end

      def create(priority)
        log "add Ticket::Priority.find_by(id: #{priority[:id]})"
        @local_priority    = ::Ticket::Priority.new(priority)
        @local_priority.id = priority[:id]
        @local_priority.save
        reset_primary_key_sequence('ticket_priorities')
      end

      def map(priority)
        {
          created_by_id: 1,
          updated_by_id: 1,
          active:        active?(priority),
        }
          .merge(from_mapping(priority))
      end
    end
  end
end
