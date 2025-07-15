#!/usr/bin/env ruby
require "bundler/setup"
require "hexapdf"
require 'hexapdf/content/parser'

def show_stream(doc)
  doc.each do |obj|
    if obj.is_a?(HexaPDF::Stream)
      str = obj.stream
      next unless str.ascii_only?
      puts "----------------------------------------------------"
      puts str
    end
  end
end

def count_utf16be_chars(byte_string)
  byte_string.bytes.each_slice(2).count
end

def analyze(filename)
  parser = HexaPDF::Content::Parser.new
  font_usage_by_page = {}

  HexaPDF::Document.open(filename) do |doc|
    doc.pages.each_with_index do |page, page_index|
      current_font = nil
      current_size = nil
      usage = Hash.new { |h, k| h[k] = Hash.new(0) }

      font_dict = page.resources[:Font] rescue {}

      contents = page.contents
      contents = [contents] unless contents.is_a?(Array)

      contents.each do |stream|
        stream = doc.object(stream) if stream.is_a?(Integer)
        buffer = stream.respond_to?(:stream) ? stream.stream : stream

        parser.parse(buffer) do |operator, operands|
          case operator
          when :Tf
            current_font, current_size = operands
          when :TJ
            array = operands[0]
            char_count = 0
            array.each do |entry|
              char_count += count_utf16be_chars(entry) if entry.is_a?(String)
            end
            usage[current_font][current_size] += char_count if current_font && current_size
          end
        end
      end

      font_usage_by_page[page_index + 1] = usage
    end
  end

  # 結果を出力
  font_usage_by_page.each do |page_num, usage|
    puts "=== Page #{page_num} ==="
    usage.each do |font, sizes|
      sizes.each do |size, count|
        puts "Font #{font}, size #{size} → #{count} chars"
      end
    end
  end
end


filename = ARGV[0]
doc = HexaPDF::Document.open(filename)
show_stream(doc)

#analyze(filename)