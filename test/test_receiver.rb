require 'test_helper'

class TestReceiver < ActiveSupport::TestCase
  setup do
    Marconi.outbound.nuke_q('gem.person')
    Marconi.outbound.pop('gem.person', :key => "#.person.#")
    @e = Marconi::Envelope.new { |e| e.create Person.new }
    Marconi.outbound.publish(@e, :topic => "idauth.person.create")
    @saved_handlers = Person.handlers
    Person.purge_handlers
  end

  teardown do
    Person.instance_variable_set(:@handlers, @saved_handlers)
  end

  should "add a block for processing incoming messages" do
    my_var = nil
    Person.register(:create) { |foo| my_var = :yeehaw }
    Person.handlers[:create].first.call
    assert_equal :yeehaw, my_var
  end

  should "execute the appropriate handler for an incoming message" do
    my_var = nil
    Person.register(:create) { |foo| my_var = :howdy }
    Person.listen(1)
    assert_equal :howdy, my_var
  end

  should "deliver a given message to all handlers for an operation" do
    my_var1 = nil
    my_var2 = nil
    Person.register(:create) { |foo| my_var1 = :howdy }
    Person.register(:create) { |foo| my_var2 = :doody }
    Person.listen(1)
    assert_equal :howdy, my_var1
    assert_equal :doody, my_var2
  end

  should "run only handlers appropriate for a given operation" do
    my_var1 = nil
    my_var2 = nil
    Person.register(:create) { |foo| my_var1 = :howdy }
    Person.register(:update) { |foo| my_var2 = :howdy }
    Person.listen(1)
    assert_equal :howdy, my_var1
    assert_nil my_var2
  end

  should "run the correct handlers for the operation" do
    e = Marconi::Envelope.new { |e| e.update Person.new }
    Marconi.outbound.publish(e, :topic => "core.person.update")
    my_var1 = nil
    my_var2 = nil
    Person.register(:create) { |foo| my_var1 = :howdy }
    Person.register(:update) { |foo| my_var2 = :doody }
    Person.listen(2)
    assert_equal :howdy, my_var1
    assert_equal :doody, my_var2
  end
end
