# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Attributes::Group < CoreWorkflow::Attributes::Base
  def values
    groups.each do |group|
      assets(group)
    end

    if groups.blank?
      ['']
    else
      groups.pluck(:id)
    end
  end

  def groups
    @groups ||= if @attributes.user.permissions?('ticket.agent')
                  if @attributes.payload['screen'] == 'create_middle'
                    @attributes.user.groups_access(%w[create])
                  else
                    @attributes.user.groups_access(%w[create change])
                  end
                else
                  Group.where(active: true)
                end
  end

  def assets(group)
    return if @attributes.assets[Group.to_app_model] && @attributes.assets[Group.to_app_model][group.id]

    @attributes.assets = group.assets(@attributes.assets)
  end
end
