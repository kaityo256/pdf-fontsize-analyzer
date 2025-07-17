# frozen_string_literal: true

# !/usr/bin/env ruby
require 'bundler/setup'
require 'hexapdf'
require 'optparse'
require 'hexapdf/content/parser'

def contains_control_char?(str)
  !!(str =~ /[\x00-\x1F\x7F]/)
end

def process_contents(contents, font_size_hash, options)
  parser = HexaPDF::Content::Parser.new
  contents.each do |stream|
    stream = doc.object(stream) if stream.is_a?(Integer)
    buffer = stream.respond_to?(:stream) ? stream.stream : stream
    current_size = 0
    current_scale = 1.0
    parser.parse(buffer) do |operator, operands|
      case operator
      when :cm
        # 変換行列を検出したら、縦横のスケールの調和平均をスケールパラメータとする
        r1 = operands[0]
        r2 = operands[3]
        current_scale = Math.sqrt(r1 * r2)
        puts "Scaling Matrix #{operands}" if options[:verbose]
      when :Q
        # Qを検出したらスケールを元に戻す(厳密な対応ではない)
        current_scale = 1.0
      when :Tf
        current_font, current_size = operands
        puts "Font #{current_font}, Fontsize #{current_size}, Scale #{current_scale}" if options[:verbose]
      when :TJ
        operands[0].each do |v|
          next unless v.is_a?(String)

          font_size = current_size * current_scale

          if contains_control_char?(v)
            font_size_hash[font_size] += v.size / 2
            v = "<#{v.bytes.map { |b| format('%02X', b) }.join}>"
          else
            font_size_hash[font_size] += v.size
          end
          puts v if options[:verbose]
        end
      end
    end
  end
end

def round_size(font_size_hash, options)
  return font_size_hash unless options[:round_size]

  step = options[:round_size]
  rounded_font_size_hash = Hash.new(0)
  font_size_hash.each_key do |size|
    rounded_size = (size / step).round * step
    rounded_font_size_hash[rounded_size] += font_size_hash[size]
  end
  rounded_font_size_hash
end

def show_results(font_size_hash, options)
  font_size_hash = round_size(font_size_hash, options)
  puts "Font Size\tCharacter count"
  average_size = 0
  count = 0
  font_size_hash.keys.sort.each do |size|
    puts "#{size}\t\t#{font_size_hash[size]}"
    average_size += size * font_size_hash[size]
    count += font_size_hash[size]
  end
  puts

  puts "Average Size: #{(average_size / count).round(2)}"
end

def analyze(doc, options)
  font_size_hash = Hash.new(0)
  doc.pages.each_with_index do |page, page_index|
    puts "Page #{page_index + 1}:" if options[:verbose]
    begin
      page.resources[:Font]
    rescue StandardError
      {}
    end
    contents = page.contents
    contents = [contents] unless contents.is_a?(Array)
    process_contents(contents, font_size_hash, options)
  end
  show_results(font_size_hash, options)
end

def parse_args
  options = {
    verbose: false
  }

  opt_parser = OptionParser.new do |opts|
    opts.banner = 'Usage: ruby analyze_font_size.rb [options] filename.pdf'

    opts.on('-v', '--verbose', 'Enable verbose output') do
      options[:verbose] = true
    end

    opts.on('-r', '--round-size[=STEP]', Float, 'Round font sizes to nearest STEP (e.g., 0.5)') do |step|
      options[:round_size] = step || 0.5
    end

    opts.on('-h', '--help', 'Show this help message') do
      puts opts
      exit
    end
  end

  opt_parser.parse!

  if ARGV.empty?
    warn 'Error: You must specify a PDF filename.'
    puts opt_parser
    exit 1
  end

  filename = ARGV.shift
  [filename, options]
end

filename, options = parse_args

unless File.exist?(filename)
  warn "Error: File '#{filename}' does not exist."
  exit 1
end

HexaPDF::Document.open(filename) do |doc|
  analyze(doc, options)
end
