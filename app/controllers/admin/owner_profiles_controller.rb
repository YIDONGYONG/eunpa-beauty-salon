module Admin
  class OwnerProfilesController < BaseController
    def edit
      @profile = OwnerProfile.instance
    end

    def update
      @profile = OwnerProfile.instance
      if @profile.update(profile_params)
        redirect_to edit_admin_owner_profile_path, notice: "원장님 소개를 저장했습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy_image
      profile = OwnerProfile.instance
      ActiveStorage::Attachment.where(record: profile).find(params[:attachment_id]).purge_later
      redirect_to edit_admin_owner_profile_path, notice: "사진을 삭제했습니다."
    end

    def destroy_photo
      OwnerProfile.instance.photo.purge_later
      redirect_to edit_admin_owner_profile_path, notice: "원장님 사진을 삭제했습니다."
    end

    private

    def profile_params
      langs = Translatable::LOCALES
      keys = %i[name headline career].product(langs).map { |k, l| :"#{k}_#{l}" }
      params.require(:owner_profile).permit(:years_of_experience, :photo, :show_photo_on_home, *keys, gallery_images: [],
                                            greetings_attributes: %i[id body_ko body_en visible])
    end
  end
end
