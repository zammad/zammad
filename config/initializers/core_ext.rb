# load all core_ext extentions
Dir.glob("#{Rails.root}/lib/core_ext/**/*").each { |file|
  if File.file?(file)
    require file
  end
}
