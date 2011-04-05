
module SmartXML
  
  class << self
    def parse(xml)
      return nil unless xml
      hash = Hash.from_xml(xml)
      return nil unless hash

      # If the top-level object is a hash, rails's deserializer puts it 
      # under the key "hash".  If it's an array, it uses "object".  Simple
      # values like numbers and strings can't be XML docs all by themselves
      # so we don't need to consider any other cases.

      indifferentize(hash['hash'] || hash['objects'])
    end

    private

    # Convert all hashes to indifferent hashes, because otherwise we get
    # subtle bugs.
    def indifferentize(hash)
      case hash
      when Hash
        new_hash = HashWithIndifferentAccess.new
        hash.each do |key, value|
          new_hash[key] = indifferentize(value)
        end
        new_hash
      else
        hash
      end
    end
  end
    
end
