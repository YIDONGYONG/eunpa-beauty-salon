module Admin
  class SessionsController < BaseController
    skip_before_action :require_admin, only: %i[new create]
    layout "admin_login"

    # 総当たり攻撃の防止: 3分間に10回まで
    rate_limit to: 10, within: 3.minutes, only: :create,
               with: -> { redirect_to admin_login_path, alert: "잠시 후 다시 시도해 주세요." }

    def new
      redirect_to admin_root_path if current_admin
    end

    def create
      user = AdminUser.find_by(email: params[:email].to_s.strip.downcase)
      if user&.authenticate(params[:password].to_s)
        reset_session # セッション固定攻撃の防止
        session[:admin_user_id] = user.id
        redirect_to admin_root_path, notice: "로그인되었습니다."
      else
        flash.now[:alert] = "이메일 또는 비밀번호가 올바르지 않습니다."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to admin_login_path, notice: "로그아웃되었습니다."
    end
  end
end
