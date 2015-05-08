class Sessions::Backend::Collections::Signature < Sessions::Backend::Collections::Base
  model_set 'Signature'
  not_roles_add 'Customer'
end
