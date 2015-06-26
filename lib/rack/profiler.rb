require 'objspace'
require 'yajl'
require 'json'
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

      dumper = Thread.new { dump_allocations(env) }
      dumper.join unless @async

      result
    end

    def dump_allocations(env)
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
        parse_dump(input: read, key: request_id(request: env, pid: Process.ppid))
        read.close
      end
    end

    def parse_dump(input:, key:, run: ->(id, obj) { store_object(id, obj) })
      parser = Yajl::Parser.new
      parser.on_parse_complete = lambda do |obj|
        run.call(key, obj)
      end
      parser.parse(input)
    end

    def store_object(request_id, obj)
      object_id = obj.delete('address')
      if object_id
        obj.each do |attr, value|
          @store["#{request_id}-#{object_id}-#{attr}"] = value.to_json.gsub(/^"(.*)"$/, '\1')
        end
      end
    end

    def request_id(request:, pid:, time: Time)
      timestamp = time.now.to_i
      request_path = request['PATH_INFO'].tr_s(::File::SEPARATOR, '-').sub!(/^-/, '').downcase
      request_method = request['REQUEST_METHOD'].downcase
      random_salt = SecureRandom.hex(4)
      "#{pid}-#{timestamp}-#{request_path}-#{request_method}-#{random_salt}"
    end
  end
end
