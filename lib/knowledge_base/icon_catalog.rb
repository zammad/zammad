# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase
  # Searchable index over one icon font catalog in public/assets/icon-fonts, backing
  #   the category icon picker. The catalogs are build-time static assets, so each one
  #   is parsed exactly once per process — see .for.
  class IconCatalog
    CATALOG_DIRECTORY = Rails.public_path.join('assets/icon-fonts')

    DEFAULT_LIMIT = 50

    # 'Give me everything', same convention as AutocompleteSearch::Tag: surrounding
    #   asterisks are stripped, and a query that is empty afterwards selects the whole
    #   set. Such a result is deliberately not limited — the picker renders it as a
    #   browsable grid.
    WILDCARD = '*'.freeze

    # Everything the picker needs per icon: the codepoint it stores (also the sprite
    #   symbol id), the name it displays, and the pre-normalized strings it matches
    #   against. Normalizing them once at load time keeps a search from rebuilding
    #   them for every icon it walks.
    Icon = Data.define(:unicode, :name, :searchable)

    @catalogs = Concurrent::Map.new

    class << self
      def for(icon_set)
        raise ArgumentError, "Unknown knowledge base iconset #{icon_set.inspect}" if ICONSETS.exclude?(icon_set)

        @catalogs.compute_if_absent(icon_set) { new(icon_set) }
      end

      # Only relevant for tests, which must not observe a catalog another example
      #   already memoized.
      def reset!
        @catalogs.clear
      end
    end

    attr_reader :icon_set, :icons

    # Parsed eagerly rather than memoized, so that .for — which constructs inside
    #   Concurrent::Map#compute_if_absent — is what serializes the parsing.
    def initialize(icon_set)
      @icon_set = icon_set
      @icons = parse_catalog
    end

    # A blank query means the picker was just opened, so it gets the same full set as
    #   the wildcard rather than nothing to display.
    def search(query, limit: nil)
      needles = self.class.tokenize(query)

      return icons if needles.empty?

      icons
        .lazy
        .select { matches?(it, needles) }
        .first(sanitized_limit(limit))
    end

    # Delimiters carry no meaning for the user typing a query, so '3d_rotation',
    #   'user-female' and 'ion-alert' are matched by '3d rotation', 'user female' and
    #   'ion alert' alike.
    def self.normalize(value)
      value
        .to_s
        .downcase
        .gsub(%r{[-_\s]+}, ' ')
        .strip
    end

    # Terms are matched individually, so the user does not have to know in which order
    #   a set spells its names.
    def self.tokenize(query)
      normalize(query.to_s.delete_prefix(WILDCARD).delete_suffix(WILDCARD)).split
    end

    private

    # Every term has to be found, but neither in the order typed nor within the same
    #   value: 'wifi android' finds 'ion-android-wifi', 'folder outlined' finds both
    #   'Folder Outlined' and 'Folder Open Outlined', and 'glass martini' finds the
    #   icon named 'Glass' through its 'martini' keyword.
    def matches?(icon, needles)
      needles.all? { |needle| icon.searchable.any? { |value| value.include?(needle) } }
    end

    # A negative limit would make Enumerable#first raise, and the argument reaches us
    #   straight from the API as a plain Int.
    def sanitized_limit(limit)
      [limit || DEFAULT_LIMIT, 0].max
    end

    # Some catalogs list the same codepoint under several names (anticon's
    #   'right-circle' / 'circle-right' / 'caret-circle-right'). Since the codepoint is
    #   the value the picker stores, those have to collapse into a single entry —
    #   otherwise the grid shows the same icon repeatedly under ambiguous values. The
    #   first name wins as the label, the alias names stay searchable.
    def parse_catalog
      JSON
        .parse(CATALOG_DIRECTORY.join("#{icon_set}.json").read)
        .fetch('icons')
        .group_by { it['unicode'] }
        .map { |unicode, entries| coerce_to_icon(unicode, entries) }
        .freeze
    end

    def coerce_to_icon(unicode, entries)
      Icon.new(
        unicode:    unicode,
        name:       entries.first['name'].downcase,
        searchable: searchable_values(unicode, entries),
      )
    end

    # The alias ('id') matches as well, and so does the codepoint, so a stored icon can
    #   be looked up by its value alone. Only FontAwesome ships 'filter' keywords; most
    #   sets have an 'id' identical to the name, hence the #uniq.
    def searchable_values(unicode, entries)
      entries
        .flat_map { [it['name'], it['id'], *it['filter']] }
        .push(unicode)
        .compact
        .map { self.class.normalize(it) }
        .uniq
        .freeze
    end
  end
end
