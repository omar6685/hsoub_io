class RegistrationsController < Devise::RegistrationsController
    private

    def account_update_params
        params.require(:user).permit(:first_name, :last_name, :description, :country, :language, :gender, :birth_date, :password, :password_confirmation, :current_password)
    end
    def sign_up_params
        params.require(:user).permit(:first_name, :last_name, :description,:password, :password_confirmation)
    end

end