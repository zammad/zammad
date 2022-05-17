# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormSchema::Field::Select < FormSchema::Field
  attribute :placeholder, :options, :multiple, :link
end
