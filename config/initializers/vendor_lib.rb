# load all vendor/lib extentions
Dir["#{Rails.root}/vendor/lib/*"].each { |file|
  if File.file?(file)
    require file
  end
}
