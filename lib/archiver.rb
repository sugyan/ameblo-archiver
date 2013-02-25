#!/usr/bin/env ruby
require 'cgi'
require 'logger'
require 'open-uri'
require 'nokogiri'

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
      # css
      doc.css('head link[rel="stylesheet"]').each do |e|
        href = e.get_attribute('href')
        path = CGI.escape(URI(href).path)
        unless downloaded[href]
          @log.info(href)
          open(href) do |src|
            open(@dir + '/css/' + path, 'wb') do |des|
              des.write(src.read)
            end
          end
          downloaded[href] = true
        end
        e.set_attribute('href', './css/' + CGI.escape(path))
      end
      # images
      doc.css('img').each do |e|
        src = e.get_attribute('src')
        path = CGI.escape(URI(src).path)
        if path.match(/#{id}/)
          unless downloaded[src]
            @log.info(src)
            open(src) do |src|
              open(@dir + '/img/' + path, 'wb') do |des|
                des.write(src.read)
              end
            end
            downloaded[src] = true
          end
          e.set_attribute('src', './img/' + CGI.escape(path))
        end
      end
      # scripts
      doc.css('script').remove

      # link to other entry
      doc.css('a').each do |e|
        href = e.get_attribute('href')
        if href && href.match(/#{id}\/(?:entry-\d+|entrylist-\d+)\.html/)
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
