class Sessions::Backend::Collections::EmailAddress < Sessions::Backend::Collections::Base
  model_set 'EmailAddress'
  add_if_permission 'ticket.agent'
end
