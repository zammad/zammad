module Ref
  $LOAD_PATH.unshift(File.dirname(__FILE__))

  require 'ref/abstract_reference_value_map'
  require 'ref/abstract_reference_key_map'
  require 'ref/reference'
  require 'ref/reference_queue'

  if defined?(Java)
    begin
      require 'ref_ext'
      require 'org/jruby/ext/ref/references'
    rescue LoadError
      require 'ref/soft_reference'
      require 'ref/weak_reference'
      warn 'Error loading Rspec rake tasks, probably building the gem...'
    end
  else
    require 'ref/soft_reference'
    if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
      # If using Rubinius set the implementation to use WeakRef since it is very efficient and using finalizers is not.
      require 'ref/weak_reference/weak_ref'
    elsif defined?(::ObjectSpace::WeakMap)
      # Ruby 2.0 has a working implementation of weakref.rb backed by the new ObjectSpace::WeakMap
      require 'ref/weak_reference/weak_ref'
    elsif defined?(::ObjectSpace._id2ref)
      # If ObjectSpace can lookup objects from their object_id, then use the pure ruby implementation.
      require 'ref/weak_reference/pure_ruby'
    else
      # Otherwise, wrap the standard library WeakRef class
      require 'ref/weak_reference/weak_ref'
    end
  end

  require 'ref/soft_key_map'
  require 'ref/soft_value_map'
  require 'ref/strong_reference'
  require 'ref/weak_key_map'
  require 'ref/weak_value_map'

  def self.jruby?
    defined?(Java)
  end
end
