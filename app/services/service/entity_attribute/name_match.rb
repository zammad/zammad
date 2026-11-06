# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Finds the one record a name stands for, as people and other systems name records: without regard to case and spaces,
#   exactly first, then by a part that fits one record only. A name that fits several records or none raises
#   Service::EntityAttribute::Invalid with the candidates or the valid values; so does a part that fits one record where
#   the caller matches strictly, as a write does for a person or a group. The caller passes only the records the
#   user may use, so that neither the match nor the error names one behind a permission.
class Service::EntityAttribute::NameMatch
  # Zammad's "nobody": the system user owns every ticket without an owner.
  NOBODY_ID = 1

  # The candidates an error carries at most, of a name that fits several records.
  CANDIDATES = 5

  # A record named by its ID, as "ID 12", "#12" or "12".
  ID = %r{\A(?:id\s*)?#?(\d+)\z}i

  Invalid = Service::EntityAttribute::Invalid

  class << self
    # A short list matched in Ruby: by its whole label or its short name, else by a part of its label.
    #
    # @param label [Symbol, Proc] what a record is called
    # @param short [Symbol, Proc, nil] another name a record is known by, such as the last part of a group's name
    # @param strict [Boolean] whether a part that fits one record names it as the candidate instead of standing for it
    def match(value, records, filter:, kind:, label:, short: nil, strict: false)
      name_of = label.to_proc
      exact   = exact_matches(value, records, name_of, short&.to_proc)
      found   = exact.presence || records.select { |record| name_of.call(record).downcase.include?(value.downcase) }
      raise partial(found, filter:, value:, kind:) if strict && exact.empty? && found.one?
      return found.first if found.one?

      raise Invalid.new('ambiguous', reason: :ambiguous, field: filter, value:, kind:, items: found.first(CANDIDATES), count: found.size) if found.many?

      raise Invalid.new('invalid_value', reason: :unknown, field: filter, value:, kind:, items: records)
    end

    # A user by ID, email or login, by the whole name in either order, else by a part of the name or the email.
    #
    # @param scope [ActiveRecord::Relation] the users the value may name
    def user(value, scope, filter:, kind:, strict: false)
      name = value.delete(',').squish.downcase
      id   = value[ID, 1]

      record(
        value, scope,
        filter:, kind:, strict:,
        exact: [
          (scope.where(id:) if id),
          scope.where('LOWER(users.email) = :value OR LOWER(users.login) = :value', value: value.downcase),
          scope.where("LOWER(TRIM(CONCAT(users.firstname, ' ', users.lastname))) = :name OR LOWER(TRIM(CONCAT(users.lastname, ' ', users.firstname))) = :name", name:),
        ],
        part:  "LOWER(CONCAT(users.firstname, ' ', users.lastname)) LIKE :pattern OR LOWER(users.email) LIKE :pattern"
      )
    end

    # An organization by ID or by its whole name, else by a part of the name. A value that reads as an ID is no part of
    #   a name: "ID 12" would otherwise find "Vendor ID 123" where organization 12 is not there.
    #
    # @param scope [ActiveRecord::Relation] the organizations the value may name
    def organization(value, scope, filter:, kind:)
      id = value[ID, 1]

      record(
        value, scope,
        filter:, kind:,
        exact: [
          (scope.where(id:) if id),
          scope.where('LOWER(organizations.name) = ?', value.downcase),
        ],
        part:  ('LOWER(organizations.name) LIKE :pattern' if !id)
      )
    end

    # A record of a list too long to load, matched in the database.
    #
    # @param exact [Array<ActiveRecord::Relation>] the records the value names exactly, the most exact first
    # @param part [String, nil] the SQL condition of a record the value names by a part, with :pattern; none where the
    #   value is matched exactly only
    def record(value, scope, filter:, kind:, exact:, part:, strict: false)
      by_part  = part ? scope.where(part, pattern: like_pattern(value)) : scope.none
      relation = [*exact.compact, by_part].find(&:exists?)
      raise Invalid.new('invalid_value', reason: :no_match, field: filter, value:, kind:, items: (part ? closest_records(value, scope, part) : [])) if relation.nil?

      found = relation.reorder(:id).limit(CANDIDATES + 1).to_a
      raise partial(found, filter:, value:, kind:) if strict && relation.equal?(by_part) && found.one?
      return found.first if found.one?

      raise Invalid.new('ambiguous', reason: :ambiguous, field: filter, value:, kind:, items: found.first(CANDIDATES), count: found.size > CANDIDATES ? relation.count : found.size)
    end

    private

    # The records the value names by the whole label, else by the short name.
    def exact_matches(value, records, name_of, short_of)
      exact = records.select { |record| name_of.call(record).casecmp?(value) }
      return exact if exact.any? || short_of.nil?

      records.select { |record| short_of.call(record).to_s.casecmp?(value) }
    end

    # A client acts on it as on several candidates: it asks its user.
    def partial(found, filter:, value:, kind:)
      Invalid.new('ambiguous', reason: :partial, field: filter, value:, kind:, items: found)
    end

    # Records that hold one of the value's words, for a value that has a typo or names too much.
    def closest_records(value, scope, part)
      words = value.downcase.scan(%r{[[:alnum:]@.\-_]{3,}}).uniq
      return [] if words.empty?

      words.map { |word| scope.where(part, pattern: like_pattern(word)) }.reduce(:or).reorder(:id).limit(CANDIDATES).to_a
    end

    def like_pattern(value)
      "%#{ActiveRecord::Base.sanitize_sql_like(value.downcase)}%"
    end
  end
end
