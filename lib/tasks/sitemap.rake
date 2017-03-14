require 'aws-sdk'
require 'nokogiri'
require 'mongoid'

require_relative '../models/additional_image'
require_relative '../models/artwork'

class Sitemap
  include Enumerable

  def initialize(filename)
    raise 'Missing filename.' unless filename
    raise 'No such file, #{filename}.' unless File.exist?(filename)
    @sitemap = File.open(filename) { |f| Nokogiri::XML(f) }
  end

  def each(&block)
    xmlns = {
      'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
      'image' => 'http://www.google.com/schemas/sitemap-image/1.1'
    }

    @sitemap.xpath('//xmlns:url', xmlns).each do |url|
      loc = url.xpath('xmlns:loc', xmlns).text
      slug = loc.split('/').last
      image_loc = url.xpath('image:image/image:loc', xmlns).text

      yield({
        url: url,
        loc: loc,
        slug: slug,
        image_loc: image_loc
      })
    end
  end
end

desc 'Copy files in a sitemap.'
task 'sitemap:copy', [:filename] do |t, args|
  sitemap = Sitemap.new(args[:filename])

  # s3 bucket
  s3_client = Aws::S3::Client.new(
    access_key_id: ENV['AWS_ID'],
    secret_access_key: ENV['AWS_SECRET']
  )

  sitemap.each do |line|
    image_src = line[:image_loc].split('/')[-2..-1].join('/')
    image_dest = line[:image_loc].split('/')[-2] + '/' + line[:slug] + '.jpg'
    puts "Copying #{image_src} => #{image_dest} ..."

    s3_client.copy_object(
      bucket: 'artsy-media-assets',
      copy_source: "artsy-media-assets/#{image_src}",
      key: image_dest
    )

    s3_client.put_object_acl(
      acl: 'public-read',
      bucket: 'artsy-media-assets',
      key: image_dest
    )
  end
end

desc 'Update image versions in Gravity.'
task 'sitemap:update', [:filename] do |t, args|
  sitemap = Sitemap.new(args[:filename])

  Mongoid.load!("config/mongoid.yml", ENV['RAILS_ENV'])
  puts "Connected to #{ENV['RAILS_ENV']}."

  sitemap.each do |line|
    slug = line[:slug]
    image_dest = line[:image_loc].split('/')[0..-2].join('/') + '/' + line[:slug] + '.jpg'
    image_version = line[:image_loc].split('/')[-1].split('.').first
    artwork = Artwork.where(_slugs: slug).first
    default_image = artwork.default_image
    if default_image
      puts "#{artwork.id} (#{default_image.id}): setting '#{image_version}' to #{image_dest}"
      default_image.set("image_urls.#{image_version}" => image_dest)
    else
      puts "MISSING: #{artwork.id}"
    end
  end
end
