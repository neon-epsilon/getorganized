-- ---------- calories --------------
LOCK TABLES `calories_categories` WRITE;
INSERT INTO `calories_categories` (name, priority) VALUES ('Normales',1),('Getränke',2),('Snacks',3);
UNLOCK TABLES;

LOCK TABLES `calories_items` WRITE;
INSERT INTO `calories_items` (name, unit, kcal_per_unit, category_id) VALUES ('Müsli','100g',500,1),('Cola','100ml',40,2),('Schokolade','100g',550,3),('Süßigkeiten','Gramm',550,3),('Nüsse','100g',607,3),('Joghurt','100g',60,1),('Club Mate','100ml',20,2),('Magnum Double','Stück',245,3),('Baked Beans','420g',360,1),('Brot','50g Scheibe',125,1),('Hummus','100g',290,1),('Brezli','100g',370,3),('Tomatensaft','100g',17,2),('Veggie Fleischsalat','180g',405,1),('Miree Bärlauch','100g',237,1),('Fritt','Streifen',46,3),('Ei','60g',98,1),('Honigmelone','100g',36,1),('Konfitüre','100g',280,1),('Lutscher','12g',48,3),('Mittagessen','Portion',700,1),('Nachtisch','Portion',150,3),('Reis, gekocht','100g',130,1),('Brötchen','70g',210,1),('Chips','100g',500,3),('Nektarine','125g',55,1),('Grillkäse','100g Stück',321,1),('Salat','100g',80,1),('Dessert Creme','100g',200,3),('Pasta Arrabiata','100g',108,1),('Mars Eisriegel','51ml',140,3),('Butterbrezel','100g Stück',310,1),('Apfelstrudel','100g',200,3);
UNLOCK TABLES;

LOCK TABLES `calories_goals` WRITE;
INSERT INTO `calories_goals` (property, value) VALUES ('daily goal',2000);
UNLOCK TABLES;


-- ---------- hoursofwork --------------
LOCK TABLES `hoursofwork_categories` WRITE;
INSERT INTO `hoursofwork_categories` VALUES ('Amnesty',2),('FSI',3),('Uni',1);
UNLOCK TABLES;

LOCK TABLES `hoursofwork_goals` WRITE;
INSERT INTO `hoursofwork_goals` (property, value) VALUES ('weekly goal',37.5);
UNLOCK TABLES;


-- ---------- shoppinglist --------------
LOCK TABLES `shoppinglist_categories` WRITE;
INSERT INTO `shoppinglist_categories` VALUES ('Baumarkt',5),('Büro',4),('Drogerie',2),('Haushalt',3),('Kleidung',6),('Lebensmittel',1),('Sonstiges',127);
UNLOCK TABLES;


-- ---------- spendings --------------
LOCK TABLES `spendings_categories` WRITE;
INSERT INTO `spendings_categories` VALUES ('Anschaffung',4),('Behörden',5),('Dienstleistung',5),('Einkaufen',1),('Essen/Trinken',2),('Geschenk',4),('Hobby',4),('Kleidung',5),('Medizinisches',6),('Reise',7),('Sonstiges',127),('Spende',5),('Transport',6),('Weggehen',3);
UNLOCK TABLES;

LOCK TABLES `spendings_goals` WRITE;
INSERT INTO `spendings_goals` (property, value) VALUES ('monthly goal',500);
UNLOCK TABLES;

-- ---------- workout --------------
LOCK TABLES `workout_categories` WRITE;
INSERT INTO `workout_categories` VALUES ('Dehnen',3,'Übungen',5.00),('Fitnessstudio',2,'Wiederholungen',1.20),('Home Workout',4,'Wiederholungen',0.70),('Radfahren',1,'Minuten',4.00),('Rock\'n\'Roll',2,'Stunde',240.00),('Schwimmen',5,'Bahnen',40.00),('Zirkeltraining',5,'Trainingseinheit',300.00);
UNLOCK TABLES;
