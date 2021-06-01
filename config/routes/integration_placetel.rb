# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do

  match '/api/v1/placetel/:token',     to: 'integration/placetel#event',    via: :post

end
