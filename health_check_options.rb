class HealthCheckOptions < HealthCheck

  def initialize
    main
  end

  def main
    table_output('Views Health Check', health_check_headers, output(main_options))
    option = gets.strip.to_i
    if valid?(option, 'initial')
      main_option(option)
    else
      error_message(option)
      reload(main)
    end
  end

  def main_option(option)
    case option
      when 1 then view
      when 2 then exit
    end
  end

  def view
    table_output('Which view server would you like to check?', health_check_headers, output(view_options))
    option = gets.strip.to_i
    if valid?(option, 'view')
      @view = view_option(option)
      region
    else
      error_message(option)
      reload(view)
    end
  end

  def view_option(option)
    case option
      when 1 then 'primary_views'
      when 2 then 'backout_views'
      when 3 then 'pre_release_views'
      when 4 then 'risk_views'
      when 5 then 'all'
      when 6 then exit
    end
  end

  def region
    table_output('Which region would you like to check?', health_check_headers, output(region_options))
    option = gets.strip.to_i
    if valid?(option, 'region')
      @region = region_option(option)
    else
      error_message(option)
      reload(region)
    end
  end

  def region_option(option)
    case option
      when 1 then 'apac'
      when 2 then 'emea'
      when 3 then 'amers_1'
      when 4 then 'amers_2'
      when 5 then 'all'
      when 6 then exit
    end
  end

  def health_check_headers
    %w(Option Explanation)
  end

  def main_options
    ['OUTPUT HEALTH CHECK ERRORS', 'EXIT']
  end

  def view_options
    ['PRIMARY VIEWS', 'BACK OUT VIEWS', 'PRE-RELEASE VIEWS', 'RISK VIEWS', 'ALL', 'EXIT']
  end

  def region_options
    %w(APAC EMEA AMERS-1 AMERS-2 ALL EXIT)
  end

  def output(info)
    info.map.with_index {|value, index| [index + 1, value]}
  end

  def urls
    {search: {view_options: @view, region: @region}}
  end

  def exit(message = 'PROGRAM HAS BEEN TERMINATED!')
    abort(message)
  end

  def reload(region)
    region
  end

  def valid?(option, type)
    numerical?(option) && correct_value?(option, type)
  end

  def numerical?(option)
    option.to_i.is_a? Integer rescue false
  end

  def correct_value?(entered, type)
    response = false
    response = entered.between?(1,2)        if type == 'initial'
    response = entered.between?(1,6)        if type == 'view'
    response = entered.between?(1,6)        if type == 'region'
    response
  end

  def error_message(option)
    puts "THE INPUT #{underline_output(option)} IS INCORRECT. PLEASE TRY AGAIN."
  end

  def colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end

  def underline_output(text)
    colorize(text, 4)
  end

end
