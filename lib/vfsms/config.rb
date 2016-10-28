module Vfsms
  class Config
    attr_accessor :username, :password, :url, :proxy_host, :proxy_port, :proxy_user, :proxy_password
    
    def initialize(opts)
      @api_params = {}
      @api_params[:version] = opts[:version] || '1.3'

      raise "Unsupported version" unless @api_params[:version] == '1.3'
    end
  end
end
