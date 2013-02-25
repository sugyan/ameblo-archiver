#!/usr/bin/env ruby
require 'open-uri'
require 'nokogiri'
require 'logger'

class Archiver
  def initialize(dir = 'data')
    @log = Logger.new(STDERR)
    @dir = File.dirname(__FILE__) + '/../' + dir
  end

  def start(id)
    targets = ['entrylist.html']
    downloaded = {}

    while page = targets.shift
      @log.info(page)
      doc = Nokogiri::HTML(open("http://ameblo.jp/#{id}/#{page}"))
      doc.css('a').each do |e|
        href = e.get_attribute('href')
        if href && href.match(/#{@id}\/(?:entry-\d+|entrylist-\d+)\.html/)
          path = URI(href).path.split(/\//).last
          e.set_attribute('href', './' + path)
          targets.push(path) unless downloaded[path]
        end
      end
      # save
      open(@dir + '/' + page, 'wb') do |des|
        des.write(doc)
      end
      downloaded[page] = true

      sleep 1
      targets = targets.uniq.reject{ |t| downloaded[t] }
    end
  end
end
