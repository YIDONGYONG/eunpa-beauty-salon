module Admin
  class DashboardController < BaseController
    def show
      @counts = {
        menu_items: MenuItem.kept.count,
        posts: Post.kept.count,
        published_posts: Post.published.count,
        trash: Trash.count
      }
      @clicks = ClickEvent.counts_since(30)
    end
  end
end
