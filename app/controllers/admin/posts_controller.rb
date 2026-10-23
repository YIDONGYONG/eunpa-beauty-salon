module Admin
  class PostsController < BaseController
    before_action :set_post, only: %i[edit update destroy toggle]

    def index
      @posts = Post.order(created_at: :desc)
    end

    def new
      @post = Post.new
    end

    def create
      @post = Post.new(post_params)
      if @post.save
        redirect_to admin_posts_path, notice: "글을 저장했습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @post.update(post_params)
        @post.featured_image.purge_later if params.dig(:post, :remove_featured_image) == "1"
        redirect_to admin_posts_path, notice: "글을 수정했습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_path, notice: "글을 삭제했습니다.", status: :see_other
    end

    # 公開／非公開の切り替え
    def toggle
      @post.update!(published: !@post.published?)
      redirect_to admin_posts_path,
                  notice: @post.published? ? "글을 게시했습니다." : "글을 비공개로 바꿨습니다."
    end

    private

    def set_post
      @post = Post.find(params[:id])
    end

    def post_params
      keys = Translatable::LOCALES.flat_map { |l| [ :"title_#{l}", :"content_#{l}" ] }
      params.require(:post).permit(:published, :featured_image, *keys)
    end
  end
end
