class AboutController < ApplicationController
  def show
    @gallery_images = owner_profile.gallery_images.attachments
  end
end
