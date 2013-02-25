#!/usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
require 'archiver'

Archiver.new.start(ARGV.shift)
