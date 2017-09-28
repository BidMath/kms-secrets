require 'erb'

class Template
  def initialize(tempate_path)
    @template = ERB.new(File.read(tempate_path))
  end

  def interpolate(data)
    # for shortness
    d = data
    @template.result(binding)
  end
end
