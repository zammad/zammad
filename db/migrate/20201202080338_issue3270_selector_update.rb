# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue3270SelectorUpdate < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Overview.find_each do |overview|
      fix_selector(overview)
    end
    Trigger.find_each do |trigger|
      fix_selector(trigger)
    end
    Job.find_each do |job|
      fix_selector(job)
    end
  end

  def fix_selector(object)
    fixed = false
    object.condition.each do |_attribute, attribute_condition|
      next if attribute_condition['operator'] != 'within next (relative)' && attribute_condition['operator'] != 'within last (relative)'

      attribute_condition['operator'] = if attribute_condition['operator'] == 'within next (relative)'
                                          'till (relative)'
                                        else
                                          'from (relative)'
                                        end

      fixed = true
    end

    return if !fixed

    save(object)
  end

  def save(object)
    object.save
  rescue => e
    Rails.logger.error "Migration Issue3270SelectorUpdate failed: #{object.class} - #{object.id} - #{e.inspect}."
  end
end
