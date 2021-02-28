-- ---------- tasks --------------

DROP TABLE IF EXISTS `tasks_entries`;
DROP TABLE IF EXISTS `tasks_categories`;
--
-- Table structure for table `tasks_categories`
--

CREATE TABLE `tasks_categories` (
  `category` varchar(40) NOT NULL,
  `priority` tinyint(4) NOT NULL,
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `tasks_entries`
--

CREATE TABLE `tasks_entries` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL,
  `category` varchar(40) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `category` (`category`),
  CONSTRAINT `tasks_entries_ibfk_1` FOREIGN KEY (`category`) REFERENCES `tasks_categories` (`category`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;