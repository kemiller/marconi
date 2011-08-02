
class FakeAR

  attr_reader :attributes

  def initialize(attrs = {})
    @attributes = self.class.defaults.merge(attrs)
  end

  def method_missing(method, *args)
    if @attributes.has_key?(method)
      @attributes[method]
    elsif method =~ /\A(.*)=\Z/ && @attributes.has_key?($1)
      @attributes[$1] = args.first
    else
      raise NoMethodError
    end
  end

  def logger
    self.class.logger
  end

  def destroy
    self.class.all.delete(self)
  end

  def reload
    self if self.class.all.include?(self)
  end

  class << self

    def set_defaults(hash)
      @defaults = hash.with_indifferent_access
    end

    def defaults
      @defaults ||= {}
    end

    def after_update(*methods)
      @after_update = methods
    end

    def after_create(*methods)
      @after_create = methods
    end

    def after_destroy(*methods)
      @after_destroy = methods
    end

    def logger
      @logger ||= Logger.new(STDOUT).tap { |l| l.level = Logger::ERROR }
    end

    def create(*args)
      new(*args).tap { |o| all << o }
    end

    def create!(*args)
      create(*args)
    end

    def first
      all.first
    end

    def find_each(&block)
      all.each(&block)
    end

    def all
      @objects ||= []
    end

    def count
      all.size
    end

    def delete_all
      @objects = []
    end

  end

end
