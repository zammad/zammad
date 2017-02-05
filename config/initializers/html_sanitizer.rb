
# content of this tags will also be removed
Rails.application.config.html_sanitizer_tags_remove_content = %w(
  style
)

# only this tags are allowed
Rails.application.config.html_sanitizer_tags_whitelist = %w(
  a abbr acronym address area article aside audio
  b bdi bdo big blockquote br
  canvas caption center cite code col colgroup command
  datalist dd del details dfn dir div dl dt em
  figcaption figure footer h1 h2 h3 h4 h5 h6 header hr
  i img ins kbd label legend li map mark menu meter nav
  ol output optgroup option p pre q
  s samp section small span strike strong sub summary sup
  text table tbody td tfoot th thead time tr tt u ul var video
)

# attributes allowed for tags
Rails.application.config.html_sanitizer_attributes_whitelist = {
  :all         => %w(class dir lang style title translate data-signature data-signature-id),
  'a'          => %w(href hreflang name rel),
  'abbr'       => %w(title),
  'blockquote' => %w(cite),
  'col'        => %w(span width),
  'colgroup'   => %w(span width),
  'data'       => %w(value),
  'del'        => %w(cite datetime),
  'dfn'        => %w(title),
  'img'        => %w(align alt border height src srcset width),
  'ins'        => %w(cite datetime),
  'li'         => %w(value),
  'ol'         => %w(reversed start type),
  'table'      => %w(align bgcolor border cellpadding cellspacing frame rules sortable summary width),
  'td'         => %w(abbr align axis colspan headers rowspan valign width),
  'th'         => %w(abbr align axis colspan headers rowspan scope sorted valign width),
  'ul'         => %w(type),
  'q'          => %w(cite),
  'time'       => %w(datetime pubdate),
}

# only this css properties are allowed
Rails.application.config.html_sanitizer_css_properties_whitelist = %w(
  width height
  max-width min-width
  max-height min-height
)
