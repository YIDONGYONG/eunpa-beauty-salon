module Admin
  class SiteSettingsController < BaseController
    def edit
      @setting = SiteSetting.instance
    end

    def update
      @setting = SiteSetting.instance
      if @setting.update(setting_params)
        redirect_to edit_admin_site_setting_path, notice: "사이트 설정을 저장했습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy_hero_photo
      SiteSetting.instance.hero_photo.purge_later
      redirect_to edit_admin_site_setting_path, notice: "첫 화면 사진을 삭제했습니다."
    end

    private

    def setting_params
      langs = Translatable::LOCALES
      text_keys = %i[tagline address hours closed_days parking entrance business_info]
      params.require(:site_setting).permit(:phone, :latitude, :longitude, :hero_photo,
                                           *text_keys.product(langs).map { |k, l| :"#{k}_#{l}" })
    end
  end
end
