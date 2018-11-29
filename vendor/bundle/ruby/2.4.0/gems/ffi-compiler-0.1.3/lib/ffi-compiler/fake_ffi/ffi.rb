module FFI

  def self.exporter=(exporter)
    @@exporter = exporter
  end
  
  def self.exporter
    @@exporter
  end
  
  class Type
    attr_reader :name
    def initialize(name)
      @name = name
    end
  end
  
  class StructByReference < Type
    def initialize(struct_class)
      super("struct #{struct_class.to_s.gsub('::', '_')} *")
    end
  end

  class StructByValue < Type
    def initialize(struct_class)
      super("struct #{struct_class.to_s.gsub('::', '_')}")
    end
  end
  
  PrimitiveTypes = {
      :char => 'char',
      :uchar => 'unsigned char',
      :short => 'short',
      :ushort => 'unsigned short',
      :int => 'int',
      :uint => 'unsigned int',
      :long => 'long',
      :ulong => 'unsigned long',
      :float => 'float',
      :double => 'double',
      :pointer => 'void *',
      :string => 'const char *',
  }
  
  TypeMap = {}
  def self.find_type(type)
    return type if type.is_a?(Type)

    t = TypeMap[type]
    return t unless t.nil?

    if PrimitiveTypes.has_key?(type)
      return TypeMap[type] = Type.new(PrimitiveTypes[type])
    end
    raise TypeError.new("cannot resolve type #{type}")
  end

  class Exporter
    attr_reader :mod, :functions

    def initialize(mod)
      @mod = mod
      @functions = []
      @structs = []
    end

    def attach(mname, fname, result_type, param_types)
      @functions << { mname: mname, fname: fname, result_type: result_type, params: param_types.dup }
    end
    
    def struct(name, fields)
      @structs << { name: name, fields: fields.dup }
    end
    
    def dump(out_file)
      File.open(out_file, 'w') do |f|
        guard = File.basename(out_file).upcase.gsub('.', '_').gsub('/', '_')
        f.puts <<-HEADER
#ifndef #{guard}
#define #{guard} 1

#ifndef RBFFI_EXPORT
# ifdef __cplusplus
#  define RBFFI_EXPORT extern "C"
# else
#  define RBFFI_EXPORT
# endif
#endif

        HEADER
        
        @structs.each do |s|
          f.puts "struct #{s[:name].gsub('::', '_')} {"
          s[:fields].each do |field|
            f.puts "#{' ' * 4}#{field[:type].name} #{field[:name].to_s};"
          end
          f.puts '};'
          f.puts
        end
        @functions.each do |fn|
          param_string = fn[:params].empty? ? 'void' : fn[:params].map(&:name).join(', ')
          f.puts "RBFFI_EXPORT #{fn[:result_type].name} #{fn[:fname]}(#{param_string});"
        end
        f.puts <<-EPILOG

#endif /* #{guard} */
        EPILOG
      end
    end
    
  end

  module Library
    def self.extended(mod)
      FFI.exporter = Exporter.new(mod)
    end

    def attach_function(*args)
      FFI.exporter.attach(args[0], args[0], find_type(args[2]), args[1].map { |t| find_type(t) })
    end

    def ffi_lib(*args)

    end

    TypeMap = {}
    def find_type(type)
      t = TypeMap[type]
      return t unless t.nil?
      
      if type.is_a?(Class) && type < Struct
        return TypeMap[type] = StructByReference.new(type)
      end

      TypeMap[type] = FFI.find_type(type)
    end
  end

  class Struct
    def self.layout(*args)
      fields = []
      i = 0
      while i < args.length
        fields << { name: args[i], type: find_type(args[i+1]) }
        i += 2
      end
      FFI.exporter.struct(self.to_s, fields)
    end

    TypeMap = {}
    def self.find_type(type)
      t = TypeMap[type]
      return t unless t.nil?

      if type.is_a?(Class) && type < Struct
        return TypeMap[type] = StructByValue.new(type)
      end

      TypeMap[type] = FFI.find_type(type)
    end
    
    def self.by_value
      StructByValue.new(self)
    end
    
    def self.by_ref
      StructByReference.new(self)
    end
  end
end