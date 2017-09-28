require 'tempfile'

class InteractiveEditor
  def initialize(content, ext = '.yaml')
    @ext = ext
    @content = content
  end

  def edit
    Tempfile.open(['secret', "#{@ext}"]) do |f|
      f.write(@content)
      f.flush

      system "#{editor} #{f.path}"

      File.read(f.path)
    end
  end

  def editor
    ENV["EDITOR"] || "vim"
  end
end
