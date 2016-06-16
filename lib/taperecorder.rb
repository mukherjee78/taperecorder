require "json"
require "active_support/all"
require_relative "taperecorder/version"
require_relative "taperecorder/middleware"

if defined?(Rails) && Rails.env.development?
  require "taperecorder/engine"
end

require "taperecorder/rails" if defined?(Rails)