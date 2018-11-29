module Mysql2
  class Statement
    include Enumerable

    if Thread.respond_to?(:handle_interrupt)
      def execute(*args)
        Thread.handle_interrupt(::Mysql2::Util::TimeoutError => :never) do
          _execute(*args)
        end
      end
    else
      def execute(*args)
        _execute(*args)
      end
    end
  end
end
