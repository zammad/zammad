# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The hash of a tool's result as an MCP client gets it: as JSON, with the link of every object that has a page of its
#   own, and every text labelled where it copies one of the tools' own forms, as the tool's text is. Clients hand either
#   this hash or the text to their model, so both have to be safe for one.
class Service::MCPServer::StructuredContent
  attr_reader :content, :links

  private attr_reader :urls

  # @param hash [Hash] the content of a tool's result
  def self.of(hash)
    new(hash)
  end

  def initialize(hash)
    json     = hash.as_json
    objects  = objects_in(json, nil)
    @urls    = Service::AI::Tool::ObjectLink.urls(objects.map(&:first))
    @links   = objects.each_with_object({}) { |(row, key), links| links[urls[row]] ||= Service::AI::Tool::ObjectLink.label(row, key:) if urls[row] }
    @content = walk(json)
  end

  # The links for the tool's text, which some clients hand their model alone.
  #
  # @return [String, nil]
  def links_text
    return if links.empty?

    ['Links:', *links.map { |url, label| "#{label}: #{url}" }].join("\n")
  end

  private

  def walk(node)
    case node
    when Hash
      hash = node.transform_values { |value| walk(value) }
      urls[node] ? hash.merge('url' => urls[node]) : hash
    when Array
      node.map { |item| walk(item) }
    when String
      AI::PromptText.labelled_text(node)
    else
      node
    end
  end

  # Each object of the hash with the name it stands under, such as "customer"; an object before what it names, so that
  #   the text lists it first.
  #
  # @return [Array(Hash, String)]
  def objects_in(node, key)
    case node
    when Hash
      own = node['id'].is_a?(Integer) && node['type'].is_a?(String) ? [[node, key]] : []
      own + node.flat_map { |name, value| objects_in(value, name) }
    when Array
      node.flat_map { |item| objects_in(item, nil) }
    else
      []
    end
  end
end
