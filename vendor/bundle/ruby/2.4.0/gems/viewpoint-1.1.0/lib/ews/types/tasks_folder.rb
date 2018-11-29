module Viewpoint::EWS::Types
  class TasksFolder
    include Viewpoint::EWS
    include Viewpoint::EWS::Types
    include Viewpoint::EWS::Types::GenericFolder

    # Creates a new task
    # @param attributes [Hash] Parameters of the task. Some example attributes are listed below.
    # @option attributes :subject [String]
    # @option attributes :start_date [Time]
    # @option attributes :due_date [Time]
    # @option attributes :reminder_due_by [Time]
    # @option attributes :reminder_is_set [Boolean]
    # @return [Task]
    # @see Template::Task
    def create_item(attributes)
      template = Viewpoint::EWS::Template::Task.new attributes
      template.saved_item_folder_id = {id: self.id, change_key: self.change_key}
      rm = ews.create_item(template.to_ews_create).response_messages.first
      if rm && rm.success?
        Task.new ews, rm.items.first[:task][:elems].first
      else
        raise EwsCreateItemError, "Could not create item in folder. #{rm.code}: #{rm.message_text}" unless rm
      end
    end
  end
end
