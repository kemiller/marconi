
require 'uuidtools'

module Marconi
  module GUIDGenerator

    extend self

    def next_guid
      shortname = Marconi.short_application_name[0,2]
      uid = UUIDTools::UUID.random_create.to_i.to_s(36).rjust(25,'0')
      "#{shortname}-#{uid}"
    end

  end
end
