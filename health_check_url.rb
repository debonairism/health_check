class HealthCheckUrl

  require 'json'

  attr_accessor :views, :region, :urls

  def initialize(options = {})
    options[:search] ||= {}
    @views            = options[:search][:view_options]
    @region           = options[:search][:region]
    load_health_check_file
  end

  def hc_file
    File.dirname(__FILE__) + '/health_check_url.json'
  end

  def read_json_file(files)
    File.read(files)
  end

  def load_health_check_file
    @urls = JSON.parse(read_json_file(hc_file))
  end

  def server_urls
    urls = all_servers                               if (views.eql?('all')      &&  region.eql?('all'))
    urls = all_views(views)                          if (!views.eql?('all')     &&  region.eql?('all'))
    urls = all_region(region)                        if (views.eql?('all')      &&  !region.eql?('all'))
    urls = specific_server(views, region)            if (!views.eql?('all')     &&  !region.eql?('all'))

    urls.flatten
  end

  def all_views(type)
    @urls["#{type}"].values
  end

  def all_region(location)
    @urls.values.map do |views|
      views["#{location}"]
    end
  end

  def all_servers
    urls.values.map do |views|
      views.values
    end
  end

  def specific_server(view, region)
    @urls[view][region]
  end

end