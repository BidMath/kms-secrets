require "google/apis/cloudkms_v1"
require "base64"

module Gcloud
  class KMS
    Cloudkms = Google::Apis::CloudkmsV1

    def initialize(
      project:,
      location: 'global',
      key_ring:,
      key_name:,
      create_keys: false
    )
      @project = project
      @location = location
      @key_ring = key_ring
      @key_name = key_name
    end

    def encrypt(content)
      with_retries do
        ensure_key_exists!

        request = Cloudkms::EncryptRequest.new(plaintext: content)
        response = kms_client.encrypt_crypto_key(key_path, request)
        Base64.strict_encode64(response.ciphertext)
      end
    end

    def decrypt(content)
      with_retries do
        ciphertext = Base64.decode64(content)
        request = Cloudkms::DecryptRequest.new(ciphertext: ciphertext)
        response = kms_client.decrypt_crypto_key(key_path, request)
        response.plaintext
      end
    end

    def kms_client
      Thread.current[:kms_client] ||= create_kms_client
    end

    def create_kms_client
      Cloudkms::CloudKMSService.new.tap { |kms_client|
        kms_client.authorization = Google::Auth.get_application_default(
          "https://www.googleapis.com/auth/cloud-platform"
        )
        kms_client.request_options.retries = 3
      }
    end

    def create_key_ring!
      ignore_already_exists_error do
        kms_client.create_project_location_key_ring(
          location_path,
          Cloudkms::KeyRing.new,
          key_ring_id: @key_ring
        )
        puts "Created key ring #{key_ring_path}"
      end
    end

    def create_key!
      ignore_already_exists_error do
        kms_client.create_project_location_key_ring_crypto_key(
          key_ring_path,
          Cloudkms::CryptoKey.new(purpose: "ENCRYPT_DECRYPT"),
          crypto_key_id: @key_name
        )
        puts "Created key #{key_path}"
      end
    end

    def ensure_key_exists!
      create_key_ring!
      create_key!
    end

    def location_path
      ["projects", @project, "locations", @location].join("/")
    end

    def key_ring_path
      [location_path, "keyRings", @key_ring].join("/")
    end

    def key_path
      [key_ring_path, "cryptoKeys", @key_name].join("/")
    end

    def with_retries(n = 5)
      yield
    rescue => e
      if n > 0
        puts "retrying #{e}; left #{n}"
        with_retries(n - 1) { yield }
      else
        raise(e)
      end
    end

    def ignore_already_exists_error
      yield
    rescue Google::Apis::ClientError => e
      unless e.message =~ /alreadyExists/
        raise(e)
      end
    end
  end
end
