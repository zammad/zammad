Zammad::Application.routes.draw do

  match '/tests_core',                    to: 'tests#core',            via: :get
  match '/tests_ui',                      to: 'tests#ui',              via: :get
  match '/tests_model',                   to: 'tests#model',           via: :get
  match '/tests_model_ui',                to: 'tests#model_ui',        via: :get
  match '/tests_form',                    to: 'tests#form',            via: :get
  match '/tests_form_trim',               to: 'tests#form_trim',       via: :get
  match '/tests_form_extended',           to: 'tests#form_extended',   via: :get
  match '/tests_form_validation',         to: 'tests#form_validation', via: :get
  match '/tests_form_column_select',      to: 'tests#form_column_select', via: :get
  match '/tests_form_searchable_select',  to: 'tests#form_searchable_select', via: :get
  match '/tests_table',                   to: 'tests#table',           via: :get
  match '/tests_html_utils',              to: 'tests#html_utils',      via: :get
  match '/tests_taskbar',                 to: 'tests#taskbar',         via: :get
  match '/tests/wait/:sec',               to: 'tests#wait',            via: :get

end
