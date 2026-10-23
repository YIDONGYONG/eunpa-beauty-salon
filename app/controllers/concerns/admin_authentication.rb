module AdminAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_admin
    helper_method :current_admin
  end

  private

  def current_admin
    @current_admin ||= AdminUser.find_by(id: session[:admin_user_id])
  end

  def require_admin
    redirect_to admin_login_path, alert: "로그인이 필요합니다." unless current_admin
  end
end
