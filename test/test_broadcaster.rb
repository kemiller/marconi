require 'test_helper'

class TestBroadcaster < ActiveSupport::TestCase

  setup do
    Marconi.inbound.nuke_q('muggle')
  end

  should "publish creates" do
    Marconi.inbound.pop('muggle', :key => 'gem.person.create')
    person = Person.new
    person.publish_create
    payload = Marconi.inbound.pop('muggle', :key => 'gem.person.create')
    assert_not_nil payload, "There should have been a create message sent"
    envelope = Marconi::Envelope.from_xml(payload)
    assert_soft_equal person.attributes, envelope.messages.first[:data]
  end

  should "publish updates" do
    Marconi.inbound.pop('muggle', :key => "gem.person.update")
    person = Person.new
    person.publish_update
    payload = Marconi.inbound.pop('muggle', :key => 'gem.person.update')
    assert_not_nil payload, "There should have been an update message sent"
    envelope = Marconi::Envelope.from_xml(payload)
    assert_soft_equal person.attributes, envelope.messages.first[:data]
  end

  should "publish destroys" do
    Marconi.inbound.pop('muggle', :key => "gem.person.destroy")
    person = Person.new
    person.publish_destroy
    payload = Marconi.inbound.pop('muggle', :key => 'gem.person.destroy')
    assert_not_nil payload, "There should have been a delete message sent"
    envelope = Marconi::Envelope.from_xml(payload)
    assert_soft_equal person.attributes, envelope.messages.first[:data]
  end

  should "not publish anything in response to an external update" do

    # Ensure the inbound queue exists
    Marconi.inbound.pop('muggle', :key => "gem.person.create")

    # Arrange for a create message
    Marconi.outbound.nuke_q('gem.person') 
    Marconi.outbound.pop('gem.person', :key => "#.person.#")
    @e = Marconi::Envelope.new { |e| e.create Person.new }
    Marconi.outbound.publish(@e, :topic => "idauth.person.create")

    # Handle us some messages
    Person.listen(1)

    # make sure nothing goes
    assert_nil Marconi.inbound.pop('muggle', :key => 'gem.person.create')
  end

end
