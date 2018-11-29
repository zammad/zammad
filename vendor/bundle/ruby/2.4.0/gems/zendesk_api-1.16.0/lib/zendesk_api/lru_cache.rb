module ZendeskAPI
  # http://codesnippets.joyent.com/posts/show/12329
  # @private
  class ZendeskAPI::LRUCache
    attr_accessor :size

    def initialize(size = 10)
      @size = size
      @store = {}
      @lru = []
    end

    def write(key, value)
      @store[key] = value
      set_lru(key)
      @store.delete(@lru.pop) if @lru.size > @size
      value
    end

    def read(key)
      set_lru(key)
      @store[key]
    end

    def fetch(key)
      if @store.has_key? key
        read key
      else
        write key, yield
      end
    end

    private

    def set_lru(key)
      @lru.unshift(@lru.delete(key) || key)
    end
  end
end
