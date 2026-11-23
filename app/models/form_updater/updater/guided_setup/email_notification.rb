# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::Updater::GuidedSetup::EmailNotification < FormUpdater::Updater
  def self.required_permissions
    %w[admin.wizard]
  end

  def resolve
    result['adapter'] = email_outbound_adapters if meta[:initial]

    super
  end

  private

  def available_adapters
    @available_adapters ||= EmailHelper.available_driver
  end

  def email_outbound_adapters
    {
      initialValue: available_adapters[:outbound].find { |adapter| !adapter[0].to_s.casecmp?('smtp') }&.first.to_s,
      options:      available_adapters[:outbound].each_with_object([]) do |adapter, options|
                      options << {
                        value: adapter[0].to_s,
                        label: adapter[1],
                      }
                    end,
    }
  end
end
