# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Service
  class SystemAssets
    class ProductLogo
      PRODUCT_LOGO_RESIZED = 2
      PRODUCT_LOGO_RAW     = 1

      def self.sendable_asset
        if (asset = custom_logo)
          return SendableAsset.new(
            content:  asset.content,
            filename: asset.filename,
            type:     asset.preferences['Content-Type']
          )
        end

        SendableAsset.new(
          content:  Rails.public_path.join('assets/images/logo.svg').read,
          filename: 'logo.svg',
          type:     'image/svg+xml'
        )
      end

      def self.store_logo(file)
        clear_all

        store_one PRODUCT_LOGO_RAW, file, 'logo_raw'

        Time.current.to_i
      end

      def self.store(logo, logo_resize)
        raw_preprocessed     = preprocess(logo)
        resized_preprocessed = preprocess(logo_resize)

        return if !raw_preprocessed && !resized_preprocessed

        clear_all

        raw     = store_one PRODUCT_LOGO_RAW,     raw_preprocessed,     'logo_raw'
        resized = store_one PRODUCT_LOGO_RESIZED, resized_preprocessed, 'logo'

        Time.current.to_i if resized || raw
      end

      def self.custom_logo
        [PRODUCT_LOGO_RESIZED, PRODUCT_LOGO_RAW]
          .lazy
          .map { |elem| Store.list(object: 'System::Logo', o_id: elem).first }
          .find(&:present?)
      end
      private_class_method :custom_logo

      def self.preprocess(data)
        return if !data&.match? %r{^data:image}i

        ImageHelper.data_url_attributes(data)
      end
      private_class_method :preprocess

      def self.clear_all
        [PRODUCT_LOGO_RAW, PRODUCT_LOGO_RESIZED].each do |elem|
          Store.remove(object: 'System::Logo', o_id: elem)
        end
      end
      private_class_method :clear_all

      def self.store_one(o_id, file, filename)
        return if !file

        Store.create!(
          object:        'System::Logo',
          o_id:          o_id,
          data:          file[:content],
          filename:      filename,
          preferences:   {
            'Content-Type' => file[:mime_type]
          },
          created_by_id: 1,
        )
      end
      private_class_method :store_one
    end
  end
end
