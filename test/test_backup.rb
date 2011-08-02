require 'test_helper'

class TestBackup < ActiveSupport::TestCase

  setup do
    Marconi.backup_queue_class_name = 'UnsentMessage'
    UnsentMessage.delete_all

    @person = Person.new

    envelope = Marconi::Envelope.new(:topic => "my.lousy.topic") do |e|
      e.create(@person)
    end

    @body = envelope.to_s
  end

  should "create an unsent message record if we try to send a message but can't" do

    Marconi.inbound.expects(:connect).raises(Exception)

    Marconi.inbound.publish(@body, :topic => "my.lousy.topic")

    assert_not_nil UnsentMessage.first
    assert_equal @body, UnsentMessage.first.body
  end

  should "resend UnsentMessages on the queue when recovering" do

    Marconi.inbound.nuke_q('falsework.person')
    Marconi.inbound.pop('falsework.person', :key => "#")

    UnsentMessage.create(:exchange_name => 'marconi.events.inbound', 
                         :topic => 'my.lousy.topic',
                         :body => @body)

    Marconi.run_recovery_loop

    payload = Marconi.inbound.pop('falsework.person', :key => "#")
    assert_not_nil payload
    envelope = Marconi::Envelope.from_xml(payload)
    assert_soft_equal @person.attributes, envelope.messages.first[:data]
    assert_equal 0, UnsentMessage.count

  end

  should "not remove the UnsentMessage if retrying doesn't work" do

    Marconi.inbound.nuke_q('falsework.person')
    Marconi.inbound.pop('falsework.person', :key => "#")

    umsg = UnsentMessage.create(:exchange_name => 'marconi.events.inbound', 
                                :topic => 'my.lousy.topic',
                                :body => @body)

    Marconi.inbound.expects(:connect).raises(Exception)

    Marconi.run_recovery_loop

    assert_equal 1, UnsentMessage.count
    assert umsg.reload

  end
end
