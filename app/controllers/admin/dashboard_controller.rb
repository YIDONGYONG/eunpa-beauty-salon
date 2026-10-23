module Admin
  class DashboardController < BaseController
    def show
      @counts = {
        menu_items: MenuItem.count,
        posts: Post.count,
        published_posts: Post.published.count
      }
    end
  end
end
