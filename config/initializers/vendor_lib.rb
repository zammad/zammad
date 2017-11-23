# load all vendor/lib extentions
Dir[ Rails.root.join('vendor', 'lib', '*') ].each do |file|
  if File.file?(file)
    require file
  end
end
