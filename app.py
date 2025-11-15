# streamlit_app.py - FINAL COMPLETE APPLICATION CODE (Full CRUD Implemented)

import streamlit as st
import mysql.connector
import hashlib 
import pandas as pd
from datetime import date
from io import BytesIO

# --- Database Configuration (UPDATE THIS!) ---
def get_db_connection():
    db_config = {
        "host": "localhost",
        "user": "root", # <<< REPLACE THIS!
        "password": "kalim", # <<< REPLACE THIS!
        "database": "tender" 
    }
    try:
        db = mysql.connector.connect(**db_config)
        return db
    except mysql.connector.Error as err:
        st.error(f"Database connection error: {err}")
        st.stop()
        return None

# --- Core Database Functions for Login ---

def verify_credentials(login_id, password):
    """Retrieves user details and verifies password hash."""
    db = get_db_connection()
    if db is None: return None
    cursor = db.cursor(dictionary=True)
    
    try:
        cursor.execute("SELECT User_ID, Login, Role, Password_Hash FROM user WHERE Login = %s", (login_id,))
        user = cursor.fetchone()
    finally:
        cursor.close()
        db.close()
    
    if user:
        input_hash = hashlib.sha256(password.encode()).hexdigest()
        if input_hash == user['Password_Hash']:
            return user
        
    return None

# --- EVALUATOR/USER ROLE PAGES (FLOWCHART: USER) ---

def create_tender_page():
    st.header("Create New Tender (CRUD: CREATE)")
    st.markdown("---")
    
    db = get_db_connection()
    if db is None: return

    with st.form("create_tender_form"):
        title = st.text_input("Tender Title")
        deadline = st.date_input("Submission Deadline")
        document_name = st.text_input("Attached Document Name (e.g., tender_spec.pdf)")
        
        submitted = st.form_submit_button("Create Tender")
        
        if submitted:
            try:
                cursor = db.cursor()
                cursor.execute("""
                    INSERT INTO tender (Title, Deadline, Doc, uid)
                    VALUES (%s, %s, %s, %s)
                """, (title, deadline, document_name, st.session_state['user_id']))
                db.commit()
                st.success(f"Tender '{title}' created successfully.")
            except mysql.connector.Error as err:
                st.error(f"Error creating tender: {err}")
            finally:
                cursor.close()
                db.close()

def manage_tenders_page():
    st.header("Manage Tenders (CRUD: UPDATE & DELETE)")
    st.markdown("---")

    db = get_db_connection()
    if db is None: return

    try:
        cursor = db.cursor(dictionary=True)
        # READ current tenders
        cursor.execute("SELECT Tender_ID, Title, Deadline, Doc FROM tender ORDER BY Tender_ID DESC;")
        tenders = cursor.fetchall()

        if not tenders:
            st.info("No tenders available to manage.")
            return

        tender_titles = {t['Tender_ID']: t['Title'] for t in tenders}
        
        # Select tender for action
        selected_id = st.selectbox("Select Tender to Modify", options=list(tender_titles.keys()), format_func=lambda x: tender_titles[x])
        selected_tender = next(t for t in tenders if t['Tender_ID'] == selected_id)

        st.subheader(f"Actions for: {selected_tender['Title']}")

        # --- UPDATE FORM (CRUD: UPDATE) ---
        with st.form("update_form"):
            st.markdown("##### Update Tender Details")
            new_title = st.text_input("New Title", value=selected_tender['Title'])
            new_deadline = st.date_input("New Deadline", value=selected_tender['Deadline'])
            new_doc = st.text_input("New Document Name", value=selected_tender['Doc'])
            
            col1, col2 = st.columns(2)
            
            if col1.form_submit_button("Update Tender"):
                try:
                    cursor.execute("""
                        UPDATE tender SET Title = %s, Deadline = %s, Doc = %s WHERE Tender_ID = %s
                    """, (new_title, new_deadline, new_doc, selected_id))
                    db.commit()
                    st.success(f"Tender {selected_id} updated successfully.")
                except mysql.connector.Error as err:
                    st.error(f"Update failed: {err}")
                finally:
                    st.rerun()

        # --- DELETE BUTTON (CRUD: DELETE) ---
            if col2.form_submit_button("Delete Tender", help="WARNING: This action is permanent."):
                try:
                    cursor.execute("DELETE FROM tender WHERE Tender_ID = %s", (selected_id,))
                    db.commit()
                    st.success(f"Tender {selected_id} deleted successfully.")
                except mysql.connector.Error as err:
                    st.error(f"Delete failed: {err}. Ensure no contracts or bids reference this tender.")
                finally:
                    st.rerun()
        
        st.subheader("Current Tender List (CRUD: READ)")
        st.dataframe(pd.DataFrame(tenders)) # Displaying the list is the Read operation

    except Exception as e:
        st.error(f"An unexpected error occurred: {e}")
    finally:
        if db.is_connected(): db.close()

def view_all_tenders_page(db):
    st.header("View All Tenders (CRUD: READ & JOIN)")
    st.markdown("---")
    try:
        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT Tender_ID, Title, Deadline, Doc FROM tender;")
        tenders = cursor.fetchall()
        
        st.subheader("View Bids for a Tender (SP3 - Join)")
        tender_ids = [t['Tender_ID'] for t in tenders]
        if not tender_ids:
            st.info("No tenders available.")
            return

        selected_id = st.selectbox("Select Tender to view bids", options=tender_ids, format_func=lambda x: next(t['Title'] for t in tenders if t['Tender_ID'] == x))
        
        if selected_id:
            cursor.callproc('SP_RetrieveTenderDetailsWithBids', (selected_id,))
            bids_data = []
            for res in cursor.stored_results(): # Safe result fetching
                bids_data.extend(res.fetchall())
            
            if bids_data:
                st.dataframe(pd.DataFrame(bids_data))
            else:
                st.info("No bids submitted for this tender.")
            
    except mysql.connector.Error as err:
        st.error(f"Error loading tenders: {err}")

def evaluate_bids_page():
    st.header("Evaluate Bids (SP4)")
    st.markdown("---")
    
    db = get_db_connection()
    if db is None: return
    
    try:
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT b.Bid_ID, t.Tender_ID, v.Vendor_ID, t.Title, v.Company_Name, b.Price 
            FROM bid b
            JOIN tender t ON b.Tender_ID = t.Tender_ID
            JOIN vendor v ON b.Vendor_ID = v.Vendor_ID
            WHERE b.Status IN ('Submitted', 'Under Review');
        """)
        bids_to_evaluate = cursor.fetchall()

        if not bids_to_evaluate:
            st.info("No active bids requiring evaluation.")
            return
        
        bid_options = {b['Bid_ID']: f"{b['Title']} - {b['Company_Name']} (₹{b['Price']:,.2f})" for b in bids_to_evaluate}
        selected_bid_id = st.selectbox("Select Bid to Score", options=list(bid_options.keys()), format_func=lambda x: bid_options[x])
        
        selected_bid = next(b for b in bids_to_evaluate if b['Bid_ID'] == selected_bid_id)
        
        with st.form("evaluation_form"):
            score = st.slider("Score (0-100)", min_value=0.00, max_value=100.00, value=85.00, step=0.50)
            comments = st.text_area("Evaluation Comments")

            submit_eval = st.form_submit_button("Submit Evaluation (Calls SP4)")

            if submit_eval:
                cursor.close()
                cursor = db.cursor() 
                try:
                    # EXECUTE SP4 - The INSERT operation
                    args = (selected_bid['Tender_ID'], st.session_state['user_id'], selected_bid['Vendor_ID'], score, comments)
                    cursor.callproc('SP_SubmitEvaluationScore', args)
                    db.commit()
                    st.success("Evaluation submitted successfully (SP4 executed).")
                except mysql.connector.Error as err:
                    st.error(f"Evaluation Error: {err}")
                finally:
                    cursor.close()
                    st.rerun()
        
    except mysql.connector.Error as err:
        st.error(f"Database Error: {err}")
    finally:
        if db.is_connected(): db.close()

def award_contract_page():
    st.subheader("Award Contract (SP1)")
    st.markdown("---")
    
    db = get_db_connection()
    if db is None: return
    
    try:
        cursor = db.cursor(dictionary=True)
        # 1. Get open tenders
        cursor.callproc('SP_GetOpenTenders')
        open_tenders = []
        for res in cursor.stored_results(): # Safe result fetching
             open_tenders.extend(res.fetchall())
             
        # 2. Get all vendors
        cursor.execute("SELECT Vendor_ID, Company_Name FROM vendor;")
        vendors = cursor.fetchall()

        if not open_tenders:
            st.info("No tenders currently available for awarding.")
            return

        tender_options = {t['Tender_ID']: f"{t['Tender_ID']} - {t['Title']}" for t in open_tenders}
        selected_tender_id = st.selectbox("Select Tender to Award", options=list(tender_options.keys()), format_func=lambda x: tender_options[x])
        
        # 3. Get Lowest Bid Price (FN2) based on selected tender
        # Re-fetch cursor as previous one might be messy from stored_results()
        cursor.close()
        cursor = db.cursor()
        cursor.execute("SELECT FN_GetLowestBidPrice(%s);", (selected_tender_id,))
        lowest_price = cursor.fetchone()[0]
        
        # Convert lowest_price to float safely for display/input
        lowest_price_float = float(lowest_price) if lowest_price is not None else 1.00 
        
        # Re-fetch vendors to map IDs correctly for the form
        vendor_map = {v['Vendor_ID']: v['Company_Name'] for v in vendors}

        with st.form("award_form"):
            st.markdown(f"**Lowest Bid Price Found (FN2):** ₹{lowest_price_float:,.2f}")
            
            selected_vendor_id = st.selectbox(
                "Select Winning Vendor", 
                options=list(vendor_map.keys()), 
                format_func=lambda x: vendor_map[x]
            )
            value = st.number_input(
                "Contract Value (Must match Bid Price)", 
                min_value=1.00, 
                value=lowest_price_float, # Use the safely converted float
                format="%.2f"
            )
            start_date = st.date_input("Start Date", value=date.today())
            end_date = st.date_input("End Date", value=date(date.today().year + 1, date.today().month, date.today().day))
            terms = st.text_area("Contract Terms")
            
            submitted = st.form_submit_button("Finalize Award and Create Contract (Calls SP1)")

            # --- SUBMISSION LOGIC (THE FIX) ---
            if submitted:
                # Ensure the previous cursor (from FN_GetLowestBidPrice) is closed
                cursor.close() 
                cursor = db.cursor()
                try:
                    # EXECUTE SP1: SP_AwardContract
                    args = (
                        selected_tender_id, 
                        selected_vendor_id, 
                        value, 
                        start_date, 
                        end_date, 
                        terms,
                        st.session_state['user_id'] # Evaluator/Admin UID
                    )
                    
                    cursor.callproc('SP_AwardContract', args) 
                    db.commit()
                    st.success("Contract awarded successfully (SP1 executed).")
                    
                    # Close the cursor before re-running the app state
                    cursor.close() 
                    st.rerun() 
                    
                except mysql.connector.Error as err:
                    st.error(f"Contract Award Error (SP1 Failed): {err.msg}") 
                    # Only close cursor on failure, as success branches to rerun (implicitly cleaning up resources)
                    cursor.close() 
                # Removed the inner 'finally' block to prevent the 'connection' error.
        
    except Exception as e:
        # Generic catch block remains, but the submission logic now handles its own errors
        st.error(f"An error occurred: {e}") 
    finally:
        # Only close the connection if it's still open
        if db.is_connected(): db.close()

def view_contracts_page():
    st.header("View Contracts")
    st.markdown("---")

    db = get_db_connection()
    if db is None: return

    try:
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT c.Contract_ID, t.Title, v.Company_Name, c.Value, c.Status, c.Signed_Date
            FROM contract c
            JOIN tender t ON c.Tender_ID = t.Tender_ID
            JOIN vendor v ON c.Vendor_ID = v.Vendor_ID;
        """)
        contracts = cursor.fetchall()
        st.dataframe(pd.DataFrame(contracts))

    except Exception as e:
        st.error(f"Error loading contracts: {e}")
    finally:
        if db.is_connected(): db.close()

def user_management_page():
    st.header("Create New User or Vendor (SP2)")
    st.markdown("---")
    
    db = get_db_connection()
    if db is None: return

    with st.form("user_creation_form"):
        new_login = st.text_input("Login ID (e.g., user@company.com)")
        new_role = st.selectbox("Role", options=['Vendor', 'Evaluator']) # Consolidated roles
        new_permission = st.text_input("Permission Summary", value="Default Access")
        st.markdown("---")
        
        company_name = st.text_input("Company Name (Required for Vendor)")
        credentials = st.text_area("Vendor Credentials/Certifications")
        
        submit_user = st.form_submit_button("Create User (Calls SP2)")

        if submit_user:
            cursor = db.cursor() 
            try:
                # EXECUTE SP2
                args = (new_login, new_role, new_permission, company_name if new_role == 'Vendor' else None, credentials if new_role == 'Vendor' else None)
                cursor.callproc('SP_CreateNewUserAndVendor', args)
                db.commit()
                st.success(f"User/Vendor '{new_login}' created successfully (SP2 executed). Default password is 'password123'.")
            except mysql.connector.Error as err:
                st.error(f"Creation Error: {err}")
            finally:
                cursor.close()
                db.close()
                st.rerun()

def reports_insights_page():
    st.header("Reports & Insights")
    st.markdown("---")

    db = get_db_connection()
    if db is None: return
    
    try:
        cursor = db.cursor()

        # FN1: Average Tender Score
        tender_id = 1
        cursor.execute("SELECT FN_GetAverageTenderScore(%s);", (tender_id,))
        avg_score = cursor.fetchone()[0]

        # General Metrics
        col1, col2 = st.columns(2)
        col1.metric(f"Avg Score (Tender {tender_id})", f"{avg_score:.2f}%")
        
        # View Vendor Performance (Simulated logic matching flowchart)
        st.subheader("Vendor Success Rates (Simulated)")

        cursor.execute("""
            SELECT v.Company_Name, 
                   COUNT(DISTINCT c.Contract_ID) AS awarded,
                   COUNT(b.Bid_ID) AS submitted
            FROM vendor v
            LEFT JOIN bid b ON v.Vendor_ID = b.Vendor_ID
            LEFT JOIN contract c ON v.Vendor_ID = c.Vendor_ID
            GROUP BY v.Company_Name;
        """)
        report_data = cursor.fetchall()
        
        report_df = pd.DataFrame(report_data, columns=['Vendor', 'Awarded Contracts', 'Total Bids'])
        report_df['Success Rate (%)'] = (report_df['Awarded Contracts'] / report_df['Total Bids'].replace(0, 1)) * 100
        
        st.dataframe(report_df.sort_values('Success Rate (%)', ascending=False))


    except Exception as e:
        st.error(f"Error loading reports: {e}")
    finally:
        if db.is_connected(): db.close()

def manager_dashboard(): # Keeping function name, changing content references
    st.title("Tender Evaluator Console") 
    
    if 'manager_page' not in st.session_state:
        st.session_state['manager_page'] = 'Dashboard'

    st.sidebar.markdown("### Evaluator Actions") # Changed header
    
    # Navigation Buttons (Set page state)
    if st.sidebar.button("Dashboard"): st.session_state['manager_page'] = 'Dashboard'
    if st.sidebar.button("Create Tender"): st.session_state['manager_page'] = 'Create Tender'
    if st.sidebar.button("Manage Tenders (U/D)"): st.session_state['manager_page'] = 'Manage Tenders' # CRUD U/D
    if st.sidebar.button("View All Tenders"): st.session_state['manager_page'] = 'View All Tenders' # CRUD R
    if st.sidebar.button("Evaluate Bids"): st.session_state['manager_page'] = 'Evaluate Bids'
    if st.sidebar.button("Award Contract"): st.session_state['manager_page'] = 'Award Contract'
    if st.sidebar.button("View Contracts"): st.session_state['manager_page'] = 'View Contracts'
    if st.sidebar.button("Reports & Insights"): st.session_state['manager_page'] = 'Reports & Insights'
    if st.sidebar.button("User Management"): st.session_state['manager_page'] = 'User Management'
    
    db = get_db_connection()
    if db is None: return

    if st.session_state['manager_page'] == 'Dashboard':
        st.header("Dashboard Summary")
        try:
            cursor = db.cursor(dictionary=True)
            cursor.execute("SELECT COUNT(Tender_ID) AS total_tenders FROM tender;")
            total_tenders = cursor.fetchone()['total_tenders']
            cursor.execute("SELECT COUNT(Bid_ID) AS bids_review FROM bid WHERE Status='Under Review';")
            bids_review = cursor.fetchone()['bids_review']
            cursor.execute("SELECT COUNT(Contract_ID) AS active_contracts FROM contract WHERE Status='Active';")
            active_contracts = cursor.fetchone()['active_contracts']
            
            col1, col2, col3 = st.columns(3)
            col1.metric("Total Tenders", total_tenders)
            col2.metric("Bids Under Review", bids_review)
            col3.metric("Active Contracts", active_contracts)
            
        except mysql.connector.Error as err:
            st.error(f"Error loading summary: {err}")
        
    elif st.session_state['manager_page'] == 'Create Tender': create_tender_page()
    elif st.session_state['manager_page'] == 'Manage Tenders': manage_tenders_page()
    elif st.session_state['manager_page'] == 'View All Tenders': view_all_tenders_page(db)
    elif st.session_state['manager_page'] == 'Evaluate Bids': evaluate_bids_page()
    elif st.session_state['manager_page'] == 'Award Contract': award_contract_page()
    elif st.session_state['manager_page'] == 'View Contracts': view_contracts_page()
    elif st.session_state['manager_page'] == 'Reports & Insights': reports_insights_page()
    elif st.session_state['manager_page'] == 'User Management': user_management_page()

# --- VENDOR ROLE PAGES ---

def vendor_dashboard():
    st.title("Vendor Portal")
    
    if 'vendor_page' not in st.session_state:
        st.session_state['vendor_page'] = 'Dashboard'

    st.sidebar.markdown("### Vendor Actions")
    
    if st.sidebar.button("Dashboard"): st.session_state['vendor_page'] = 'Dashboard'
    if st.sidebar.button("View Open Tenders"): st.session_state['vendor_page'] = 'View Open Tenders'
    if st.sidebar.button("Submit Bid"): st.session_state['vendor_page'] = 'Submit Bid'
    if st.sidebar.button("My Bids"): st.session_state['vendor_page'] = 'My Bids'
    if st.sidebar.button("View Awarded Contracts"): st.session_state['vendor_page'] = 'View Awarded Contracts'
    if st.sidebar.button("Performance Report"): st.session_state['vendor_page'] = 'Performance Report'
        
    db = get_db_connection()
    if db is None: return

    if st.session_state['vendor_page'] == 'Dashboard':
        st.header("Welcome to the Vendor Portal")
        cursor = db.cursor()
        cursor.execute("SELECT COUNT(Tender_ID) FROM tender WHERE FN_IsTenderDeadlinePassed(Tender_ID) = 0;")
        open_count = cursor.fetchone()[0]
        cursor.execute("SELECT COUNT(Bid_ID) FROM bid WHERE Vendor_ID = %s;", (st.session_state['user_id'],))
        my_bid_count = cursor.fetchone()[0]

        col1, col2 = st.columns(2)
        col1.metric("Open Tenders", open_count)
        col2.metric("Your Submitted Bids", my_bid_count)
        
    elif st.session_state['vendor_page'] == 'View Open Tenders': view_open_tenders_page()
    elif st.session_state['vendor_page'] == 'Submit Bid': submit_bid_page()
    elif st.session_state['vendor_page'] == 'My Bids': my_bids_page()
    elif st.session_state['vendor_page'] == 'View Awarded Contracts': view_awarded_contracts_page()
    elif st.session_state['vendor_page'] == 'Performance Report': vendor_performance_page()

def view_open_tenders_page():
    # ... (view_open_tenders_page content) ...
    st.header("View Open Tenders")
    st.markdown("---")

    db = get_db_connection()
    if db is None: return

    try:
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT Tender_ID, Title, Deadline 
            FROM tender 
            WHERE Tender_ID NOT IN (SELECT Tender_ID FROM contract) 
            AND FN_IsTenderDeadlinePassed(Tender_ID) = 0;
        """)
        open_tenders = cursor.fetchall()
        
        if open_tenders: st.dataframe(pd.DataFrame(open_tenders))
        else: st.info("No tenders are currently open for bidding.")

    except Exception as e:
        st.error(f"Error loading open tenders: {e}")
    finally:
        if db.is_connected(): db.close()

def submit_bid_page():
    # ... (submit_bid_page content) ...
    st.header("Submit Bid (Checks T2, T3, and T5)") # Updated header for clarity
    st.markdown("---")

    db = get_db_connection()
    if db is None: return
    
    # Check FN4 (Pre-Qualification Status)
    cursor = db.cursor()
    cursor.execute("SELECT FN_CheckIfVendorHasActiveContract(%s);", (st.session_state['user_id'],))
    has_active = cursor.fetchone()[0]

    if has_active == 1: st.info("Status: You currently have an Active Contract (FN4 Verified).")
    else: st.success("Status: You are free to submit new bids.")

    try:
        cursor.execute("""
            SELECT Tender_ID, Title 
            FROM tender 
            WHERE Tender_ID NOT IN (SELECT Tender_ID FROM contract) 
            AND FN_IsTenderDeadlinePassed(Tender_ID) = 0;
        """)
        open_tenders = cursor.fetchall()
        
        if not open_tenders:
             st.warning("No tenders are currently open for bidding.")
             return

        tender_map = {t[0]: t[1] for t in open_tenders}

        with st.form("bid_submission_form"):
            selected_tender_id = st.selectbox("Select Tender", options=list(tender_map.keys()), format_func=lambda x: tender_map[x])
            price = st.number_input("Proposed Price", min_value=0.00, value=100000.00, format="%.2f")
            
            uploaded_file = st.file_uploader("Upload Technical Proposal")
            
            submit_bid = st.form_submit_button("Submit Bid")
            
            if submit_bid:
                if price <= 0.00: st.error("Bid submission failed: Price must be greater than zero. (T2 Trigger test condition)")
                else:
                    cursor.close()
                    cursor = db.cursor()
                    vendor_id_for_bid = st.session_state['user_id'] 
                    
                    try:
                        # INSERT INTO bid (T2, T3, and T5 fire automatically)
                        cursor.execute("""
                            INSERT INTO bid (Tender_ID, Vendor_ID, Price, Status, Documents)
                            VALUES (%s, %s, %s, 'Submitted', %s)
                        """, (selected_tender_id, vendor_id_for_bid, price, uploaded_file.name if uploaded_file else 'N/A'))
                        db.commit()
                        st.success("Bid submitted successfully. (T2/T3/T5 checks passed).")
                    except mysql.connector.Error as err:
                        # --- ADDED LOGIC FOR T5 ERROR MESSAGE ---
                        if 'T5 Trigger Blocked Submission' in err.msg:
                             st.error(f"Submission Blocked: You have already submitted a bid for this tender. (Rule: One bid per tender enforced by T5).")
                        else:
                             st.error(f"Submission Failed: {err.msg}. (Database trigger or constraint blocked submission)")
                        # --- END ADDED LOGIC ---
                    finally:
                        cursor.close()
                        st.rerun()

    except Exception as e:
        st.error(f"An error occurred: {e}")
    finally:
        if db.is_connected(): db.close()

def my_bids_page():
    # ... (my_bids_page content) ...
    st.header("My Submitted Bids")
    st.markdown("---")

    db = get_db_connection()
    if db is None: return

    try:
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT b.Bid_ID, t.Title, b.Price, b.Status, b.Documents
            FROM bid b
            JOIN tender t ON b.Tender_ID = t.Tender_ID
            WHERE b.Vendor_ID = %s
            ORDER BY b.Bid_ID DESC;
        """, (st.session_state['user_id'],))
        my_bids = cursor.fetchall()
        if my_bids: st.dataframe(pd.DataFrame(my_bids))
        else: st.info("You have not submitted any bids yet.")

    except Exception as e:
        st.error(f"Error loading bids: {e}")
    finally:
        if db.is_connected(): db.close()

def view_awarded_contracts_page():
    # ... (view_awarded_contracts_page content) ...
    st.header("View Awarded Contracts")
    st.markdown("---")

    db = get_db_connection()
    if db is None: return

    try:
        cursor = db.cursor(dictionary=True)
        cursor.execute("""
            SELECT c.Contract_ID, t.Title, c.Value, c.Start_Date, c.End_Date, c.Status
            FROM contract c
            JOIN tender t ON c.Tender_ID = t.Tender_ID
            WHERE c.Vendor_ID = %s
            ORDER BY c.Start_Date DESC;
        """, (st.session_state['user_id'],))
        contracts = cursor.fetchall()
        if contracts: st.dataframe(pd.DataFrame(contracts))
        else: st.info("No contracts have been awarded to your company.")

    except Exception as e:
        st.error(f"Error loading contracts: {e}")
    finally:
        if db.is_connected(): db.close()

def vendor_performance_page():
    # ... (vendor_performance_page content) ...
    st.header("Performance Report")
    st.markdown("---")
    
    db = get_db_connection()
    if db is None: return
    
    try:
        cursor = db.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM contract WHERE Vendor_ID = %s;", (st.session_state['user_id'],))
        awarded_count = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM bid WHERE Vendor_ID = %s;", (st.session_state['user_id'],))
        total_bids = cursor.fetchone()[0]
        
        success_rate = (awarded_count / total_bids) * 100 if total_bids > 0 else 0
        
        st.metric("Total Bids Submitted", total_bids)
        st.metric("Contracts Awarded", awarded_count)
        st.metric("Success Rate (Estimated)", f"{success_rate:.2f}%")
        
    except Exception as e:
        st.error(f"Error generating report: {e}")
    finally:
        if db.is_connected(): db.close()


# --- LOGIN PAGE AND MAIN ROUTER ---

def login_page():
    # ... (login_page content) ...
    st.title("Secure Tender Management System")
    st.subheader("DBMS Mini Project Console")
    st.markdown("---")
    
    login_id = st.text_input("Login ID", value="")
    password = st.text_input("Password", type="password")
    
    if st.button("Login"):
        if login_id and password:
            user = verify_credentials(login_id, password)
            
            if user:
                st.session_state['user_id'] = user['User_ID']
                st.session_state['login_id'] = user['Login']
                st.session_state['role'] = user['Role']
                st.success(f"Login successful! Welcome, {user['Role']}")
                st.rerun() 
            else:
                st.error("Invalid Login ID or Password. (Default password is 'password123')")
        else:
            st.warning("Please enter both login ID and password.")

# --- MAIN APPLICATION ROUTER ---

if 'user_id' not in st.session_state:
    login_page()
else:
    # Sidebar Navigation and User Info
    role = st.session_state['role']
    st.sidebar.title(f"Logged in as: {role}")
    st.sidebar.markdown(f"User: **{st.session_state['login_id']}**")
    st.sidebar.markdown("---")
    
    # ROLE-BASED NAVIGATION
    if role in ['Evaluator']: # Consolidate Admin, Manager, Evaluator to just 'Evaluator'
        manager_dashboard()
    elif role == 'Vendor':
        vendor_dashboard()
    
    # Global Logout Button
    if st.sidebar.button("Logout"):
        st.session_state.clear()
        st.rerun()