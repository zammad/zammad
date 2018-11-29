require 'power_assert/configuration'

if defined? RubyVM
  if PowerAssert.configuration._redefinition
    verbose = $VERBOSE
    begin
      $VERBOSE = nil
      module PowerAssert
        # set redefined flag
        basic_classes = [
          Fixnum, Float, String, Array, Hash, Bignum, Symbol, Time, Regexp
        ]

        basic_operators = [
          :+, :-, :*, :/, :%, :==, :===, :<, :<=, :<<, :[], :[]=,
          :length, :size, :empty?, :succ, :>, :>=, :!, :!=, :=~, :freeze
        ]

        class Bug11182
          def fixed?
            true
          end
        end
        private_constant :Bug11182

        refine Bug11182 do
          def fixed?
          end
        end

        class Bug11182Sub < Bug11182
          alias _fixed? fixed?
          protected :_fixed?
        end
        private_constant :Bug11182Sub

        if (Bug11182.new.fixed? rescue false)
          basic_classes.each do |klass|
            basic_operators.each do |bop|
              refine(klass) do
                define_method(bop) {}
              end
            end
          end
        else
          # workaround for https://bugs.ruby-lang.org/issues/11182
          basic_classes.each do |klass|
            basic_operators.each do |bop|
              if klass.public_method_defined?(bop)
                klass.ancestors.find {|i| i.instance_methods(false).index(bop) }.module_eval do
                  public bop
                end
              end
            end
          end

          refine Symbol do
            def ==
            end
          end
        end

        # bypass check_cfunc
        refine BasicObject do
          def !
          end

          def ==
          end
        end

        refine Module do
          def ==
          end
        end
      end
    ensure
      $VERBOSE = verbose
    end
  end

  # disable optimization
  RubyVM::InstructionSequence.compile_option = {
    specialized_instruction: false
  }
end
