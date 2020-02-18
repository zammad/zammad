# load all core_ext extensions
Dir.glob( Rails.root.join('lib/core_ext/**/*') ).sort.each do |file|
  if File.file?(file)
    require file
  end
end
