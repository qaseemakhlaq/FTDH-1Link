*** Settings ***
Library    Autosphere.Browser.Selenium
Library    Autosphere.FileSystem
Library    captcha_handling.py
Library    Autosphere.Outlook.Application
Library    Pythonhandler.py
Library    OperatingSystem
Library    Autosphere.Tasks
Library    DateTime
Library    BuiltIn
Library    String
Library    Collections
Library    Process
Library    Onelink_Captcha_Code.py
Library    Autosphere.Desktop
Resource    CPS_PORTAL_TASKS.robot


*** Keywords ***

Get Data From Config File
    [Arguments]   ${config_file}
    ${config_file_exists}=  run keyword and return status   File Should Exist   ${config_file}
    IF  ${config_file_exists}
        ${config_data}=  read_config_file   ${config_file}
        IF  ${config_data}
            #CPS Portal
            Set Global Variable    ${CPS_URL}    ${config_data}[CPS Portal Creds][CPS_URL]
            Set Global Variable    ${CPS_Username_MKR}    ${config_data}[CPS Portal Creds][CPS_USERNAME_MKR]
            Set Global Variable    ${CPS_Password_MKR}    ${config_data}[CPS Portal Creds][CPS_PASSWORD_MKR]
            Set Global Variable    ${CPS_Username_CHK}    ${config_data}[CPS Portal Creds][CPS_USERNAME_CHK]
            Set Global Variable    ${CPS_Password_CHK}    ${config_data}[CPS Portal Creds][CPS_PASSWORD_CHK]
            #One Link Creds
            Set Global Variable    ${1Link_URL}    ${config_data}[One Link Creds][1LINK_URL]
            Set Global Variable    ${1Link_Username}    ${config_data}[One Link Creds][1LINK_USERNAME]
            Set Global Variable    ${1Link_Password}    ${config_data}[One Link Creds][1LINK_PASSWORD]

            #Email Configurations
            Set Global Variable    ${Email_Recivers}    ${config_data}[Email_Configurations][Receiver]
            Set Global Variable    ${CC_Recivers}    ${config_data}[Email_Configurations][CC_Reciver]

        END
    END
Login to OneLink Portal
    Autosphere.Outlook.Application.Open Application
    sleep    4s
    ${emails}=    Get Emails    folder_name=OTPFTDH
    Run Keyword And Ignore Error    Move Emails    email_filter=${emails}   source_folder=OTPFTDH    target_folder=OLDOTP
    Switch Browser    Main_Browser
    ${windows}=     Get Window Handles
    Switch Window    ${windows}[0]
    Go To    ${1Link_URL}
    Run Keyword And Return Status    Wait Until Page Contains Element    //button[contains (text(), 'Advanced')]    10s
    ${Advance_option_Exists}=    Does Page Contain Element    //button[contains (text(), 'Advanced')]
    IF    ${Advance_option_Exists}
        Click Button When Visible    //button[contains (text(), 'Advanced')]
        Click Element When Visible    //a[contains (text(), 'Proceed to')]
    END
    Wait Until Page Contains Element    //*[contains (text(),'Enter the code shown above')]/../img     40s
    Input Text When Element Is Visible    //label[contains (text(),'Username')]/../input    user-phantom1         #Add variable for username
    Input Password    //label[contains (text(),'Password')]/../input    P@kistan1234                   #Add variable for password
    Run Keyword And Ignore Error    Remove File         ${CURDIR}//OneLinkCaptcha.png
    Capture Element Screenshot    //*[contains (text(),'Enter the code shown above')]/../img        ${CURDIR}//OneLinkCaptcha.png
    ${Captcha_Text}=    Onelink Captcha     ${CURDIR}//OneLinkCaptcha.png
    Input Text When Element Is Visible    //*[contains (text(),'Enter the code shown above')]/../input    ${Captcha_Text}
    Click Element When Visible    //input[@value="LogIn"]
    Wait Until Page Contains Element    //input[@placeholder="Enter OTP"]    20s
    # Wait Until Page Contains Element    locator

Login OneLink Using OTP
    Switch Browser    Main_Browser
    ${windows}=     Get Window Handles
    Switch Window    ${windows}[0]   
    ${OTP_Page_Exists}=    Run Keyword And Return Status    Wait Until Keyword Succeeds    3x    2s    Login to OneLink Portal
    IF    ${OTP_Page_Exists}
        ${OTP}=    Get OTP From Outlook
        IF    '${OTP}'=='False'
            Log     Unable to get otp
            
        ELSE
            Log    OTP Exis+ts
            Input Text When Element Is Visible    //input[@placeholder="Enter OTP"]    ${OTP}
            Click Element When Visible    //input[@value="Login Securely"]
            Wait Until Page Contains Element    //*[contains(text(), 'Suspect Transactions')]    10s
        END
    ELSE
        Log   Send Email
    END

Get OTP From Outlook
    ${OTP}=    Set Variable    False
    # Sleep    4s
    # END
    Sleep    2s
    FOR    ${i}    IN RANGE    1    28
    ${emails}=    Get Emails    folder_name=OTPFTDH
    ${count}=     Get Length    ${emails}
        IF    ${count} > 0
            Log    Email Found
            FOR    ${email}    IN    @{emails}
                Log    ${email['Body']}
                ${Email_Body}=   Set Variable    ${email['Body']}
                ${OTP}=    extract_otp    ${Email_Body}
                Log    ${OTP}
            END
            BREAK
        ELSE
            Log    No Email Yet - Retry ${i}
            Sleep    10s
        END
    END
    [Return]    ${OTP}
	
Get Tickets From OneLink
    # Mouse Over    //*[contains(text(), 'Suspect Transactions')]
    # Mouse Over    //*[contains(text(), 'Fund Transfer Auto Log')]
    # Click Element When Visible    //*[contains(text(), 'AutoLog Pending Dashboard')]
    # Wait Until Page Contains Element    //*[contains(text(), 'Suspect Transactions')]    20s
    Go To     https://10.95.8.162:4444/FTDH/DashboardIBFT_Refactored
    Wait Until Page Contains Element    //td[contains(text(), 'Filters')]/select/option[contains(text(), 'Sender')]/..    20s
    Select From List By Label    //td[contains(text(), 'Filters')]/select/option[contains(text(), 'Sender')]/..    Beneficiary
    Select From List By Label    //td[contains(text(), 'Filters')]/select/option[contains(text(), 'MMBL')]/..   MMBL
    # Get Value    //input[@id="MainContent_txtDtFrom"]
    Click Element When Visible    //input[@id="MainContent_txtDtFrom"]
    # Sleep   10s
    # Input Text    //input[@id="MainContent_txtDtFrom"]    01/02/2026    clear: bool = True
    # Click Element When Visible    //input[@id="MainContent_btnCalendarFrom"]
    # Click Element When Visible    //div[@id="MainContent_calFrom_title"]
    # Click Element When Visible    //div[@id="MainContent_calFrom_title"]
    # Click Element When Visible    //div[contains(text(), '2026')]
    # Click Element When Visible    //div[contains(text(), 'Jan')]
    # Click Element When Visible    //div[contains(@title,"January 10, 2026")]
    Wait Until Keyword Succeeds    3x    2s    Click Element When Visible    //input[@value="Apply Filters"]
    Wait Until Page Contains Element    //table[@class="table table-bordered table-sm"]/..      20s
	# ${table_html}=   Get Element Attribute    //table[@class="table table-bordered table-sm"]/..    innerHTML
    # Log    ${table_html}
    ${Pending_disputes_dt}=    Set Variable    ${None}
    ${resolved_disputes_dt}=    Set Variable    ${None}
    # ${table}=    html_to_datatable    ${table_html}
    ${page_counter}=    Set Variable    1
    Run Keyword And Return Status    Wait Until Page Contains Element    //table[@class="table table-bordered table-sm"]//tr/td[count(//table[@class="table table-bordered table-sm"]//tr/th/a[contains(text(),'Status')]/parent::th/preceding-sibling::th)+1][contains(text(),'Pending')]    10s
    ${pending_exist}=    Does Page Contain Element    //table[@class="table table-bordered table-sm"]//tr/td[count(//table[@class="table table-bordered table-sm"]//tr/th/a[contains(text(),'Status')]/parent::th/preceding-sibling::th)+1][contains(text(),'Pending')]
    # ${next_page_button}=    Does Page Contain Element    //tbody/tr/td/a[contains (text(), '${page_counter}')]
    ${pending_exist}=    Set Variable    ${True}
    WHILE    ${pending_exist}
        Log    pending exists
        ${page_counter}=    Evaluate    ${page_counter} + 1
        ${table_html}=   Get Element Attribute    //table[@class="table table-bordered table-sm"]/..    innerHTML
        Log    ${table_html}
        ${pending_page_dispute}    ${resolved_disputes}=    html_to_datatable    ${table_html}
        ${Pending_disputes_dt}=    Merge Datatables        ${Pending_disputes_dt}    ${pending_page_dispute}
        ${resolved_disputes_dt}=    Merge Datatables        ${resolved_disputes_dt}    ${resolved_disputes}
        ${pending_exist}=    Does Page Contain Element    //table[@class="table table-bordered table-sm"]//tr/td[count(//table[@class="table table-bordered table-sm"]//tr/th/a[contains(text(),'Status')]/parent::th/preceding-sibling::th)+1][contains(text(),'Pending')]
        ${next_page_button}=    Does Page Contain Element    //tbody/tr/td/a[contains (text(), '${page_counter}')]
        IF    ${next_page_button}
            # Click Element When Visible    //tbody/tr/td/a[contains (text(), '${page_counter}')]
            Execute Javascript    document.evaluate("//tbody/tr/td/a[contains(text(), '${page_counter}')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue?.click();
            Wait Until Page Contains Element    //tbody/tr/td/span[contains (text(), '${page_counter}')]    10s
        ELSE
            BREAK
        END
    END
    # IF    ${Pending_disputes_dt}==${None}
    #     Terminate Process
    # END
    ${Disputes_Dict}=    Sort Dt Convert To Dict    ${Pending_disputes_dt}
    
    Log    ${Disputes_Dict}
    FOR    ${ticket_row}    IN    @{Disputes_Dict}
        Switch Browser    Main_Browser
        ${windows}=     Get Window Handles
        Switch Window    ${windows}[0]
        Go To    https://10.95.8.162:4444/FTDH/DashboardIBFT_Refactored
        Log    ${ticket_row}
        ${Beneficiary_AC}=    Validate And Return Branchless Account    ${ticket_row}[Beneficiary A/C #]
        Set Global Variable    ${Beneficiary_AC}    ${Beneficiary_AC}
        IF    '${Beneficiary_AC}'=='False'
            Log     Send Email account is for core
            ${Email_Body}=   generate_email_body      Unable To Validate ${Beneficiary_AC} Account Please check at your own end
            Pythonhandler.Send Email    Unable To Validate ${Beneficiary_AC} Account    ${CC_Recivers}    ${Email_Recivers}    ${Email_Body}
            Continue For Loop
        END
        ${Stan_ID}=    Set Variable    ${ticket_row}[Stan/Transaction ID]
        ${Ticket_Dict}=    Create Dictionary    Dispute ID=${EMPTY}    Log Date=${EMPTY}    Time Remaining=${EMPTY}    Beneficiary Account=${EMPTY}    Sender Account=${EMPTY}    Dispute Amount=${EMPTY}    TRX Date=${EMPTY}    TRX Time=${EMPTY}    Fraudulent TID=${EMPTY}    Account Suspended=${EMPTY}    CNIC Blacklist=${EMPTY}    Authorization Complete=${EMPTY}    Layering=${EMPTY}    SF/NSF Case=${EMPTY}    Lien Mark=${EMPTY}    Account Status=${EMPTY}    Status=${EMPTY}
        Set To Dictionary    ${Ticket_Dict}    Dispute ID=${ticket_row}[Dispute ID]
        Set To Dictionary    ${Ticket_Dict}    Log Date=${ticket_row}[Log Date]
        Set To Dictionary    ${Ticket_Dict}     Beneficiary Account=${ticket_row}[Beneficiary A/C #]
        Set To Dictionary    ${Ticket_Dict}    Sender Account=${ticket_row}[Sender A/C #]
        Set To Dictionary    ${Ticket_Dict}    TRX Date=${ticket_row}[Trx Date]
        Set To Dictionary    ${Ticket_Dict}    TRX Time=${ticket_row}[Trx Time]
        Set To Dictionary    ${Ticket_Dict}    TRX Amount=${ticket_row}[Trx Amount]
        Set Global Variable    ${Ticket_Dict}    ${Ticket_Dict}
        ${duplicate_dispute_exists}=    Get Status Dispute Id For Duplicate    ${resolved_disputes_dt}    ${ticket_row}[Log Date]    ${Stan_ID}    ${Beneficiary_AC}
        IF    '${duplicate_dispute_exists}'!='False'
            Mark Ticket As Invalid    Duplicate with ${duplicate_dispute_exists}
            Continue For Loop
        END
        ${Ticket_Count}=    Get Element Count    //td[contains(text(), '${Stan_ID}')]/../td[contains(text(),'${Beneficiary_AC}')]
        ${Ticket_Count}=    Set Variable    1
        IF    ${Ticket_Count}>1
            FOR    ${ticket}    IN RANGE    ${Ticket_Count}
                Log    ${ticket}
                ${index_counter}=    Evaluate    ${ticket} + 1
                ${Dispute_ID}=    Get Text    (//td[contains(text(), '${Stan_ID}')]/../td[contains(text(),'${Beneficiary_AC}')]/../td[1])[${index_counter}]
                IF    '${Dispute_ID}'=='${ticket_row}[Dispute ID]' and ${ticket} != ${Ticket_Count}-1
                    Continue For Loop
                ELSE
                    ${Duplicate_Dispute}=    Set Variable      ${Dispute_ID}
                END
                ${Status}=    Get Text    (//td[contains(text(), '${Stan_ID}')]/../td[contains(text(),'${Beneficiary_AC}')]/../td[18])[${index_counter}]
                IF    '${Status}'=='Pending' or '${Status}'=='Invalid'
                    Log    Handle pending ticket
                    ${Dispute_Status}=    Run Keyword And Return Status    Handle Dispute Ticket On CPS
                    Send Ticket Email    ${Dispute_Status}
                    Append Dict To Excel    ${Daliy_Report_Path}    ${Ticket_Dict}
                    Exit For Loop
                ELSE
                    Log    Ticket is pending or invalid
                    Mark Ticket As Invalid    Duplicate with ${Duplicate_Dispute}
                    Exit For Loop
                END
            END
        ELSE
            Log    Stan does not duplicate
            ${Dispute_Status}=    Run Keyword And Return Status    Handle Dispute Ticket On CPS
            Send Ticket Email    ${Dispute_Status}
            Append Dict To Excel    ${Daliy_Report_Path}    ${Ticket_Dict}
            # IF    ${Dispute_Status}
            #     Set To Dictionary    ${Ticket_Dict}    ['Status']=Resolved
            #     ${Email_Body}=   generate_email_body      ${Ticket_Dict}
            #     Pythonhandler.Send Email    Ticket Resolved Succesfully    ${CC_Recivers}    ${Email_Recivers}    ${Email_Body}
            #     # Exit For Loop
            # ELSE
            #     Set To Dictionary    ${Ticket_Dict}    ['Status']=Failed
            #     ${Email_Body}=   generate_email_body      ${Ticket_Dict}
            #     Pythonhandler.Send Email    Bot Failed At Dispute ${Dispute_ID}    ${CC_Recivers}    ${Email_Recivers}    ${Email_Body}
            # END
            # ${Email_Body}=   generate_email_body      ${Ticket_Dict}
            # Pythonhandler.Send Email    Ticket Resolved Succesfully    ${CC_Recivers}    ${Email_Recivers}    ${Email_Body}
        END
    Switch Browser    Main_Browser
    ${windows}=     Get Window Handles
    Switch Window    ${windows}[0]
    END

    


Send Ticket Email
    [Arguments]    ${status}

    IF    ${status}
        Set To Dictionary    ${Ticket_Dict}    ['Status']=Resolved
        ${subject}=    Set Variable    Ticket Resolved Successfully
    ELSE
        Set To Dictionary    ${Ticket_Dict}    ['Status']=Failed
        ${subject}=    Set Variable    Bot Failed At Dispute
    END

    ${Email_Body}=   generate_email_body      ${Ticket_Dict}
    Pythonhandler.Send Email    ${subject}    ${CC_Recivers}    ${Email_Recivers}    ${Email_Body}

Mark Ticket As Invalid
    [Arguments]    ${Invalid_Reason}
    Switch Browser    Main_Browser
    ${windows}=     Get Window Handles
    Switch Window    ${windows}[0]
    Go To    https://10.95.8.162:4444/FTDH/DashboardIBFTDetail?mID=${Ticket_Dict}[Dispute ID]
    Wait Until Page Contains Element    //td[contains(text(), 'Invalid')]/..//input    20s
    Click Element When Visible    //td[contains(text(), 'Invalid')]/..//input
    Input Text When Element Is Visible    //td[contains(text(), 'Comments')]/..//textarea[@id="MainContent_txtDesc"]       ${Invalid_Reason}
    Click Element When Visible    //input[@id="MainContent_imgBtnAcknowledge"]


Acknowledge On OneLink
    Switch Browser    Main_Browser
    ${windows}=     Get Window Handles
    Switch Window    ${windows}[0]
    Go To    https://10.95.8.162:4444/FTDH/DashboardIBFTDetail?mID=${Ticket_Dict}[Dispute ID]
    Wait Until Page Contains Element    //td[contains(text(), 'Acknowledge')]/..//input    20s
    Click Element When Visible    //td[contains(text(), 'Acknowledge')]/..//input
    Input Text When Element Is Visible    //td[contains(text(), 'Comments')]/..//textarea[@id="MainContent_txtDesc"]      Acknowledge
    Click Element When Visible    //input[@id="MainContent_imgBtnAcknowledge"]


Handle Dispute Ticket For Existing Account
    [Arguments]    ${Account_Exists}
    # convert_to_24hr_format    
    ${Transation_Exists}    ${available_amount}    ${Fraudlent_TID}=    Valdate Transaction In CPS    ${Ticket_Dict}[TRX Date]    ${Ticket_Dict}[TRX Time]    ${Ticket_Dict}[TRX Amount]
    IF    ${Transation_Exists}
        Log     Acknowledge 
        Acknowledge On OneLink
        ${Dispute_Amount}=    Set Variable    ${Ticket_Dict}[TRX Amount]
        ${Dispute_Amount}=    Coverion of amount to Integer    ${Dispute_Amount}
        IF    '${available_amount}'>='${Dispute_Amount}'
            Log    SF Flow
            SF Flow Of Dispute Transaction    ${Fraudlent_TID}    ${Account_Exists}
        ELSE
            Log   NSF Case
            Switch Browser    Main_Browser
            ${windows}=     Get Window Handles
            Switch Window    ${windows}[1]
            
            NSF Flow For Dispute Transaction    ${Account_Exists}
        END

    ELSE
        Log    Transaction not found
        Mark Ticket As Invalid    Transaction not found
    END


Update Dispute Status
    [Arguments]      ${Account_SF_NSF}    ${Action}
    Go To    https://10.95.8.162:4444/FTDH/DashboardIBFTDetail?mID=${Ticket_Dict}[Dispute ID]
    ${Checked_Exists}=    Run Keyword And Return Status    Wait Until Page Contains Element    //td[contains (text(), 'Disputed Funds Status')]/..//input[@checked="checked"]    10s
    IF    '${Checked_Exists}' == 'False'
        Click Element When Visible    //td[contains (text(), 'Disputed Funds Status')]/..//input
    END
    # Click Element When Visible    //td[contains (text(), 'Disputed Funds Status')]/..//input
    
    Select From List By Label    //select[@id="MainContent_ddAccountBlocked"]    ${Account_SF_NSF}
    Input Text When Element Is Visible    //td[contains(text(), 'Comments')]/../td/textarea[@id="MainContent_txtBlockComments"]    ${Action}
    Scroll Element Into View    //input[@id="MainContent_imgBtnBlockAging"]
    Wait Until Element Is Enabled    //input[@id="MainContent_imgBtnBlockAging"]
    # Click Element When Visible    //input[@id="MainContent_imgBtnBlockAging"]
    Execute JavaScript    document.evaluate("//input[@id='MainContent_imgBtnBlockAging']", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.click()
    Sleep    2s

SF Flow Of Dispute Transaction
    [Arguments]    ${Fraudlent_TID}    ${Account_Exists}
    ${windows}=     Get Window Handles
    Switch Window    ${windows}[1]
    ${Lien_Mark_Status}=    Lien mark the amount in CPS    ${Fraudlent_TID}
    IF  ${Lien_Mark_Status}
        Switch Browser    Authorization_Performer
        ${Login_Status}=    Run Keyword And Return Status    Validation for cps login    ${CPS_Username_CHK}    ${CPS_Password_CHK}
        IF  ${Login_Status}
            ${Authorization_Status}=    Authrization Steps on CPS
            IF    ${Authorization_Status}
                Switch Browser    Main_Browser
                ${windows}=     Get Window Handles
                Switch Window    ${windows}[0]
                Log   Update Status
                Set To Dictionary    ${Ticket_Dict}    Lien Mark=Funds On Hold SF
                Update Dispute Status    Funds On Hold SF    Amount Block
            ELSE
                Execute Account Blocking Flow    ${Account_Exists}
                Switch Browser    Main_Browser
                ${windows}=     Get Window Handles
                Switch Window    ${windows}[0]
                Set To Dictionary    ${Ticket_Dict}    Lien Mark=SF Case Failed To Lien Mark Account Blocked
                Update Dispute Status    Funds On Hold SF    Account Block
            END
            
        ELSE
            Log     Send Email
            Set To Dictionary    ${Ticket_Dict}    Authorization Complete=Authorization Failed Unable To Login
        END
        Switch Browser    Main_Browser
        ${windows}=     Get Window Handles
        Switch Window    ${windows}[0]
    ELSE
        Log    Failed To Lien Mark
        Execute Account Blocking Flow    ${Account_Exists}
        Set To Dictionary    ${Ticket_Dict}    Status=Failed To Lien Mark Account Blocked
        Switch Browser    Main_Browser
        ${windows}=     Get Window Handles
        Switch Window    ${windows}[0]
        Set To Dictionary    ${Ticket_Dict}    Lien Mark=SF Case Failed To Lien Mark Account Blocked
        Update Dispute Status    Funds On Hold SF    Account Block
    END


Execute Account Blocking Flow
    [Arguments]    ${Account_Exists}
    ${account_status}=    Get Account Status
    IF    '${account_status}' == 'Active'
        Run Keyword If    '${Account_Exists}'=='CustomerTabTrue'      Update KYC Info Of Customer
        Suspend Or Block Account On CPS
        Switch Browser    Authorization_Performer
        ${Login_Status}=    Run Keyword And Return Status    Validation for cps login    ${CPS_Username_CHK}    ${CPS_Password_CHK}
        IF  ${Login_Status}
            ${Authorization_Status}=    Authrization Steps on CPS
        ELSE
            Log     Send Email
            Set To Dictionary    ${Ticket_Dict}    Authorization Complete=Authorization Failed Unable To Login
        END
        Switch Browser    Main_Browser
    ELSE IF    '${account_status}'=='Dormant' or '${account_status}'=='Frozen'
        Log    Account is already dormant
        Block CNIC From CPS    ${Ticket_Dict}[Dispute ID]
    ELSE IF    '${account_status}' == 'Suspended'
        Log     Send email
        Set To Dictionary    ${Ticket_Dict}    Account Suspended=Already Suspended 
        Set To Dictionary    ${Ticket_Dict}    CNIC Blacklist=N/A
        Set To Dictionary    ${Ticket_Dict}    Authorization Complete=N/A
    END 
   


NSF Flow For Dispute Transaction
    [Arguments]    ${Account_Exists}
    Execute Account Blocking Flow    ${Account_Exists}
    Switch Browser    Main_Browser
    ${windows}=     Get Window Handles
    Switch Window    ${windows}[0]
    Set To Dictionary    ${Ticket_Dict}    Lien Mark=NSF Case
    Update Dispute Status    Funds On Hold NSF    Account Block

Handle Dispute Ticket On CPS
    ${windows}=     Get Window Handles
    Switch Window    ${windows}[1]
    ${Login_Status}=    Run Keyword And Return Status    Validation for cps login    ${CPS_Username_MKR}    ${CPS_Password_MKR}
    Log    ${Login_Status}
    IF    '${Login_Status}'=='False'
        Log    Send Email
        Terminate Process
    END
    ${Account_Exists}=    Get Results Against Fraudlant MISDN    ${Beneficiary_AC}
    IF   '${Account_Exists}' != 'False'
        Log    ${Account_Exists}
        Handle Dispute Ticket For Existing Account    ${Account_Exists}
    ELSE
        ${windows}=     Get Window Handles
        Switch Window    ${windows}[0]
        Set To Dictionary    ${Ticket_Dict}    Account Status=Account Not Found
        Mark Ticket As Invalid    Account not found
    END


*** Tasks ***
Init Data From Config
    # ${JOB_ID}  evaluate  os.environ.get("BUILD_NUMBER", None)
    # set global variable  ${JOB_ID}  ${JOB_ID}
    ${user_home}=  Get environment variable   UserProfile
    ${current_date}=    Get Current Date    result_format=%d%m%Y
    Set Global Variable    ${Daliy_Report_Path}    ${user_home}\\Documents\\FTDH DATA\\${current_date} FTDH One Link Report.xlsx
    ${Daliy_Report_Exists}=  Does File Exist    ${Daliy_Report_Path}
    IF    '${Daliy_Report_Exists}' == 'False'
        # Create Today Excel Report    ${Daliy_Report_Path}
        # Create File    ${Daliy_Report_Path}
        Log    I am here
    END
    Set Global Variable     ${files_data_path}    ${user_home}\\Documents\\FTDH DATA\\FTDH_CONFIG.ini
    Log    ${files_data_path}
    Get Data From Config File    ${files_data_path}
    Open Available Browser     ${CPS_URL}    alias=Authorization_Performer
    Maximize Browser Window
    Open Available Browser    ${1Link_URL}     alias=Main_Browser
    Maximize Browser Window
    Execute Javascript      window.open('')
    Jump To Task        Get Tickets From OneLink And Resolve


Get Tickets From OneLink And Resolve
    Login OneLink Using OTP
    Get Tickets From OneLink
    Sleep    10s


test Tasks
    # Run   start chrome.exe --remote-debugging-port=9223 --user-data-dir="C:\\Temp\\ChromeProfile"
    Attach Chrome Browser    9223
    Get Tickets From OneLink
    # Open Available Browser    https://10.95.8.162:4444/FTDH/Login
    # Maximize Browser Window
    # Wait Until Keyword Succeeds    3x    2s    Login to OneLink Portal
    # ${OTP}=    Get OTP From Outlook
    # Input Text When Element Is Visible 3   //input[@placeholder="Enter OTP"]    ${OTP}
    # Click Element When Visible    //input[@value="Login Securely"]
    # Get Tickets From OneLink
    

    # ${Account_Number}=    Validate And Return Branchless Account    PK75JCMA0908913204082695
    # Log    ${Account_Number}
    # Login to OneLink Portal
    # FOR    ${counter}    IN RANGE    10
    #     Log    ${counter}
    #     ${OTP_Exists}=   Get OTP From Outlook
    #     IF    ${OTP_Exists}
    #         Exit For Loop
    #     END
        
        
    # END
    