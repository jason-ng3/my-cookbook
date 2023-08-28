require 'pg'

# Implement API application uses to interact with SQL database
class DatabasePersistence
  def initialize(logger = nil)
    if Sinatra::Base.development?
      @db = PG.connect(dbname: 'my_cookbook')
    elsif Sinatra::Base.test?
      @db = PG.connect(dbname: 'my_cookbook_test')
    end

    @logger = logger
  end

  # USER
  def find_user_by_username(username)
    sql = 'SELECT * FROM users WHERE username ILIKE $1;'

    result = query(sql, username)
    result.ntuples.zero? ? nil : result.first
  end

  def create_user(username, password)
    sql = <<~SQL
      INSERT INTO users (username, hashed_password)
      VALUES ($1, $2)
    SQL

    hashed_password = BCrypt::Password.create(password)
    query(sql, username, hashed_password)
  end

  # CUISINES
  def all_cuisines(user_id)
    sql = <<~SQL
      SELECT cuisines.*, COUNT(recipes.id) AS recipes_count
      FROM cuisines LEFT OUTER JOIN recipes
      ON cuisines.id = recipes.cuisine_id
      WHERE cuisines.user_id = $1
      GROUP BY cuisines.id
      ORDER BY LOWER(cuisines.name);
    SQL

    result = query(sql, user_id)
    result.map { |tuple| tuple_to_cuisine_hash(tuple) }
  end

  def find_cuisine_by_name(cuisine_name, user_id)
    sql = <<~SQL
      SELECT * FROM cuisines
      WHERE name ILIKE $1 AND user_id = $2;
    SQL

    result = query(sql, cuisine_name, user_id)
    result.ntuples.zero? ? nil : tuple_to_cuisine_hash(result.first)
  end

  def find_cuisine_by_id(cuisine_id, user_id)
    sql = 'SELECT * FROM cuisines WHERE id = $1 AND user_id = $2;'

    result = query(sql, cuisine_id, user_id)
    result.first ? tuple_to_cuisine_hash(result.first) : nil
  end

  def create_cuisine(cuisine_name, user_id)
    sql = <<~SQL
      INSERT INTO cuisines (name, user_id)
      VALUES ($1, $2)
    SQL

    query(sql, cuisine_name, user_id)
  end

  def update_cuisine(cuisine_name, cuisine_id, user_id)
    sql = <<~SQL
      UPDATE cuisines
      SET name = $1
      WHERE id = $2 AND user_id = $3
    SQL

    query(sql, cuisine_name, cuisine_id, user_id)
  end

  def delete_cuisine(cuisine_id, user_id)
    sql = 'DELETE FROM cuisines WHERE id = $1 AND user_id = $2'

    query(sql, cuisine_id, user_id)
  end

  # RECIPES
  def all_recipes(cuisine_id, user_id)
    sql = <<~SQL
      SELECT * FROM recipes 
      WHERE cuisine_id = $1 AND user_id = $2 
      ORDER BY LOWER(name);
    SQL

    result = query(sql, cuisine_id, user_id)

    result.map do |tuple|
      tuple_to_recipe_hash(tuple)
    end
  end

  def find_recipe_id(recipe_name, user_id)
    sql = 'SELECT id FROM recipes WHERE name ILIKE $1 AND user_id = $2;'
    result = query(sql, recipe_name, user_id)
    result.values.first.first.to_i
  end

  def find_recipe_by_id(recipe_id, cuisine_id, user_id)
    sql = <<~SQL
      SELECT * FROM recipes 
      WHERE id = $1 AND cuisine_id = $2 AND user_id = $3;
    SQL

    result = query(sql, recipe_id, cuisine_id, user_id)
    result.first ? tuple_to_recipe_hash(result.first) : nil
  end

  def create_new_recipe(recipe_info, cuisine_id, user_id)
    sql = <<~SQL
      INSERT INTO recipes (name, ingredients, instructions, cuisine_id, user_id)
      VALUES ($1, $2, $3, $4, $5);
    SQL

    query(sql, *recipe_info, cuisine_id, user_id)
  end

  def update_recipe(recipe_info, recipe_id, cuisine_id, user_id)
    sql = <<~SQL
      UPDATE recipes
      SET name = $1, ingredients = $2, instructions = $3
      WHERE id = $4 AND cuisine_id = $5 AND user_id = $6;
    SQL

    query(sql, *recipe_info, recipe_id, cuisine_id, user_id)
  end

  def delete_recipe(recipe_id, cuisine_id, user_id)
    sql = <<~SQL
      DELETE FROM recipes 
      WHERE id = $1 AND cuisine_id = $2 AND user_id = $3;
    SQL

    query(sql, recipe_id, cuisine_id, user_id)
  end

  def delete_all
    @db.exec('DELETE FROM recipes;')
    @db.exec('DELETE FROM cuisines;')
    @db.exec('DELETE FROM users;')
  end

  def disconnect
    @db.close
  end

  private

  def query(sql, *params)
    @logger&.info "#{sql}: #{params}"
    @db.exec_params(sql, params)
  end

  def tuple_to_cuisine_hash(tuple)
    { id: tuple['id'].to_i,
      name: tuple['name'],
      recipes_count: tuple['recipes_count'].to_i }
  end

  def tuple_to_recipe_hash(tuple)
    { id: tuple['id'].to_i,
      name: tuple['name'],
      ingredients: tuple['ingredients'],
      instructions: tuple['instructions'] }
  end
end
