-- ---------- shoppinglist --------------

CREATE TABLE IF NOT EXISTS `shoppinglist_categories` (
  `category` varchar(40) NOT NULL,
  `priority` tinyint(4) NOT NULL,
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `shoppinglist`
--

CREATE TABLE IF NOT EXISTS `shoppinglist` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(40) NOT NULL DEFAULT '',
  `category` varchar(40) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  CONSTRAINT `shoppinglist_ibfk_1` FOREIGN KEY (`category`) REFERENCES `shoppinglist_categories` (`category`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
