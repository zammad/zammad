
# == Synopsis
# LittlePlugger is a module that provides Gem based plugin management.
# By extending your own class or module with LittlePlugger you can easily
# manage the loading and initializing of plugins provided by other gems.
#
# == Details
# Plugins are great! They allow other developers to add functionality to
# an application but relieve the application developer of the responsibility
# for mainting some other developer's plugin code. LittlePlugger aims to
# make it dead simple to manage external plugins as gems.
#
# === Naming
# Every plugin managed by LittlePlugger will have a name represented as a
# Symbol. This name is used to register the plugin, load the plugin file,
# and manage the plugin class/module. Here are the three rules for plugin
# names:
#
# 1) all lowercase with underscores
# 2) maps to a file of the same name with an '.rb' extension
# 3) converting the name to camel case yields the plugin class / module
#
# These rules are essentially the standard ruby practice of naming files
# after the class / module the file defines.
#
# === Finding & Loading
# Plugins are found by searching through the lib folders of all installed
# gems; these gems are not necessarily loaded - just searched. If the lib
# folder has a subdirectory that matches the +plugin_path+, then all ruby
# files in the gem's +plugin_path+ are noted for later loading.
#
# A file is only loaded if the basename of the file matches one of the
# registered plugin names. If no plugins are registered, then every file in
# the +plugin_path+ is loaded.
#
# The plugin classes / modules are all expected to live in the same
# namespace for a particular application. For example, all plugins for the
# "Foo" application should reside in a "Foo::Plugins" namespace. This allows
# the plugins to be automatically initialized by LittlePlugger.
#
# === Initializing
# Optionally, plugins can provide an initialization method for running any
# setup code needed by the plugin. This initialize method should be named as
# follows: "initializer_#{plugin_name}" where the name of the plugin is
# appended to the end of the initializer method name.
#
# If this method exists, it will be called automatically when plugins are
# loaded. The order of loading of initialization is not strictly defined, so
# do not rely on another plugin being initialized for your own plugin
# successfully initialize.
#
# == Usage
# LittlePlugger is used by extending your own class or module with the
# LittlePlugger module.
#
#    module Logging
#      extend LittlePlugger
#    end
#
# This defines a +plugin_path+ and a +plugin_module+ for our Logging module.
# The +plugin_path+ is set to "logging/plugins", and therefore, the
# +plugin_modlue+ is defined as Logging::Plugins. All plugins for the
# Logging module should be found underneath this plugin module.
#
# The plugins for the Logging module are loaded and initialized by calling
# the +initialize_plugins+ method.
#
#    Logging.initialize_plugins
#
# If you only want to load the plugin files but not initialize the plugin
# classes / modules then you can call the +load_plugins+ method.
#
#    Logging.load_plugins
#
# Finally, you can get a hash of all the loaded plugins.
#
#    Logging.plugins
#
# This returns a hash keyed by the plugin names with the plugin class /
# module as the value.
#
# If you only want a certain set of plugins to be loaded, then pass the
# names to the +plugin+ method.
#
#    Logging.plugin :foo, :bar, :baz
#
# Now only three plugins for the Logging module will be loaded.
#
# === Customizing
# LittlePlugger allows the use of a custom plugin path and module. These are
# specified when extending with LilttlePlugger by passing the specific path
# and module to LittlePlugger.
#
#    class Hoe
#      extend LittlePlugger( :path => 'hoe', :module => Hoe )
#
#      plugin(
#          :clean, :debug, :deps, :flay, :flog, :package,
#          :publish, :rcov, :signing, :test
#      )
#    end
#
# All ruby files found under the "hoe" directory will be treated as
# plugins, and the plugin classes / modules should reside directly under the
# Hoe namespace.
#
# We also specify a list of plugins to be loaded. Only these plugins will be
# loaded and initialized by the LittlePlugger module. The +plugin+ method
# can be called multiple times to add more plugins.
#
module LittlePlugger

  VERSION = '1.1.4'  # :nodoc:

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end

  module ClassMethods

    # Add the _names_ to the list of plugins that will be loaded.
    #
    def plugin( *names )
      plugin_names.concat(names.map! {|n| n.to_sym})
    end

    # Add the _names_ to the list of plugins that will *not* be loaded. This
    # list prevents the plugin system from loading unwanted or unneeded
    # plugins.
    #
    # If a plugin name appears in both the 'disregard_plugin' list and the
    # 'plugin' list, the disregard list takes precedence; that is, the plugin
    # will not be loaded.
    #
    def disregard_plugin( *names )
      @disregard_plugin ||= []
      @disregard_plugin.concat(names.map! {|n| n.to_sym})
      @disregard_plugin
    end
    alias :disregard_plugins :disregard_plugin

    # Returns the array of plugin names that will be loaded. If the array is
    # empty, then any plugin found in the +plugin_path+ will be loaded.
    #
    def plugin_names
      @plugin_names ||= []
    end

    # Loads the desired plugins and returns a hash. The hash contains all
    # the plugin classes and modules keyed by the plugin name.
    #
    def plugins
      load_plugins
      pm = plugin_module
      names = pm.constants.map { |s| s.to_s }
      names.reject! { |n| n =~ %r/^[A-Z_]+$/ }

      h = {}
      names.each do |name|
        sym = ::LittlePlugger.underscore(name).to_sym
        next unless plugin_names.empty? or plugin_names.include? sym
        next if disregard_plugins.include? sym
        h[sym] = pm.const_get name
      end
      h
    end

    # Iterate over the loaded plugin classes and modules and call the
    # initialize method for each plugin. The plugin's initialize method is
    # defeind as +initialize_plugin_name+, where the plugin name is unique
    # to each plugin.
    #
    def initialize_plugins
      plugins.each do |name, klass|
        msg = "initialize_#{name}"
        klass.send msg if klass.respond_to? msg
      end
    end

    # Iterate through all installed gems looking for those that have the
    # +plugin_path+ in their "lib" folder, and load all .rb files found in
    # the gem's plugin path. Each .rb file should define one class or module
    # that will be used as a plugin.
    #
    def load_plugins
      @loaded ||= {}
      found = {}

      Gem.find_files(File.join(plugin_path, '*.rb')).sort!.reverse_each do |path|
        name = File.basename(path, '.rb').to_sym
        found[name] = path unless found.key? name
      end

      :keep_on_truckin while found.map { |name, path|
        next unless plugin_names.empty? or plugin_names.include? name
        next if disregard_plugins.include? name
        next if @loaded[name]
        begin
          @loaded[name] = load path
        rescue ScriptError, StandardError => err
          warn "Error loading #{path.inspect}: #{err.message}. skipping..."
        end
      }.any?
    end

    # The path to search in a gem's 'lib' folder for plugins.
    #
    def plugin_path
      ::LittlePlugger.default_plugin_path(self)
    end

    # This module or class where plugins are located.
    #
    def plugin_module
      ::LittlePlugger.default_plugin_module(plugin_path)
    end

  end  # module ClassMethods

  # :stopdoc:

  # Called when another object extends itself with LittlePlugger.
  #
  def self.extended( other )
    other.extend ClassMethods
  end

  # Convert the given string from camel case to snake case. Method liberally
  # stolen from ActiveSupport.
  #
  #    underscore( "FooBar" )    #=> "foo_bar"
  #
  def self.underscore( string )
    string.to_s.
        gsub(%r/::/, '/').
        gsub(%r/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(%r/([a-z\d])([A-Z])/,'\1_\2').
        tr('-', '_').
        downcase
  end

  # For a given object returns a default plugin path. The path is
  # created by splitting the object's class name on the namespace separator
  # "::" and converting each part of the namespace into an underscored
  # string (see the +underscore+ method). The strings are then joined using
  # the File#join method to give a filesystem path. Appended to this path is
  # the 'plugins' directory.
  #
  #    default_plugin_path( FooBar::Baz )    #=> "foo_bar/baz/plugins"
  #
  def self.default_plugin_path( obj )
    obj = obj.class unless obj.is_a? Module
    File.join(underscore(obj.name), 'plugins')
  end

  # For a given path returns the class or module corresponding to the
  # path. This method assumes a correspondence between directory names and
  # Ruby namespaces.
  #
  #    default_plugin_module( "foo_bar/baz/plugins" )  #=> FooBar::Baz::Plugins
  #
  # This method will fail if any of the namespaces have not yet been
  # defined.
  #
  def self.default_plugin_module( path )
    path.split(File::SEPARATOR).inject(Object) do |mod, const|
      const = const.split('_').map { |s| s.capitalize }.join
      mod.const_get const
    end
  end
  # :startdoc:

end  # module LittlePlugger


module Kernel

  # call-seq:
  #    LittlePlugger( opts = {} )
  #
  # This method allows the user to override some of LittlePlugger's default
  # settings when mixed into a module or class.
  #
  # See the "Customizing" section of the LittlePlugger documentation for an
  # example of how this method is used.
  #
  # ==== Options
  #
  # * :path <String>
  #    The default plugin path. Defaults to "module_name/plugins".
  #
  # * :module <Module>
  #    The module where plugins will be loaded. Defaults to
  #    ModuleName::Plugins.
  #
  # * :plugins <Array>
  #    The array of default plugins to load. Only the plugins listed in this
  #    array will be loaded by LittlePlugger.
  # 
  def LittlePlugger( opts = {} )
    return ::LittlePlugger::ClassMethods if opts.empty?
    Module.new {
      include ::LittlePlugger::ClassMethods

      if opts.key?(:path)
        eval %Q{def plugin_path() #{opts[:path].to_s.inspect} end}
      end

      if opts.key?(:module)
        eval %Q{def plugin_module() #{opts[:module].name} end}
      end

      if opts.key?(:plugins)
        plugins = Array(opts[:plugins]).map {|val| val.to_sym.inspect}.join(',')
        eval %Q{def plugin_names() @plugin_names ||= [#{plugins}] end}
      end
    }
  end
end  # module Kernel

# EOF
