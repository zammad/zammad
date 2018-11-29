begin
  if ENV['COVERAGE']
    require 'simplecov'
    SimpleCov.start do
      add_filter '/test/'
      add_filter '/vendor/'
    end
  end
rescue LoadError
end
