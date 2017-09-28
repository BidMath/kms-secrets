require "base64"

class Encryption
  def initialize(engine_params)
    @engine = make_engine(engine_params)
    setup_cache
  end

  def encrypt(value)
    return @cache_encrypt[value] if @cache_encrypt.key?(value)

    encrypted = @engine.encrypt(value)
    populate_cache(enc_value: encrypted, dec_value: value)
    encrypted
  end

  def decrypt(value)
    return @cache_decrypt[value] if @cache_decrypt.key?(value)

    decrypted = @engine.decrypt(value)
    populate_cache(enc_value: value, dec_value: decrypted)
    decrypted
  end

  private

  def populate_cache(dec_value:, enc_value:)
    @cache_decrypt[enc_value] = dec_value
    @cache_encrypt[dec_value] = enc_value
  end

  def make_engine(params)
    engine_type = params["engine_type"]
    fail("Engine type not supported: #{params}") if engine_type != "gcloud_kms"

    Gcloud::KMS.new(
      project: params["project"],
      key_ring: params["key_ring"],
      key_name: params["key_name"],
      create_keys: params["create_keys"]
    )
  end

  def setup_cache
    @cache_encrypt = {}
    @cache_decrypt = {}

    populate_cache(enc_value: true, dec_value: true)
    populate_cache(enc_value: false, dec_value: false)
  end
end
