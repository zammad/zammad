# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::ObjectAttribute::SanitizedName < Sequencer::Unit::Common::Provider::Named
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_action :skipped, :failed

  private

  def sanitized_name
    # model_no
    # model_nos
    # model_name
    # model_name
    # model_name
    # model_name_
    # model_name
    without_double_underscores.gsub(%r{_id(s?)$}, '_no\1')
  end

  def without_double_underscores
    # model_id
    # model_ids
    # model_name
    # model_name
    # model_name
    # model_name_
    # model_name
    only_supported_chars.gsub(%r{_{2,}}, '_')
  end

  def only_supported_chars
    # model_id
    # model_ids
    # model___name
    # model_name
    # model__name
    # model_name_
    # model_name
    downcased.chars.map { |char| char.match?(%r{[a-z0-9_]}) ? char : '_' }.join
  end

  def downcased
    # model id
    # model ids
    # model / name
    # model name
    # model::name
    # model name?
    # model name
    transliterated.downcase
  end

  def transliterated
    # Model ID
    # Model IDs
    # Model / Name
    # Model Name
    # Model::Name
    # Model Name?
    # Model Name
    ::ActiveSupport::Inflector.transliterate(unsanitized_name, '_'.freeze)
  end

  def unsanitized_name
    # Model ID
    # Model IDs
    # Model / Name
    # Model Name
    # Model::Name
    # Model Name?
    # Mödel Nâmé
    raise 'Missing implementation for unsanitized_name method'
  end
end
