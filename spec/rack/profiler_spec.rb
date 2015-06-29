require 'spec_helper'
require 'support/rack_helpers'
require 'support/object_space_helpers'
require 'support/fake_store_helpers'
require 'support/time_helpers'
require 'support/rack_matchers'
require 'rack/mock'
require 'securerandom'

describe Rack::Profiler do
  include RackHelpers
  include ObjectSpaceHelpers
  include FakeStoreHelpers
  include TimeHelpers

  let(:env) { [418, { 'Content-Type' => 'text/plain', 'Content-Length' => '12' }, ["I'm a teapot"]] }
  let(:app) { ->(_) { env } }
  let(:store) { Hash.new }
  let(:middleware) { described_class.new(app, store: store, async: false, object_space: objects) }

  let(:object_data) do
    <<-STR
      {"address":"0x7f930a8203a8", "type":"ARRAY"}
    STR
  end
  let(:objects) { object_space(object_data) }

  describe '#call' do
    it 'does not modify the response from the app' do
      expect(response(middleware, '/endpoint')).to match_response(response(middleware, '/endpoint'))
    end

    context 'with real data' do
      let(:object_data) do
        <<-STR
          {"address":"0x7f930a820650", "type":"ARRAY"}
          {"address":"0x7f930a8206c8", "type":"OBJECT"}
        STR
      end
      let(:store_id) { SecureRandom.uuid }
      let(:store) { fake_store(store_id) }

      it 'saves every object in the object space to the store' do
        response(middleware, '/endpoint')
        expect(fake_store_keys(store_id).map { |k| store[k] }).to match_array(['ARRAY', 'OBJECT'])
      end
    end
  end

  describe '#request_id' do
    it 'returns a unique string every time' do
      request_ids = 2.times.map do
        middleware.request_id(request: request('/endpoint'), pid: 12345)
      end
      expect(request_ids.first).to_not eq(request_ids.last)
    end

    it 'includes the process id, timestamp, request path and method' do
      expect(middleware.request_id(request: request('/my/api/endpoint', method: 'GET'), pid: 12345, time: time(Time.at(1435347800)))).to start_with('rack-profiler-12345-1435347800-my-api-endpoint-get')
    end
  end

  describe '#store_object' do
    it 'store each property separately in a key containing the address and property name' do
      expect {
        middleware.store_object('key', 'address' => '0x7f930a820010', 'type' => 'OBJECT', 'flags' => { 'marked' => true })
      }.to change {
        [store['key-0x7f930a820010-type'], store['key-0x7f930a820010-flags']]
      }.from([nil, nil]).to(['OBJECT', '{"marked":true}'])
    end

    it 'stores nothing if there is no address property' do
      expect {
        middleware.store_object('key', 'type' => 'OBJECT')
      }.to_not change {
        store.keys
      }.from([])
    end
  end

  describe '#parse_dump' do
    it 'parses the input io stream and calls run for each line (parsed as json)' do
      json = <<-STR
        {"address":"0x7f930a8203a8", "type":"ARRAY"}
        {"address":"0x7f930a820420", "type":"ARRAY"}
      STR
      io = StringIO.new(json)
      calls = []
      processor = ->(id, obj) { calls << [id, obj] }
      middleware.parse_dump(input: io, key: 'key', run: processor)
      expect(calls).to eq([['key', { 'address' => '0x7f930a8203a8', 'type' => 'ARRAY' } ],
                           ['key', { 'address' => '0x7f930a820420', 'type' => 'ARRAY' } ]])
    end
  end
end
