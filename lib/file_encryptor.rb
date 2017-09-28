require 'digest'

class FileEncryptor
  attr_reader :encryption, :metadata, :file_format

  def initialize(
    file_format:,
    traverser:,
    metadata:,
    unencrypted_data:,
    encryption: nil
  )
    @traverser = traverser
    @file_format = file_format

    @metadata = metadata
    @unencrypted_data = unencrypted_data
    @encryption = encryption || Encryption.new(metadata)
  end

  def encrypted_with_meta_as_format
    unencrypted_content = file_format.generate(@unencrypted_data)
    @metadata["checksum"] = self.class.checksum(unencrypted_content)

    file_format.generate("metadata" => @metadata, "data" => encrypted)
  end

  def self.checksum(content)
    Digest::SHA256.hexdigest(content)
  end

  private

  def encrypted
    @traverser.update_values(@unencrypted_data) { |v| @encryption.encrypt(v) }
  end
end
