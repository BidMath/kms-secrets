require 'bundler/setup'
require 'thor'

Dir["#{__dir__}/lib/**/*.rb"].each(&method(:require))

class CLI < Thor
  desc "edit PATH", "Edit encrypted file"
  def edit(path)
    decryptor = decryptor_from_file(path)
    decrypted_content = decryptor.decrypted_as_format

    editor = InteractiveEditor.new(
      decrypted_content,
      decryptor.file_format.extension
    )
    edited_content = editor.edit

    encryptor = encryptor_from_decryptor(decryptor, edited_content)

    puts "writing new content to #{path}"
    File.write(path, encryptor.encrypted_with_meta_as_format)
    puts "Done!"
  end

  desc "view PATH", "View encrypted file"
  def view(path)
    decryptor = decryptor_from_file(path)
    viewer = InteractiveViewer.new(decryptor.decrypted_as_format)
    viewer.view
  end

  desc "encrypt INPUT_PATH OUTPUT_PATH", "encrypt file to output path"
  method_option(
    :project,
    required: true,
    desc: "Project for the key (eg. my-google-project)"
  )
  method_option(
    :key_ring,
    required: true,
    desc: "Keyring name (eg. my-key-ring)"
  )
  method_option(
    :key_name,
    required: false,
    desc: "Key name. Required if 'generate_key_name' not set"
  )
  method_option(
    :generate_key_name,
    type: :boolean,
    desc: "Required if 'key_name' not provided"
  )

  def encrypt(input_path, output_path)
    encryptor = encryptor_from_params(input_path)
    puts "writing content to #{output_path}"
    File.write(output_path, encryptor.encrypted_with_meta_as_format)
    puts "Done!"
  end

  desc "decrypt INPUT_PATH OUTPUT_PATH", "decrypt file to output path"
  method_option(
    :erb_template,
    required: false,
    desc: ("ERB template to pass data to. " +
           "It will be available as hash 'data' or 'd' with string keys")
  )

  def decrypt(input_path, output_path)
    decryptor = decryptor_from_file(input_path)

    if decryptor.content_same_as_in?(output_path)
      puts "Content the same, not changing"
      return
    end

    puts "Writing content to #{output_path}"

    content = if options[:erb_template]
                Template.new(
                  options[:erb_template]
                ).interpolate(
                  decryptor.decrypted_as_hash
                )
              else
                decryptor.decrypted_as_format
              end

    File.write(output_path, content)
    puts "Done!"
  end

  private

  def encryptor_from_params(path)
    file_format = FileFormat.for_file(path)
    data = file_format.parse(File.read(path))

    FileEncryptor.new(
      file_format: file_format,
      traverser: Traversers::ParallelTraverser.new(title: "Encrypting"),
      metadata: metadata_from_params(path),
      unencrypted_data: data,
    )
  end

  def encryptor_from_decryptor(decryptor, content)
    file_format = decryptor.file_format
    data = file_format.parse(content)

    FileEncryptor.new(
      file_format: file_format,
      traverser: Traversers::ParallelTraverser.new(title: "Re-encrypting"),
      metadata: decryptor.metadata,
      encryption: decryptor.encryption,
      unencrypted_data: data,
    )
  end

  def decryptor_from_file(path)
    file_format = FileFormat.for_file(path)

    FileDecryptor.new(
      file_format: file_format,
      traverser: Traversers::ParallelTraverser.new(title: "Decrypting"),
      path: path
    )
  end

  def metadata_from_params(input_path)
    {
      "project" => options[:project],
      "key_ring" => options[:key_ring],
      "key_name" => get_key_name_from_options(input_path),
      "engine_type" => "gcloud_kms"
    }
  end

  def get_key_name_from_options(input_path)
    return options[:key_name] if options[:key_name]
    return generate_key_name(input_path) if options[:generate_key_name]
    fail("Neither 'key_name' nor 'generate_key_name' options provided")
  end

  def generate_key_name(input_path)
    name = File.basename(input_path, ".*").gsub(/[\W_]/, "-")
    time = Time.now.utc.strftime("%Y%m%d-%H%M%S")

    "#{name}_#{time}"
  end
end

CLI.start(ARGV)
