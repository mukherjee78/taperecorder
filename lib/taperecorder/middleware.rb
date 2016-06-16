module Taperecorder

  # This middleware is responsible for injecting taperecorder.js
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      # Inject taperecorder.js and friends if this is a successful HTML response
      status, headers, response = @app.call(env)

      if html_headers?(status, headers) && body = response_body(response)
        if body =~ script_matcher('taperecorder')
          inject_taperecorder_helper!(body)
        else
          inject_taperecorder_helper!(body)
        end

        content_length = body.bytesize.to_s

        # For rails v4.2.0+ compatibility
        if defined?(ActionDispatch::Response::RackBody) && ActionDispatch::Response::RackBody === response
          response = response.instance_variable_get(:@response)
        end

        # Modifying the original response obj maintains compatibility with other middlewares
        if ActionDispatch::Response === response
          response.body = [body]
          response.header['Content-Length'] = content_length unless committed?(response)
          response.to_a
        else
          headers['Content-Length'] = content_length
          [status, headers, [body]]
        end
      else
        [status, headers, response]
      end
    end

    private

    def committed?(response)
      response.respond_to?(:committed?) && response.committed?
    end

    def inject_taperecorder_helper!(html)
      html.sub!(/<body[^>]*>/) { "#{$~}\n#{render_taperecorder_helper}" }
    end

    def render_taperecorder_helper
      if ApplicationController.respond_to?(:render)
        # Rails 5
        ApplicationController.render(:partial => "/taperecorder_helper").html_safe
      else
        # Rails <= 4.2
        ac = ActionController::Base.new
        ac.render_to_string(:partial => '/taperecorder_helper').html_safe
      end
    end

    # Matches:
    def script_matcher(script_name)
      /
        <script[^>]+
        \/#{script_name}
        \.js                   # Must have .js extension
        [^>]+><\/script>
      /x
    end

    def helper
      ActionController::Base.helpers
    end

    def html_headers?(status, headers)
      status == 200 &&
      headers['Content-Type'] &&
      headers['Content-Type'].include?('text/html') &&
      headers["Content-Transfer-Encoding"] != "binary"
    end

    def response_body(response)
      body = ''
      response.each { |s| body << s.to_s }
      body
    end
  end
end