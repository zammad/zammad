# load all core_ext extentions
Dir.glob("#{Rails.root}/lib/core_ext/**/*").each do |file|
  if File.file?(file)
    require file
  end
end
