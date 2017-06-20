Zammad::Application.routes.draw do

  match '/tests_core',                    to: 'tests#core',                       via: :get
  match '/tests_ui',                      to: 'tests#ui',                         via: :get
  match '/tests_model',                   to: 'tests#model',                      via: :get
  match '/tests_model_ui',                to: 'tests#model_ui',                   via: :get
  match '/tests_form',                    to: 'tests#form',                       via: :get
  match '/tests_form_tree_select',        to: 'tests#form_tree_select',           via: :get
  match '/tests_form_find',               to: 'tests#form_find',                  via: :get
  match '/tests_form_trim',               to: 'tests#form_trim',                  via: :get
  match '/tests_form_extended',           to: 'tests#form_extended',              via: :get
  match '/tests_form_timer',              to: 'tests#form_timer',                 via: :get
  match '/tests_form_validation',         to: 'tests#form_validation',            via: :get
  match '/tests_form_column_select',      to: 'tests#form_column_select',         via: :get
  match '/tests_form_searchable_select',  to: 'tests#form_searchable_select',     via: :get
  match '/tests_table',                   to: 'tests#table',                      via: :get
  match '/tests_html_utils',              to: 'tests#html_utils',                 via: :get
  match '/tests_ticket_selector',         to: 'tests#ticket_selector',            via: :get
  match '/tests_taskbar',                 to: 'tests#taskbar',                    via: :get
  match '/tests/wait/:sec',               to: 'tests#wait',                       via: :get
  match '/tests/unprocessable_entity',    to: 'tests#error_unprocessable_entity', via: :get
  match '/tests/not_authorized',          to: 'tests#error_not_authorized',       via: :get
  match '/tests/ar_not_found',            to: 'tests#error_ar_not_found',         via: :get
  match '/tests/standard_error',          to: 'tests#error_standard_error',       via: :get
  match '/tests/argument_error',          to: 'tests#error_argument_error',       via: :get

end
