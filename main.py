import pandas as pd
from dbconnector.database import engine

alignmix_file = "./Alignment Export (2025-06-10).xlsx"

def personnel_data(connection):
    with open("./personnel.sql") as file:
        query = file.read()
    sql_df = pd.read_sql_query(query, connection)
    excel_df = pd.read_excel("./Comp Planning Report.xlsx", sheet_name="1")
    personnel = pd.merge(sql_df, excel_df, how="left", left_on="Personnel ID", right_on="Work Contact: Work Email")
    personnel = personnel[["Job Title", "Personnel ID", "Name", "TERRITORY_ID", "TERR_NM",
                     "REGION_ID", "REGION_NM", "Address Line 1", "Address Line 2", "City", "Zip", "State"]]
    return personnel

def zip_codes():
    excel_df = pd.read_excel(alignmix_file, sheet_name="Zip Codes")
    excel_df = excel_df[["Zip Code ID", "Zip Code Name", "Territory ID"]]
    return excel_df

def accounts(connection):
    excel_df = pd.read_excel(alignmix_file, sheet_name="Accounts")
    with open("./revenue.sql") as file:
        query = file.read()
    sql_df = pd.read_sql_query(query, connection)
    merged = pd.merge(excel_df, sql_df, how="left", left_on="Salesforce ID", right_on="ACT_ID")
    merged["TAM25"] = merged["TAM_ALL"] * 0.25
    merged = merged[["Account ID", "Account Name", "Salesforce ID", "Street", "Street 2", "City", "State", "Zip Code",
                       "Segment", "Territory ID", "TAM_ALL", "TAM25", "R12_SALES"]]
    return merged

def territories(connection):
    excel_df = pd.read_excel(alignmix_file, sheet_name="Territories")
    with open("./territories.sql") as file:
        query = file.read()
    sql_df = pd.read_sql_query(query, connection)
    merged = pd.merge(excel_df, sql_df, how="left", left_on="Territory ID", right_on="TERRITORY_ID")
    merged = merged[["Territory ID", "TERR_NM", "REGION_ID", "REGION_NM"]]
    return merged

def create_upload():
    conn = engine.connect()
    # Create UPLOAD.xlsx, write all dfs to different tabs
    with pd.ExcelWriter("./UPLOAD.xlsx", engine="openpyxl", mode="w") as writer:
        personnel_data(conn).to_excel(writer, sheet_name="Personnel", index=False)
        zip_codes().to_excel(writer, sheet_name="Zip Codes", index=False)
        accounts(conn).to_excel(writer, sheet_name="Accounts", index=False)
        territories(conn).to_excel(writer, sheet_name="Territories", index=False)
    conn.close()

create_upload()