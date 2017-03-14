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
  filename = args[:filename]
  sitemap = Sitemap.new(args[:filename])

  # s3 bucket
  s3_client = AWS::S3.new(
    access_key_id: ENV['AWS_ID'],
    secret_access_key: ENV['AWS_SECRET']
  )

  s3_bucket = s3_client.buckets['artsy-media-assets']

  output = {}

  sitemap.each do |line|
    slug = line[:slug]
    image_src = line[:image_loc].split('/')[-2..-1].join('/')
    image_dest = line[:image_loc].split('/')[-2] + '/' + line[:slug] + '.jpg'
    puts "Copying #{image_src} => #{image_dest} ..."

    output[slug] = {
      src: image_src,
      dest: image_dest
    }

    s3_bucket.objects[image_dest].copy_from(image_src, acl: :public_read)
  end

  File.open(filename.gsub('.xml', '-copy.json'), 'w') do |f|
    f.write(output.to_json)
  end
end

desc 'Update image versions in Gravity.'
task 'sitemap:update', [:filename] do |t, args|
  filename = args[:filename]
  sitemap = Sitemap.new(filename)

  Mongoid.load!("config/mongoid.yml", ENV['RAILS_ENV'])
  puts "Connected to #{ENV['RAILS_ENV']}."

  output = {}

  sitemap.each do |line|
    slug = line[:slug]
    image_dest = line[:image_loc].split('/')[0..-2].join('/') + '/' + line[:slug] + '.jpg'
    image_version = line[:image_loc].split('/')[-1].split('.').first
    artwork = Artwork.where(_slugs: slug).first
    default_image = artwork.default_image

    output[slug] = {
      artwork_id: artwork.id.to_s,
      default_image_id: default_image.try(:id).try(:to_s),
      image_version: image_version,
      image_dest: image_dest
    }

    if default_image
      puts "#{artwork.id} (#{default_image.id}): setting '#{image_version}' to #{image_dest}"
      default_image.set("image_urls.#{image_version}" => image_dest)
    else
      puts "MISSING: #{artwork.id}"
    end
  end

  File.open(filename.gsub('.xml', '-update.json'), 'w') do |f|
    f.write(output.to_json)
  end
end

desc 'Info about artworks in Gravity.'
task 'sitemap:info', [:filename] do |t, args|
  filename = args[:filename]
  sitemap = Sitemap.new(filename)

  Mongoid.load!("config/mongoid.yml", ENV['RAILS_ENV'])
  puts "Connected to #{ENV['RAILS_ENV']}."

  count = 0
  slugs = sitemap.map do |line|
    line[:slug]
  end

  total_count = slugs.count
  published_count = Artwork.where(:_slugs.in => slugs, published: true).count
  puts "#{published_count}/#{total_count} published artworks"
end
