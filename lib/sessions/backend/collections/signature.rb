class Sessions::Backend::Collections::Signature < Sessions::Backend::Collections::Base
  model_set 'Signature'
  add_if_permission 'ticket.agent'
end
