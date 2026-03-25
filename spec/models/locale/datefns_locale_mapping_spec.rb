# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

SUPPORTED_LOCALES = %w[
  ar
  bg
  ca
  cs
  da
  de-de
  el
  en-ca
  en-gb
  en-us
  es-ca
  es-co
  es-es
  es-mx
  et
  fa-ir
  fi
  fr-ca
  fr-fr
  he-il
  hi-in
  hr
  hu
  id
  is
  it-it
  ja
  ko-kr
  lt
  lv
  ms-my
  nl-nl
  no-no
  pl
  pt-br
  pt-pt
  ro-ro
  ru
  rw
  sk
  sl
  sr-cyrl-rs
  sr-latn-rs
  sv-se
  th
  tr
  uk
  vi
  zh-cn
  zh-tw
].freeze

RSpec.describe 'date-fns locale mapping' do # rubocop:disable Rspec/DescribeClass
  it 'ensures that all locales match the imported date-fns locales' do
    db_locales = Locale.pluck(:locale).sort

    expect(db_locales).to match_array(SUPPORTED_LOCALES), <<~MSG
      Mismatch between database locales and supported date-fns locale imports.

      Missing date-fns imports: #{(db_locales - SUPPORTED_LOCALES).inspect}
      Stale date-fns imports:   #{(SUPPORTED_LOCALES - db_locales).inspect}

      Please update the list of supported locales and the imports in `useDateFnsLocale.ts`.
    MSG
  end
end
