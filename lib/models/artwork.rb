class Artwork
  include Mongoid::Document
  include Mongoid::Timestamps

  field :published
  field :default_image_id
  embeds_many :additional_images

  def default_image
    additional_images.where(_id: default_image_id).first
  end
end
