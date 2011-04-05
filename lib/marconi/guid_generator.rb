
require 'uuidtools'

module Marconi
  module GUIDGenerator

    extend self

    def next_guid
      # TODO Prefix needs to become generic somehow
      "sd-#{UUIDTools::UUID.random_create.to_i.to_s(36).rjust(25,'0')}"
    end

  end
end
