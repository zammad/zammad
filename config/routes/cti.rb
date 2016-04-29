Zammad::Application.routes.draw do

  match '/api/v1/cti/log',        to: 'cti#index', via: :get
  match '/api/v1/cti/done/:id',   to: 'cti#done',  via: :post

end
