class Sessions::Backend::Collections::TicketPriority < Sessions::Backend::Collections::Base
  model_set 'Ticket::Priority'
end
