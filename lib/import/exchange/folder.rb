# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'mixin/rails_logger'

module Import
  class Exchange
    class Folder
      include ::Mixin::RailsLogger

      DEFAULT_ROOTS = %i[root msgfolderroot publicfoldersroot].freeze

      def initialize(connection)
        @connection = connection
        @lookup_map = {}
      end

      def id_folder_map
        @id_folder_map ||= all.index_by(&:id)

        # duplicate object to avoid errors where keys get
        # added via #get_folder while iterating over
        # the result of this method
        @lookup_map = @id_folder_map.dup
        @id_folder_map
      end

      def find(id)
        @lookup_map[id] ||= @connection.get_folder(id)
      end

      def all
        @all ||= children(*DEFAULT_ROOTS)
      end

      def children(*parents)
        return [] if parents.empty?

        direct_descendants = parents.map { |parent| request_children(parent) }
                                    .flatten.uniq.compact

        direct_descendants | children(*direct_descendants)
      end

      def display_path(folder)
        display_name  = folder.display_name.utf8_encode(fallback: :read_as_sanitized_binary)
        parent_folder = id_folder_map[folder.parent_folder_id]

        return display_name if parent_folder.blank?

        "#{display_path(parent_folder)} -> #{display_name}"
      rescue Viewpoint::EWS::EwsError
        display_name
      end

      private

      def request_children(parent)
        parent = parent.id if parent.respond_to?(:id) # type coercion
        @connection.folders(root: parent)
      rescue Viewpoint::EWS::EwsFolderNotFound => e
        logger.warn("Try to get children folders of: #{parent.inspect}")
        logger.warn(e)
        nil
      end
    end
  end
end
