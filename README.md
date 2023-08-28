# My Cookbook
My Cookbook is a Sinatra application that manages two data types: cuisines and recipes. Cuisines are collections of recipes. The user is able to create, display, update and delete both cuisines and recipes, and any changes are reflected in a PostgreSQL database that operates as our data store.

All paths on the application except the home page, signup page and login page are restricted and require login authentication.

## Database Schema & Seed Data
The SQL to create the database schema and seed data are contained within the seed_data.sql file. It includes the SQL to create the database `my_cookbook`, and the tables `users`, `cuisines`, and `recipes`. It also includes the SQL to insert seed data: the `admin` user, cuisines and recipes.

## Getting Started
**Version of Ruby I Used to Run Application:**
Ruby 2.7.0

**Browser Used to Test This Application:**
Google Chrome Version 102.0.5005.115 (Official Build) (64-bit)

**PostgreSQL Used to Create Databases:**
PostgreSQL 10.20

1. From your terminal, create the `my_cookbook` database with the following command: `createdb my_cookbook`.
2. Execute the `seed_data.sql` file within the database with the following command:
`psql -d my_cookbook < seed_data.sql`. This step creates the schema for the `my_cookbook` database and inserts the seed data into its tables.
3. Run the command `bundle install` to install all application dependencies.  
4. Start the application by running the main application file in the terminal: `ruby my_cookbook.rb`.
5.  Once you have connected the application to the web server, open the browser on your local computer to visit any paths on the application via the domain/port: http://localhost:4567.

**To Login After Creating Table Schema & Inserting Seed Data**
- Username: admin
- Password: abcd1234

**To Create An Account:**
- Enter a username
- Enter a password with 8 or more characters that contain a least 1 alphabetic letter and 1 number.
- Both the entered password and confirming password should match.
- After creating an account, user is redirected to the login page.

## Database Specifics:
users has a 1:Many relationship with cuisines
users has a 1:Many relationship with recipes
cuisines has a 1:Many relationship with recipes

- Purpose: A user can create and store many cuisines and recipes, each of which belongs to that specific user. A cuisine can have many recipes, however each recipe belongs to one cuisine.

- Advantage: This is advantageous for those who would like to store their recipes in multiple different cuisine categories. 

- Trade-off: It makes sense for a recipe to belong to one cuisine. However, there is a lack of flexibility when it comes to assigning a recipe that can belong to multiple different types of categories, such as Courses or Diet. One way to create more flexibility is to create a Categories table that has a Many:Many relationship with Recipes.

## General Features
- **'/cuisines'** displays all the cuisines in the cookbook, sorted alphabetically. 
	- Unique URLs are provided as buttons for adding a new cuisine and editing a cuisine name. 
	- Links to individual cuisines are provided, and a count of 5 cuisines are displayed per page of cuisines. 
	- The delete operation to delete a cuisine is provided as a button on this display page.

- **'/cuisines/:cuisine_id/recipes'** displays all the recipes for a cuisine, sorted alphabetically. 
	- Unique URLs are provided as buttons for adding a new recipe and editing a recipe. 
	- Links to individual recipes are provided, and a count of 10 recipes are displayed per page of recipes. 
	- The delete operation to delete a recipe is provided as a button on this display page.

- **Pagination**
	- On the bottom of the Cuisines and Recipes display page, a Previous link and a Next link allow you to display the previous or next page of cuisines/recipes.
    - If there are no recipes or cuisines, Previous and Next are not displayed. 
    - When the user is on the first page, the Previous is not presented as a link.
    - When the user is on the last page, Next is not presented as a link.  
	- Numbered page links in between Previous and Next allow access to specific pages. 
    - There is a maximum of 5 numbered page links, which can be adjusted to another odd number via a constant. 
    - When the number of pages (i.e. 4) is less than or equal to 5, numbers 1 to the number of pages (4) are displayed.
    - When the number of pages is more than 5 and the current page is 1 or 2, numbers 1 to 5 are displayed.
    - When the number of pages is more than 5 and the current page is higher than 2 but less than the total number of pages minus 2, then a sequence of 5 numbers are displayed with the current page in the middle of the sequence.   
    - The bolded numbered page link represents the current page the user is on.
	
- **Login Authentication**
	- If the user requests a URL (GET) while logged out:
    - The requested URL is saved as session data so that it can be accessed later. 
    - The user is redirected to the login page. 
    - Once the user logs in successfully, they are redirected to the requested URL, or '/cuisines' if there is none. 
    - The requested URL is deleted once the user is logged in.
  - If the user requests a URL (POST) while logged out (i.e. executes a create/update/delete operation):
    - The requested URL and the any user input submitted via HTML forms are saved as session data so that it can be accessed later. 
    - The user is redirected to the login page. 
    - Once the user logs in successfully, the POST route is called along with the user input, executing the operation. 
    - The requested URL and user input are deleted once the user is logged in.
 
- **Creating and Editing a Recipe**
	- The user is prompted to enter an ingredient per line, and to use an empty line between each instruction step.
	- Purpose: Allows the app to more easily parse the ingredients or instructions. The string of text is split on a newline or newlines into separate strings of ingredients or instruction steps, respectively, and then placed onto a list to be displayed.

## Notes
  - I extracted all my constants, view helpers and route helpers to a helpers.rb file and required it within the my_cookbook.rb main application file. 
