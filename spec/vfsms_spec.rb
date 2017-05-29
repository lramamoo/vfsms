require 'spec_helper'
require 'logger'

describe Vfsms do
  describe "Initialization" do

    it "should successfully initialize with the correct version" do
      Vfsms.config(:opts => {}).should_not be_nil
    end

    it "should successfully initialize with the proxy parameters" do
      vfsms = Vfsms.config do |config|
        config.username = 'c1111'
        config.password = 'vfpassword'
        config.url = 'http://api.myvf.com'

        config.proxy_host = "dwar1.abc.com"
        config.proxy_port = "8080"
        config.proxy_user = "abc"
        config.proxy_password = "proxypassword"
      end

      vfsms.username.should_not be_nil
      vfsms.password.should_not be_nil
      vfsms.url.should_not be_nil

      vfsms.proxy_host.should_not be_nil
      vfsms.proxy_port.should_not be_nil
      vfsms.proxy_user.should_not be_nil
      vfsms.proxy_password.should_not be_nil
    end
  end

  describe "Send SMS" do
    it "should send SMS when correct parameters" do
      # Vfsms.send_sms({:from => 'JUSTBOOK', :send_to => ['9538321404'], :message => 'Test Message'}).should be_true
    end
  end

  describe "Send SMS with proxy" do
    before(:each) do
      Vfsms.config do |config|
        config.username = 'c1111'
        config.password = 'vfpassword'
        config.url = 'http://api.myvf.com'

        config.proxy_host = "dwar1.abc.com"
        config.proxy_port = "8080"
        config.proxy_user = "abc"
        config.proxy_password = "proxypassword"
      end
    end
  end

  describe "To Number validations" do

    # it "should not send SMS without 'to' number" do
    #   Vfsms.send_sms({:from => 'JUSTBOOK', :message => 'Test Message'}).should == ([false, "Phone Number is too short"])
    # end

    # it "should not send SMS when 'to' number is less than 10 integers" do
    #   Vfsms.send_sms({:from => 'JUSTBOOK', :send_to => '98805', :message => 'Test Message'}).should == ([false, "Phone Number is too short"])
    # end

    # it "should not send SMS when 'to' number is more than 10 integers" do
    #   Vfsms.send_sms({:from => 'JUSTBOOK', :send_to => '98805972921', :message => 'Test Message'}).should == ([false, "Phone Number is too long"])
    # end

    # it "should not send SMS when 'to' number is not numeric" do
    #   Vfsms.send_sms({:from => 'JUSTBOOK', :send_to => '988059729A', :message => 'Test Message'}).should == ([false, "Phone Number should be numerical value"])
    # end

  end

  describe "Message validations" do

    it "should not send SMS without message" do
      Vfsms.send_sms({:from => 'JUSTBOOK', :send_to => ['9538321404']}).should == ([false, "Message should be at least 10 characters long"])
    end

    it "should not send SMS if message is bigger than 400 characters" do
      Vfsms.send_sms({:from => 'JUSTBOOK', :send_to => ['9538321404'], :message => "%401i" % "12"})
        .should == ([false, "Message should be less than 400 characters long"])
    end

  end

  context "sms_msgs" do
    it "should generate one sms block for each number" do
      msg = Vfsms.sms_msgs({:send_to => ['9842214059','9538321404'],:message => 'Hi', :from => 'Sender', :action => 'creation'})
      msg.should == "<ADDRESS FROM='Sender' TO='9842214059' SEQ='1' TAG='creation'/>\n        <ADDRESS FROM='Sender' TO='9538321404' SEQ='2' TAG='creation'/>\n        "
      msg = Vfsms.sms_msgs({:send_to => [],:message => 'Hi', :from => 'Sender'})
      msg.should == ""
      msg = Vfsms.sms_msgs({:send_to => ['9842214059'],:message => 'Hi', :from => 'Sender', :action => 'creation'})
      msg.should =="<ADDRESS FROM='Sender' TO='9842214059' SEQ='1' TAG='creation'/>\n        "
    end
  end

  context "filter_sms_sent_nos" do
    it "should remove nos with error code" do
      Vfsms.logger = Logger.new(STDOUT).tap { |l| l.level = Logger::DEBUG }
      response = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n <MESSAGEACK> \n <GUID GUID=\"ke7pk164089942f410014boemkRATNAKARBN\" SUBMITDATE=\"2014-07-25 20:16:40\" ID=\"0\">\n</GUID>\n</MESSAGEACK>\n"
      nos = Vfsms.filter_sms_sent_nos(response,{:send_to => ['9842214059','9538321404']})
      nos.should == ['9842214059','9538321404']
      response = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n <MESSAGEACK> \n <GUID GUID=\"ke7pk164089942f410014boemkRATNAKARBN\" SUBMITDATE=\"2014-07-25 20:16:40\" ID=\"0\">\n <ERROR SEQ=\"1\" CODE=\"28676\" /> \n</GUID>\n</MESSAGEACK>\n"
      nos = Vfsms.filter_sms_sent_nos(response,{:send_to => ['9842214059','9538321404']})
      nos.should == ['9538321404']
      response = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n <MESSAGEACK> \n <GUID GUID=\"ke7pk164089942f410014boemkRATNAKARBN\" SUBMITDATE=\"2014-07-25 20:16:40\" ID=\"0\">\n <ERROR SEQ=\"2\" CODE=\"28676\" /> \n</GUID>\n</MESSAGEACK>\n"
      nos = Vfsms.filter_sms_sent_nos(response,{:send_to => ['9842214059','9538321404']})
      nos.should == ['9842214059']
    end
  end
end