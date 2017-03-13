require 'aws-sdk'
require 'nokogiri'

desc 'Copy files in a sitemap.'
task 'sitemap:copy', [:filename] do |t, args|
  # a sitemap
  filename = args[:filename]
  raise 'Missing filename.' unless filename
  raise 'No such file, #{filename}.' unless File.exist?(filename)
  sitemap = File.open(filename) { |f| Nokogiri::XML(f) }

  # s3 bucket
  s3_client = Aws::S3::Client.new(
    access_key_id: ENV['AWS_ID'],
    secret_access_key: ENV['AWS_SECRET']
  )

  xmlns = {
    'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
    'image' => 'http://www.google.com/schemas/sitemap-image/1.1'
  }

  sitemap.xpath('//xmlns:url', xmlns).each do |url|
    loc = url.xpath('xmlns:loc', xmlns).text
    slug = loc.split('/').last
    image_loc = url.xpath('image:image/image:loc', xmlns).text
    image_src = image_loc.split('/')[-2..-1].join('/')
    image_dest = image_loc.split('/')[-2] + '/' + slug + '.jpg'
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
