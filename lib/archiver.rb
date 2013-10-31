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
      doc = nil
      begin
        doc = Nokogiri::HTML(open("http://ameblo.jp/#{id}/#{page}"))
      rescue => err
        @log.error(err)
        sleep 3
        retry
      end
      # css
      doc.css('head link[rel="stylesheet"]').each do |e|
        href = e.get_attribute('href')
        csspath = CGI.escape(href)
        unless downloaded[href]
          @log.info(href)
          begin
            open(href) do |src|
              content = src.read
              content.scan(/url\((http:.*?)\)/).each do |m|
                url = m[0]
                next unless url.match(id)
                imgpath = CGI.escape(url)
                unless downloaded[url]
                  @log.info(url)
                  open(url) do |src|
                    open(@dir + '/img/' + imgpath, 'wb') do |des|
                      des.write(src.read)
                    end
                  end
                end
                downloaded[url] = true
                content.gsub!(url, '../img/' + CGI.escape(imgpath))
              end
              open(@dir + '/css/' + csspath, 'wb') do |des|
                des.write(content)
              end
            end
            downloaded[href] = true
          rescue => err
            @log.error(err)
          end
        end
        e.set_attribute('href', './css/' + CGI.escape(csspath))
      end
      # images
      doc.css('img').each do |e|
        src = e.get_attribute('src')
        imgpath = CGI.escape(src)
        if src.match(id) && ! src.match(/measure/)
          unless downloaded[src]
            @log.info(src)
            begin
              open(src) do |src|
                open(@dir + '/img/' + imgpath, 'wb') do |des|
                  des.write(src.read)
                end
              end
              downloaded[src] = true
            rescue => err
              @log.error(err)
            end
          end
          e.set_attribute('src', './img/' + CGI.escape(imgpath))
        end
      end
      # scripts
      doc.css('script').remove

      # link to other entry
      doc.css('a').each do |e|
        href = e.get_attribute('href')
        if href && href.match(/#{id}\/(?:entry-\d+|entrylist(-\d+)?)\.html/)
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
