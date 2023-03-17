# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do

  match '/api/v1/cti/:token',     to: 'integration/cti#event',    via: :post

end
