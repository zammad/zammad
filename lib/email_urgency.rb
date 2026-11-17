# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A present Importance header wins even with an unknown value ([MS-OXCMAIL] 2.2.3.2.5).
# X-Priority and X-MSMail-Priority are vendor conventions without an RFC.
module EmailUrgency
  HIGH   = 'high'.freeze
  NORMAL = 'normal'.freeze
  LOW    = 'low'.freeze

  # How each level is stated by the headers that have their own words for it.
  # Importance and X-MSMail-Priority use the level's name itself.
  LEVELS = {
    HIGH   => { priority: 'urgent',     x_priority: %w[1 2] },
    NORMAL => { priority: NORMAL,       x_priority: %w[3] },
    LOW    => { priority: 'non-urgent', x_priority: %w[4 5] },
  }.freeze

  VALUES = LEVELS.keys.freeze

=begin

read the urgency a sender attached to an email

  level = EmailUrgency.parse(mail)

mail is a hash of the email's header fields, keyed by their lower case names.

returns

  'high' / 'normal' / 'low', or nil if the sender stated no urgency

=end

  def self.parse(mail)
    return from_importance(mail) if normalize(mail['importance'])

    from_priority(mail) ||
      from_x_priority(mail) ||
      from_x_msmail_priority(mail)
  end

  def self.from_importance(mail)
    level(normalize(mail['importance']))
  end
  private_class_method :from_importance

  def self.from_priority(mail)
    value = normalize(mail['priority'])
    level_where { |stated| stated[:priority] == value }
  end
  private_class_method :from_priority

  # Clients write anything from "1" over "1 (Highest)" to "Urgent"; only the
  # leading digit of the 1..5 scale is defined by the convention.
  def self.from_x_priority(mail)
    digit = normalize(mail['x-priority'])&.slice(%r{\A[1-5](?!\d)})
    level_where { |stated| stated[:x_priority].include?(digit) }
  end
  private_class_method :from_x_priority

  def self.from_x_msmail_priority(mail)
    level(normalize(mail['x-msmail-priority']))
  end
  private_class_method :from_x_msmail_priority

  def self.level(value)
    value if VALUES.include?(value)
  end
  private_class_method :level

  def self.level_where(&)
    LEVELS.find { |_level, stated| yield(stated) }&.first
  end
  private_class_method :level_where

  def self.normalize(value)
    return if value.blank?

    value.to_s.strip.downcase.presence
  end
  private_class_method :normalize
end
