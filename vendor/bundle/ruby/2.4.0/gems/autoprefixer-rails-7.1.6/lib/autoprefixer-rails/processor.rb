require 'pathname'
require 'execjs'
require 'json'

IS_SECTION = /^\s*\[(.+)\]\s*$/

module AutoprefixerRails
  # Ruby to JS wrapper for Autoprefixer processor instance
  class Processor

    def initialize(params = { })
      @params = params || { }
    end

    # Process `css` and return result.
    #
    # Options can be:
    # * `from` with input CSS file name. Will be used in error messages.
    # * `to` with output CSS file name.
    # * `map` with true to generate new source map or with previous map.
    def process(css, opts = { })
      opts = convert_options(opts)

      apply_wrapper =
        "(function(opts, pluginOpts) {" +
        "return eval(process.apply(this, opts, pluginOpts));" +
        "})"

      pluginOpts = params_with_browsers(opts[:from]).merge(opts)
      processOpts = {
        from: pluginOpts.delete(:from),
        to:   pluginOpts.delete(:to),
        map:  pluginOpts.delete(:map)
      }

      result = runtime.call(apply_wrapper, [css, processOpts, pluginOpts])

      Result.new(result['css'], result['map'], result['warnings'])
    end

    # Return, which browsers and prefixes will be used
    def info
      runtime.eval("autoprefixer(#{ js_params }).info()")
    end

    # Parse Browserslist config
    def parse_config(config)
      sections = { 'defaults' => [] }
      current  = 'defaults'
      config.gsub(/#[^\n]*/, '')
            .split(/\n/)
            .map(&:strip)
            .reject(&:empty?)
            .each do |line|
              if line =~ IS_SECTION
                current = line.match(IS_SECTION)[1].strip
                sections[current] ||= []
              else
                sections[current] << line
              end
            end
      sections
    end

    private

    def params_with_browsers(from = nil)
      unless from
        if defined? Rails and Rails.respond_to?(:root) and Rails.root
          from = Rails.root.join('app/assets/stylesheets').to_s
        else
          from = '.'
        end
      end

      params = @params
      if not params.has_key?(:browsers) and from
        file = find_config(from)
        if file
          env    = params[:env].to_s || 'development'
          config = parse_config(file)
          params = params.dup
          if config[env]
            params[:browsers] = config[env]
          else
            params[:browsers] = config['defaults']
          end
        end
      end

      params
    end

    # Convert params to JS string and add browsers from Browserslist config
    def js_params
      '{ ' +
        params_with_browsers.map { |k, v| "#{k}: #{v.inspect}"}.join(', ') +
      ' }'
    end

    # Convert ruby_options to jsOptions
    def convert_options(opts)
      converted = { }

      opts.each_pair do |name, value|
        if name =~ /_/
          name = name.to_s.gsub(/_\w/) { |i| i.gsub('_', '').upcase }.to_sym
        end
        value = convert_options(value) if value.is_a? Hash
        converted[name] = value
      end

      converted
    end

    # Try to find Browserslist config
    def find_config(file)
      path = Pathname(file).expand_path

      while path.parent != path
        config1 = path.join('browserslist')
        return config1.read if config1.exist? and not config1.directory?

        config2 = path.join('.browserslistrc')
        return config2.read if config2.exist? and not config1.directory?

        path = path.parent
      end

      nil
    end

    # Lazy load for JS library
    def runtime
      @runtime ||= begin
        if ExecJS.eval('typeof(Array.prototype.map)') != 'function'
          raise "Current ExecJS runtime does't support ES5. " +
                "Please install node.js."
        end

        ExecJS.compile(build_js)
      end
    end

    # Cache autoprefixer.js content
    def read_js
      @@js ||= begin
        root = Pathname(File.dirname(__FILE__))
        path = root.join("../../vendor/autoprefixer.js")
        path.read.gsub(/Object.setPrototypeOf\(chalk[^)]+\)/, '')
      end
    end

    def polyfills
      <<-JS
        if (typeof Uint8Array === "undefined")
          global.Uint8Array = Array;
        if (typeof ArrayBuffer === "undefined")
          global.ArrayBuffer = Array;
        if (typeof Set === "undefined") {
          global.Set = function (values) { this.values = values }
          global.Set.prototype = {
            has: function (i) { return this.values.indexOf(i) !== -1 }
          }
        }
        if (typeof Map === "undefined") {
          global.Map = function () { this.data = { } }
          global.Map.prototype = {
            set: function (k, v) { this.data[k] = v },
            get: function (k) { return this.data[k] },
            has: function (k) {
              return Object.keys(this.data).indexOf(k) !== -1
            },
          }
        }
          Math.log2 = Math.log2 ||
          function(x) { return Math.log(x) * Math.LOG2E; };
        Math.sign = Math.sign ||
          function(x) {
            x = +x;
            if (x === 0 || isNaN(x)) return Number(x);
            return x > 0 ? 1 : -1;
          };
        Array.prototype.fill = Array.prototype.fill ||
          function(value) {
            var O = Object(this);
            var len = O.length >>> 0;
            var start = arguments[1];
            var relativeStart = start >> 0;
            var k = relativeStart < 0 ?
              Math.max(len + relativeStart, 0) :
              Math.min(relativeStart, len);
            var end = arguments[2];
            var relativeEnd = end === undefined ?
              len : end >> 0;
            var final = relativeEnd < 0 ?
              Math.max(len + relativeEnd, 0) :
              Math.min(relativeEnd, len);
            while (k < final) {
              O[k] = value;
              k++;
            }
            return O;
          };
        if (!Object.assign) {
          Object.assign = function(target, firstSource) {
            var to = Object(target);
            for (var i = 1; i < arguments.length; i++) {
              var nextSource = arguments[i];
              if (nextSource === undefined || nextSource === null) continue;
              var keysArray = Object.keys(Object(nextSource));
              for (var n = 0, len = keysArray.length; n < len; n++) {
                var nextKey = keysArray[n];
                var desc = Object.getOwnPropertyDescriptor(nextSource, nextKey);
                if (desc !== undefined && desc.enumerable) {
                  to[nextKey] = nextSource[nextKey];
                }
              }
            }
            return to;
          }
        }
      JS
    end

    # Return processor JS with some extra methods
    def build_js
      'var global = this;' + polyfills + read_js + process_proxy
    end

    # Return JS code for process method proxy
    def process_proxy
      <<-JS
        var processor;
        var process = function() {
          var result = autoprefixer.process.apply(autoprefixer, arguments);
          var warns  = result.warnings().map(function (i) {
            delete i.plugin;
            return i.toString();
          });
          var map = result.map ? result.map.toString() : null;
          return { css: result.css, map: map, warnings: warns };
        };
      JS
    end
  end
end
