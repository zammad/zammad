# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# content of this tags will also be removed
Rails.application.config.html_sanitizer_tags_remove_content = %w[
  style
  comment
  meta
]

# content of this tags will will be inserted html quoted
Rails.application.config.html_sanitizer_tags_quote_content = %w[
  script
]

# only this tags are allowed
Rails.application.config.html_sanitizer_tags_whitelist = %w[
  a abbr acronym address area article aside audio
  b bdi bdo big blockquote br
  canvas caption center cite code col colgroup command
  datalist dd del details dfn dir div dl dt em
  figcaption figure footer h1 h2 h3 h4 h5 h6 header hr
  i img ins kbd label legend li map mark menu meter nav
  ol output optgroup option p pre q
  s samp section small span strike strong sub summary sup
  text table tbody td tfoot th thead time tr tt u ul var video
]

# attributes allowed for tags
Rails.application.config.html_sanitizer_attributes_whitelist = {
  :all         => %w[class dir lang title translate data-signature data-signature-id],
  'a'          => %w[href hreflang name rel data-target-id data-target-type data-mention-user-id],
  'abbr'       => %w[title],
  'blockquote' => %w[type cite],
  'col'        => %w[span width],
  'colgroup'   => %w[span width],
  'data'       => %w[value],
  'del'        => %w[cite datetime],
  'dfn'        => %w[title],
  'img'        => %w[align alt border height src srcset width style],
  'ins'        => %w[cite datetime],
  'li'         => %w[value],
  'ol'         => %w[reversed start type],
  'table'      => %w[align bgcolor border cellpadding cellspacing frame rules sortable summary width style],
  'td'         => %w[abbr align axis colspan headers rowspan valign width style],
  'th'         => %w[abbr align axis colspan headers rowspan scope sorted valign width style],
  'tr'         => %w[width style],
  'ul'         => %w[type],
  'q'          => %w[cite],
  'span'       => %w[style],
  'div'        => %w[style],
  'time'       => %w[datetime pubdate],
}

# only this css properties are allowed
Rails.application.config.html_sanitizer_css_properties_whitelist = {
  'img'   => %w[
    width height
    max-width min-width
    max-height min-height
  ],
  'span'  => %w[
    color
  ],
  'div'   => %w[
    color
  ],
  'table' => %w[
    background background-color color font-size vertical-align
    margin margin-top margin-right margin-bottom margin-left
    padding padding-top padding-right padding-bottom padding-left
    text-align
    border border-top border-right border-bottom border-left border-collapse border-style border-spacing

    border-top-width border-right-width border-bottom-width border-left-width
    border-top-color border-right-color border-bottom-color border-left-color
    border-top-style border-right-style border-bottom-style border-left-style
  ],
  'th'    => %w[
    background background-color color font-size vertical-align
    margin margin-top margin-right margin-bottom margin-left
    padding padding-top padding-right padding-bottom padding-left
    text-align
    border border-top border-right border-bottom border-left border-collapse border-style border-spacing

    border-top-width border-right-width border-bottom-width border-left-width
    border-top-color border-right-color border-bottom-color border-left-color
    border-top-style border-right-style border-bottom-style border-left-style
  ],
  'tr'    => %w[
    background background-color color font-size vertical-align
    margin margin-top margin-right margin-bottom margin-left
    padding padding-top padding-right padding-bottom padding-left
    text-align
    border border-top border-right border-bottom border-left border-collapse border-style border-spacing

    border-top-width border-right-width border-bottom-width border-left-width
    border-top-color border-right-color border-bottom-color border-left-color
    border-top-style border-right-style border-bottom-style border-left-style
  ],
  'td'    => %w[
    background background-color color font-size vertical-align
    margin margin-top margin-right margin-bottom margin-left
    padding padding-top padding-right padding-bottom padding-left
    text-align
    border border-top border-right border-bottom border-left border-collapse border-style border-spacing

    border-top-width border-right-width border-bottom-width border-left-width
    border-top-color border-right-color border-bottom-color border-left-color
    border-top-style border-right-style border-bottom-style border-left-style
  ],
}

Rails.application.config.html_sanitizer_css_values_backlist = {
  'div'   => [
    'color:white',
    'color:black',
    'color:#000',
    'color:#000000',
    'color:#fff',
    'color:#ffffff',
    'color:rgb(0,0,0)',
  ],
  'span'  => [
    'color:white',
    'color:black',
    'color:#000',
    'color:#000000',
    'color:#fff',
    'color:#ffffff',
    'color:rgb(0,0,0)',
  ],
  'table' => [
    'font-size:0',
    'font-size:0px',
    'font-size:0em',
    'font-size:0%',
    'font-size:1px',
    'font-size:1em',
    'font-size:1%',
    'font-size:2',
    'font-size:2px',
    'font-size:2em',
    'font-size:2%',
    'font-size:3',
    'font-size:3px',
    'font-size:3em',
    'font-size:3%',
    'display:none',
    'visibility:hidden',
  ],
  'th'    => [
    'font-size:0',
    'font-size:0px',
    'font-size:0em',
    'font-size:0%',
    'font-size:1px',
    'font-size:1em',
    'font-size:1%',
    'font-size:2',
    'font-size:2px',
    'font-size:2em',
    'font-size:2%',
    'font-size:3',
    'font-size:3px',
    'font-size:3em',
    'font-size:3%',
    'display:none',
    'visibility:hidden',
  ],
  'tr'    => [
    'font-size:0',
    'font-size:0px',
    'font-size:0em',
    'font-size:0%',
    'font-size:1',
    'font-size:1px',
    'font-size:1em',
    'font-size:1%',
    'font-size:2',
    'font-size:2px',
    'font-size:2em',
    'font-size:2%',
    'font-size:3',
    'font-size:3px',
    'font-size:3em',
    'font-size:3%',
    'display:none',
    'visibility:hidden',
  ],
  'td'    => [
    'font-size:0',
    'font-size:0px',
    'font-size:0em',
    'font-size:0%',
    'font-size:1px',
    'font-size:1em',
    'font-size:1%',
    'font-size:2',
    'font-size:2px',
    'font-size:2em',
    'font-size:2%',
    'font-size:3',
    'font-size:3px',
    'font-size:3em',
    'font-size:3%',
    'display:none',
    'visibility:hidden',
  ],
}
