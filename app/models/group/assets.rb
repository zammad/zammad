# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

module Group::Assets

=begin

get all assets / related models for this group

  group = Group.find(123)
  result = group.assets( assets_if_exists )

returns

  result = {
    :groups => {
      123  => group_model_123,
      1234 => group_model_1234,
    }
  }

=end

  def assets (data)

    if !data[ Group.to_app_model ]
      data[ Group.to_app_model ] = {}
    end
    if !data[ Group.to_app_model ][ self.id ]
      data[ Group.to_app_model ][ self.id ] = self.attributes
    end
    data
  end

end