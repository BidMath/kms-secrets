require 'parallel'
require 'thread'

module Traversers
  class ParallelTraverser
    THREAD_COUNT = 4

    def initialize(pb_params = {})
      @pb_params = pb_params
    end

    def update_values(v, &block)
      values = {}
      traverser = Traverser.new
      traverser.update_values(v) { |e| values[e] = true; e }

      to_process = values.keys.shuffle

      progressbar_params = { total: to_process.size }.merge(@pb_params)
      progressbar = ProgressBar.create(progressbar_params)

      # shuffle to avoid running big chunks that are often in the end of file
      # simultaneously, which causes KMS API to fail

      res = Parallel.map(to_process, in_threads: THREAD_COUNT) do |k|
        el = [k, block.call(k)]
        progressbar.increment
        el
      end.to_h

      traverser.update_values(v, &res)
    end
  end
end
