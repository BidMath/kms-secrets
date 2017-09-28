require 'ruby-progressbar'

module Traversers
  class ProgressbarTraverser
    def initialize(pb_params = {})
      @pb_params = pb_params
    end

    def update_values(v, &block)
      total = 0
      traverser = Traverser.new
      traverser.update_values(v) { |e| total += 1; e }

      progressbar = ProgressBar.create({total: total}.merge(@pb_params))

      traverser.update_values(v) do |el|
        res = block.call(el)
        progressbar.increment
        res
      end
    end
  end
end
