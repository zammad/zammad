class Controllers::MentionsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('ticket.agent')
end
