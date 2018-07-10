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
        @id_folder_map ||= all.collect do |folder|
          [folder.id, folder]
        end.to_h

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

        direct_descendants = parents.map(&method(:request_children))
                                    .flatten.uniq.compact

        direct_descendants | children(*direct_descendants)
      end

      def display_path(folder)
        display_name = folder.display_name
        return display_name if !folder.parent_folder_id

        parent_folder = find(folder.parent_folder_id)
        return display_name if !parent_folder

        parent_folder = id_folder_map[folder.parent_folder_id]
        return display_name if !parent_folder

        # recursive
        parent_folder_path = display_path(parent_folder)

        "#{parent_folder_path} -> #{display_name}"
      rescue Viewpoint::EWS::EwsError
        folder.display_name
      end

      private

      def request_children(parent)
        parent = parent.id if parent.respond_to?(:id) # type coercion
        @connection.folders(root: parent)
      rescue Viewpoint::EWS::EwsFolderNotFound => e
        logger.warn(e) && return
      end
    end
  end
end
