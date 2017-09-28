module Traversers
  class Traverser
    def update_values(v, &block)
      if v.is_a?(Hash)
        traverse_map(v, &block)
      elsif v.is_a?(Array)
        traverse_array(v, &block)
      else
        block.call(v)
      end
    end

    private

    def traverse_array(e, &block)
      e.map { |v| update_values(v, &block) }
    end

    def traverse_map(e, &block)
      e.map { |k, v|
        [k, update_values(v, &block)]
      }.to_h
    end
  end
end
