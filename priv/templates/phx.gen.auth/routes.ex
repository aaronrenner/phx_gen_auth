
  ## Authentication routes

  scope "/", <%= inspect context.web_module %> do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", <%= inspect schema.alias %>RegistrationController, :new
    post "/users/register", <%= inspect schema.alias %>RegistrationController, :create
    get "/users/login", <%= inspect schema.alias %>SessionController, :new
    post "/users/login", <%= inspect schema.alias %>SessionController, :create
    get "/users/reset_password", <%= inspect schema.alias %>ResetPasswordController, :new
    post "/users/reset_password", <%= inspect schema.alias %>ResetPasswordController, :create
    get "/users/reset_password/:token", <%= inspect schema.alias %>ResetPasswordController, :edit
    put "/users/reset_password/:token", <%= inspect schema.alias %>ResetPasswordController, :update
  end

  scope "/", <%= inspect context.web_module %> do
    pipe_through [:browser, :require_authenticated_user]

    delete "/users/logout", <%= inspect schema.alias %>SessionController, :delete
    get "/users/settings", <%= inspect schema.alias %>SettingsController, :edit
    put "/users/settings/update_password", <%= inspect schema.alias %>SettingsController, :update_password
    put "/users/settings/update_email", <%= inspect schema.alias %>SettingsController, :update_email
    get "/users/settings/confirm_email/:token", <%= inspect schema.alias %>SettingsController, :confirm_email
  end

  scope "/", <%= inspect context.web_module %> do
    pipe_through [:browser]

    get "/users/confirm", <%= inspect schema.alias %>ConfirmationController, :new
    post "/users/confirm", <%= inspect schema.alias %>ConfirmationController, :create
    get "/users/confirm/:token", <%= inspect schema.alias %>ConfirmationController, :confirm
  end
