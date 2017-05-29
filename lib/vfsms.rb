require "vfsms/version"
require "vfsms/config"
require 'net/http'
require 'uri'

=begin
initializer format
# Vfsms.config do |config|
#   config.username = useranme
#   config.password = password
#   config.url = url
# end
=end

module Vfsms
  class << self
    attr_accessor :logger
  end

  def self.config(opts = {})
    @config ||= Vfsms::Config.new(opts)
    yield(@config) if block_given?
    @config
  end

  def self.send_sms(opts = {})
    @config ||= Vfsms.config(opts)

    message = opts[:message]
    from = opts[:from]
    send_to = opts[:send_to]

    # return false, 'Phone Number is too short' if send_to.to_s.length < 10
    # return false, 'Phone Number is too long' if send_to.to_s.length > 10
    # return false, 'Phone Number should be numerical value' unless send_to.to_i.to_s == send_to.to_s
    return false, 'Message should be at least 10 characters long' if message.to_s.length < 11
    return false, 'Message should be less than 400 characters long' if message.to_s.length > 400

    opts[:username] = @config.username
    opts[:password] = @config.password
    opts[:url] = @config.url

    opts[:proxy_host] = @config.proxy_host
    opts[:proxy_port] = @config.proxy_port
    opts[:proxy_user] = @config.proxy_user
    opts[:proxy_password] = @config.proxy_password

    call_api(opts)
  end

  private
    def self.format_msg(opts = {})
      "<?xml version='1.0' encoding='ISO-8859-1'?>
      <!DOCTYPE MESSAGE SYSTEM 'http://127.0.0.1/psms/dtd/messagev12.dtd'>
      <MESSAGE VER='1.2'>
      <USER USERNAME='#{opts[:username]}' PASSWORD='#{opts[:password]}'/>
      <SMS UDH='0' CODING='1' TEXT='#{opts[:message]}' PROPERTY='0' ID='0'>
      #{sms_msgs(opts)}
      </SMS>
      </MESSAGE>"
    end

    def self.sms_msgs(opts)
      send_to_list = opts[:send_to]
      send_to_count = 0
      msg = ""
      unless send_to_list.empty?
        while send_to_count < send_to_list.count
        msg = msg + "<ADDRESS FROM='#{opts[:from]}' TO='#{send_to_list[send_to_count]}' SEQ='#{send_to_count + 1}' TAG='#{opts[:action]}'/>
        "
        send_to_count = send_to_count + 1
        end
      end
      msg
    end

    def self.filter_sms_sent_nos(response,opts)
      send_to_count = opts[:send_to].count
      cycle = 0
      mobile_numbers = opts[:send_to]
      while cycle < send_to_count
        if response.include?("ERROR SEQ=\"#{cycle + 1}\"")
          self.logger.info("Error Occured for number : " + opts[:send_to][cycle].to_s)
          mobile_numbers = mobile_numbers - [opts[:send_to][cycle]]
        end
        cycle = cycle + 1
      end
      mobile_numbers
    end

    def self.call_api(opts)
      params = {'data' => format_msg(opts), 'action' => 'send'}
      if opts[:proxy_host].nil?
        res = Net::HTTP.post_form(
          URI.parse(opts[:url]),
          params
        )
      else
        res = Net::HTTP::Proxy(opts[:proxy_host], opts[:proxy_port], opts[:proxy_user], opts[:proxy_password]).post_form(
          URI.parse(opts[:url]),
          params
        )
      end
      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        if res.body.include?('GUID')
          mobile_numbers = filter_sms_sent_nos(res.body,opts)
          self.logger.info("SMS sent to: " + mobile_numbers.join(',')) unless mobile_numbers.empty?
          return true, nil
        end
        return false, res.body
      else
        return false, "HTTP Error : #{res}"
      end
    end
end
