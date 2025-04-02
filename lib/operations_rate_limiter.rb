# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class OperationsRateLimiter
  class ThrottleLimitExceeded < Exceptions::Forbidden; end

  def initialize(limit:, period:, operation:)
    @limit = limit
    @period = period
    @operation = operation
  end

  def ensure_within_limits!(by_ip:, by_identifier: nil)
    ensure_within_identifier_limit(by_identifier) if by_identifier.present?
    ensure_within_ip_limit(by_ip)
  end

  private

  def ensure_within_identifier_limit(value)
    value       = value.downcase.gsub(%r{\s+}, '')
    fingerprint = Digest::MD5.hexdigest(value)

    ensure_within :identifier, fingerprint
  end

  def ensure_within_ip_limit(ip_addr)
    ensure_within :ip, ip_addr
  end

  def ensure_within(key, value)
    period_identifier, lapsed_time = Time.now.to_i.divmod(@period.to_i)

    cache_key  = cache_key(key, value, period_identifier)
    expires_in = cache_expires_in(lapsed_time)
    value      = increment(cache_key, expires_in)

    return true if value <= @limit

    raise ThrottleLimitExceeded, __('The request limit for this operation was exceeded.')
  end

  def cache_key(key, value, period_identifier)
    [
      self.class.name,
      @operation,
      key,
      value,
      period_identifier
    ].join('::')
  end

  def cache_expires_in(lapsed_time)
    @period.to_i - lapsed_time + 1.minute # make sure there's no race condition with cache expiring during processing
  end

  def increment(cache_key, expires_in)
    # Rails.cache.increment has surpising behaviours/bugs in Rails 7.0, so we don't use it.
    # This may be working better in 7.1 and could be cleaned up after upgrading to Rails 7.1
    #
    # https://github.com/rails/rails/commit/f48bf3975f62e875a1cf4264b18ce3735915684d
    new_value = (Rails.cache.read(cache_key) || 0) + 1
    new_value.tap do
      Rails.cache.write(cache_key, new_value, expires_in:)
    end
  end
end
