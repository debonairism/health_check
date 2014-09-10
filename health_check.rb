#!/usr/bin/env ruby

class HealthCheck

  require File.dirname(__FILE__) + '/health_check_options'
  require File.dirname(__FILE__) + '/health_check_url'
  require File.dirname(__FILE__) + '/penetrator'
  require 'terminal-table'

  def initialize
    @options = HealthCheckOptions.new.urls
    get_server_urls
    penetrate_urls
  end

  def get_server_urls
    health_check = HealthCheckUrl.new(@options)
    @server_urls = health_check.server_urls
  end

  def penetrate_urls
    Penetrator.new(@server_urls, @options)
  end

  def table_output(title, header, row, message = nil)
    puts message unless message.nil?

    table = Terminal::Table.new title: title,
                                headings: header,
                                rows: row
    table.style = {             border_x: '-',
                                border_i: '+',
                                padding_left: 1,
                                padding_right: 1}

    row.empty? ? (puts 'There are no errors on the page') : (puts table)
  end

  def clear_screen
    system('clear')
  end

end

HealthCheck.new