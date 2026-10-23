class HomeController < ApplicationController
  def show
    @price_list = MenuCategory.for_price_list
    @recent_posts = Post.published.latest.with_all_rich_text.with_attached_featured_image.limit(3)
  end
end
