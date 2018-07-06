class CheckForObjectAttributes < ActiveRecord::Migration[5.1]
  def change
    return if !Setting.find_by(name: 'system_init_done')

    attributes.each do |attribute|

      fix_nil_data_option(attribute)
      fix_options(attribute)
      fix_relation(attribute)

      next if !attribute.changed?

      attribute.save!
    end
  end

  private

  def attributes
    ObjectManager::Attribute.all
  end

  def fix_nil_data_option(attribute)
    return if attribute[:data_option].is_a?(Hash) || attribute[:data_option][:options].is_a?(Array)
    attribute[:data_option] = {}
  end

  def fix_options(attribute)
    return if attribute[:data_option][:options].is_a?(Hash)
    return if attribute[:data_option][:options].is_a?(Array)
    attribute[:data_option][:options] = {}
  end

  def fix_relation(attribute)
    return if attribute[:data_option][:relation].is_a?(String)
    attribute[:data_option][:relation] = ''
  end
end
