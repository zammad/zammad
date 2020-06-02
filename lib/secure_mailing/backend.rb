class SecureMailing::Backend
  include Mixin::IsBackend

  def self.inherited(subclass)
    subclass.is_backend_of(::SecureMailing)
  end
end

Mixin::RequiredSubPaths.eager_load_recursive(__dir__)
