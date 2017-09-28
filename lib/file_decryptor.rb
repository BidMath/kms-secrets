class FileDecryptor
  attr_reader :encryption, :metadata, :file_format

  def initialize(file_format:, path:, traverser:, encryption: nil)
    @path = path
    @traverser = traverser
    @file_format = file_format

    content = file_format.parse(File.read(path))
    @metadata = content.fetch("metadata")
    @encrypted_data = content.fetch("data")
    @encryption = encryption || Encryption.new(metadata)
  end

  def content_same_as_in?(path)
    return false unless File.exist?(path)

    calculated = FileEncryptor.checksum(File.read(path))
    from_metadata = @metadata["checksum"]

    calculated == from_metadata
  end

  def decrypted_as_format
    decrypted_content = file_format.generate(decrypted)
    validate_checksum!(decrypted_content)
    decrypted_content
  end

  def decrypted_as_hash
    decrypted
  end

  def validate_checksum!(decrypted_content)
    calculated = FileEncryptor.checksum(decrypted_content)
    from_metadata = @metadata["checksum"]

    fail("Checksums don't match") unless calculated == from_metadata
  end

  private

  def decrypted
    @traverser.update_values(@encrypted_data) { |v| @encryption.decrypt(v) }
  end
end
