# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormSchema::Field::Textarea < FormSchema::Field
  attribute :placeholder, :cols, :rows, :minlength, :maxlength
end
