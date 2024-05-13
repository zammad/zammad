# rubocop:disable all
class YARD::CustomExtensions
  # Automatically create modules for every parent namespace for the given name.
  #
  # For exampe, if `name` is `Foo::Bar::Baz`, code objects for `Foo` and `Foo::Bar` will be created
  # and added to YARD's registry before continuing to process `Foo::Bar::Baz` as normal.
  # This is a copy-paste from the following Github comment
  # Full credit goes to @jeraki.
  # https://github.com/lsegal/yard/issues/1002#issuecomment-1201852997
  def self.autovivify_parents(name)
    parts = []

    while name =~ /(?:::)([^:]+)$/
      parts.push($1)
      name = $`
    end

    return if parts.empty?

    ns = :root
    n = name

    loop do
      ns = YARD::CodeObjects::ModuleObject.new(ns, name)
      ns.add_file("(autovivifed)")
      break if parts.empty?
      name = parts.pop
    end
  end
end

class YARD::Handlers::Ruby::ModuleHandler
  def process
    modname = statement[0].source
    YARD::CustomExtensions.autovivify_parents(modname)
    super
  end
end

class YARD::Handlers::Ruby::ClassHandler
  def process
    classname = statement[0].source.gsub(/\s/, '')
    YARD::CustomExtensions.autovivify_parents(classname)
    super
  end
end
# rubocop:enable all
