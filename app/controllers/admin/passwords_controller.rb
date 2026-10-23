module Admin
  class PasswordsController < BaseController
    def edit
    end

    def update
      if current_admin.authenticate(params[:current_password].to_s) &&
         current_admin.update(password: params[:password], password_confirmation: params[:password_confirmation])
        redirect_to admin_root_path, notice: "비밀번호가 변경되었습니다."
      else
        flash.now[:alert] = "현재 비밀번호가 맞지 않거나, 새 비밀번호가 8자 미만이거나 서로 다릅니다."
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
