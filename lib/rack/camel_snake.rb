require 'oj'
require 'rack/camel_snake/refinements'

module Rack
  class CamelSnake

    def initialize(app)
      @app = app
    end

    def call(env)
      rewrite_request_body_to_snake(env)

      response = @app.call(env)

      rewrite_response_body_to_camel(response)
    end

    private

    def rewrite_request_body_to_snake(env)
      if env['CONTENT_TYPE'] && env['CONTENT_TYPE'] =~ /application\/json/
        input = env['rack.input'].read
        snakified = Oj.snakify(input)
        env['rack.input'] = StringIO.new(snakified)
        env['CONTENT_LENGTH'] = snakified.bytesize
      end
    end

    def rewrite_response_body_to_camel(response)
      response_header = response.header
      response_body   = response.body

      if response_header['Content-Type'] =~ /application\/json/
        camelized_body = []
        response_body.each { |chunk| camelized_body << Oj.camelize(chunk) }
        response_header['Content-Length'] =
            camelized_body.reduce(0){ |s, i| s + i.bytesize }.to_s
        response.body = camelized_body
      end

      response
    end
  end
end
