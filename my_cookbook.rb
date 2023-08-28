require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'bcrypt'

require_relative 'database_persistence'
require_relative 'helpers'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload '*.rb'
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

# Display home page
get '/' do
  erb :home, layout: :layout
end

# Display signup page
get '/signup' do
  erb :signup, layout: :layout
end

# Sign up for a new user account
post '/signup' do
  error = error_for_username(params[:username]) ||
          error_for_password(params[:password], params[:confirm_password])

  if error
    session[:message] = error
    erb :signup, layout: :layout
  else
    @storage.create_user(params[:username], params[:password])
    session[:message] = 'You account has been created. You may now login.'
    redirect '/login'
  end
end

# Display login page
get '/login' do
  erb :login, layout: :layout
end

# Login to user account
post '/login' do
  user = @storage.find_user_by_username(params[:username])

  if user && BCrypt::Password.new(user['hashed_password']) == params[:password]
    session[:user_id] = user['id']
    session[:message] = 'Welcome!'
    redirect_after_login
  else
    session[:message] = 'Invalid username or password.'
    status 422
    erb :login
  end
end

# Log out of user account
post '/logout' do
  session.delete(:user_id)
  redirect '/'
end

# Display cuisines
get '/cuisines' do
  require_sign_in(request.fullpath)

  @cuisines = @storage.all_cuisines(session[:user_id])
  @num_of_pages = (@cuisines.count / MAX_CUISINES_COUNT.to_f).ceil

  error = error_for_page_num(params[:page], @num_of_pages)
  if error
    session[:message] = error
    redirect '/cuisines'
  end

  @current_page_num = params[:page].nil? ? 1 : params[:page].to_i
  @cuisines = current_page_of_items(@current_page_num, MAX_CUISINES_COUNT, @cuisines)

  erb :cuisines, layout: :layout
end

# Display form for creating a new cuisine
get '/cuisines/new' do
  require_sign_in(request.fullpath)

  erb :new_cuisine, layout: :layout
end

# Create a new cuisine
post '/cuisines' do
  require_sign_in(request.fullpath, request.env['rack.request.form_hash'])

  cuisine_name = params[:cuisine_name].strip
  error = error_for_cuisine_name(cuisine_name, session[:user_id])

  if error
    session[:message] = error
    erb :new_cuisine, layout: :layout
  else
    @storage.create_cuisine(cuisine_name, session[:user_id])
    session[:message] = 'Cuisine has been added.'
    redirect '/cuisines'
  end
end

# Display form for updating a cuisine
get '/cuisines/:cuisine_id/edit' do
  require_sign_in(request.fullpath)

  @cuisine = load_cuisine(params[:cuisine_id], session[:user_id])

  erb :edit_cuisine, layout: :layout
end

# Update a cuisine
post '/cuisines/:cuisine_id' do
  require_sign_in(request.fullpath, request.env['rack.request.form_hash'])

  @cuisine = load_cuisine(params[:cuisine_id], session[:user_id])

  updated_name = params[:cuisine_name].strip
  error = error_for_updated_cuisine_name(updated_name, @cuisine[:name], session[:user_id])

  if error
    session[:message] = error
    erb :edit_cuisine, layout: :layout
  else
    @storage.update_cuisine(updated_name, @cuisine[:id], session[:user_id])
    session[:message] = 'Cuisine has been updated.'
    redirect '/cuisines'
  end
end

# Delete a cuisine
post '/cuisines/:cuisine_id/delete' do
  require_sign_in(request.fullpath, request.env['rack.request.form_hash'])

  @storage.delete_cuisine(params[:cuisine_id], session[:user_id])
  session[:message] = 'Cuisine has been deleted.'

  redirect '/cuisines'
end

# Display recipes for a cuisine
get '/cuisines/:cuisine_id/recipes' do
  require_sign_in(request.fullpath)

  @cuisine = load_cuisine(params[:cuisine_id], session[:user_id])
  @recipes = @storage.all_recipes(params[:cuisine_id], session[:user_id])
  @num_of_pages = (@recipes.count / MAX_RECIPES_COUNT.to_f).ceil

  error = error_for_page_num(params[:page], @num_of_pages)
  if error
    session[:message] = error
    redirect "/cuisines/#{@cuisine[:id]}/recipes"
  end

  @current_page_num = params[:page].nil? ? 1 : params[:page].to_i
  @recipes = current_page_of_items(@current_page_num, MAX_RECIPES_COUNT, @recipes)

  erb :recipes, layout: :layout
end

# Display form for creating a new recipe
get '/cuisines/:cuisine_id/recipes/new' do
  require_sign_in(request.fullpath)

  erb :new_recipe, layout: :layout
end

# Create a new recipe
post '/cuisines/:cuisine_id/recipes' do
  require_sign_in(request.fullpath, request.env['rack.request.form_hash'])

  recipe_name = params[:recipe_name].strip
  error = error_for_recipe_name(recipe_name)

  if error
    session[:message] = error
    erb :new_recipe, layout: :layout
  else
    recipe_info = [params[:recipe_name], params[:ingredients], params[:instructions]]
    @storage.create_new_recipe(recipe_info, params[:cuisine_id], session[:user_id])
    session[:message] = 'Recipe has been added.'
    recipe_id = @storage.find_recipe_id(recipe_name, session[:user_id])
    redirect "cuisines/#{params[:cuisine_id]}/recipes/#{recipe_id}"
  end
end

# Display form for updating a recipe
get '/cuisines/:cuisine_id/recipes/:recipe_id/edit' do
  require_sign_in(request.fullpath)

  @recipe = @storage.find_recipe_by_id(params[:recipe_id], params[:cuisine_id], session[:user_id])

  erb :edit_recipe, layout: :layout
end

# Update a recipe
post '/cuisines/:cuisine_id/recipes/:recipe_id' do
  require_sign_in(request.fullpath, request.env['rack.request.form_hash'])

  @recipe = @storage.find_recipe_by_id(params[:recipe_id], params[:cuisine_id], session[:user_id])
  recipe_name = params[:recipe_name].strip
  error = error_for_recipe_name(recipe_name)

  if error
    session[:message] = error
    erb :edit_recipe, layout: :layout
  else
    recipe_info = [params[:recipe_name], params[:ingredients], params[:instructions]]
    @storage.update_recipe(recipe_info, params[:recipe_id], params[:cuisine_id], session[:user_id])
    session[:message] = 'Recipe has been updated.'
    redirect "/cuisines/#{params[:cuisine_id]}/recipes/#{params[:recipe_id]}"
  end
end

# Delete a recipe
post '/cuisines/:cuisine_id/recipes/:recipe_id/delete' do
  require_sign_in(request.fullpath, request.env['rack.request.form_hash'])

  if @storage.find_recipe_by_id(params[:recipe_id], params[:cuisine_id], session[:user_id])
    @storage.delete_recipe(params[:recipe_id], params[:cuisine_id], session[:user_id])
    session[:message] = 'Recipe has been deleted.'
  end

  redirect "/cuisines/#{params[:cuisine_id]}/recipes"
end

# View a recipe
get '/cuisines/:cuisine_id/recipes/:recipe_id' do
  require_sign_in(request.fullpath, request.env['rack.request.form_hash'])

  @cuisine = load_cuisine(params[:cuisine_id], session[:user_id])
  @recipe = load_recipe(params[:recipe_id], @cuisine[:id], session[:user_id])

  erb :recipe, layout: :layout
end
