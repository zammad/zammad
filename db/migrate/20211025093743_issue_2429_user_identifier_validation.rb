# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue2429UserIdentifierValidation < ActiveRecord::Migration[6.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    %i[firstname lastname email phone].each { |elem| update_single(elem) }
  end

  def update_single(elem)
    attr = ObjectManager::Attribute.for_object(User).find_by(name: elem)

    attr.screens.each do |_, value|
      if value.try(:key?, 'null')
        value['null'] = true
      end

      next if !value.is_a? Hash

      value.each do |_, inner_value|
        if inner_value.try(:key?, 'null')
          inner_value['null'] = true
        end
      end
    end

    attr.save!
  rescue => e
    Rails.logger.error e
  end
end
