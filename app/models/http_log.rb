# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class HttpLog < ApplicationModel
  store :request
  store :response

  # What caused the request, e.g. the AI provider connection or the webhook that was performed.
  # Optional: not every facility knows an object, and some requests happen before it exists.
  belongs_to :related_object, polymorphic: true, optional: true

  # See https://github.com/zammad/zammad/issues/2100
  before_save :messages_to_utf8

  before_save :filter_sensitive_data, :truncate_long_data

  # Make sure facility is valid if given.
  validates :facility, inclusion: { in: ->(_) { HttpLog.facilities_permission_lookup.keys } }

  # The model behind related_object_type, nil if the type does not resolve to one. Logs outlive
  # their cause, so a removed addon or a renamed class must not take the whole log screen down with
  # it. Resolving alone is not enough, the constant has to be a model too - 'AI::Provider' for
  # example is a plain class and would raise on the association lookup.
  def related_object_class
    klass = related_object_type.presence&.safe_constantize
    return if klass.nil? || !(klass < ApplicationModel)

    klass
  end

  # Human readable name of what caused the request, for the log table. Generic on purpose: any
  # model answering to #name works, nil hides the reference.
  def related_object_label
    return if related_object_class.nil?

    related_object.try(:name)
  end

  # Same labels as #related_object_label, but with one query per referenced model instead of one per
  # row: the log tables poll every 20 seconds, so a per-row lookup adds up quickly.
  #
  # @param logs [Array<HttpLog>] the rows to label
  # @return [Hash{Integer => String}] log id to label, missing for rows without a usable reference
  def self.related_object_labels(logs)
    logs
      .select(&:related_object_class)
      .group_by(&:related_object_class)
      .each_with_object({}) do |(klass, grouped), result|
        # Full records rather than a plucked column, so a model computing #name works here too.
        records = klass.where(id: grouped.map(&:related_object_id)).index_by(&:id)

        grouped.each { |log| result[log.id] = records[log.related_object_id].try(:name) }
      end
  end

  BEARER_REGEX = %r{
    Authorization:\s*Bearer\s+
    (?:\[FILTERED\]|[A-Za-z0-9\-._~+/]+=*(?:\[TRUNCATED\])?)
    (?:\.(?:[A-Za-z0-9\-._~+/]+=*(?:\[TRUNCATED\])?)?)*
  }ix

  BASIC_REGEX       = %r{Authorization:\s*Basic\s+[A-Za-z0-9+/]+=*}i
  TOKEN_REGEX       = %r{(access[_-]?token|api[_-]?key|secret)(["']?\s*[:=]\s*["']?)[A-Za-z0-9\-_~+/=:.]+}ix
  COOKIE_REGEX      = %r{Cookie:\s*((?:[^=;]+=[^;]+;?\s*)+)}i
  QUERY_PARAM_REGEX = %r{([?&](?:access[_-]?token|api[_-]?key|secret)=)[^&]+}i
  BASE64_REGEX      = %r{(data:.*?;base64,)?[A-Za-z0-9+/\r\n]*={0,3}}

=begin

cleanup old http logs

  HttpLog.cleanup

optional you can put the max oldest chat entries as argument

  HttpLog.cleanup(1.month)

=end

  def self.cleanup(diff = 1.month)
    where(created_at: ...diff.ago)
      .delete_all

    true
  end

  # Provide a mapping of facilities to required permissions as a function to be easily extendable in custom devs.
  def self.facilities_permission_lookup
    {
      'AI::Provider'       => 'admin.ai_feedback_logs',
      'check_mk'           => 'admin.integration',
      'clearbit'           => 'admin.integration',
      'cti'                => 'admin.integration',
      'EWS'                => 'admin.integration',
      'GitHub'             => 'admin.integration',
      'GitLab'             => 'admin.integration',
      'idoit'              => 'admin.integration',
      'ldap'               => 'admin.integration',
      'MicrosoftGraph'     => 'admin.channel_microsoft_graph',
      'PGP'                => 'admin.integration',
      'placetel'           => 'admin.integration',
      'S/MIME'             => 'admin.integration',
      'SAML'               => 'admin.security',
      'sipagte.io'         => 'admin.integration', # typo in facility name, keep for backward compatibility
      'sipgate.io'         => 'admin.integration',
      'webhook'            => 'admin.webhook',
      'WhatsApp::Business' => 'admin.channel_whatsapp',
    }
  end

  def self.facility_to_permission(facility)
    return 'admin.*' if facility.blank?

    return facilities_permission_lookup[facility] if facilities_permission_lookup.key?(facility)

    nil
  end

  def self.facilities_by_permission
    @facilities_by_permission ||= facilities_permission_lookup
      .group_by { |_, permission| permission }
      .transform_values { |values| values.map { |facility, _| facility } }
  end

  def self.mask_sensitive_data(text)
    return text if text.blank?

    sanitized = text.dup

    # Mask Bearer and Basic auth headers
    sanitized.gsub!(BEARER_REGEX, 'Authorization: Bearer [FILTERED]') # rubocop:disable Zammad/DetectTranslatableString
    sanitized.gsub!(BASIC_REGEX,  'Authorization: Basic [FILTERED]')  # rubocop:disable Zammad/DetectTranslatableString

    # Mask cookie values but keep names
    sanitized.gsub!(COOKIE_REGEX) do |_match|
      cookies = Regexp.last_match(1).split(';').map { |c| "#{c.strip.split('=')[0]}=[FILTERED]" }
      "Cookie: #{cookies.join('; ')}"
    end

    # Mask sensitive query parameters in URLs
    sanitized.gsub!(QUERY_PARAM_REGEX) do |match|
      match.gsub!(%r{=[^&]+}, '=[FILTERED]')
    end

    # Mask inline tokens/keys
    sanitized.gsub!(TOKEN_REGEX, '\1\2[FILTERED]')

    sanitized
  end

  def self.truncate_long_data(text)
    return text if text.blank?

    truncated = text.dup

    # Truncate `base64` encoded data by shortening long strings.
    #   Include data URI prefix if present to ease the debugging.
    truncated.gsub!(BASE64_REGEX) do |match|
      match.length > 32 ? "#{match.first(29)}...[TRUNCATED]" : match
    end

    truncated
  end

  private

  def messages_to_utf8
    request.transform_values! { |v| v.try(:utf8_encode) || v }
    response.transform_values! { |v| v.try(:utf8_encode) || v }
  end

  def filter_sensitive_data
    request.transform_values! { |v| v.is_a?(String) ? HttpLog.mask_sensitive_data(v) : v }
    response.transform_values! { |v| v.is_a?(String) ? HttpLog.mask_sensitive_data(v) : v }
  end

  def truncate_long_data
    request.transform_values! { |v| v.is_a?(String) ? HttpLog.truncate_long_data(v) : v }
    response.transform_values! { |v| v.is_a?(String) ? HttpLog.truncate_long_data(v) : v }
  end
end
