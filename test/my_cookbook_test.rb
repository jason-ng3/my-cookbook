ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../my_cookbook'

# Test methods in My Cookbook application
class MyCookBooktest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    @storage = DatabasePersistence.new
    @storage.create_user('testuser', 'abcd1234')
    @user_id = @storage.find_user_by_username('testuser')['id']

    cuisines = %w(Italian Spanish Thai French German Indian)
    cuisines.each { |cuisine| @storage.create_cuisine(cuisine, @user_id) }

    cuisine_ids = cuisines.map do |cuisine|
      @storage.find_cuisine_by_name(cuisine, @user_id)[:id]
    end

    @cuisine_id, @cuisine2_id, @cuisine3_id,
    @cuisine4_id, @cuisine5_id, @cuisine6_id = cuisine_ids

    @storage.create_new_recipe(['Spaghetti With Meatballs', '1 lb. ground beef', nil], @cuisine_id, @user_id)
    @storage.create_new_recipe(['Spaghetti Aglio e Olio', nil, nil], @cuisine_id, @user_id)
    @recipe_id = @storage.find_recipe_id('Spaghetti With Meatballs', @user_id)
    @recipe2_id = @storage.find_recipe_id('Spaghetti Aglio e Olio', @user_id)
  end

  def teardown
    @storage.delete_all
  end

  def session
    last_request.env['rack.session']
  end

  def user_session
    { 'rack.session' => {user_id: @user_id.to_s } }
  end

  def test_home
    get '/'
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q("submit">Create Account</button>)
  end

  def test_view_signup_form
    get '/signup'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'contain letters (A-Z)'
  end

  def test_signup_invalid_username
    post '/signup', { 'username' => '' }
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Please enter a username between 2 and 64 characters long.'

    post '/signup', { 'username' => 'A1?' }
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Please enter a username containing alphanumeric (0-9, A-Z) characters only.'
  end

  def test_signup_username_taken
    post '/signup', { 'username' => 'testuser', 'password' => 'abcd1234', 'confirm_password' => 'abcd1234' }
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Sorry! That username is taken. Please choose a different one.'
  end

  def test_signup_invalid_password
    post '/signup', { 'username' => 'jason', 'pw' => 'abcd' }
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Please enter a password containing 8 or more alphanumeric characters. ' \
                                        'Your password must include at least one alphabetic (A-Z) ' \
                                        'and one numeric (0-9) character.'

    post '/signup', { 'username' => 'jason', 'password' => 'abcd1234', 'confirm_password' => 'abcd12345' }
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Please make sure your password and confirmed password match.'
  end

  def test_successful_signup
    post '/signup', { 'username' => 'jason', 'password' => 'abcd1234', 'confirm_password' => 'abcd1234' }
    assert_equal 302, last_response.status
    assert_equal 'You account has been created. You may now login.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_view_login_form
    get '/login'
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_invalid_login
    post '/login', { username: 'testuser', password: 'invalidpw' }
    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid username or password'
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_successful_login
    post '/login', { username: 'testuser', password: 'abcd1234' }
    assert_equal 302, last_response.status
    assert_equal session[:user_id], @user_id
    assert_equal 'Welcome!', session[:message]
    assert_nil session[:user_input]

    get last_response['Location']
    assert_includes last_response.body, 'My Cookbook'
    assert_includes last_response.body, 'Italian'
    assert_includes last_response.body, 'Spanish'
  end

  def test_logout
    post '/login', { username: 'testuser', password: 'abcd1234' }
    assert_equal 302, last_response.status
    assert_equal session[:user_id], @user_id
    assert_equal 'Welcome!', session[:message]

    post 'logout'
    get last_response['Location']
    assert_includes last_response.body, %q("submit">Create Account</button>)
  end

  def test_view_cuisines
    get '/cuisines', {}, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'My Cookbook'
    assert_includes last_response.body, 'French'
    assert_includes last_response.body, 'German'
    assert_includes last_response.body, 'Indian'
    assert_includes last_response.body, 'Italian'
  end

  def test_view_cuisines_pagination
    get '/cuisines', {}, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<span class="previous_page">Previous</span>)
    assert_includes last_response.body, %q(<a class="current_page" href="/cuisines?page">1</a>)
    assert_includes last_response.body, %q(<a class="" href="/cuisines?page=2">2</a>)
    assert_includes last_response.body, %q(<a class="next_page" href="/cuisines?page=2">Next</a>)

    get '/cuisines?page=2', {}, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<a class="previous_page" href="/cuisines?page">Previous</a>)
    assert_includes last_response.body, %q(<a class="" href="/cuisines?page">1</a>)
    assert_includes last_response.body, %q(<a class="current_page" href="/cuisines?page=2">2</a>)
    assert_includes last_response.body, %q(<span class="next_page">Next</span>)
  end

  def test_view_cuisines_invalid_page_number
    get '/cuisines?page=3', {}, user_session
    assert_equal 302, last_response.status
    assert_includes 'Please enter a valid page number in the URL.', session[:message]
  end

  def test_view_cuisines_case_insensitive_ordering
    post '/cuisines', { cuisine_name: 'guatemalan' }, user_session
    assert_equal 302, last_response.status
    assert_equal 'Cuisine has been added.', session[:message]

    get '/cuisines?page=1', {}, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'guatemalan'
  end

  def test_view_cuisines_signed_out
    get '/cuisines'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_view_add_new_cuisine_form
    get '/cuisines/new', {}, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<form action="/cuisines" method="post">)
    assert_includes last_response.body, %q(name="cuisine_name" type="text")
  end

  def test_view_add_new_cuisine_form_signed_out
    get '/cuisines/new'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_add_invalid_cuisine
    post '/cuisines', { cuisine_name: '' }, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Please enter a cuisine name between 1 and 64 characters.'
  end

  def test_add_same_cuisine_name
    post '/cuisines', { cuisine_name: 'Italian' }, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Cuisine name must be unique.'
  end

  def test_add_valid_cuisine
    post '/cuisines', { cuisine_name: 'Greek' }, user_session
    assert_equal 302, last_response.status
    assert_equal 'Cuisine has been added.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, 'Greek'
    refute_includes last_response.body, 'Spanish'
  end

  def test_add_cuisine_signed_out
    post '/cuisines'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_view_update_cuisine_form
    get "cuisines/#{@cuisine_id}/edit", {}, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<input type="submit" value="Update")
    assert_includes last_response.body, 'Enter new name for cuisine:<label>'
  end

  def test_view_update_cuisine_form_signed_out
    get "/cuisines/#{@cuisine_id}/edit"
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_update_invalid_cuisine_name
    post "/cuisines/#{@cuisine_id}", { cuisine_name: '' }, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Please enter a cuisine name between 1 and 64 characters.'

    post "/cuisines/#{@cuisine_id}", { cuisine_name: 'Spanish' }, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Cuisine name must be unique.'
  end

  def test_update_cuisine
    post "/cuisines/#{@cuisine_id}", { cuisine_name: 'Chinese' }, user_session
    assert_equal 302, last_response.status
    assert_equal 'Cuisine has been updated.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, 'Chinese'
    refute_includes last_response.body, 'Italian'
  end

  def test_update_cuisine_signed_out
    post "/cuisines/#{@cuisine_id}"
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_delete_cuisine
    post "/cuisines/#{@cuisine_id}/delete", { cuisine_id: @cuisine_id }, user_session
    assert_equal 302, last_response.status
    assert_equal 'Cuisine has been deleted.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, 'French'
    assert_includes last_response.body, 'German'
    assert_includes last_response.body, 'Spanish'
    refute_includes last_response.body, 'Italian'
  end

  def test_delete_cuisine_signed_out
    post "/cuisines/#{@cuisine_id}/delete"
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_view_recipes
    get "/cuisines/#{@cuisine_id}/recipes", {}, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Spaghetti With Meatballs'
    assert_includes last_response.body, 'Spaghetti Aglio e Olio'
    assert_includes last_response.body, 'Previous'
    assert_includes last_response.body, 'Next'
  end

  def test_view_recipes_pagination
    get "/cuisines/#{@cuisine2_id}/recipes", {}, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Spanish'
    assert_includes last_response.body, %q(<input type="submit" value="Add New Recipe">)
    refute_includes last_response.body, 'Previous'
    refute_includes last_response.body, 'Next'
  end

  def test_view_cuisines_case_insensitive_ordering
    post '/cuisines', { cuisine_name: 'guatemalan' }, user_session
    assert_equal 302, last_response.status
    assert_equal 'Cuisine has been added.', session[:message]

    get '/cuisines?page=1', {}, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'guatemalan'
  end

  def test_view_recipes_invalid_page_number
    get "/cuisines/#{@cuisine_id}/recipes?page=2", {}, user_session
    assert_equal 302, last_response.status
    assert_includes 'Please enter a valid page number in the URL.', session[:message]
  end

  def test_view_recipes_invalid_cuisine
    get '/cuisines/0/recipes', {}, user_session
    assert_equal 302, last_response.status
    assert_equal 'The specified cuisine was not found.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, 'My Cookbook'
    assert_includes last_response.body, 'Italian'
    assert_includes last_response.body, 'Spanish'
  end

  def test_view_recipes_signed_out
    get "/cuisines/#{@cuisine_id}/recipes"
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_view_add_new_recipe_form
    get "/cuisines/#{@cuisine_id}/recipes/new", {}, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<b>Instructions (Use one empty line between each step)</b>'
    assert_includes last_response.body, %q(recipes" method="post">)
  end

  def test_view_add_new_recipe_form_signed_out
    get "/cuisines/#{@cuisine_id}/recipes/new"
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_add_invalid_recipe
    post "/cuisines/#{@cuisine_id}/recipes", { recipe_name: 'me' }, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'You must enter a recipe name between 3 and 255 characters.'
  end

  def test_add_recipe
    post "/cuisines/#{@cuisine_id}/recipes",
         { recipe_name: 'Pesto Lasagna',
           ingredients: '8 lasagna noodles' }, user_session
    assert_equal 302, last_response.status
    assert_equal 'Recipe has been added.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, 'Pesto Lasagna'
    assert_includes last_response.body, '8 lasagna noodles'
  end

  def test_add_recipe_signed_out
    post "/cuisines/#{@cuisine_id}/recipes"
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_view_update_new_recipe_form
    get "/cuisines/#{@cuisine_id}/recipes/#{@recipe_id}/edit", {}, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<b>Instructions (Use one empty line between each step)</b>'
    assert_includes last_response.body, %q(<div class="edit_recipe">)
  end

  def test_view_update_new_recipe_form_signed_out
    get "/cuisines/#{@cuisine_id}/recipes/#{@recipe_id}"
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_update_invalid_recipe
    post "/cuisines/#{@cuisine_id}/recipes/#{@recipe_id}", { recipe_name: 'me' }, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'You must enter a recipe name between 3 and 255 characters.'
  end

  def test_update_recipe
    post "/cuisines/#{@cuisine_id}/recipes/#{@recipe_id}",
         { recipe_name: 'Mushroom Risotto',
           ingredients: '1 tbsp olive oil' }, user_session
    assert_equal 302, last_response.status
    assert_equal 'Recipe has been updated.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, 'Mushroom Risotto'
    assert_includes last_response.body, '1 tbsp olive oil'
    refute_includes last_response.body, 'Spaghetti With Meatballs'
  end

  def test_update_recipe_signed_out
    post "/cuisines/#{@cuisine_id}/recipes/#{@recipe_id}"
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_delete_recipe
    post "/cuisines/#{@cuisine_id}/recipes/#{@recipe_id}/delete", {}, user_session
    assert_equal 302, last_response.status
    assert_equal 'Recipe has been deleted.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, 'Spaghetti Aglio e Olio'
    refute_includes last_response.body, 'Spaghetti With Meatballs'
  end

  def test_delete_recipe_signed_out
    post "/cuisines/#{@cuisine_id}/recipes/#{@recipe_id}/delete"
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end

  def test_view_recipe
    get "/cuisines/#{@cuisine_id}/recipes/#{@recipe_id}", {}, user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Spaghetti With Meatballs'
    assert_includes last_response.body, '1 lb. ground beef'
  end

  def test_view_invalid_recipe
    get "/cuisines/#{@cuisine_id}/recipes/0", {}, user_session
    assert_equal 302, last_response.status
    assert_equal 'The specified recipe was not found.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, 'Italian'
    assert_includes last_response.body, 'Spaghetti With Meatballs'
    assert_includes last_response.body, 'Spaghetti Aglio e Olio'
  end

  def test_view_recipe_signed_out
    get "/cuisines/#{@cuisine_id}/recipes/#{@recipe_id}"

    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to do that.', session[:message]

    get last_response['Location']
    assert_includes last_response.body, %q(<input type="submit" value="Login">)
  end
end
