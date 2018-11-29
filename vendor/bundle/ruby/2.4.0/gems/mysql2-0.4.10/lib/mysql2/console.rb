# Loaded by script/console. Land helpers here.

Pry.config.prompt = lambda do |context, *|
  "[mysql2] #{context}> "
end
