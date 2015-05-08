class Sessions::Backend::Collections::EmailAddress < Sessions::Backend::Collections::Base
  model_set 'EmailAddress'
  not_roles_add 'Customer'
end
