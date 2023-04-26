# rubocop:disable all
# Ruby 3.0 brought 128 characters limit to DateTime#parse
# to avoid performance issues if a very long string is given.
# This breaks Mail gem if email date header is malformed.
#
# There is a PR to fix this issue in Mail gem.
# However, it is not merged for months
# and it's not clear when next release may come out.
# https://github.com/mikel/mail/pull/1469
#
# This monkeypatch shall be removed once above PR is merged
# and Mail gem is updated.

module Mail
  class CommonDateField < NamedStructuredField #:nodoc:
    def self.normalize_datetime(string)
      if Utilities.blank?(string)
        datetime = ::DateTime.now
      else
        stripped = string.to_s.gsub(/\(.*?\)/, '').squeeze(' ')
          .slice(0, 128) # this is the custom addition in this monkeypatch
        begin
          datetime = ::DateTime.parse(stripped)
        rescue ArgumentError => e
          raise unless 'invalid date' == e.message
        end
      end

      if datetime
        datetime.strftime('%a, %d %b %Y %H:%M:%S %z')
      else
        string
      end
    end
  end
end
# rubocop:enable all
