-- ---------- calories --------------

DROP TABLE IF EXISTS `calories_entries`;
DROP TABLE IF EXISTS `calories_categories`;
DROP TABLE IF EXISTS `calories_goals`;
--
-- Table structure for table `calories_categories`
--

CREATE TABLE `calories_categories` (
  `category` varchar(40) NOT NULL,
  `priority` tinyint(4) NOT NULL,
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `calories_entries`
--

CREATE TABLE `calories_entries` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `amount` decimal(15,2) NOT NULL,
  `date` date NOT NULL,
  `category` varchar(40) NOT NULL,
  `comment` varchar(40) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `category` (`category`),
  CONSTRAINT `calories_entries_ibfk_1` FOREIGN KEY (`category`) REFERENCES `calories_categories` (`category`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `calories_goals`
--

CREATE TABLE `calories_goals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `property` varchar(40) NOT NULL,
  `value` float NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `property` (`property`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ---------- hoursofwork --------------

DROP TABLE IF EXISTS `hoursofwork_entries`;
DROP TABLE IF EXISTS `hoursofwork_categories`;
DROP TABLE IF EXISTS `hoursofwork_goals`;
--
-- Table structure for table `hoursofwork_categories`
--

CREATE TABLE `hoursofwork_categories` (
  `category` varchar(40) NOT NULL,
  `priority` tinyint(4) NOT NULL,
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `hoursofwork_entries`
--

CREATE TABLE `hoursofwork_entries` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `amount` decimal(15,2) NOT NULL,
  `date` date NOT NULL,
  `category` varchar(40) NOT NULL,
  `comment` varchar(40) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `category` (`category`),
  CONSTRAINT `hoursofwork_entries_ibfk_1` FOREIGN KEY (`category`) REFERENCES `hoursofwork_categories` (`category`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `hoursofwork_goals`
--

CREATE TABLE `hoursofwork_goals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `property` varchar(40) NOT NULL,
  `value` float NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `property` (`property`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ---------- spendings --------------

DROP TABLE IF EXISTS `spendings_entries`;
DROP TABLE IF EXISTS `spendings_categories`;
DROP TABLE IF EXISTS `spendings_goals`;
--
-- Table structure for table `spendings_categories`
--

CREATE TABLE `spendings_categories` (
  `category` varchar(40) NOT NULL,
  `priority` tinyint(4) NOT NULL,
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `spendings_entries`
--

CREATE TABLE `spendings_entries` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `amount` decimal(15,2) NOT NULL,
  `date` date NOT NULL,
  `category` varchar(40) NOT NULL,
  `comment` varchar(40) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `category` (`category`),
  CONSTRAINT `spendings_entries_ibfk_1` FOREIGN KEY (`category`) REFERENCES `spendings_categories` (`category`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `spendings_goals`
--

CREATE TABLE `spendings_goals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `property` varchar(40) NOT NULL,
  `value` float NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `property` (`property`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
