# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class FormSchema::Field::Telephone < FormSchema::Field::Text
  def self.type
    'tel'
  end
end
