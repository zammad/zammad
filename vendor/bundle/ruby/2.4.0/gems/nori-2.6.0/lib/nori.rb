require "nori/version"
require "nori/core_ext"
require "nori/xml_utility_node"

class Nori

  def self.hash_key(name, options = {})
    name = name.tr("-", "_") if options[:convert_dashes_to_underscores]
    name = name.split(":").last if options[:strip_namespaces]
    name = options[:convert_tags_to].call(name) if options[:convert_tags_to].respond_to? :call
    name
  end

  PARSERS = { :rexml => "REXML", :nokogiri => "Nokogiri" }

  def initialize(options = {})
    defaults = {
      :strip_namespaces              => false,
      :delete_namespace_attributes   => false,
      :convert_tags_to               => nil,
      :convert_attributes_to         => nil,
      :empty_tag_value               => nil,
      :advanced_typecasting          => true,
      :convert_dashes_to_underscores => true,
      :parser                        => :nokogiri
    }

    validate_options! defaults.keys, options.keys
    @options = defaults.merge(options)
  end

  def find(hash, *path)
    return hash if path.empty?

    key = path.shift
    key = self.class.hash_key(key, @options)

    value = find_value(hash, key)
    find(value, *path) if value
  end

  def parse(xml)
    cleaned_xml = xml.strip
    return {} if cleaned_xml.empty?

    parser = load_parser @options[:parser]
    parser.parse(cleaned_xml, @options)
  end

  private
  def load_parser(parser)
    require "nori/parser/#{parser}"
    Parser.const_get PARSERS[parser]
  end

  # Expects a +block+ which receives a tag to convert.
  # Accepts +nil+ for a reset to the default behavior of not converting tags.
  def convert_tags_to(reset = nil, &block)
    @convert_tag = reset || block
  end

  def validate_options!(available_options, options)
    spurious_options = options - available_options

    unless spurious_options.empty?
      raise ArgumentError, "Spurious options: #{spurious_options.inspect}\n" \
                           "Available options are: #{available_options.inspect}"
    end
  end

  def find_value(hash, key)
    hash.each do |k, v|
      key_without_namespace = k.to_s.split(':').last
      return v if key_without_namespace == key.to_s
    end

    nil
  end

end
