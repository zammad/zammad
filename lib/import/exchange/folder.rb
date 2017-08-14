require 'mixin/rails_logger'

module Import
  class Exchange
    class Folder
      include ::Mixin::RailsLogger

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
        # request folders only if neccessary and store the result
        @all ||= children(%i(root msgfolderroot publicfoldersroot))
      end

      def children(parent_identifiers)
        parent_identifiers.each_with_object([]) do |parent_identifier, result|

          child_folders = request_children(parent_identifier)

          next if child_folders.blank?

          child_folder_ids = child_folders.collect(&:id)
          child_folders   += children(child_folder_ids)

          result.concat(child_folders)
        end
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

      def request_children(parent_identifier)
        @connection.folders(root: parent_identifier)
      rescue Viewpoint::EWS::EwsFolderNotFound => e
        logger.warn(e)
        nil
      end
    end
  end
end
