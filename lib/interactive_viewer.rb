require 'tempfile'

class InteractiveViewer
  def initialize(content, ext = 'yaml')
    @ext = ext.sub(".", "")
    @content = content
  end

  def view
    Tempfile.open(['secret', ".#{@ext}"]) do |f|
      f.write(@content)
      f.flush

      system "#{pager} #{f.path}"
    end
  end

  def pager
    ENV["PAGER"] || "vim"
  end
end
