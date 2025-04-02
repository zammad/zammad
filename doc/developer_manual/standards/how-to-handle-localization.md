# How to Handle Localization

## Translations

### Zammad GUI Translations - `i18n/*.po`

Zammad translations are managed exclusively via [translations.zammad.org](https://translations.zammad.org/).

You are welcome to contribute. Please get a free account there if you want to do so.

Any pull requests modifying translation files directly will be rejected.

### Zammad Notification Templates - `app/views/mailer/*` and `app/views/messaging/*`

These back end template files are also managed via [translations.zammad.org](https://translations.zammad.org/).

Translatable strings are extracted from the English templates. Any other languages are automatically generated
from the available translated contents of translations.zammad.org.

Any pull requests modifying translated template files directly will be rejected.

### Zammad Text Modules - `i18n/text_modules/*.yml`

Zammad text modules are automatically imported when the first admin user is created, according to this user's language.
This is just meant to provide for a smooth start with some existing helpful text modules. They can be modified later on;
no subsequent import from the example files will be performed.

Feel free to send pull requests to add more helpful examples to existing files or even files for new languages.

## Developer Workflows

### How to Write Translatable Strings Well

Writing strings that can be translated well and are a pleasure to read for the end user is not always easy.

#### Bad Examples

- `lock` - this English word is ambiguous, it can be a noun (`a lock`), an infinitive (`to lock`) and an imperative
  (`lock this!`). That makes it impossible to translate it properly.
- `No email!` - this error message is not understandable for an end user.

#### Good Practices

- _Talk to the end user._ Imagine you are a non-technical end user of Zammad. Would you understand the error messages?
  Use natural, respectful language.
- _Write at least two words._ Whenever possible, avoid creating single-word strings. This will reduce ambiguity
  drastically.
- _Include punctuation._ Strings should include punctuation like final stops (`This is a sentence.`) or colons
  (`My label:`) as part of the translatable string. This punctuation might look different in some languages and should
  therefore not be hardcoded.
- _Use placeholders, don't concatenate strings._ Bad: `"Open" + ticket_number`, good: `"Open ticket %s"` (and pass
  `ticket_number` as parameter). It's almost always a good idea to produce such slightly longer strings with
  placeholders. That helps translators to understand them and allows them to change the position of the placeholders in
  translations.
- _Personal pronouns only for the user_: When referring to the user, `you` and `my` are fine (`Do you want to proceed?`,
  `My escalated tickets`). Other pronouns should be avoided, especially when talking about the software/system itself.
  Bad: `I / we could not generate the key`. Use the passive (`The key could not be generated`) or talk about `Zammad`
  instead (`Zammad does not support OTRS BPM processes`).

### Weblate Process Overview

- The codebase has a translation catalog file [i18n/zammad.pot](zammad.pot), which must be kept up-to-date.
- Weblate automatically picks this file up from git and updates its database. Now translators see the new/changed
  strings and can work on them.
- From time to time, Weblate pushes the new/updated translations via merge request to git.
- After the merge, the translation files in `i18n/zammad.*.po` are updated.
- Zammad will pick them up as soon as `Translation.sync` gets called, which happens for example during a package update.

### Updating the Source String Catalog

If changes to translatable strings are made during the development process, developers can just run the following to
re-extract the strings to the catalog file:

`rails generate zammad:translation_catalog`

This will update the `i18n/zammad.pot` file in Zammad. To do this for an existing addon module, call

`rails generate zammad:translation_catalog --addon-path /path/to/addon`

To perform additional tasks such as updating template files from translations, use:

`rails generate zammad:translation_catalog --full`

### Testing Translation Changes from Weblate

To test any changes made to translations in Weblate that are not yet published to Zammad,
you can use this workflow:

- Download the current state of the language from Weblate as po file.
- Save it locally in the Zammad folder as `i18n/zammad.pt-br.po` (for `pt-br` in this case, use corresponding file
  names for other languages).
- Run `rails r Translation.sync` to import the latest state to the database.
- Now the changes should appear in the GUI.

### Known Issues With Localization

- There is currently no support for plural forms.

## API & Code Examples

### CoffeeScript

See [i18n.coffee](app/assets/javascripts/app/lib/app_post/i18n.coffee)

#### Translate With Markup Support

```coffeescript
App.i18n.translateContent('translate and <b>html escape</b> and replace _markup_')
```

#### Translate Without Markup Support

```coffeescript
App.i18n.translateInline('translate and <b>html escape</b> and no _markup_')
```

#### Translate Without Escaping

```coffeescript
App.i18n.translatePlain('plain text')
```

#### Translate Datetime

```coffeescript
App.Ticket.find(1).created_at
"2021-06-10T09:45:30.394Z"
App.i18n.translateTimestamp(App.Ticket.find(1).created_at)
"10.06.2021 11:45"
```

#### Translate Date

```coffeescript
App.Ticket.find(1).created_at
"2021-06-10T09:45:30.394Z"
App.i18n.translateDate(App.Ticket.find(1).created_at)
"10.06.2021"
```

### Ruby

#### Translate a String

```ruby
Translation.translate('de-de', '3 high')
"3 hoch"
```

#### Enable Translation For an ObjectAttribute

```ruby
> obj = ObjectManager::Attribute.find_by(name: 'my_attribute')
=> #<ObjectManager::Attribute:0x0000564593325508
...
[34] pry(main)> obj.data_option['translate'] = true
=> true
[35] pry(main)> obj.save
=> true
```
