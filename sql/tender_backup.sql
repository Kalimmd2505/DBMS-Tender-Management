-- MySQL dump 10.13  Distrib 9.4.0, for Win64 (x86_64)
--
-- Host: localhost    Database: tendermanagementsystem
-- ------------------------------------------------------
-- Server version	9.4.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `bid`
--

DROP TABLE IF EXISTS `bid`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bid` (
  `Bid_ID` int NOT NULL AUTO_INCREMENT,
  `Vendor_ID` int NOT NULL,
  `Price` decimal(15,2) NOT NULL,
  `Status` enum('Submitted','Under Review','Accepted','Rejected','Withdrawn') DEFAULT 'Submitted',
  `Documents` text,
  PRIMARY KEY (`Bid_ID`),
  KEY `Vendor_ID` (`Vendor_ID`),
  KEY `idx_bid_status` (`Status`),
  CONSTRAINT `bid_ibfk_2` FOREIGN KEY (`Vendor_ID`) REFERENCES `vendor` (`Vendor_ID`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bid`
--

LOCK TABLES `bid` WRITE;
/*!40000 ALTER TABLE `bid` DISABLE KEYS */;
INSERT INTO `bid` VALUES (1,1,4800000.00,'Submitted','tech_proposal.pdf'),(2,3,4950000.00,'Under Review','edutech_proposal.pdf'),(3,1,2300000.00,'Submitted','lms_tech_proposal.pdf'),(4,3,2450000.00,'Submitted','lms_edutech_proposal.pdf'),(5,5,1450000.00,'Submitted','furniture_proposal.pdf'),(6,4,7800000.00,'Under Review','solar_proposal.pdf'),(7,6,750000.00,'Rejected','printing_proposal.pdf'),(8,1,3400000.00,'Accepted','security_proposal.pdf');
/*!40000 ALTER TABLE `bid` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contract`
--

DROP TABLE IF EXISTS `contract`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `contract` (
  `Contract_ID` int NOT NULL AUTO_INCREMENT,
  `Tender_ID` int NOT NULL,
  `Vendor_ID` int NOT NULL,
  `Terms` text,
  `Value` decimal(15,2) NOT NULL,
  `Start_Date` date DEFAULT NULL,
  `End_Date` date DEFAULT NULL,
  `Signed_Date` date DEFAULT NULL,
  `Status` enum('Draft','Active','Completed','Terminated') DEFAULT 'Draft',
  PRIMARY KEY (`Contract_ID`),
  KEY `Tender_ID` (`Tender_ID`),
  KEY `Vendor_ID` (`Vendor_ID`),
  CONSTRAINT `contract_ibfk_1` FOREIGN KEY (`Tender_ID`) REFERENCES `tender` (`Tender_ID`) ON DELETE CASCADE,
  CONSTRAINT `contract_ibfk_2` FOREIGN KEY (`Vendor_ID`) REFERENCES `vendor` (`Vendor_ID`) ON DELETE CASCADE,
  CONSTRAINT `contract_chk_1` CHECK ((`End_Date` > `Start_Date`))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contract`
--

LOCK TABLES `contract` WRITE;
/*!40000 ALTER TABLE `contract` DISABLE KEYS */;
INSERT INTO `contract` VALUES (1,6,1,'Installation within 90 days, 5-year AMC included, penalty clause for delays',3400000.00,'2025-10-15','2026-01-15','2025-10-10','Active');
/*!40000 ALTER TABLE `contract` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `evaluation`
--

DROP TABLE IF EXISTS `evaluation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `evaluation` (
  `Evaluation_ID` int NOT NULL AUTO_INCREMENT,
  `Tender_ID` int NOT NULL,
  `User_ID` int NOT NULL,
  `Score` decimal(5,2) DEFAULT NULL,
  `Comments` text,
  `vid` int DEFAULT NULL,
  PRIMARY KEY (`Evaluation_ID`),
  UNIQUE KEY `unique_evaluation` (`Tender_ID`,`User_ID`,`vid`),
  KEY `User_ID` (`User_ID`),
  KEY `fk_evaluation_vendor` (`vid`),
  CONSTRAINT `evaluation_ibfk_1` FOREIGN KEY (`Tender_ID`) REFERENCES `tender` (`Tender_ID`) ON DELETE CASCADE,
  CONSTRAINT `evaluation_ibfk_2` FOREIGN KEY (`User_ID`) REFERENCES `user` (`User_ID`) ON DELETE CASCADE,
  CONSTRAINT `fk_evaluation_vendor` FOREIGN KEY (`vid`) REFERENCES `vendor` (`Vendor_ID`),
  CONSTRAINT `evaluation_chk_1` CHECK (((`Score` >= 0) and (`Score` <= 100)))
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evaluation`
--

LOCK TABLES `evaluation` WRITE;
/*!40000 ALTER TABLE `evaluation` DISABLE KEYS */;
INSERT INTO `evaluation` VALUES (1,1,4,85.50,'Strong technical proposal, competitive pricing',NULL),(2,1,5,82.00,'Good solution but needs clarification on support',NULL),(3,2,4,88.00,'Excellent cloud-based approach, scalable',NULL),(4,2,5,84.50,'Good features, slightly higher cost',NULL),(5,3,4,90.00,'Best quality and eco-friendly materials',NULL),(6,3,5,89.00,'Excellent warranty terms',NULL),(7,6,4,92.00,'Outstanding AI capabilities and integration',NULL),(8,6,5,91.50,'Best overall solution, recommend for award',NULL);
/*!40000 ALTER TABLE `evaluation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tender`
--

DROP TABLE IF EXISTS `tender`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tender` (
  `Tender_ID` int NOT NULL AUTO_INCREMENT,
  `Title` varchar(255) NOT NULL,
  `Deadline` date NOT NULL,
  `Doc` text,
  `uid` int DEFAULT NULL,
  PRIMARY KEY (`Tender_ID`),
  KEY `idx_tender_deadline` (`Deadline`),
  KEY `fk_tender_user` (`uid`),
  CONSTRAINT `fk_tender_user` FOREIGN KEY (`uid`) REFERENCES `user` (`User_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tender`
--

LOCK TABLES `tender` WRITE;
/*!40000 ALTER TABLE `tender` DISABLE KEYS */;
INSERT INTO `tender` VALUES (1,'Campus WiFi Infrastructure Upgrade','2025-11-15','wifi_tender_doc.pdf',NULL),(2,'Library Management System Development','2025-11-20','lms_tender_doc.pdf',NULL),(3,'Classroom Furniture Supply','2025-10-25','furniture_tender_doc.pdf',NULL),(4,'Solar Panel Installation','2025-12-01','solar_tender_doc.pdf',NULL),(5,'Annual Printing Services','2025-10-20','printing_tender_doc.pdf',NULL),(6,'Campus Security System Upgrade','2025-11-30','security_tender_doc.pdf',NULL);
/*!40000 ALTER TABLE `tender` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `User_ID` int NOT NULL AUTO_INCREMENT,
  `Login` varchar(100) NOT NULL,
  `Role` enum('Admin','Vendor','Manager','Evaluator') NOT NULL,
  `Permission` varchar(255) DEFAULT NULL,
  `Created_At` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `Last_Login` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`User_ID`),
  UNIQUE KEY `Login` (`Login`),
  KEY `idx_user_role` (`Role`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'admin@pesu.edu','Admin','Full Access','2025-10-09 17:14:33',NULL),(2,'manager1@pesu.edu','Manager','Create Tenders, View Reports','2025-10-09 17:14:33',NULL),(3,'manager2@pesu.edu','Manager','Create Tenders, View Reports','2025-10-09 17:14:33',NULL),(4,'evaluator1@pesu.edu','Evaluator','Evaluate Bids, View Tenders','2025-10-09 17:14:33',NULL),(5,'evaluator2@pesu.edu','Evaluator','Evaluate Bids, View Tenders','2025-10-09 17:14:33',NULL),(6,'vendor1@company.com','Vendor','Submit Bids, View Tenders','2025-10-09 17:14:33',NULL),(7,'vendor2@company.com','Vendor','Submit Bids, View Tenders','2025-10-09 17:14:33',NULL);
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vendor`
--

DROP TABLE IF EXISTS `vendor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vendor` (
  `Vendor_ID` int NOT NULL AUTO_INCREMENT,
  `Company_Name` varchar(200) NOT NULL,
  `Credentials` text,
  PRIMARY KEY (`Vendor_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vendor`
--

LOCK TABLES `vendor` WRITE;
/*!40000 ALTER TABLE `vendor` DISABLE KEYS */;
INSERT INTO `vendor` VALUES (1,'Tech Solutions Pvt Ltd','ISO 9001:2015, CMMI Level 3'),(2,'BuildRight Constructions','ISO 14001, OHSAS 18001'),(3,'EduTech Services','ISO 27001, PCI DSS Certified'),(4,'Green Energy Solutions','ISO 50001, LEED Certified'),(5,'Smart Furniture Co','FSC Certified, ISO 9001'),(6,'QuickPrint Services','ISO 9001:2015');
/*!40000 ALTER TABLE `vendor` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-10-30 12:43:12
