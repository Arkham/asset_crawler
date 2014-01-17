require 'nokogiri'
require 'open-uri'

class AssetCrawler
  def self.crawl(url)
    new.crawl(url)
  end

  def info(message)
    puts message
  end

  def crawl(url)
    Hash.new.tap do |result|
      HostPathCrawler.find_local_paths(url) do |current_path, current_page|
        info "\nCrawling '#{current_path}'"
        result[current_path] = PageAssetFinder.find_assets(current_page)
        info "Retrieved assets: #{result[current_path]}"
      end
    end
  end
end

class HostPathCrawler
  attr_reader :host, :root_path, :reached_paths

  def self.find_local_paths(*args, &block)
    new(*args).find_local_paths(&block)
  end

  def initialize(host, root_path = "/")
    @host = host.gsub(/\/*$/, '')
    @root_path = root_path
  end

  def open_path(path)
    Nokogiri::HTML(open(host + path))
  end

  def reached_paths
    @reached_paths ||= {}
  end

  def find_local_paths
    add_new_path(root_path)

    loop do
      break unless path = first_unvisited_path
      page = visit_and_discover(path)
      yield(path, page) if block_given?
    end

    reached_paths.keys
  end

  def visit_and_discover(path)
    begin
      open_path(path).tap do |page|
        page.css('a').each do |node|
          current = node['href']
          add_new_path(current) if valid_path?(current)
        end

        mark_path_as_visited(path)
      end
    rescue StandardError => e
      puts e.backtrace
    end
  end

  def first_unvisited_path
    match = reached_paths.find do |key, value|
      value == :unvisited
    end

    match.first if match
  end

  private

  def add_new_path(path)
    reached_paths[path] = :unvisited
  end

  def valid_path?(path)
    new_path?(path) && local_path?(path)
  end

  def new_path?(path)
    reached_paths[path].nil?
  end

  def local_path?(path)
    path =~ %r(^/)
  end

  def mark_path_as_visited(path)
    reached_paths[path] = :visited
  end
end

class PageAssetFinder
  attr_accessor :page

  def self.find_assets(page)
    new(page).find_assets
  end

  def initialize(page)
    @page = page
  end

  def static_assets_map
    {
      "img"    => "src",
      "link"   => "href",
      "script" => "src"
    }
  end

  def find_assets
    static_assets_map.each_with_object([]) do |(tag, attr), result|
      page.css(tag).each do |node|
        source = node[attr]
        result << source if valid_source?(source)
      end
    end
  end

  private

  def valid_source?(source)
    source =~ %r(^/[^/])
  end
end
