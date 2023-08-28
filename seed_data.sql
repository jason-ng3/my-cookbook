CREATE TABLE users (
  id serial PRIMARY KEY,
  username varchar(64) NOT NULL UNIQUE,
  hashed_password text NOT NULL
);

CREATE TABLE cuisines (
  id serial PRIMARY KEY,
  name text NOT NULL,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE recipes (
  id serial PRIMARY KEY,
  name varchar(255) NOT NULL,
  ingredients text,
  instructions text,
  cuisine_id INTEGER NOT NULL REFERENCES cuisines(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
);

INSERT INTO users (username, hashed_password)
VALUES ('admin', '$2a$12$3z45XTeaxkgbTOKm.T49L..0eLjAXe/9mmAKC/dFeUHXOGgLPDqvW');

INSERT INTO cuisines (name, user_id)
VALUES ('Chinese', 1), ('American', 1), ('Italian', 1), ('Greek', 1),
       ('Japanese', 1), ('Korean', 1), ('Thai', 1), ('Vietnamese', 1),
       ('Indonesian', 1), ('Malaysian', 1), ('Indian', 1), ('Tex-Mex', 1),
       ('Mexican', 1), ('Spanish', 1), ('Peruvian', 1), ('Colombian', 1),
       ('Southern', 1), ('German', 1), ('French', 1), ('Moroccan', 1),
       ('Singaporean', 1), ('Portuguese', 1), ('Lebanese', 1), ('Turkish', 1),
       ('Hungarian', 1), ('Cajun', 1);

INSERT INTO recipes (name, ingredients, instructions, cuisine_id, user_id)
VALUES ('Fried Rice', E'1 bowl short-grain rice cooked hard & refrigerated overnight\r\n3 tbsp oil\r2 whole eggs\r1 1/2 tsp chicken powd\r\n1/4 tsp salt\r1 tbsp soy sauce\r1/2 tsp white pepp\r\n1 spring onion, diced', 
        E'Cook rice so that it is hard. Use 10% less water.\r\nAdd 3 tbsp of oil and heat till hot, then add eggs and scramble.\r\nAdd rice and stir-fry. Loosen clumps of rice with the back of the spatula.\r\nAdd chicken powder, soy sauce, white pepper & spring onions.', 
        1, 1),
       ('Chicken Fried Rice', NULL, NULL, 1, 1),
       ('Pumpkin Congee', NULL, NULL, 1, 1),
       ('Long Bean Congee', NULL, NULL, 1, 1),
       ('Radish Soup', NULL, NULL, 1, 1),
       ('Mapo Tofu', NULL, NULL, 1, 1),
       ('Sichuan Chicken Wings', NULL, NULL, 1, 1),
       ('Stir-Fried Spinach', NULL, NULL, 1, 1),
       ('Crispy Chili Beef', NULL, NULL, 1, 1),
       ('Barbecued Pork', NULL, NULL, 1, 1),
       ('Soy Sauce Chicken', NULL, NULL, 1, 1),
       ('Roast Duck', NULL, NULL, 1, 1),
       ('Roast Pork', NULL, NULL, 1, 1),
       ('Pineapple Fried Rice', NULL, NULL, 1, 1),
       ('Dried Bean Curd Soup', NULL, NULL, 1, 1),
       ('Dried Mushroom Garlic Soup', NULL, NULL, 1, 1),
       ('Sea Bass With Ginger & Chilli', NULL, NULL, 1, 1),
       ('Cabbage Rice', NULL, NULL, 1, 1),
       ('Stir-Fried Green Beans', NULL, NULL, 1, 1),
       ('Sichuan Prawns', NULL, NULL, 1, 1),
       ('Steamed Chicken', NULL, NULL, 1, 1),
       ('Chinese Steamed Egg', NULL, NULL, 1, 1),
       ('One-Pot Hainanese Chicken Rice', NULL, NULL, 1, 1);