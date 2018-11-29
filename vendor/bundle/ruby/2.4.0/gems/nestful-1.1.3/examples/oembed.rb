require 'nestful'
require 'nokogiri'

module OEmbed
  def self.parse(html)
    base = Nokogiri::HTML(html)
    link = base.css('link[type="application/json+oembed"]').first
    return unless link
    Response.new(Nestful.get(link['href']).decoded)
  end

  class Response
    def initialize(attributes = {})
      @attributes = attributes
    end

    def type
      @attributes['type']
    end

    def html
      @attributes['html']
    end

    def title
      @attributes['title']
    end

    def provider_name
      @attributes['provider_name']
    end

    def provider_url
      @attributes['provider_url']
    end

    def width
      @attributes['width']
    end

    def height
      @attributes['height']
    end

    def thumbnail_url
      @attributes['thumbnail_url']
    end

    def thumbnail_width
      @attributes['thumbnail_width']
    end

    def thumbnail_height
      @attributes['thumbnail_height']
    end

    def author_name
      @attributes['author_name']
    end

    def author_url
      @attributes['author_url']
    end

    def version
      @attributes['version']
    end

    def video?
      type == 'video'
    end

    def photo?
      type == 'photo'
    end

    def link?
      type == 'link'
    end

    def rich?
      type == 'rich'
    end
  end
end