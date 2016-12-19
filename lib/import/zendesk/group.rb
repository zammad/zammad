module Import
  module Zendesk
    class Group
      include Import::Helper

      attr_reader :zendesk_id, :id

      def initialize(group)
        local_group = ::Group.create_if_not_exists(
          name:          group.name,
          active:        !group.deleted,
          updated_by_id: 1,
          created_by_id: 1
        )

        @zendesk_id = group.id
        @id         = local_group.id
      end
    end
  end
end
