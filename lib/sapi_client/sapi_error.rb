# frozen_string_literal: true

module SapiClient
  # Custom exception class for Sapi errors
  class SapiError < RuntimeError
    def initialize(message = 'There was a problem', status = nil)
      super(message)
      @status = status
    end

    def status
      @status&.to_i
    end
  end
end
