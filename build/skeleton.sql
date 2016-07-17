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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

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
