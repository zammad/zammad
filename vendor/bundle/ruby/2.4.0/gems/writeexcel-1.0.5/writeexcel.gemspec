# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'writeexcel/version'

Gem::Specification.new do |gem|
  gem.name          = "writeexcel"
  gem.version       = WriteExcel::VERSION
  gem.authors       = ["Hideo NAKAMURA"]
  gem.email         = ["cxn03651@msj.biglobe.ne.jp"]
  gem.description   = "Multiple worksheets can be added to a workbook and formatting can be applied to cells. Text, numbers, formulas, hyperlinks and images can be written to the cells."
  gem.summary       = "Write to a cross-platform Excel binary file."
  gem.homepage      = "http://github.com/cxn03651/writeexcel#readme"
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency 'test-unit'
  gem.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  gem.add_development_dependency 'simplecov'
end
