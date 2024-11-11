# frozen_string_literal: true

require_relative "synology/configuration"
require_relative "synology/client"
require_relative "synology/version"
require_relative "synology/error"

module Synology
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end
end
