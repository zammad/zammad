require File.expand_path('../lib/autoprefixer-rails/version', __FILE__)

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'autoprefixer-rails'
  s.version     = AutoprefixerRails::VERSION.dup
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'Parse CSS and add vendor prefixes to CSS rules using ' +
                  'values from the Can I Use website.'

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {spec}/*`.split("\n")
  s.extra_rdoc_files = ['README.md', 'LICENSE', 'CHANGELOG.md']
  s.require_path     = 'lib'
  s.required_ruby_version = '>= 2.0'

  s.author   = 'Andrey Sitnik'
  s.email    = 'andrey@sitnik.ru'
  s.homepage = 'https://github.com/ai/autoprefixer-rails'
  s.license  = 'MIT'

  s.add_dependency 'execjs', '>= 0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rails'
  s.add_development_dependency 'compass'
  s.add_development_dependency 'rspec-rails'
end
