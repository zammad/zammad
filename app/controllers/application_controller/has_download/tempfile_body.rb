# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Deliberately neither responds to #to_path nor #to_ary, so Rack::Sendfile and
#   Rack::ETag pass it through instead of buffering the whole file.
class ApplicationController::HasDownload::TempfileBody
  CHUNK_SIZE = 64.kilobytes

  attr_reader :file

  def initialize(file)
    @file = file
  end

  def each
    file.rewind
    while (chunk = file.read(CHUNK_SIZE))
      yield chunk
    end
  end

  def close
    file.close
  end
end
