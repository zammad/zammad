# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::GuidedSetup::EmailOutbound < FormUpdater::Updater
  def authorized?
    current_user.permissions?('admin.wizard')
  end

  def resolve
    if meta[:initial]
      result['adapter'] = email_outbound_adapters
    end

    super
  end

  private

  def available_adapters
    @available_adapters ||= EmailHelper.available_driver
  end

  def email_outbound_adapters
    {
      initialValue: available_adapters[:outbound].find { |adapter| adapter[0].to_s.casecmp?('smtp') }&.first.to_s,
      options:      available_adapters[:outbound].each_with_object([]) do |adapter, options|
                      options << {
                        value: adapter[0].to_s,
                        label: adapter[1],
                      }
                    end,
    }
  end
end
