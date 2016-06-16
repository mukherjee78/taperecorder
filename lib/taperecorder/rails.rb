module Taperecorder
  # @private
  class Railtie < Rails::Railtie
    initializer "taperecorder.configure_rails_initialization" do |app|
      app.middleware.use Taperecorder::Middleware
    end
  end
end