# CONSTANTS
PASSWORD_REGEX = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$/.freeze
MAX_CUISINES_COUNT = 5
MAX_RECIPES_COUNT = 10
NUM_OF_LINKS = 5 # Must be odd number

# VIEW HELPERS
helpers do
  def format_ingredients(text)
    text.split(/\r\n+/)
  end

  def format_instructions(text)
    text.split(/\r\n\r\n+/)
  end

  def page_class(page_num, current_page_num)
    'current_page' if page_num == current_page_num ||
                      (page_num == 1 && current_page_num.zero?)
  end

  # Returns a Range of desired numbered page links
  def page_links(num_of_pages, current_page_num)
    if num_of_pages <= NUM_OF_LINKS
      (1..num_of_pages)
    elsif (1..NUM_OF_LINKS / 2).cover?(current_page_num)
      (1..NUM_OF_LINKS)
    elsif current_page_num <= num_of_pages - (NUM_OF_LINKS / 2)
      (current_page_num - (NUM_OF_LINKS / 2)..current_page_num + (NUM_OF_LINKS / 2))
    else
      (num_of_pages - (NUM_OF_LINKS - 1)..num_of_pages)
    end
  end
end

# ROUTE HELPERS
def user_signed_in?
  session.key?(:user_id)
end

# Require login authentication
def require_sign_in(requested_url, user_input = nil)
  if user_signed_in?
    # Deletes requested URL & user input from session data after
    # successful login
    session.delete(:requested_url)
    session.delete(:user_input)
  else
    # Saves requested URL & any user input from submitted HTML forms
    # in the session data
    session[:requested_url] = requested_url
    session[:user_input] = user_input
    session[:message] = 'You must be signed in to do that.'
    redirect '/login'
  end
end

# Redirects user to appropriate URL after logging in
def redirect_after_login
  # If user performed create/update/delete operation while logged out
  # After logging in, invoke post route of the operation
  if session[:user_input]
    call env.merge('PATH_INFO' => session[:requested_url],
                   'rack.request.form_hash' => session[:user_input])
  else
    # If user performed read operation while logged out
    # After logging in, redirects to requested URL or '/cuisines' if none
    redirect session[:requested_url] || '/cuisines'
  end
end

def load_cuisine(id, user_id)
  if id =~ /^\d+$/
    cuisine = @storage.find_cuisine_by_id(id, user_id)
    return cuisine if cuisine
  end

  session[:message] = 'The specified cuisine was not found.'
  redirect '/cuisines'
end

def load_recipe(id, cuisine_id, user_id)
  if id =~ /^\d+$/
    recipe = @storage.find_recipe_by_id(id, cuisine_id, user_id)
    return recipe if recipe
  end

  session[:message] = 'The specified recipe was not found.'
  redirect "/cuisines/#{cuisine_id}/recipes"
end

# PAGINATION

# Creates a Hash with each key-value pair representing the
# page number referencing an Array of the items
# (cuisines/recipes) for that page
def all_pages_of_items(items, items_max_count)
  pages = Hash.new { |h, k| h[k] = [] }
  page_num = 1

  items.each_with_index do |item, index|
    pages[page_num] << item
    page_num += 1 if ((index + 1) % items_max_count).zero?
  end

  pages
end

# Returns an Array of items (cuisines/recipes) for a given page
def current_page_of_items(page_num, items_max_count, items)
  pages = all_pages_of_items(items, items_max_count)
  pages[page_num]
end

# INPUT VALIDATION
def error_for_username(username)
  if !(2..64).cover?(username.size)
    'Please enter a username between 2 and 64 characters long.'
  elsif username =~ /[^a-zA-Z0-9]/
    'Please enter a username containing alphanumeric (0-9, A-Z) characters only.'
  elsif @storage.find_user_by_username(username)
    'Sorry! That username is taken. Please choose a different one.'
  end
end

def error_for_password(password, confirm_password)
  if password !~ PASSWORD_REGEX
    'Please enter a password containing 8 or more alphanumeric characters. ' \
    'Your password must include at least one alphabetic (A-Z) and one numeric (0-9) ' \
    'character.'
  elsif password != confirm_password
    'Please make sure your password and confirmed password match.'
  end
end

def error_for_cuisine_name(cuisine_name, user_id)
  if !(1..64).cover?(cuisine_name.size)
    'Please enter a cuisine name between 1 and 64 characters.'
  elsif @storage.find_cuisine_by_name(cuisine_name, user_id)
    'Cuisine name must be unique.'
  end
end

def error_for_updated_cuisine_name(updated_name, original_name, user_id)
  if !(1..64).cover?(updated_name.size)
    'Please enter a cuisine name between 1 and 64 characters.'
  elsif updated_name !~ /#{original_name}/i &&
        @storage.find_cuisine_by_name(updated_name, user_id)
    'Cuisine name must be unique.'
  end
end

def error_for_recipe_name(recipe_name)
  return if (3..255).cover?(recipe_name.size)

  'You must enter a recipe name between 3 and 255 characters.'
end

def error_for_page_num(page_param, max_page)
  return if page_param.nil?

  if page_param !~ /^\d+$/ ||
    (max_page == 0 && page_param.to_i > 1) ||
     max_page > 0 && !(1..max_page).cover?(page_param.to_i)
    'Please enter a valid page number in the URL.'
  end
end
