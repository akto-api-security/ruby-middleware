require 'rdkafka'

require 'json'

module AktoRack
  class AktoMiddleware
    def initialize(app, options = {})
      @app = app
      config = {:"bootstrap.servers" => "<AKTO_NLB_IP>:9092"}
      @producer = Rdkafka::Config.new(config).producer
    end 

    def call(env)
      req = Rack::Request.new(env)
      complex_copy = env.dup

        # Filter hash to only have keys of type string
      complex_copy = complex_copy.select { |k, _v| k.is_a? String }

      req_headers = {}
      complex_copy.select { |k, _v| k.start_with?('HTTP_', 'CONTENT_') }.each do |key, val|
          new_key = key.sub(/^HTTP_/, '')
          new_key = new_key.sub('_', '-')
          req_headers[new_key] = val
      end
        # rewind first in case someone else already read the body
      req.body.rewind
      req_body_string = req.body.read
      req.body.rewind

      start_time = Time.now.utc.iso8601(3)
      status, headers, body, status_message = @app.call env
      end_time = Time.now.utc.iso8601(3)
      config = {:"bootstrap.servers" => "localhost:9092"}
      delivery_handles = []
      
      payload = {}
      payload["path"] = req.fullpath
      payload["requestHeaders"] = req_headers.to_json
      payload["responseHeaders"] = headers
      payload["method"] = req.request_method
      payload["requestPayload"] = req_body_string
      payload["responsePayload"] = body
      payload["ip"] = req.ip
      payload["time"] = Time.now.to_i
      payload["statusCode"] = status
      payload["type"] = "HTTP1.1"
      payload["status"] = status_message
      payload["akto_account_id"] = 1000000
      payload["akto_vxlan_id"] = -1
      payload["is_pending"] = false
      payload["source"] = "SDK"
      puts payload 
      Thread.new do
        puts "Producing message"
        delivery_handles << @producer.produce(
            topic:   "akto.api.logs",
            payload: payload.to_json,
            key:     "akto-api-logs"
        )
      end

      # delivery_handles.each(&:wait)
    [status, headers, body]
    end
  end
end  
