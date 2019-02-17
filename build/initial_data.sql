-- ---------- calories --------------
LOCK TABLES `calories_categories` WRITE;
INSERT INTO `calories_categories` VALUES ('Normales',1),('Getränke',2),('Snacks',3),('Sport',4);
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
