class PostsController < ApplicationController
  def index
    @page = [ params[:page].to_i, 1 ].max
    @total_pages = Post.total_pages
    @posts = Post.published.latest.with_all_rich_text.with_attached_featured_image.page(@page)
  end

  def show
    @post = Post.published.find(params[:id])
  end
end
