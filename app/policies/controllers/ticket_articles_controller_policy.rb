class Controllers::TicketArticlesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin')
end
