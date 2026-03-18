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
    Wait Until Page Contains Element    //td[contains(text(), 'Filters')]/select/option[contains(text(), 'Sender')]/..
    Select From List By Label    //td[contains(text(), 'Filters')]/select/option[contains(text(), 'Sender')]/..    Beneficiary
    Select From List By Label    //td[contains(text(), 'Filters')]/select/option[contains(text(), 'MMBL')]/..   MMBL
    # Get Value    //input[@id="MainContent_txtDtFrom"]
    Click Element When Visible    //input[@id="MainContent_txtDtFrom"]
    # Sleep   10s
    # Input Text    //input[@id="MainContent_txtDtFrom"]    01/02/2026    clear: bool = True
    Click Element When Visible    //input[@id="MainContent_btnCalendarFrom"]
    Click Element When Visible    //div[@id="MainContent_calFrom_title"]
    Click Element When Visible    //div[@id="MainContent_calFrom_title"]
    Click Element When Visible    //div[contains(text(), '2026')]
    Click Element When Visible    //div[contains(text(), 'Jan')]
    Click Element When Visible    //div[contains(@title,"January 10, 2026")]
    Wait Until Keyword Succeeds    3s    2s    Click Element When Visible    //input[@value="Apply Filters"]
    Wait Until Page Contains Element    //table[@class="table table-bordered table-sm"]/..      40s
	${table_html}=   Get Element Attribute    //table[@class="table table-bordered table-sm"]/..    innerHTML
    Log    ${table_html}
    ${table}=    html_to_datatable    ${table_html}  
    Log    ${table}
    FOR    ${ticket_row}    IN    @{table}
        Switch Browser    Main_Browser
        ${windows}=     Get Window Handles
        Switch Window    ${windows}[0]
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
        ${Ticket_Dict}=    Create Dictionary    Dispute ID=${EMPTY}    Log Date=${EMPTY}    Time Remaining=${EMPTY}    Beneficiary Account=${EMPTY}    Sender Account=${EMPTY}    Dispute Amount=${EMPTY}    TRX Date=${EMPTY}    TRX Time=${EMPTY}    Fraudulent TID=${EMPTY}    Account Suspended=${EMPTY}    CNIC Blacklist=${EMPTY}    Authorization Complete=${EMPTY}    Layering=${EMPTY}    SF/NSF Case=${EMPTY}    Lien Mark=${EMPTY}    Status=${EMPTY}
        Set To Dictionary    ${Ticket_Dict}    Dispute ID=${ticket_row}[Dispute ID]
        Set To Dictionary    ${Ticket_Dict}    Log Date=${ticket_row}[Log Date]
        Set To Dictionary    ${Ticket_Dict}     Beneficiary Account=${ticket_row}[Beneficiary A/C #]
        Set To Dictionary    ${Ticket_Dict}    Sender Account=${ticket_row}[Sender A/C #]
        Set To Dictionary    ${Ticket_Dict}    TRX Date=${ticket_row}[Trx Date]
        Set To Dictionary    ${Ticket_Dict}    TRX Time=${ticket_row}[Trx Time]
        Set To Dictionary    ${Ticket_Dict}    TRX Amount=${ticket_row}[Trx Amount]
        Set Global Variable    ${Ticket_Dict}    ${Ticket_Dict}
        ${Ticket_Count}=    Get Element Count    //td[contains(text(), '${Stan_ID}')]/../td[contains(text(),'${Beneficiary_AC}')]
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
                    Handle Dispute Ticket On CPS
                    ${Email_Body}=   generate_email_body      ${Ticket_Dict}
                    Pythonhandler.Send Email    Ticket Resolved Succesfully    ${CC_Recivers}    ${Email_Recivers}    ${Email_Body}
                    Exit For Loop
                ELSE
                    Log    Ticket is pending or invalid
                    # Mark Ticket As Invalid    Duplicate with ${Duplicate_Dispute}
                END
            END
        ELSE
            Log    Stan does not duplicate
            Handle Dispute Ticket On CPS
            ${Email_Body}=   generate_email_body      ${Ticket_Dict}
            Pythonhandler.Send Email    Ticket Resolved Succesfully    ${CC_Recivers}    ${Email_Recivers}    ${Email_Body}
        END
    Switch Browser    Main_Browser
    ${windows}=     Get Window Handles
    Switch Window    ${windows}[0]
    END

Mark Ticket As Invalid
    [Arguments]    ${Invalid_Reason}
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
        
        # Acknowledge On OneLink
        IF    ${available_amount}
            Log    SF Flow
            SF Flow Of Dispute Transaction    ${Fraudlent_TID}
        ELSE
            Log   NSF Case
            NSF Flow For Dispute Transaction    ${Account_Exists}
        END

    ELSE
        Log    Transaction not found
        # Mark Ticket As Invalid    Transaction not found
    END


Update Dispute Status
    [Arguments]      ${Account_SF_NSF}    ${Action}
    Go To    https://10.95.8.162:4444/FTDH/DashboardIBFTDetail?mID=${Ticket_Dict}[Dispute ID]
    Click Element When Visible    //td[contains (text(), 'Disputed Funds Status')]/..//input
    Select From List By Label    //select[@id="MainContent_ddAccountBlocked"]    ${Account_SF_NSF}
    Input Text When Element Is Visible    //td[contains(text(), 'Comments')]/../td/textarea[@id="MainContent_txtBlockComments"]    ${Action}
    Click Element When Visible    //input[@id="MainContent_imgBtnBlockAging"]

SF Flow Of Dispute Transaction
    [Arguments]    ${Fraudlent_TID}
    ${windows}=     Get Window Handles
    Switch Window    ${windows}[1]
    Lien mark the amount in CPS    ${Fraudlent_TID}
    Switch Browser    Authorization_Performer
    ${Login_Status}=    Run Keyword And Return Status    Validation for cps login    ${CPS_Username_CHK}    ${CPS_Password_CHK}
    IF  ${Login_Status}
        Authrization Steps on CPS
        Switch Browser    Main_Browser
        ${windows}=     Get Window Handles
        Switch Window    ${windows}[0]
        Log   Update Status
        # Update Dispute Status    Funds On Hold SF    Amount Block
    ELSE
        Log     Send Email
        Set To Dictionary    ${Ticket_Dict}    Authorization Complete=Authorization Failed Unable To Login
    END
    Switch Browser    Main_Browser
    ${windows}=     Get Window Handles
    Switch Window    ${windows}[0]
    


NSF Flow For Dispute Transaction
    [Arguments]    ${Account_Exists}
    ${account_status}=    Get Account Status
    IF    '${account_status}' == 'Active'
        Run Keyword If    '${Account_Exists}'=='CustomerTabTrue'      Update KYC Info Of Customer
        Suspend Or Block Account On CPS
        Switch Browser    Authorization_Performer
        ${Login_Status}=    Run Keyword And Return Status    Validation for cps login    ${CPS_Username_CHK}    ${CPS_Password_CHK}
        IF  ${Login_Status}
            Authrization Steps on CPS
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
    Switch Browser    Main_Browser
    ${windows}=     Get Window Handles
    Switch Window    ${windows}[0]
    # Update Dispute Status    Funds On Hold NSF    Account Block

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
        # Mark Ticket As Invalid    Account not found
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
        Create Today Excel Report    ${Daliy_Report_Path}
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
    # Open Available Browser    https://10.95.8.162:4444/FTDH/Login
    # Maximize Browser Window
    # Wait Until Keyword Succeeds    3x    2s    Login to OneLink Portal
    # ${OTP}=    Get OTP From Outlook
    # Input Text When Element Is Visible    //input[@placeholder="Enter OTP"]    ${OTP}
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
    