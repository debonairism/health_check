class Penetrator < HealthCheck

#  requires
  require 'mechanize'
  require 'watir-webdriver'
  require 'parallel'
  require 'phantomjs'
  require 'logger'

  def initialize(servers, options, argument)
    clear_screen

    @errors = Parallel.map(servers, :in_processes => 4, :progress => "Penetrating #{options.values}") do |url|
      headless_web_page(url)
      wrong_title? ? wrong_server(url) : errors rescue skip_server
    end

    logging
    all_errors.empty? ? passing_log('There are no errors on the page') : failing_log(all_errors.to_s)

    table_output('Penetrator', headers, output) unless @errors.empty?
    HealthCheck.new if argument.empty?
  end

  def headless_web_page(url)
    @browser = Watir::Browser.new :phantomjs
    @url = URI(url)
    open_browser(url)
  end

  def open_browser(url)
    tries ||= 2
    begin
      @browser.goto url
      put_into_nokogiri(@browser.html)
    rescue Exception => error
      retry unless (tries -= 1).zero?
      @exception = error
    end
  end

  def put_into_nokogiri(html)
    @agent = Nokogiri::HTML("#{html}")
    @browser.close
  end

  def title
    @agent.title.strip.downcase rescue nil
  end

  def wrong_title?
    title != 'reuters explorer health status page'
  end

  def all_unavailable
    @agent.css('body').css("img[src='Images/Unavailable.gif']")
  end

  def unavailable_categories
    @agent.css('body').css("td[colspan='6']").css("img[src='Images/Unavailable.gif']")
  end

  def unavailable_services
    unavailable_categories.map do |category|
      category['id']
    end
  end

  def system_name
    @agent.css('body').css("td[colspan='6']").map do |category|
      category.text.gsub(/\(.*\)/, '').strip
    end
  end

  def system_id
    @agent.css('body').css("td[colspan='6']").map do |category|
      /(?<=_)[^_]+(?=_)/.match(category.css("span[class='system_title']").first['id']).to_s
    end
  end

  def category_info
    system_name.zip(system_id)
  end

  def sub_cat
    @agent.css('body').css("tr[style='display:none;']").css('div')
  end

  def unavailable_sub_cat
    sub_cat.select do |sub_cat|
      !sub_cat.css("div[id ='serviceStatus']").text.empty?
    end
  end

  def unavailable_sub_cat_id(category)
    /(?<=_)[^_]+(?=_)/.match(category['id']).to_s
  end

  def unavailable_sub_cat_status(category)
    category.text
  end

  def view
    view = @url.path.split('/')[1]
    view == :runtime ? 'Primary' : view
  end

  def region
    @url.host.split('.').first
  end

  def web_server
    @url.query.split('=').last
  end

  def category(service)
    category_info.rassoc(unavailable_sub_cat_id(service)).first.upcase
  end

  def service_error(name)
    @agent.css('body').css("a[id='#{service(name)}hlServiceType']").text.strip
  end

  def service(name)
    service_id = (name['id'])
    service = /[^_]*$/.match(name['id']).to_s
    service_id.slice! service
    service_id
  end

  def error_message(service)
    unavailable_sub_cat_status(service)
  end

  def errors
    load_health_check_rules
    errors = unavailable_sub_cat.map do |service|
      [view, region, web_server, service_error(service), category(service), error_message(service)] unless exempt?(service)
    end
    errors.compact
  end

  def rules_file
    File.dirname(__FILE__) + '/health_check_rules.json'
  end

  def load_health_check_rules
    @rules = JSON.parse(read_json_file(rules_file))
  end

  def read_json_file(files)
    File.read(files)
  end

  def rules
    @rules.values.first.map {|rule| rule.upcase}
  end

  def exempt?(service)
    rules.include? category(service)
  end

  def skip_server
    [view, region, web_server,'N/A' ,'N/A', "#{@exception}"]
  end

  def wrong_server(url)
    ['N/A', 'N/A', 'N/A', url, 'N/A', 'Incorrect URL has been provided. Please try again']
  end

  def headers
    ['View', 'Region', 'Host Server', 'Service Name', 'Service Type', 'Error Message']
  end

  def all_errors
    @errors.flatten.each_slice(6).to_a
  end

  def logging
    @log = Logger.new('health_check.log', 30)
    @log.level = Logger::DEBUG
    @log.progname = 'Health Check Log'
    @log.formatter = proc do |severity, datetime, progname, msg|
      "#{severity} | #{datetime.strftime('%Y-%m-%d %H:%M:%S.%L')} |  #{msg}\n"
    end
  end

  def failing_log(message)
    @log.error(message)
    puts Time.now.to_s + ' | ' + message
    close_log
  end

  def passing_log(message)
    @log.info(message)
    puts Time.now.to_s + ' | ' + message
    close_log
  end

  def close_log
    @log.close
  end

  def url?(string)
    uri = URI.parse(string)
    %w( http https ).include?(uri.scheme)
  rescue
    false
  end

  def output
    all_errors.map do |row|
      row.map do |string|
        url?(string) ? word_wrap_url(string) : word_wrap(string, 50)
      end
    end
  end

  def word_wrap_url(string)
    url = string.scan(/.{1,50}/)
    separated_url = url.map {|part| part + "\n"}
    separated_url.join
  end

  def word_wrap (text, number)
    words = text.split(' ' && '.')
    str = words.shift
    words.each do |word|
      connection = (str.size - str.rindex("\n").to_i + word.size > number) ? "\n" : ' '
      str += connection + word
    end
    str
  end

end
