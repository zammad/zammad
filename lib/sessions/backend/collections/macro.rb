class Sessions::Backend::Collections::Macors < Sessions::Backend::Collections::Base
  model_set 'Macro'
  add_if_not_role 'Customer'
end
