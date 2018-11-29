module AutoprefixerRails
  # Container of prefixed CSS and source map with changes
  class Result
    # Prefixed CSS after Autoprefixer
    attr_reader :css

    # Source map of changes
    attr_reader :map

    # Warnings from Autoprefixer
    attr_reader :warnings

    def initialize(css, map, warnings)
      @warnings = warnings
      @css      = css
      @map      = map
    end

    # Stringify prefixed CSS
    def to_s
      @css
    end
  end
end
