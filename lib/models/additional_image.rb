class AdditionalImage
  include Mongoid::Document
  include Mongoid::Timestamps

  field :image_urls, type: Hash
  embedded_in :artwork, inverse_of: :additional_images
end
