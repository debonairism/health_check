class Penetrator < HealthCheck

#  requires
  require 'mechanize'
  require 'watir-webdriver'
  require 'parallel'
  require 'phantomjs'

  def initialize(servers, options)
    clear_screen
    @errors = Parallel.map(servers, :in_processes => 4, :progress => "Penetrating #{options.values}") do |url|
      headless_web_page(url)
      errors rescue skip_server
    end
    table_output('Penetrator', headers, output)
    HealthCheck.new
  end

  def headless_web_page(url)
    @browser = Watir::Browser.new :phantomjs
    @url = URI(url)
    open(url)
  end

  def open(url)
    begin
      @browser.goto url
      put_into_nokogiri(@browser.html)
    rescue Exception => error
      @exception = error
    end
  end

  def put_into_nokogiri(url)
    @agent = Nokogiri::HTML("#{url}")
    @browser.close
  end

  def title
    @agent.title.strip.downcase
  end

  def service_unavailable?
    title == ''
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
    view == 'runtime' ? 'Primary' : view
  end

  def region
    @url.host.split('.').first
  end

  def web_server
    @url.query.split('=').last
  end

  def category(service)
    category_info.rassoc(unavailable_sub_cat_id(service)).first
  end

  def service_name
  #  work on this after
  end

  def error_message(service)
    unavailable_sub_cat_status(service)
  end

  def errors
    unavailable_sub_cat.map do |service|
      [view, region, web_server, category(service), error_message(service)]
    end
  end

  def skip_server
    [view, region, web_server, 'N/A', "#{@exception}"]
  end

  def headers
    ['View', 'Region', 'Host Server', 'Category Service', 'Error Message']
  end

  def all_errors
    @errors.flatten.each_slice(5).to_a
  end

  def output
    all_errors.map do |row|
      row.map do |test|
        word_wrap(test, 70)
      end
    end
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