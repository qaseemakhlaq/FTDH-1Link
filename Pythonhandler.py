import pandas as pd
import configparser
import smtplib
import re
import os
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from datetime import datetime, timedelta
from email import encoders
from io import StringIO

# import os

class Pythonhandler():
    def create_data_table(self, column_names):
        """
        column_names: list of column names (runtime)
        return: empty pandas DataFrame
        """
        column_names = [col.strip() for col in column_names.split(",")]
        return pd.DataFrame(columns=column_names)
    def add_row_by_pairs(self, data_table, *args):
        """
        args format:
        column1, value1, column2, value2, ...
        """
        if len(args) % 2 != 0:
            raise ValueError("Column aur value pairs complete honay chahiye")

        row = {}
        for i in range(0, len(args), 2):
            column = args[i]
            value = args[i + 1]
            row[column] = value

        data_table.loc[len(data_table)] = row
        return data_table
    def add_row_by_values(self, data_table, values):
        """
        values: list of values
        DataFrame ke columns order me match karte hue row add kare
        """
        values=[col.strip() for col in values.split(",")]
        print(values)
        if len(values) != len(data_table.columns):
            raise ValueError("Number of values must match number of columns")
        data_table.loc[len(data_table)] = values
        return data_table
    def read_config_file(self, filename: str):
        """
        Read the config file
        :param filename: configuration file

        :return: config object
        """

        config = configparser.ConfigParser()
        config.read(filename)
        return config

    def update_config_data(self, config_filename: str, section_name: str, key_name: str, value: str) -> bool:
        """
        Update data in config file

        :param config_filename: file name of the config file.
        :param section_name: section name
        :param key_name:  key name to update its value
        :param value: new value to update old one
        :return: writing status --> bool
        """

        try:
            config = configparser.ConfigParser()
            # when updating config file, the key name in UPPER-CASE is converted into lower-case.
            # to close this conversion, use below option.
            config.optionxform = str
            config.read(config_filename)
            config[section_name][key_name] = value
            with open(config_filename, 'w') as configfile:
                config.write(configfile, space_around_delimiters=False)
            del config
        except Exception as e:
            print(f"Error occurs.", e)
            del config
            return False
        return True
    
    def create_today_excel_report(self, file_path):
        headers = [
            "COM ID",
            "Ticket Resolution Time",
            "Ticket Start Time",
            "Ticket End Time",
            "Time Remaining",
            "Opened",
            "Sub-Category",
            "Fraudulent MSISDN",
            "Customer MSISDN",
            "Fraudulent TID",
            "Account Suspended",
            "CNIC Blacklist",
            "Authorization Complete",
            "Layering",
            "C2C Account Blocked",
            "C2C CNIC Blacklist",
            "Layering TID",
            "IBFT Lodgement ID",
            "UBP/Merchant Email sent"
        ]

        df = pd.DataFrame(columns=headers)
        df.to_excel(file_path, index=False)
        return file_path

    def append_row_pandas(self, file_path, **kwargs):
        df = pd.read_excel(file_path)
        df = pd.concat([df, pd.DataFrame([kwargs])], ignore_index=True)
        df.to_excel(file_path, index=False)

    def validate_misdn(self, text):
        pattern = r'(?:03\d{9}|\+923\d{9})'
        
        match = re.search(pattern, text)
        
        if match:
            return True
        else:
            return False
    
    def append_dict_to_excel(self, file_path, data_dict):
        new_df = pd.DataFrame([data_dict])
        if os.path.exists(file_path):
            print("I am here")
            existing_df = pd.read_excel(file_path)  # No sheet name needed
            updated_df = pd.concat([existing_df, new_df], ignore_index=True)
        else:
            updated_df = new_df
        updated_df.to_excel(file_path, index=False)


 
 
    def send_email(self, subject, ccreceiver, receiver, body, attachment_path=None):
        
        # cc_receiver = "qaseem.akhlaq@mercurialminds.com"
    
        send_message = MIMEMultipart()
        smtp_server = "10.28.231.148"
        email_receiver = [email.strip() for email in receiver.split(",")]
        cc_receiver = [email.strip() for email in ccreceiver.split(",")]
        smtp_port= "25"
        user_email = "phantom@mobilinkbank.com"
        send_message["From"] = user_email
        send_message["To"] = ", ".join(email_receiver)
        send_message["Cc"] = ", ".join(cc_receiver)
        send_message["Subject"] = subject
    
        email_body = f"{body}"
        send_message.attach(MIMEText(email_body, "html"))
    
        if attachment_path:
            try:
                with open(attachment_path, "rb") as attachment:
                    part = MIMEBase("application", "octet-stream")
                    part.set_payload(attachment.read())
                    encoders.encode_base64(part)
                    part.add_header(
                        "Content-Disposition",
                        f"attachment; filename={os.path.basename(attachment_path)}",
                    )
                    send_message.attach(part)
            except Exception as e:
                print(f"Error attaching file: {str(e)}")
    
        try:
            smtp_session = smtplib.SMTP(smtp_server, int(smtp_port))
            all_email_receivers = email_receiver
            smtp_session.sendmail(user_email, all_email_receivers, send_message.as_string())
            smtp_session.quit()
            print("Email sent successfully!")
        except Exception as e:
            print("Acknowledgement not sent: " + str(e))

    def generate_email_body(self, data_rows, suspend_request=False, Fraudlent_MISDN=None, officer_name="Compliance Team"):
        """
        suspend_request = True  → Strong suspension line include hogi
        suspend_request = False → Line include nahi hogi
        """

        if isinstance(data_rows, dict):
            data_rows = [data_rows]

        if not data_rows:
            return "No Data Available"

        ignore_values = [None, "", "None", "N/A", "n/a", "NA"]

        # Step 1: Find valid keys
        valid_keys = []
        for key in data_rows[0].keys():
            for row in data_rows:
                value = row.get(key)

                if isinstance(value, str):
                    value = value.strip()

                if value not in ignore_values:
                    valid_keys.append(key)
                    break

        header_html = "".join(f"<th>{key}</th>" for key in valid_keys)

        rows_html = ""
        for row in data_rows:
            rows_html += "<tr>"
            for key in valid_keys:
                cell_value = row.get(key, "")

                if cell_value in ignore_values:
                    cell_value = ""

                rows_html += f"<td>{cell_value}</td>"
            rows_html += "</tr>"

        # Conditional Paragraph

        suspension_text = ""
        if suspend_request:
            suspension_text = f"""
            <p>
            Please suspend the GSM services of the below mentioned number(s)
            as they are involved in suspected fraudulent activity.
            
            </p>
            <p>
            Fraudulent MSISDN: {Fraudlent_MISDN}
            </p>
            """

        # Final HTML
        html_body = f"""
        <html>
        <body style="font-family:Calibri; font-size:14px;">

            <p>Hi Team,</p>

            {suspension_text}

            <br>

            <table border="1" cellpadding="6" cellspacing="0"
                style="border-collapse:collapse; width:100%; text-align:center;">

                <tr style="background-color:#1F4E78; color:white; font-weight:bold;">
                    {header_html}
                </tr>

                {rows_html}

            </table>

            <br><br>
            <br>

            <p>
            Regards,<br>
            {officer_name}<br>
            Regulatory Compliance
            </p>

        </body>
        </html>
        """

        return html_body


    def adjust_time(self, time_str):
        # Input format
        dt = datetime.strptime(time_str, "%d-%m-%Y %H:%M")
        # 1 minute forward
        next_min = dt + timedelta(minutes=1)
        # 1 minute backward
        prev_min = dt - timedelta(minutes=1)
        return prev_min.strftime("%d-%m-%Y %H:%M"), next_min.strftime("%d-%m-%Y %H:%M")

    def convert_to_24hr_format(self, time_str: str) -> str:
        if not time_str:
            return "Invalid Time Format"

        # Replace '.' and ';' with ':'
        time_str = time_str.replace('.', ':').replace(';', ':').strip().lower()

        # Special midnight cases
        if time_str in ['00001', '000000', '0000']:
            return '00:00'

        # Already in 24-hour format (H:MM or HH:MM)
        if re.match(r'^\d{1,2}:\d{2}$', time_str):
            try:
                return datetime.strptime(time_str, "%H:%M").strftime("%H:%M")
            except ValueError:
                return "Invalid Time Format"

        # AM/PM without colon (e.g., 0425pm)
        if re.match(r'^\d{3,4}[ap]m$', time_str):
            try:
                time_str = re.sub(r'(\d{1,2})(\d{2})([ap]m)', r'\1:\2\3', time_str)
                return datetime.strptime(time_str, "%I:%M%p").strftime("%H:%M")
            except ValueError:
                return "Invalid Time Format"

        # AM/PM with colon (e.g., 04:25pm)
        if re.match(r'^\d{1,2}:\d{2}[ap]m$', time_str):
            try:
                return datetime.strptime(time_str, "%I:%M%p").strftime("%H:%M")
            except ValueError:
                return "Invalid Time Format"

        # 6-digit military format (hhmmss)
        if re.match(r'^\d{6}$', time_str):
            try:
                return datetime.strptime(time_str, "%H%M%S").strftime("%H:%M")
            except ValueError:
                return "Invalid Time Format"

        # 4-digit 24-hour format (hhmm)
        if re.match(r'^\d{4}$', time_str):
            try:
                return datetime.strptime(time_str, "%H%M").strftime("%H:%M")
            except ValueError:
                return "Invalid Time Format"

        return "Invalid Time Format"

    def html_to_datatable(self, html_string):
        """
        Takes HTML string containing table
        Returns pandas DataFrame
        """
        try:
            # Read HTML table
            df_list = pd.read_html(StringIO(html_string))[0]
            # df_list = df_list[0]
            # df_list = df_list.astype(str)
            df_list['Beneficiary A/C #']=df_list['Beneficiary A/C #'].astype(str).str.zfill(11)
            # Agar multiple tables hon to pehla return karega
            # df = df_list[0]
            # Convert DataFrame to list of dicts
            # return df.to_dict(orient="records")
            # df = df_to_dict(df_list)
            try:
                df_sorted = df_list.sort_values(by="Log Date", ascending=True)
            except:
                df_sorted = df_list[::-1].reset_index(drop=True)
            # print(df_sorted)
            # pending_df = df_list[df_list["Status"] == "pending"]
            data_table = df_sorted.to_dict(orient="records")
            # print(data_table)
            return data_table

        except Exception as e:
            print("Error parsing HTML:", e)
            return None

    def extract_otp(self, email_body: str):
        """
        Extracts first 6-digit OTP from email body.
        Returns OTP string if found, otherwise None.
        """
        if not email_body:
            return None
        
        match = re.search(r"\b\d{6}\b", email_body)
        if match:
            return match.group(0)
        
        return None
    
    def get_previous_and_next(self, date_str):
        """
        Input: date string in format '17-Dec-2025'
        Output: previous_date (-1 day), next_seven_date (+7 days) as strings in 'dd-mm-yyyy' format
        """
        try:
            # Convert string to datetime object
            transaction_date = datetime.strptime(date_str, "%d-%b-%Y")
            
            # Previous day (-1 day)
            previous_date = transaction_date - timedelta(days=1)
            
            # Next seven days (+7 days)
            next_seven_date = transaction_date + timedelta(days=7)
            
            # Format dates as 'dd-mm-yyyy' and return
            return previous_date.strftime("%d-%m-%Y"), next_seven_date.strftime("%d-%m-%Y")
        
        except ValueError as e:
            raise ValueError(f"Invalid date format: {e}")

    def validate_and_return_branchless_account(self, account_number):
        """
        Checks if account belongs to Branchless system.
        
        Conditions:
        1. Account number is exactly like 11 or 12 digits starting from 03 or 92.
        2. IBAN where 13th and 14th digits are '9' and '2'.
        """

        account_number = account_number.strip()

        # Condition 1: 11 digit account number
        # Mobile 03 format
        if re.fullmatch(r"03\d{9}", account_number):
            return account_number

        # Mobile 92 format
        if re.fullmatch(r"92\d{10}", account_number):
            return account_number
        # IBAN match for branchless
        if len(account_number) >= 14 and account_number[12] == "9" and account_number[13] == "2":
            # Find 92 + exactly 10 digits
            match = re.search(r"92\d{10}", account_number)
            if match:
                return match.group()
        return False

    def time_calculation_for_safe_exit(self, logment_time_str):
        lodgement_time = datetime.strptime(logment_time_str, "%d-%m-%Y %H:%M")
        x_time= lodgement_time + timedelta(minutes=15)
        current_time=datetime.now()
        remaining_time= (x_time-current_time).total_seconds() / 60
        if remaining_time<0:
            return 0
        return int(remaining_time)
