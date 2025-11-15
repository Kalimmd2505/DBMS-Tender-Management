# Secure Tender Management System (DBMS Mini Project) 🔒

This is a complete full-stack application designed to manage the entire tender lifecycle, from creation and bidding to evaluation and contract awarding. It uses a **Streamlit/Python front-end** and a **MySQL back-end** to enforce crucial business logic through Stored Procedures, Functions, and Triggers.

---

## 🚀 Key Features

* **Role-Based Access:** Features separate consoles for **Evaluators** (Admin/Manager role) and **Vendors**.
* **Full CRUD Operations:** Comprehensive management capabilities for creating, reading, updating, and deleting Tenders.
* **Evaluation Workflow (SP4):** Dedicated pages and logic for scoring bids.
* **Contract Awarding (SP1):** Automated process for creating contracts based on the tender outcome.
* **Data Integrity Enforcement (T5):** A trigger ensures each vendor can submit **only one bid per tender**.
* **Reporting (FN1, FN2):** Insight pages provide vendor performance metrics and tender scores.

---

## 🛠️ Technology Stack

The application is built using the following technologies:

* **Front-End:** Python 3 and **Streamlit** for the interactive web interface.
* **Back-End:** **MySQL Server** for data storage, integrity, and complex business logic execution.
* **Database Connector:** `mysql.connector` (Python driver).
* **Security:** `hashlib` is used for securely hashing passwords (`sha256`).
* **Data Handling:** `pandas` is used for displaying structured report data.

---

## 🔑 Database Logic & Business Rules

The backend enforces key business rules using specific MySQL elements:

### Triggers (T)
* **T5 (Prevent Duplicate Bids):** Blocks any attempt by a vendor to submit a second bid for the same tender.

### Stored Procedures (SPs) and Functions (FNs)
* **SP1 (`SP_AwardContract`):** Inserts the final contract record and updates tender/bid statuses to 'Awarded'.
* **SP2 (`SP_CreateNewUserAndVendor`):** Handles the creation of new user accounts and vendor records simultaneously.
* **SP3 (`SP_RetrieveTenderDetailsWithBids`):** Used to retrieve all bids submitted for a selected tender.
* **SP4 (`SP_SubmitEvaluationScore`):** Used by Evaluators to record a technical score and comments for a bid.
* **FN1 (`FN_GetAverageTenderScore`):** Calculates the average score for all bids submitted to a tender.
* **FN2 (`FN_GetLowestBidPrice`):** Finds the lowest submitted price, used during the award process.
* **FN4 (`FN_CheckIfVendorHasActiveContract`):** Used to verify vendor eligibility for new bids.

---

## 💻 Setup and Installation

### Prerequisites
* Python 3.x
* MySQL Server (accessible via `localhost` in the default configuration)

### Step 1: Database Setup (MySQL)
1.  Create the database: `CREATE DATABASE tender;`
2.  Create all necessary tables and ensure all Stored Procedures (SP1-SP4), Functions (FN1, FN2, FN4), and the Trigger (T5) are executed in your MySQL environment.

### Step 2: Python Environment
1.  Install all required Python packages using the **`requirements.txt`** file:
    ```bash
pip install -r requirements.txt
    ```
    (Alternatively: `pip install streamlit mysql-connector-python pandas`)

### Step 3: Configuration Update
1.  Open the **`streamlit_app.py`** file.
2.  Update the database credentials inside the `get_db_connection()` function:
    ```python
db_config = {
    "host": "localhost",
    "user": "root", # <<< REPLACE THIS!
    "password": "kalim", # <<< REPLACE THIS! 
    "database": "tender" 
}
    ```

### Step 4: Run the Application
1.  Execute the Streamlit application from your terminal:
    bash
    ```
streamlit run streamlit_app.py
    ```

---

## 👤 Default Roles for Testing

| Role | Console Name | Primary Actions |
| :--- | :--- | :--- |
| **Evaluator** | Tender Evaluator Console | Manages tenders, evaluates bids, and awards contracts. |
| **Vendor** | Vendor Portal | Submits bids and views awarded contracts. |

*(Note: The default password for users created via SP2 is **'password123'**.)*
