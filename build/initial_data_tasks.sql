-- ---------- tasks --------------
LOCK TABLES `tasks_categories` WRITE;
INSERT INTO `tasks_categories` VALUES ('Putzen',1),('Aufräumen',2),('Reparieren',3),('Sonstiges',127);
UNLOCK TABLES;