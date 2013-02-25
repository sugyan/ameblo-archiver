#!/usr/bin/env ruby
require 'open-uri'
require 'nokogiri'
require 'logger'

class Archiver
  def initialize(dir = 'data')
    @log = Logger.new(STDERR)
    @output_dir = File.dirname(__FILE__) + '/../' + dir
    @downloaded = {}
  end

  def start(id)
    @id = id
    @base_url = "http://ameblo.jp/#{id}/"
    download_page('entrylist.html')
  end

  def download_page(page)
    @log.info(page)
    targets = []
    doc = Nokogiri::HTML(open(@base_url + page))
    doc.css('a').each do |e|
      href = e.get_attribute('href')
      if href && href.match(/#{@id}\/(?:entry-\d+|entrylist-\d+)\.html/)
        path = URI(href).path.split(/\//).last
        e.set_attribute('href', './' + path)
        targets.push(path)
      end
    end

    open(@output_dir + '/' + page, 'wb') do |des|
      des.write(doc)
    end
    @downloaded[page] = true
    targets.each do |p|
      next if @downloaded[p]
      sleep 0.5
      download_page(p)
    end
  end
end
