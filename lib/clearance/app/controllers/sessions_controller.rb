module Clearance
  module App
    module Controllers
      module SessionsController

        def self.included(base)
          base.class_eval do
            skip_before_filter :authenticate
            protect_from_forgery :except => :create
            filter_parameter_logging :password
        
            include InstanceMethods
        
          private
            include PrivateInstanceMethods
          end
        end
    
        module InstanceMethods
          def create
            @user = user_model.authenticate(params[:session][:email], params[:session][:password])
            if @user.nil?
              login_failure
            else
              if @user.confirmed?
                remember_me = params[:session][:remember_me] if params[:session]
                remember(@user) if remember_me == '1'
                log_user_in(@user)
                login_successful
              else
                mailer_model.deliver_confirmation(@user)
                deny_access('Account not confirmed. Confirmation email sent.')
              end
            end
          end

          def destroy
            forget(current_user)
            reset_session
            flash[:notice] = 'You have been logged out.'
            redirect_to url_after_destroy
          end
        end

        module PrivateInstanceMethods
          def login_successful
            flash[:notice] = 'Logged in successfully'
            redirect_back_or url_after_create
          end

          def login_failure(message = "Bad email or password.")
            flash.now[:notice] = message
            render :action => :new
          end
      
          def remember(user)
            user.remember_me!
            cookies[:auth_token] = { :value   => user.remember_token, 
                                     :expires => user.remember_token_expires_at }
          end

          def forget(user)
            user.forget_me! if user
            cookies.delete :auth_token
          end

          def url_after_create
            root_url
          end

          def url_after_destroy
            new_session_url
          end
        end
        
      end
    end
  end
end
