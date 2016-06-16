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
        #insert after jquery 
        inject_taperecorder_js!(body, 'jquery')
        inject_taperecorder_html!(body)

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

    def inject_taperecorder_js!(html, after_script_name)
      html.sub!(/<script[^>].*#{after_script_name}.*<\/script>/x) { "#{$~}\n<script type=\"text/javascript\" >#{render_taperecorder_js}</script>" }
    end

    def inject_taperecorder_html!(html)
      html.sub!(/<body[^>]*>/) { "#{$~}\n#{render_taperecorder_html}" }
    end

    def render_taperecorder_js
      if ApplicationController.respond_to?(:render)
        # Rails 5
        ApplicationController.render(:partial => "/taperecorder_js").html_safe
      else
        # Rails <= 4.2
        ac = ActionController::Base.new
        ac.render_to_string(:partial => '/taperecorder_js').html_safe
      end
    end

    def render_taperecorder_html
      if ApplicationController.respond_to?(:render)
        # Rails 5
        ApplicationController.render(:partial => "/taperecorder_html").html_safe
      else
        # Rails <= 4.2
        ac = ActionController::Base.new
        ac.render_to_string(:partial => '/taperecorder_html').html_safe
      end
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