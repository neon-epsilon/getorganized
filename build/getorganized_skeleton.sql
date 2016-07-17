------------ calories --------------
--
-- Table structure for table `calories_categories`
--

DROP TABLE IF EXISTS `calories_categories`;
CREATE TABLE `calories_categories` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) DEFAULT NULL,
  `priority` tinyint(4) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `category` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

LOCK TABLES `calories_categories` WRITE;
INSERT INTO `calories_categories` VALUES (1,'Normales',1),(2,'Getränke',2),(3,'Snacks',3);
UNLOCK TABLES;

--
-- Table structure for table `calories_items`
--

DROP TABLE IF EXISTS `calories_items`;
CREATE TABLE `calories_items` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) DEFAULT NULL,
  `unit` varchar(40) NOT NULL,
  `kcal_per_unit` float unsigned NOT NULL,
  `category_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `category_id` (`category_id`),
  CONSTRAINT `calories_items_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `calories_categories` (`id`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8;

LOCK TABLES `calories_items` WRITE;
INSERT INTO `calories_items` VALUES (2,'Müsli','100g',500,1),(3,'Cola','100ml',40,2),(4,'Schokolade','100g',550,3),(5,'Süßigkeiten','Gramm',550,3),(6,'Nüsse','100g',607,3),(7,'Joghurt','100g',60,1),(8,'Club Mate','100ml',20,2),(9,'Magnum Double','Stück',245,3),(10,'Baked Beans','420g',360,1),(11,'Brot','50g Scheibe',125,1),(12,'Hummus','100g',290,1),(13,'Brezli','100g',370,3),(15,'Tomatensaft','100g',17,2),(16,'Veggie Fleischsalat','180g',405,1),(17,'Miree Bärlauch','100g',237,1),(18,'Fritt','Streifen',46,3),(19,'Ei','60g',98,1),(20,'Honigmelone','100g',36,1),(21,'Konfitüre','100g',280,1),(22,'Lutscher','12g',48,3),(23,'Mittagessen','Portion',700,1),(24,'Nachtisch','Portion',150,3),(25,'Reis, gekocht','100g',130,1),(26,'Brötchen','70g',210,1),(27,'Chips','100g',500,3),(28,'Nektarine','125g',55,1),(29,'Grillkäse','100g Stück',321,1),(30,'Salat','100g',80,1),(31,'Dessert Creme','100g',200,3),(32,'Pasta Arrabiata','100g',108,1),(33,'Mars Eisriegel','51ml',140,3),(34,'Butterbrezel','100g Stück',310,1),(35,'Apfelstrudel','100g',200,3);
UNLOCK TABLES;

--
-- Table structure for table `calories_entries`
--

DROP TABLE IF EXISTS `calories_entries`;
CREATE TABLE `calories_entries` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `item_id` int(10) unsigned NOT NULL,
  `quantity` float NOT NULL,
  PRIMARY KEY (`id`),
  KEY `item_id` (`item_id`),
  CONSTRAINT `calories_entries_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `calories_items` (`id`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `calories_goals`
--

DROP TABLE IF EXISTS `calories_goals`;
CREATE TABLE `calories_goals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `property` varchar(40) NOT NULL,
  `value` float NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `property` (`property`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

--
-- Dumping data for table `calories_goals`
--

LOCK TABLES `calories_goals` WRITE;
INSERT INTO `calories_goals` VALUES (1,'daily goal',2000);
UNLOCK TABLES;


------------ hoursofwork --------------
--
-- Table structure for table `hoursofwork_categories`
--

DROP TABLE IF EXISTS `hoursofwork_categories`;
CREATE TABLE `hoursofwork_categories` (
  `category` varchar(40) NOT NULL,
  `priority` tinyint(4) NOT NULL,
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `hoursofwork_categories` WRITE;
INSERT INTO `hoursofwork_categories` VALUES ('Amnesty',2),('FSI',3),('Uni',1);
UNLOCK TABLES;

--
-- Table structure for table `hoursofwork`
--

DROP TABLE IF EXISTS `hoursofwork`;
CREATE TABLE `hoursofwork` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `amount` decimal(15,2) NOT NULL,
  `date` date NOT NULL,
  `category` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `category` (`category`),
  CONSTRAINT `hoursofwork_ibfk_1` FOREIGN KEY (`category`) REFERENCES `hoursofwork_categories` (`category`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `hoursofwork_goals`
--

DROP TABLE IF EXISTS `hoursofwork_goals`;
CREATE TABLE `hoursofwork_goals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `property` varchar(40) NOT NULL,
  `value` float NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `property` (`property`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

LOCK TABLES `hoursofwork_goals` WRITE;
INSERT INTO `hoursofwork_goals` VALUES (1,'weekly goal',37.5);
UNLOCK TABLES;



------------ shoppinglist --------------
--
-- Table structure for table `shoppinglist_categories`
--

DROP TABLE IF EXISTS `shoppinglist_categories`;
CREATE TABLE `shoppinglist_categories` (
  `category` varchar(40) NOT NULL,
  `priority` tinyint(4) NOT NULL,
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `shoppinglist_categories` WRITE;
INSERT INTO `shoppinglist_categories` VALUES ('Baumarkt',5),('Büro',4),('Drogerie',2),('Haushalt',3),('Kleidung',6),('Lebensmittel',1),('Sonstiges',127);
UNLOCK TABLES;

--
-- Table structure for table `shoppinglist`
--

DROP TABLE IF EXISTS `shoppinglist`;
CREATE TABLE `shoppinglist` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL DEFAULT '',
  `category` varchar(40) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


------------ spendings --------------
--
-- Table structure for table `spendings_categories`
--

DROP TABLE IF EXISTS `spendings_categories`;
CREATE TABLE `spendings_categories` (
  `category` varchar(40) NOT NULL,
  `priority` tinyint(4) NOT NULL,
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `spendings_categories` WRITE;
INSERT INTO `spendings_categories` VALUES ('Anschaffung',4),('Behörden',5),('Dienstleistung',5),('Einkaufen',1),('Essen/Trinken',2),('Geschenk',4),('Hobby',4),('Kleidung',5),('Medizinisches',6),('Reise',7),('Sonstiges',127),('Spende',5),('Transport',6),('Weggehen',3);
UNLOCK TABLES;

--
-- Table structure for table `spendings`
--

DROP TABLE IF EXISTS `spendings`;
CREATE TABLE `spendings` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `amount` decimal(15,2) NOT NULL,
  `date` date NOT NULL,
  `category` varchar(40) NOT NULL,
  `comment` varchar(40) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `category` (`category`),
  CONSTRAINT `spendings_ibfk_1` FOREIGN KEY (`category`) REFERENCES `spendings_categories` (`category`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `spendings_goals`
--

DROP TABLE IF EXISTS `spendings_goals`;
CREATE TABLE `spendings_goals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `property` varchar(40) NOT NULL,
  `value` float NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `property` (`property`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

LOCK TABLES `spendings_goals` WRITE;
INSERT INTO `spendings_goals` VALUES (1,'monthly goal',500);
UNLOCK TABLES;

------------ workout --------------
--
-- Table structure for table `workout_categories`
--

DROP TABLE IF EXISTS `workout_categories`;
CREATE TABLE `workout_categories` (
  `category` varchar(40) NOT NULL,
  `priority` tinyint(4) NOT NULL,
  `unit` varchar(40) NOT NULL,
  `fitnessscore_multiplier` decimal(5,2) DEFAULT NULL,
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `workout_categories` WRITE;
INSERT INTO `workout_categories` VALUES ('Dehnen',3,'Übungen',5.00),('Fitnessstudio',2,'Wiederholungen',1.20),('Home Workout',4,'Wiederholungen',0.70),('Radfahren',1,'Minuten',4.00),('Rock\'n\'Roll',2,'Stunde',240.00),('Schwimmen',5,'Bahnen',40.00),('Zirkeltraining',5,'Trainingseinheit',300.00);
UNLOCK TABLES;

--
-- Table structure for table `workout`
--

DROP TABLE IF EXISTS `workout`;
CREATE TABLE `workout` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `amount` smallint(5) unsigned NOT NULL,
  `date` date NOT NULL,
  `category` varchar(40) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `category` (`category`),
  CONSTRAINT `workout_ibfk_1` FOREIGN KEY (`category`) REFERENCES `workout_categories` (`category`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
