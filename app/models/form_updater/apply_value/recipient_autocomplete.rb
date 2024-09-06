# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::RecipientAutocomplete < FormUpdater::ApplyValue::Base

  def can_handle_field?(field:, field_attribute:)
    %w[to cc].include?(field)
  end

  def map_value(field:, config:)
    metadata = config['value']
      .split(',')
      .each_with_object({ value: [], options: [] }) do |elem, memo|
        (value, options) = user_or_email(elem.strip)

        memo[:value].push value
        memo[:options].push options
      end

    result[field].merge!(metadata)
  end

  private

  def user_or_email(recipient)
    user = find_user_by_recipient(recipient)

    if !user
      return [
        recipient,
        {
          value: recipient,
          label: recipient,
        }
      ]
    end

    [
      user.email,
      {
        value:   user.email,
        label:   user.email,
        heading: user.fullname,
      }
    ]
  end

  def find_user_by_recipient(recipient)
    ::User.search(
      query:        recipient,
      limit:        1,
      current_user: context[:current_user],
    ).first
  end
end
