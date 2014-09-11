class HealthCheckUrl

  require 'json'

  attr_accessor :views, :region, :urls, :passed

  def initialize(options = {})
    options[:search] ||= {}
    @views            = options[:search][:view_options]
    @region           = options[:search][:region]
    @passed           = options[:search][:passed]
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
    urls = passed                                    if passed
    urls = all_servers                               if (views.eql?('all')    &&  region.eql?('all'))   && !passed
    urls = all_views(views)                          if (!views.eql?('all')   &&  region.eql?('all'))   && !passed
    urls = all_region(region)                        if (views.eql?('all')    &&  !region.eql?('all'))  && !passed
    urls = specific_server(views, region)            if (!views.eql?('all')   &&  !region.eql?('all'))  && !passed

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