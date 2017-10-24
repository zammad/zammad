# Observer for ticket creation that will assign random

class Observer::Ticket::AssignRandomAgent < ActiveRecord::Observer
  observe 'ticket'

  def after_create(record)
    # assign the agent based on the group id of ticket
    assign_agent(record)
  end

  def assign_agent(record)
    Rails.logger.info '----Process ticket auto assignment based on the group of ticket-----'
    ticket = Ticket.lookup(id: record.id)

    if ticket.auto_assign == true
      Rails.logger.info '----Autoassignment flag is true-----'
      if ticket.owner_id == 1
        result = User.get_user_ids(
          role_id:      2,
          group_id:     ticket.group_id
        )
        # any random pick logic.
        ticket.owner_id = result.ids.sample
        ticket.save
        Rails.logger.info '----Autoassignment of ticket compeleted-----'
      else
        Rails.logger.info '----Autoassignment of ticket not required as ticket aleady has an owner-----'
      end
    else
      Rails.logger.info '----Autoassignment flag is false-----'
    end
  end
end
