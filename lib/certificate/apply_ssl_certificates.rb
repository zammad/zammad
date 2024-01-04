# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Certificate::ApplySSLCertificates

  class << self

    SEMAPHORE = Thread::Mutex.new

    # Ensure the SSLContext for the current process has all custom SSL certificates.
    def ensure_fresh_ssl_context

      SEMAPHORE.synchronize do

        all_certificates = SSLCertificate.all

        # Only update the default store if there are changes with the stored SSL certificates.
        cache_key = all_certificates.cache_key_with_version
        return if @cache_key == cache_key

        @cache_key = cache_key

        # Build a new default store.
        store = OpenSSL::X509::Store.new
        store.set_default_paths
        store.flags = OpenSSL::X509::V_FLAG_CRL_CHECK_ALL
        all_certificates.each { |cert| store.add_cert(cert.certificate_parsed) }
        Kernel.silence_warnings do
          OpenSSL::SSL::SSLContext.const_set(:DEFAULT_CERT_STORE, store)
        end
      end
    end
  end
end
