#  Zammad Localization

## Zammad GUI Translations - `i18n/*.po`

Zammad translations are managed exclusively via [translations.zammad.org](https://translations.zammad.org/).

You are welcome to contribute. Please get a free account there if you want to do so.

Any pull requests modifying translation files directly will be rejected.

## Zammad Text Modules - `i18n/text_modules/*.yml`

Zammad text modules are automatically imported when the first admin user is created, according to this user's language.
This is just meant to provide for a smooth start with some existing helpful text modules. They can be modified later on;
no subsequent import from the example files will be performed.

Feel free to send pull requests to add more helpful examples to existing files or even files for new languages.

## Zammad Chat - `public/assets/chat`

The Zammad chat currently has its own build pipeline and also a custom translation handling.
Messages and translations are directly baked into [chat.coffee](../public/assets/chat/chat.coffee) and have to be maintained
there.

## Zammad Notification Templates - `app/views/mailer/*`

Zammad contains a number of different notification templates which are currently stored directly in language-specific `ERB`
template files. Modifications of existing or addition of new translations must be made in these files directly.

# Developer Workflows

## Weblate Process Overview

- The codebase has a translation catalog file [i18n/zammad.pot](zammad.pot), which must be kept up-to-date.
- Weblate automatically picks this file up from git and updates its database. Now translators see the new/changed strings and can work on them.
- From time to time, Weblate pushes the new/updated translations via merge request to git.
- After the merge, the translation files in `i18n/zammad.*.po` are updated.
- Zammad will pick them up as soon as `Translation.sync` gets called, which happens for example during a package update.

## Updating the Source String Catalog

If changes to translatable strings are made during the development process, developers can just run the following to
re-extract the strings to the catalog file:

`rails generate translation_catalog`

This will update the `i18n/zammad.pot` file in Zammad. To do this for an existing addon module, call

`rails generate translation_catalog --addon-path /path/to/addon`

## Testing Translation Changes from Weblate

To test any changes made to translations in Weblate that are not yet published to Zammad,
you can use this workflow:

- Download the current state of the language from Weblate as po file.
- Save it locally in the Zammad folder as `i18n/zammad.pt-br.po` (for `pt-br` in this case, use corresponding file names for other languages).
- Run `rails r Translation.sync` to import the latest state to the database.
- Now the changes should appear in the GUI.

## Known Issues With Localization

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

#### Enable Translation For a Dropdown

```ruby
> obj = ObjectManager::Attribute.find_by(name: 'group_id')
=> #<ObjectManager::Attribute:0x0000564593325508
 id: 4,
 object_lookup_id: 2,
 name: "group_id",
 display: "Group",
 data_type: "select",
 data_option:
  {"default"=>"",
   "relation"=>"Group",
   "relation_condition"=>{"access"=>"full"},
   "nulloption"=>true,
   "multiple"=>false,
   "null"=>false,
   "translate"=>false,
   "only_shown_if_selectable"=>true,
   "permission"=>["ticket.agent", "ticket.customer"],
   "maxlength"=>255},
 data_option_new: {},
 editable: false,
 active: true,
 screens: {"create_middle"=>{"-all-"=>{"null"=>false, "item_class"=>"column"}}, "edit"=>{"ticket.agent"=>{"null"=>false}}},
 to_create: false,
 to_migrate: false,
 to_delete: false,
 to_config: false,
 position: 25,
 created_by_id: 1,
 updated_by_id: 1,
 created_at: Thu, 10 Jun 2021 09:45:30 UTC +00:00,
 updated_at: Thu, 10 Jun 2021 09:45:30 UTC +00:00>

[34] pry(main)> obj.data_option['translate'] = true
=> true
[35] pry(main)> obj.save
=> true
```