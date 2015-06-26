require 'objspace'
require 'yajl'
require 'securerandom'

module Rack
  class Profiler
    def initialize(app, store:, async: true, object_space: ObjectSpace)
      @app = app
      @store = store
      @async = async
      @object_space = object_space
      @object_space.trace_object_allocations_start
    end

    def call(env)
      result = @app.call(env)

      dumper = Thread.new { dump_allocations }
      dumper.join unless @async

      result
    end

    def dump_allocations
      read, write = IO.pipe

      if pid = fork
        # parent
        read.close
        GC.start
        @object_space.dump_all(output: write)
        write.close
        Process.wait(pid) unless @async
      else
        # child
        write.close
        parse_dump(input: read)
        read.close
      end
    end

    def parse_dump(input:, key: request_id, run: ->(id, obj) { store_object(id, obj) })
      parser = Yajl::Parser.new
      parser.on_parse_complete = lambda do |obj|
        run.call(key, obj)
      end
      parser.parse(input)
    end

    def store_object(request_id, obj)
      object_id = obj.delete('address')
      @store["#{request_id}-#{object_id}"] = obj if object_id
    end

    def request_id
      thread_id = Thread.current.object_id
      random_salt = SecureRandom.hex(4)
      "#{thread_id}-#{random_salt}"
    end
  end
end
