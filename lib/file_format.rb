require 'json'
require 'yaml'

class FileFormat
  class FormatJSON
    def self.extension
      ".json"
    end

    def self.parse(content)
      JSON.parse(content)
    end

    def self.generate(data)
      JSON.pretty_generate(data)
    end
  end

  class FormatYAML
    def self.extension
      ".yaml"
    end

    def self.parse(content)
      YAML.load(content)
    end

    def self.generate(data)
      data.to_yaml
    end
  end

  EXTENSIONS = {
    ".yaml" => FormatYAML,
    ".yml"  => FormatYAML,
    ".json" => FormatJSON,
  }.freeze

  def self.for_file(path)
    ext = File.extname(path)
    EXTENSIONS.fetch(ext) { fail("Extension #{ext} not supported") }
  end
end
