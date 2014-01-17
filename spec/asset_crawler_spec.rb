require_relative '../asset_crawler'

describe AssetCrawler do
  let(:service) { described_class.new }

  before do
    service.stub(:info)
  end

  context "#crawl" do
    let(:url) { double}
    let(:first_page) { double }
    let(:second_page) { double }

    it 'crawls a host and finds out assets' do
      HostPathCrawler.stub(:find_local_paths).and_yield("first_path", first_page).and_yield("second_path", second_page)
      PageAssetFinder.stub(:find_assets).with(first_page).and_return(%w(first_image first_css))
      PageAssetFinder.stub(:find_assets).with(second_page).and_return(%w(second_image second_css))

      expect(service.crawl(url)).to eq({
        "first_path"  => %w(first_image first_css),
        "second_path" => %w(second_image second_css)
      })
    end
  end
end

describe HostPathCrawler do
  context "#find_local_paths" do
    let(:host) { "./fixtures/" }
    let(:root_path) { "/simple.html" }
    let(:service) { described_class.new(host, root_path) }

    it "finds all reachable local paths from current page" do
      expect(service.find_local_paths).to eq([
        "/simple.html",
        "/nolinks.html"
      ])
    end

    context "complex crawling" do
      let(:root_path) { "/complex.html" }

      it "skips already visited links" do
        expect(service.find_local_paths).to eq([
          "/complex.html",
          "/other.html",
          "/nolinks.html"
        ])
      end
    end
  end
end

describe PageAssetFinder do
  let(:page) { Nokogiri::HTML(open('./fixtures/assets.html')) }
  let(:service) { described_class.new(page) }

  context "#find_assets" do
    it "finds all static assets in a page" do
      expect(service.find_assets).to eq([
        "/assets/image.png",
        "/assets/application.css",
        "/assets/application.js"
      ])
    end
  end
end
