class Sessions::Backend::Collections::EmailAddress < Sessions::Backend::Collections::Base
  model_set 'EmailAddress'
  is_not_role_set 'Customer'
end