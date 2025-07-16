#!/usr/bin/env ruby
require 'bundler/setup'
require 'hexapdf'
require 'hexapdf/content/parser'

def show_stream(doc)
  doc.each do |obj|
    next unless obj.is_a?(HexaPDF::Stream)

    str = obj.stream
    next unless str.ascii_only?

    puts '----------------------------------------------------'
    puts str
  end
end

def count_utf16be_chars(byte_string)
  byte_string.bytes.each_slice(2).count
end

def analyze(doc)
  parser = HexaPDF::Content::Parser.new

  doc.pages.each_with_index do |page, _page_index|
    begin
      page.resources[:Font]
    rescue StandardError
      {}
    end

    contents = page.contents
    contents = [contents] unless contents.is_a?(Array)

    contents.each do |stream|
      stream = doc.object(stream) if stream.is_a?(Integer)
      buffer = stream.respond_to?(:stream) ? stream.stream : stream

      parser.parse(buffer) do |operator, operands|
        case operator
        when :Tf
          current_font, current_size = operands
          puts "#{current_font} #{current_size}"
        when :TJ
          array = operands[0]
          text = array.join.to_s
          puts text if text.ascii_only?
        end
      end
    end
  end
end

filename = ARGV[0]
HexaPDF::Document.open(filename) do |doc|
  # show_stream(doc)
  analyze(doc)
end
