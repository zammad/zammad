# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

ObjectManager::Attribute.add(
  force:       true,
  object:      'Ticket',
  name:        'number',
  display:     '#',
  data_type:   'input',
  data_option: {
    type:      'text',
    readonly:  1,
    null:      true,
    maxlength: 60,
    width:     '68px',
  },
  editable:    false,
  active:      true,
  screens:     {
    create_top: {},
    edit:       {},
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    5,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Ticket',
  name:        'title',
  display:     __('Title'),
  data_type:   'input',
  data_option: {
    type:      'text',
    maxlength: 200,
    null:      false,
    translate: false,
  },
  editable:    false,
  active:      true,
  screens:     {
    create_top: {
      '-all-' => {
        null: false,
      },
    },
    edit:       {},
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    8,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Ticket',
  name:        'customer_id',
  display:     __('Customer'),
  data_type:   'user_autocompletion',
  data_option: {
    relation:       'User',
    autocapitalize: false,
    multiple:       false,
    guess:          true,
    null:           false,
    limit:          200,
    placeholder:    __('Enter Person or Organization/Company'),
    minLengt:       2,
    translate:      false,
    permission:     ['ticket.agent'],
  },
  editable:    false,
  active:      true,
  screens:     {
    create_top: {
      '-all-' => {
        null: false,
      },
    },
    edit:       {},
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    10,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Ticket',
  name:        'organization_id',
  display:     'Organization',
  data_type:   'autocompletion_ajax_customer_organization',
  data_option: {
    relation:       'Organization',
    autocapitalize: false,
    multiple:       false,
    null:           true,
    translate:      false,
    permission:     ['ticket.agent', 'ticket.customer'],
  },
  editable:    false,
  active:      true,
  screens:     {
    create_top: {
      '-all-' => {
        null: false,
      },
    },
    edit:       {},
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    12,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Ticket',
  name:        'type',
  display:     __('Type'),
  data_type:   'select',
  data_option: {
    default:    '',
    options:    {
      'Incident'           => __('Incident'),
      'Problem'            => __('Problem'),
      'Request for Change' => __('Request for Change'),
    },
    nulloption: true,
    multiple:   false,
    null:       true,
    translate:  true,
  },
  editable:    true,
  active:      false,
  screens:     {
    create_middle: {
      '-all-' => {
        null:       false,
        item_class: 'column',
      },
    },
    edit:          {
      'ticket.agent' => {
        null: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    20,
)
ObjectManager::Attribute.add(
  force:       true,
  object:      'Ticket',
  name:        'group_id',
  display:     __('Group'),
  data_type:   'tree_select',
  data_option: {
    default:                  '',
    relation:                 'Group',
    relation_condition:       { access: 'full' },
    nulloption:               true,
    multiple:                 false,
    null:                     false,
    translate:                false,
    only_shown_if_selectable: true,
    permission:               ['ticket.agent', 'ticket.customer'],
  },
  editable:    false,
  active:      true,
  screens:     {
    create_middle: {
      '-all-' => {
        null:       false,
        item_class: 'column',
      },
    },
    edit:          {
      'ticket.agent' => {
        null: false,
      },
    },
    overview_bulk: {
      'ticket.agent' => {
        nulloption: true,
        null:       true,
        default:    '',
        direction:  'up',
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    25,
)
ObjectManager::Attribute.add(
  force:       true,
  object:      'Ticket',
  name:        'owner_id',
  display:     __('Owner'),
  data_type:   'select',
  data_option: {
    default:            '',
    relation:           'User',
    relation_condition: { roles: 'Agent' },
    nulloption:         true,
    multiple:           false,
    null:               true,
    translate:          false,
    permission:         ['ticket.agent'],
  },
  editable:    false,
  active:      true,
  screens:     {
    create_middle: {
      '-all-' => {
        null:       true,
        item_class: 'column',
      },
    },
    edit:          {
      '-all-' => {
        null: true,
      },
    },
    overview_bulk: {
      'ticket.agent' => {
        null: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    30,
)
ObjectManager::Attribute.add(
  force:       true,
  object:      'Ticket',
  name:        'state_id',
  display:     __('State'),
  data_type:   'select',
  data_option: {
    relation:   'TicketState',
    nulloption: true,
    multiple:   false,
    null:       false,
    default:    Ticket::State.find_by(default_follow_up: true).id,
    translate:  true,
    filter:     Ticket::State.where(active: true).by_category_ids(:viewable),
  },
  editable:    false,
  active:      true,
  screens:     {
    create_middle: {
      'ticket.agent'    => {
        null:       false,
        item_class: 'column',
        filter:     Ticket::State.where(active: true).by_category_ids(:viewable_agent_new),
      },
      'ticket.customer' => {
        item_class: 'column',
        nulloption: false,
        null:       true,
        filter:     Ticket::State.where(active: true).by_category_ids(:viewable_customer_new),
        default:    Ticket::State.find_by(default_create: true).id,
      },
    },
    edit:          {
      'ticket.agent'    => {
        nulloption: false,
        null:       false,
        filter:     Ticket::State.where(active: true).by_category_ids(:viewable_agent_edit),
      },
      'ticket.customer' => {
        nulloption: false,
        null:       true,
        filter:     Ticket::State.where(active: true).by_category_ids(:viewable_customer_edit),
        default:    Ticket::State.find_by(default_follow_up: true).id,
      },
    },
    overview_bulk: {
      'ticket.agent' => {
        nulloption: true,
        null:       true,
        default:    '',
        filter:     Ticket::State.where(active: true).by_category_ids(:viewable_agent_edit),
      },
    }
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    40,
)
ObjectManager::Attribute.add(
  force:       true,
  object:      'Ticket',
  name:        'pending_time',
  display:     __('Pending till'),
  data_type:   'datetime',
  data_option: {
    future:     true,
    past:       false,
    diff:       nil,
    null:       true,
    translate:  true,
    permission: %w[ticket.agent],
  },
  editable:    false,
  active:      true,
  screens:     {
    create_middle: {
      '-all-' => {
        null:       false,
        item_class: 'column',
      },
    },
    edit:          {
      '-all-' => {
        null: false,
      },
    },
    overview_bulk: {
      'ticket.agent' => {
        nulloption:    true,
        null:          true,
        default:       '',
        orientation:   'top',
        disableScroll: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    41,
)
ObjectManager::Attribute.add(
  force:       true,
  object:      'Ticket',
  name:        'priority_id',
  display:     __('Priority'),
  data_type:   'select',
  data_option: {
    relation:   'TicketPriority',
    nulloption: false,
    multiple:   false,
    null:       false,
    default:    Ticket::Priority.find_by(default_create: true).id,
    translate:  true,
  },
  editable:    false,
  active:      true,
  screens:     {
    create_middle: {
      'ticket.agent' => {
        null:       false,
        item_class: 'column',
      },
    },
    edit:          {
      'ticket.agent' => {
        null: false,
      },
    },
    overview_bulk: {
      'ticket.agent' => {
        nulloption: true,
        null:       true,
        default:    '',
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    80,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Ticket',
  name:        'tags',
  display:     __('Tags'),
  data_type:   'tag',
  data_option: {
    type:      'text',
    null:      true,
    translate: false,
  },
  editable:    false,
  active:      true,
  screens:     {
    create_bottom: {
      'ticket.agent' => {
        null: true,
      },
    },
    edit:          {},
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    900,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'TicketArticle',
  name:        'type_id',
  display:     __('Type'),
  data_type:   'select',
  data_option: {
    relation:   'TicketArticleType',
    nulloption: false,
    multiple:   false,
    null:       false,
    default:    Ticket::Article::Type.lookup(name: 'note').id,
    translate:  true,
  },
  editable:    false,
  active:      true,
  screens:     {
    create_middle: {},
    edit:          {
      'ticket.agent' => {
        null: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    100,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'TicketArticle',
  name:        'internal',
  display:     __('Visibility'),
  data_type:   'select',
  data_option: {
    options:    {
      true:  'internal',
      false: 'public'
    },
    nulloption: false,
    multiple:   false,
    null:       true,
    default:    false,
    translate:  true,
  },
  editable:    false,
  active:      true,
  screens:     {
    create_middle: {},
    edit:          {
      'ticket.agent' => {
        null: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    200,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'TicketArticle',
  name:        'to',
  display:     __('To'),
  data_type:   'input',
  data_option: {
    type:      'text',
    maxlength: 1000,
    null:      true,
  },
  editable:    false,
  active:      true,
  screens:     {
    create_middle: {},
    edit:          {
      'ticket.agent' => {
        null: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    300,
)
ObjectManager::Attribute.add(
  force:       true,
  object:      'TicketArticle',
  name:        'cc',
  display:     __('CC'),
  data_type:   'input',
  data_option: {
    type:      'text',
    maxlength: 1000,
    null:      true,
  },
  editable:    false,
  active:      true,
  screens:     {
    create_top:    {},
    create_middle: {},
    edit:          {
      'ticket.agent' => {
        null: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    400,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'TicketArticle',
  name:        'body',
  display:     __('Text'),
  data_type:   'richtext',
  data_option: {
    type:      'richtext',
    maxlength: 150_000,
    upload:    true,
    rows:      8,
    null:      true,
  },
  editable:    false,
  active:      true,
  screens:     {
    create_top: {
      '-all-' => {
        null: false,
      },
    },
    edit:       {
      '-all-' => {
        null: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    600,
)

# NB: Untranslated list of languages for now, supported by CLD library.
#   https://github.com/mzsanford/cld/blob/master/languages/internal/languages.cc
# rubocop:disable Zammad/DetectTranslatableString
detected_language_options = {
  'ab'     => 'Abkhazian',
  'aa'     => 'Afar',
  'af'     => 'Afrikaans',
  'sq'     => 'Albanian',
  'am'     => 'Amharic',
  'ar'     => 'Arabic',
  'hy'     => 'Armenian',
  'as'     => 'Assamese',
  'ay'     => 'Aymara',
  'az'     => 'Azerbaijani',
  'ba'     => 'Bashkir',
  'eu'     => 'Basque',
  'be'     => 'Belarusian',
  'bn'     => 'Bengali',
  'bh'     => 'Bihari',
  'bi'     => 'Bislama',
  'bs'     => 'Bosnian',
  'br'     => 'Breton',
  'bg'     => 'Bulgarian',
  'my'     => 'Burmese',
  'ca'     => 'Catalan',
  'chr'    => 'Cherokee',
  'zh-TW'  => 'Chinese (Taiwan)',
  'zh'     => 'Chinese',
  'co'     => 'Corsican',
  'cpe'    => 'Creoles and Pidgins (English based)',
  'cpf'    => 'Creoles and Pidgins (French based)',
  'crp'    => 'Creoles and Pidgins (Other)',
  'cpp'    => 'Creoles and Pidgins (Portuguese based)',
  'hr'     => 'Croatian',
  'cs'     => 'Czech',
  'da'     => 'Danish',
  'dv'     => 'Dhivehi',
  'nl'     => 'Dutch',
  'dz'     => 'Dzongkha',
  'en'     => 'English',
  'eo'     => 'Esperanto',
  'et'     => 'Estonian',
  'fo'     => 'Faroese',
  'fj'     => 'Fijian',
  'fi'     => 'Finnish',
  'fr'     => 'French',
  'fy'     => 'Frisian',
  'gl'     => 'Galician',
  'lg'     => 'Ganda',
  'ka'     => 'Georgian',
  'de'     => 'German',
  'el'     => 'Greek',
  'kl'     => 'Greenlandic',
  'gn'     => 'Guarani',
  'gu'     => 'Gujarati',
  'ht'     => 'Haitian Creole',
  'ha'     => 'Hausa',
  'he'     => 'Hebrew',
  'hi'     => 'Hindi',
  'hu'     => 'Hungarian',
  'is'     => 'Icelandic',
  'id'     => 'Indonesian',
  'ia'     => 'Interlingua',
  'ie'     => 'Interlingue',
  'iu'     => 'Inuktitut',
  'ik'     => 'Inupiak',
  'ga'     => 'Irish',
  'it'     => 'Italian',
  'ja'     => 'Japanese',
  'jw'     => 'Javanese',
  'kn'     => 'Kannada',
  'ks'     => 'Kashmiri',
  'kk'     => 'Kazakh',
  'kha'    => 'Khasi',
  'km'     => 'Khmer',
  'rw'     => 'Kinyarwanda',
  'ko'     => 'Korean',
  'ku'     => 'Kurdish',
  'ky'     => 'Kyrgyz',
  'lo'     => 'Laothian',
  'la'     => 'Latin',
  'lv'     => 'Latvian',
  'sit-NP' => 'Limbu',
  'ln'     => 'Lingala',
  'lt'     => 'Lithuanian',
  'lb'     => 'Luxembourgish',
  'mk'     => 'Macedonian',
  'mg'     => 'Malagasy',
  'ms'     => 'Malay',
  'ml'     => 'Malayalam',
  'mt'     => 'Maltese',
  'gv'     => 'Manx',
  'mi'     => 'Maori',
  'mr'     => 'Marathi',
  'mo'     => 'Moldavian',
  'mn'     => 'Mongolian',
  'sr-ME'  => 'Montenegrin',
  'na'     => 'Nauru',
  'ne'     => 'Nepali',
  'nn'     => 'Norwegian (Nynorsk)',
  'nb'     => 'Norwegian',
  'oc'     => 'Occitan',
  'or'     => 'Oriya',
  'om'     => 'Oromo',
  'ps'     => 'Pashto',
  'fa'     => 'Persian',
  'pl'     => 'Polish',
  'pt-BR'  => 'Portuguese (Brazil)',
  'pt-PT'  => 'Portuguese (Portugal)',
  'pt'     => 'Portuguese',
  'pa'     => 'Punjabi',
  'qu'     => 'Quechua',
  'rm'     => 'Rhaeto Romance',
  'ro'     => 'Romanian',
  'rn'     => 'Rundi',
  'ru'     => 'Russian',
  'sm'     => 'Samoan',
  'sg'     => 'Sango',
  'sa'     => 'Sanskrit',
  'gd'     => 'Scots Gaelic',
  'sco'    => 'Scots',
  'sr'     => 'Serbian',
  'sh'     => 'Serbo Croatian',
  'st'     => 'Sesotho',
  'sn'     => 'Shona',
  'sd'     => 'Sindhi',
  'si'     => 'Sinhalese',
  'ss'     => 'Siswant',
  'sk'     => 'Slovak',
  'sl'     => 'Slovenian',
  'so'     => 'Somali',
  'es'     => 'Spanish',
  'su'     => 'Sundanese',
  'sw'     => 'Swahili',
  'sv'     => 'Swedish',
  'syr'    => 'Syriac',
  'fil'    => 'Tagalog',
  'tg'     => 'Tajik',
  'ta'     => 'Tamil',
  'tt'     => 'Tatar',
  'te'     => 'Telugu',
  'th'     => 'Thai',
  'bo'     => 'Tibetan',
  'ti'     => 'Tigrinya',
  'to'     => 'Tonga',
  'ts'     => 'Tsonga',
  'tn'     => 'Tswana',
  'tr'     => 'Turkish',
  'tk'     => 'Turkmen',
  'tw'     => 'Twi',
  'ug'     => 'Uighur',
  'uk'     => 'Ukrainian',
  'ur'     => 'Urdu',
  'uz'     => 'Uzbek',
  'vi'     => 'Vietnamese',
  'vo'     => 'Volapuk',
  'cy'     => 'Welsh',
  'wo'     => 'Wolof',
  'xh'     => 'Xhosa',
  'yi'     => 'Yiddish',
  'yo'     => 'Yoruba',
  'za'     => 'Zhuang',
  'zu'     => 'Zulu',
}.freeze
# rubocop:enable Zammad/DetectTranslatableString

ObjectManager::Attribute.add(
  force:       true,
  object:      'TicketArticle',
  name:        'detected_language',
  display:     __('Detected Language'),
  data_type:   'select',
  data_option: {
    nulloption:         true,
    multiple:           false,
    null:               true,
    default:            '',
    translate:          false,
    options:            detected_language_options,
    # FIXME: Remove this after the automatic population of historical options for seeded attributes is in place.
    historical_options: detected_language_options,
  },
  editable:    false,
  active:      true,
  screens:     {
    create_middle: {},
    edit:          {
      'ticket.agent' => {
        null: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    100,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'login',
  display:     __('Login'),
  data_type:   'input',
  data_option: {
    type:           'text',
    maxlength:      100,
    null:           true,
    autocapitalize: false,
    item_class:     'formGroup--halfSize',
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {},
    edit:            {},
    view:            {
      '-all-' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    100,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'firstname',
  display:     __('First name'),
  data_type:   'input',
  data_option: {
    type:       'text',
    maxlength:  150,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {
      '-all-' => {
        null: true,
      },
    },
    invite_agent:    {
      '-all-' => {
        null: true,
      },
    },
    invite_customer: {
      '-all-' => {
        null: true,
      },
    },
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    200,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'lastname',
  display:     __('Last name'),
  data_type:   'input',
  data_option: {
    type:       'text',
    maxlength:  150,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {
      '-all-' => {
        null: true,
      },
    },
    invite_agent:    {
      '-all-' => {
        null: true,
      },
    },
    invite_customer: {
      '-all-' => {
        null: true,
      },
    },
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    300,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'email',
  display:     __('Email'),
  data_type:   'input',
  data_option: {
    type:       'email',
    maxlength:  150,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {
      '-all-' => {
        null: false,
      },
    },
    invite_agent:    {
      '-all-' => {
        null: false,
      },
    },
    invite_customer: {
      '-all-' => {
        null: false,
      },
    },
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    400,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'web',
  display:     __('Web'),
  data_type:   'input',
  data_option: {
    type:       'url',
    maxlength:  250,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    500,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'phone',
  display:     __('Phone'),
  data_type:   'input',
  data_option: {
    type:       'tel',
    maxlength:  100,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    600,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'mobile',
  display:     __('Mobile'),
  data_type:   'input',
  data_option: {
    type:       'tel',
    maxlength:  100,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    700,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'fax',
  display:     __('Fax'),
  data_type:   'input',
  data_option: {
    type:       'tel',
    maxlength:  100,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    800,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'organization_id',
  display:     __('Organization'),
  data_type:   'autocompletion_ajax',
  data_option: {
    multiple:   false,
    nulloption: true,
    null:       true,
    relation:   'Organization',
    item_class: 'formGroup--halfSize',
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {
      '-all-' => {
        null: true,
      },
    },
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    900,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'organization_ids',
  display:     __('Secondary organizations'),
  data_type:   'autocompletion_ajax',
  data_option: {
    multiple:      true,
    nulloption:    true,
    null:          true,
    relation:      'Organization',
    item_class:    'formGroup--halfSize',
    display_limit: 3,
    belongs_to:    'secondary_organizations',
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {
      '-all-' => {
        null: true,
      },
    },
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    901,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'department',
  display:     __('Department'),
  data_type:   'input',
  data_option: {
    type:       'text',
    maxlength:  200,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    true,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1000,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'street',
  display:     __('Street'),
  data_type:   'input',
  data_option: {
    type:      'text',
    maxlength: 100,
    null:      true,
  },
  editable:    true,
  active:      false,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1100,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'zip',
  display:     __('Zip'),
  data_type:   'input',
  data_option: {
    type:       'text',
    maxlength:  100,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    true,
  active:      false,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1200,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'city',
  display:     __('City'),
  data_type:   'input',
  data_option: {
    type:       'text',
    maxlength:  100,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    true,
  active:      false,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1300,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'country',
  display:     __('Country'),
  data_type:   'input',
  data_option: {
    type:       'text',
    maxlength:  100,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    true,
  active:      false,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1325,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'address',
  display:     __('Address'),
  data_type:   'textarea',
  data_option: {
    type:       'text',
    maxlength:  500,
    rows:       4,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    true,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1350,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'password',
  display:     __('Password'),
  data_type:   'input',
  data_option: {
    type:         'password',
    # password length is capped at 1000 in PasswordPolicy::MaxLength::MAX_LENGTH
    # if user copy-pastes a very long string
    # this ensures that max length check is triggered preventing saving of truncated password
    maxlength:    1001,
    null:         true,
    autocomplete: 'new-password',
    item_class:   'formGroup--halfSize',
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {
      '-all-' => {
        null: false,
      },
    },
    invite_agent:    {},
    invite_customer: {},
    edit:            {
      'admin.user' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {}
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1400,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'vip',
  display:     __('VIP'),
  data_type:   'boolean',
  data_option: {
    null:       true,
    default:    false,
    item_class: 'formGroup--halfSize',
    options:    {
      false: 'no',
      true:  'yes',
    },
    translate:  true,
    permission: ['admin.user', 'ticket.agent'],
  },
  editable:    false,
  active:      true,
  screens:     {
    edit:   {
      '-all-' => {
        null: true,
      },
    },
    create: {
      '-all-' => {
        null: true,
      },
    },
    view:   {
      '-all-' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1490,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'note',
  display:     __('Note'),
  data_type:   'richtext',
  data_option: {
    type:      'text',
    maxlength: 5000,
    no_images: true,
    null:      true,
    note:      __('Notes are visible to agents only, never to customers.'),
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {
      '-all-' => {
        null: true,
      },
    },
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1500,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'role_ids',
  display:     __('Roles'),
  data_type:   'user_permission',
  data_option: {
    relation:   'Role',
    null:       false,
    item_class: 'checkbox',
    permission: ['admin.user'],
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {
      '-all-' => {
        null:    false,
        default: [Role.lookup(name: 'Agent').id],
      },
    },
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1600,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'group_ids',
  display:     __('Group permissions'),
  data_type:   'group_permissions',
  data_option: {
    null:       false,
    item_class: 'checkbox',
    permission: ['admin.user'],
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {
      '-all-' => {
        null: true,
      },
    },
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: true,
      },
    },
    create:          {
      '-all-' => {
        null: true,
      },
    },
    view:            {
      '-all-' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1700,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'User',
  name:        'active',
  display:     __('Active'),
  data_type:   'active',
  data_option: {
    null:       true,
    default:    true,
    permission: ['admin.user', 'ticket.agent'],
  },
  editable:    false,
  active:      true,
  screens:     {
    signup:          {},
    invite_agent:    {},
    invite_customer: {},
    edit:            {
      '-all-' => {
        null: false,
      },
    },
    create:          {
      '-all-' => {
        null: false,
      },
    },
    view:            {
      '-all-' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1800,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Organization',
  name:        'name',
  display:     __('Name'),
  data_type:   'input',
  data_option: {
    type:       'text',
    maxlength:  150,
    null:       false,
    item_class: 'formGroup--halfSize',
  },
  editable:    false,
  active:      true,
  screens:     {
    edit:   {
      '-all-' => {
        null: false,
      },
    },
    create: {
      '-all-' => {
        null: false,
      },
    },
    view:   {
      'ticket.agent'    => {
        shown: true,
      },
      'ticket.customer' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    200,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Organization',
  name:        'shared',
  display:     __('Shared organization'),
  data_type:   'boolean',
  data_option: {
    null:       true,
    default:    true,
    note:       __("Customers in the organization can view each other's items."),
    item_class: 'formGroup--halfSize',
    options:    {
      true:  'yes',
      false: 'no',
    },
    translate:  true,
    permission: ['admin.organization'],
  },
  editable:    false,
  active:      true,
  screens:     {
    edit:   {
      '-all-' => {
        null: false,
      },
    },
    create: {
      '-all-' => {
        null: false,
      },
    },
    view:   {
      'ticket.agent'    => {
        shown: true,
      },
      'ticket.customer' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1400,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Organization',
  name:        'domain_assignment',
  display:     __('Domain based assignment'),
  data_type:   'boolean',
  data_option: {
    null:       true,
    default:    false,
    note:       __('Assign users based on user domain.'),
    item_class: 'formGroup--halfSize',
    options:    {
      true:  'yes',
      false: 'no',
    },
    translate:  true,
    permission: ['admin.organization'],
  },
  editable:    false,
  active:      true,
  screens:     {
    edit:   {
      '-all-' => {
        null: false,
      },
    },
    create: {
      '-all-' => {
        null: false,
      },
    },
    view:   {
      'ticket.agent'    => {
        shown: true,
      },
      'ticket.customer' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1410,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Organization',
  name:        'domain',
  display:     __('Domain'),
  data_type:   'input',
  data_option: {
    type:       'text',
    maxlength:  150,
    null:       true,
    item_class: 'formGroup--halfSize',
  },
  editable:    false,
  active:      true,
  screens:     {
    edit:   {
      '-all-' => {
        null: true,
      },
    },
    create: {
      '-all-' => {
        null: true,
      },
    },
    view:   {
      'ticket.agent'    => {
        shown: true,
      },
      'ticket.customer' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1420,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Organization',
  name:        'vip',
  display:     __('VIP'),
  data_type:   'boolean',
  data_option: {
    null:       true,
    default:    false,
    item_class: 'formGroup--halfSize',
    options:    {
      false: 'no',
      true:  'yes',
    },
    translate:  true,
    permission: ['admin.organization'],
  },
  editable:    false,
  active:      true,
  screens:     {
    edit:   {
      '-all-' => {
        null: true,
      },
    },
    create: {
      '-all-' => {
        null: true,
      },
    },
    view:   {
      '-all-' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1450,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Organization',
  name:        'note',
  display:     __('Note'),
  data_type:   'richtext',
  data_option: {
    type:      'text',
    maxlength: 5000,
    no_images: true,
    null:      true,
    note:      __('Notes are visible to agents only, never to customers.'),
  },
  editable:    false,
  active:      true,
  screens:     {
    edit:   {
      '-all-' => {
        null: true,
      },
    },
    create: {
      '-all-' => {
        null: true,
      },
    },
    view:   {
      'ticket.agent'    => {
        shown: true,
      },
      'ticket.customer' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1500,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Organization',
  name:        'active',
  display:     __('Active'),
  data_type:   'active',
  data_option: {
    null:       true,
    default:    true,
    permission: ['admin.organization'],
  },
  editable:    false,
  active:      true,
  screens:     {
    edit:   {
      '-all-' => {
        null: false,
      },
    },
    create: {
      '-all-' => {
        null: false,
      },
    },
    view:   {
      'ticket.agent'    => {
        shown: false,
      },
      'ticket.customer' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1800,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Group',
  name:        'name',
  display:     __('Name'),
  data_type:   'input',
  data_option: {
    type:      'text',
    maxlength: 255,
    readonly:  1,
  },
  editable:    false,
  active:      true,
  screens:     {},
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    200,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Group',
  name:        'name_last',
  display:     __('Name'),
  data_type:   'input',
  data_option: {
    type:      'text',
    maxlength: 160,
    null:      false,
  },
  editable:    false,
  active:      true,
  screens:     {
    create: {
      '-all-' => {
        null: false,
      },
    },
    edit:   {
      '-all-' => {
        null: false,
      },
    },
    view:   {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    210,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Group',
  name:        'parent_id',
  display:     __('Parent group'),
  data_type:   'tree_select',
  data_option: {
    default:    '',
    null:       true,
    relation:   'Group',
    nulloption: true,
    do_not_log: true,
  },
  editable:    false,
  active:      true,
  screens:     {
    create: {
      '-all-' => {
        null: true,
      },
    },
    edit:   {
      '-all-' => {
        null: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    250,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Group',
  name:        'assignment_timeout',
  display:     __('Assignment Timeout'),
  data_type:   'integer',
  data_option: {
    maxlength: 150,
    null:      true,
    note:      __('Assignment timeout in minutes if assigned agent is not working on it. Ticket will be shown as unassigend.'),
    min:       0,
    max:       999_999,
  },
  editable:    false,
  active:      true,
  screens:     {
    create: {
      '-all-' => {
        null: true,
      },
    },
    edit:   {
      '-all-' => {
        null: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    300,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Group',
  name:        'follow_up_possible',
  display:     __('Follow-up possible'),
  data_type:   'select',
  data_option: {
    default:   'yes',
    options:   {
      yes:                           __('yes'),
      new_ticket:                    __('do not reopen ticket but create new ticket'),
      new_ticket_after_certain_time: __('do not reopen ticket after certain time but create new ticket'),
    },
    null:      false,
    note:      __('Follow-up for closed ticket possible or not.'),
    translate: true
  },
  editable:    false,
  active:      true,
  screens:     {
    create: {
      '-all-' => {
        null: false,
      },
    },
    edit:   {
      '-all-' => {
        null: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    400,
)

ObjectManager::Attribute.add(
  force:         true,
  object:        'Group',
  name:          'reopen_time_in_days',
  display:       __('Reopening time in days'),
  data_type:     'integer',
  data_option:   {
    default:   '',
    min:       1,
    max:       3650,
    null:      true,
    note:      __('Allow reopening of tickets within a certain time.'),
    translate: true
  },
  editable:      false,
  active:        true,
  screens:       {
    create: { 'admin.group': { shown: false, required: false } },
    edit:   { 'admin.group': { shown: false, required: false } },
    view:   { 'admin.group': { shown: false } }
  },
  to_create:     false,
  to_migrate:    false,
  to_delete:     false,
  position:      410,
  created_by_id: 1,
  updated_by_id: 1,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Group',
  name:        'follow_up_assignment',
  display:     __('Assign Follow-Ups'),
  data_type:   'select',
  data_option: {
    default:   'true',
    options:   {
      true:  'yes',
      false: 'no',
    },
    null:      false,
    note:      __('Assign follow-up to latest agent again.'),
    translate: true
  },
  editable:    false,
  active:      true,
  screens:     {
    create: {
      '-all-' => {
        null: false,
      },
    },
    edit:   {
      '-all-' => {
        null: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    500,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Group',
  name:        'email_address_id',
  display:     __('Sending Email Address'),
  data_type:   'select',
  data_option: {
    default:    '',
    multiple:   false,
    null:       true,
    relation:   'EmailAddress',
    nulloption: true,
    do_not_log: true,
    note:       __("A group's email address determines which address should be used for outgoing mails, e.g. when an agent is composing an email or a trigger is sending an auto-reply"),
  },
  editable:    false,
  active:      true,
  screens:     {
    create: {
      '-all-' => {
        null: true,
      },
    },
    edit:   {
      '-all-' => {
        null: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    600,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Group',
  name:        'signature_id',
  display:     __('Signature'),
  data_type:   'select',
  data_option: {
    default:    '',
    multiple:   false,
    null:       true,
    relation:   'Signature',
    nulloption: true,
    do_not_log: true,
  },
  editable:    false,
  active:      true,
  screens:     {
    create: {
      '-all-' => {
        null: true,
      },
    },
    edit:   {
      '-all-' => {
        null: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    600,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Group',
  name:        'shared_drafts',
  display:     __('Shared Drafts'),
  data_type:   'active',
  data_option: {
    null:       false,
    default:    true,
    permission: ['admin.group'],
  },
  editable:    false,
  active:      true,
  screens:     {
    create: {
      '-all-' => {
        null: true,
      },
    },
    edit:   {
      '-all-': {
        null: false,
      },
    },
    view:   {
      '-all-' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1400,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Group',
  name:        'note',
  display:     __('Note'),
  data_type:   'richtext',
  data_option: {
    type:      'text',
    maxlength: 250,
    no_images: true,
    null:      true,
    note:      __('Notes are visible to agents only, never to customers.'),
  },
  editable:    false,
  active:      true,
  screens:     {
    create: {
      '-all-' => {
        null: true,
      },
    },
    edit:   {
      '-all-' => {
        null: true,
      },
    },
    view:   {
      '-all-' => {
        shown: true,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1500,
)

ObjectManager::Attribute.add(
  force:       true,
  object:      'Group',
  name:        'active',
  display:     __('Active'),
  data_type:   'active',
  data_option: {
    null:       true,
    default:    true,
    permission: ['admin.group'],
  },
  editable:    false,
  active:      true,
  screens:     {
    create: {
      '-all-' => {
        null: true,
      },
    },
    edit:   {
      '-all-': {
        null: false,
      },
    },
    view:   {
      '-all-' => {
        shown: false,
      },
    },
  },
  to_create:   false,
  to_migrate:  false,
  to_delete:   false,
  position:    1800,
)
