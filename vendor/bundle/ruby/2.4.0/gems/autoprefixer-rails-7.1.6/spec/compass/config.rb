http_path       = "/"
css_dir         = "stylesheets"
sass_dir        = "sass"
images_dir      = "images"
javascripts_dir = "javascripts"

sourcemap     = true
output_style  = :compressed
sass_options  = { cache: false }
line_comments = false

require 'rubygems'
require 'bundler'
Bundler.require
require '../../lib/autoprefixer-rails'

on_stylesheet_saved do |file|
  css = File.read(file)
  map = file + '.map'

  if File.exists? map
    result = AutoprefixerRails.process(css,
      browsers: ['chrome 25'],
      from:     file,
      to:       file,
      map:    { prev: File.read(map), inline: false })
    File.open(file, 'w') { |io| io << result.css }
    File.open(map,  'w') { |io| io << result.map }
  else
    File.open(file, 'w') do |io|
      io << AutoprefixerRails.process(css, browsers: ['chrome 25'])
    end
  end
end
