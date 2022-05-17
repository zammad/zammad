# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormSchema::Field::Text < FormSchema::Field
  attribute :placeholder, :minlength, :maxlength, :link
end
