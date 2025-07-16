# frozen_string_literal: true

# !/usr/bin/env ruby
require 'bundler/setup'
require 'hexapdf'
require 'hexapdf/content/parser'

def analyze(doc, verbose)
  parser = HexaPDF::Content::Parser.new

  doc.pages.each_with_index do |page, _page_index|
    begin
      page.resources[:Font]
    rescue StandardError
      {}
    end

    contents = page.contents
    contents = [contents] unless contents.is_a?(Array)

    font_size_hash = Hash.new(0)
    current_size = 0
    contents.each do |stream|
      stream = doc.object(stream) if stream.is_a?(Integer)
      buffer = stream.respond_to?(:stream) ? stream.stream : stream

      parser.parse(buffer) do |operator, operands|
        case operator
        when :Tf
          current_font, current_size = operands
          puts "#{current_font} #{current_size}" if verbose
        when :TJ
          operands[0].each do |v|
            next unless v.is_a?(String)

            if v.ascii_only?
              font_size_hash[current_size] += v.size
            else
              font_size_hash[current_size] += v.size / 2
              v = "<#{v.bytes.map { |b| format('%02X', b) }.join}>" unless v.ascii_only?
            end
            puts v if verbose
          end
        end
      end
    end
    p font_size_hash
  end
end

filename = ARGV[0]
HexaPDF::Document.open(filename) do |doc|
  # show_stream(doc)
  analyze(doc, true)
end
