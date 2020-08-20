class ObjectManager::Element
  include ::Mixin::HasBackends

  def self.for_object(object)
    "#{name}::#{object}".safe_constantize || ObjectManager::Element::Backend
  end
end
