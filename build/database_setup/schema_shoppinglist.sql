-- ---------- shoppinglist --------------

DROP TABLE IF EXISTS `shoppinglist_entries`;
DROP TABLE IF EXISTS `shoppinglist_categories`;
--
-- Table structure for table `shoppinglist_categories`
--

CREATE TABLE `shoppinglist_categories` (
  `category` varchar(40) NOT NULL,
  `priority` tinyint(4) NOT NULL,
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `shoppinglist_entries`
--

CREATE TABLE `shoppinglist_entries` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL,
  `category` varchar(40) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `category` (`category`),
  CONSTRAINT `shoppinglist_entries_ibfk_1` FOREIGN KEY (`category`) REFERENCES `shoppinglist_categories` (`category`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
