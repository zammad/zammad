# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormSchema::Field::Number < FormSchema::Field
  attribute :min, :max, :step, :link
end
