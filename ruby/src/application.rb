require 'date'
require 'fileutils'

module TemplateCreator
  class Application
    def self.run(unit: 'd', year: Time.now.year.to_s)
      self.new(validate_unit!(unit), validate_year!(year)).run
    end

    def initialize(unit, year)
      @unit = unit
      @year = year
    end

    def run
      Date::MONTHNAMES.compact.each.with_index(1) { |month, i|
        index     = sprintf('%02d', i)
        directory = File.join('..', 'summary_of_news_articles', year, "#{index}_#{month}")
        case unit
        when 'd', 'w'
          create_templates(month) { |d|
            day = sprintf('%02d', d)
            if unit == 'd'
              next if is_sunday?(i, d)
              export_template(directory, index, day, month)
            else
              next unless is_saturday?(i, d)
              export_template(directory, index, day, month)
            end
          }
        when 'm'
          export_template(directory, index, month)
        end
      }
    end

    private

    attr_reader :unit, :year

    class << self
      def validate_unit!(unit)
        case unit
        when 'd', 'w', 'm'
          unit
        else
          raise 'Provide d, w or y as a valid unit'
        end
      end

      def validate_year!(year)
        Integer(year)
        if year.length > 4
          raise 'Year must be 4 digits'
        elsif year.to_i < Time.now.year
          raise 'Provide newer than or equal to the current year'
        else
          year
        end
      end
    end

    def is_saturday?(month, day)
      Time.new(year, month, day).saturday?
    end

    def is_sunday?(month, day)
      Time.new(year, month, day).sunday?
    end

    def is_leap_year?
      (year.to_i % 400).zero? || (!!(year.to_i % 100).nonzero? && (year.to_i % 4).zero?)
    end

    def body(date)
      text =  "# Summary of Today's News Articles on #{date}\n\n"
      text << "## 1. Pick-Up Articles\n\n"
      text << "- [ARTICLE](url)\n"
      text << "- [ARTICLE](url)\n"
      text << "- [ARTICLE](url)\n\n"
      text << "## 2. Summary\n\n"
      text << "SUMMARY\n\n"
      text << "## 3. Discussion\n\n"
      text << "DISCUSSION\n"
    end

    def export_template(directory, index, day = '', month)
      date     =  ''
      date     << "#{day} " unless day.empty?
      date     << "#{month} #{year}"
      filename = File.join(directory, "#{year}#{index}#{day}_summary_of_news_articles.md")
      FileUtils.mkdir_p(directory) unless Dir.exist?(directory)
      IO.write(filename, body(date)) unless File.exist?(filename)
    end

    def create_templates(month)
      1.upto(31).each { |d|
        case month
        when 'February'
          next if is_leap_year? && d > 29
          next if d > 28
          yield(d)
        when 'April', 'June', 'September', 'November'
          next if d > 30
          yield(d)
        else
          yield(d)
        end
      }
    end
  end
end
