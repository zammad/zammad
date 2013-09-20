# load all core_ext extentions
Dir["#{Rails.root}/lib/core_ext/*"].each {|file|
  if File.file?(file)
    require file
  end
}
