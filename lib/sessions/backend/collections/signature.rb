class Sessions::Backend::Collections::Signature < Sessions::Backend::Collections::Base
  model_set 'Signature'
  is_not_role_set 'Customer'
end