class PostsController < ApplicationController
  def index
    @total_pages = Post.total_pages
    # 巨大な数や負の数でも落ちないように 1〜最終ページに丸める
    @page = params[:page].to_i.clamp(1, @total_pages)
    @posts = Post.published.latest.with_all_rich_text.with_attached_featured_image.page(@page)
  end

  def show
    @post = Post.published.find(params[:id])
  end
end
