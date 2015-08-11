class Sessions::Backend::Collections::Signature < Sessions::Backend::Collections::Base
  model_set 'Signature'
  add_if_not_role 'Customer'
end
