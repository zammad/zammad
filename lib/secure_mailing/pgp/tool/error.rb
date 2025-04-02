# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module SecureMailing::PGP::Tool::Error

  def self.exception(code)
    {
      'NODATA'     => SecureMailing::PGP::Tool::Error::NoData,
      'NO_SECKEY'  => SecureMailing::PGP::Tool::Error::NoSecretKey,
      'NO_PUBKEY'  => SecureMailing::PGP::Tool::Error::NoPublicKey,
      'KEYEXPIRED' => SecureMailing::PGP::Tool::Error::ExpiredKey,
      'KEYREVOKED' => SecureMailing::PGP::Tool::Error::RevokedKey,
      'EXPSIG'     => SecureMailing::PGP::Tool::Error::ExpiredSignature,
      'BADSIG'     => SecureMailing::PGP::Tool::Error::BadSignature,
      'EXPKEYSIG'  => SecureMailing::PGP::Tool::Error::ExpiredKeySignature,
      'REVKEYSIG'  => SecureMailing::PGP::Tool::Error::RevokedKeySignature,
      'INV_RECP'   => SecureMailing::PGP::Tool::Error::InvalidRecipient,
      'INV_SGNR'   => SecureMailing::PGP::Tool::Error::InvalidSigner,
      'NO_RECP'    => SecureMailing::PGP::Tool::Error::NoRecipient,
      'NO_SGNR'    => SecureMailing::PGP::Tool::Error::NoSigner,
    }[code]
  end

  class SecureMailing::PGP::Tool::Error::NoData < StandardError
    def initialize(info)
      msg = __('There was no valid OpenPGP data found.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::NoSecretKey < StandardError
    def initialize(info)
      msg = __('There was no secret PGP key found.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::NoPublicKey < StandardError
    def initialize(info)
      msg = __('There was no public PGP key found.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::ExpiredKey < StandardError
    def initialize(info)
      msg = __('The PGP key has expired.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::RevokedKey < StandardError
    def initialize(info)
      msg = __('The PGP key has been revoked.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::ExpiredSignature < StandardError
    def initialize(info)
      msg = __('The PGP signature has expired.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::BadSignature < StandardError
    def initialize(info)
      msg = __('The PGP signature is invalid.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::ExpiredKeySignature < StandardError
    def initialize(info)
      msg = __('The signature PGP key has expired.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::RevokedKeySignature < StandardError
    def initialize(info)
      msg = __('The PGP signature key has been revoked.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::InvalidRecipient < StandardError
    def initialize(info)
      msg = __('The PGP email recipient is invalid.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::InvalidSigner < StandardError
    def initialize(info)
      msg = __('The PGP email signer is invalid.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::NoRecipient < StandardError
    def initialize(info)
      msg = __('There is no valid PGP email recipient.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::NoSigner < StandardError
    def initialize(info)
      msg = __('There is no valid PGP email signer.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::BadPassphrase < StandardError
    def initialize(info)
      msg = __('The PGP passphrase is invalid.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::NoPassphrase < StandardError
    def initialize(info)
      msg = __('The required PGP passphrase is missing.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end

  class SecureMailing::PGP::Tool::Error::UnknownError < StandardError
    def initialize(info)
      msg = __('There was an unknown PGP error.')
      msg = "#{msg} #{info}" if info.present?

      super(msg)
    end
  end
end
