$:.unshift 'lib'
require 'little-plugger'

begin
  require 'bones'
rescue LoadError
  abort '### please install the "bones" gem ###'
end

task :default => 'spec:run'
task 'gem:release' => 'spec:run'

Bones {
  name 'little-plugger'
  authors 'Tim Pease'
  email 'tim.pease@gmail.com'
  url 'http://gemcutter.org/gems/little-plugger'
  version LittlePlugger::VERSION
  readme_file 'README.rdoc'

  spec.opts.concat %w[--color --format documentation]
  use_gmail

  depend_on 'rspec', '~> 3.3', :development => true
}

# depending on bones (even as a development dependency) creates a circular
# reference that prevents the auto install of little-plugger when instsalling
# bones
::Bones.config.gem._spec.dependencies.delete_if {|d| d.name == 'bones'}
