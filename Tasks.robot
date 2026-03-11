*** Settings ***
Library    Autosphere.Browser.Selenium
Library    Autosphere.FileSystem
Library    captcha_handling.py
Library    Autosphere.Outlook.Application
Library    Pythonhandler.py
Library    OperatingSystem
Library    BuiltIn
Library    String
Library    Collections


*** Keywords ***
Login to OneLink Portal
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
    ${Captcha_Text}=    get_captcha_text     ${CURDIR}//OneLinkCaptcha.png
    Input Text When Element Is Visible    //*[contains (text(),'Enter the code shown above')]/../input    ${Captcha_Text}
    Click Element When Visible    //input[@value="LogIn"]
    Wait Until Page Contains Element    //input[@placeholder="Enter OTP"]    20s
    
    

    # Wait Until Page Contains Element    locator
Get OTP From Outlook
    ${OTP_Exists}=    Set Variable    False
    Open Application
    Sleep    4s
    ${emails}=    Get Emails    folder_name=OTPFTDH
    # FOR    ${mail}    IN    @{emails}
    Run Keyword And Ignore Error    Move Emails    email_filter=${emails}   source_folder=OTPFTDH    target_folder=OLDOTP
    # END
    Sleep    2s
    FOR    ${i}    IN RANGE    1    16
    ${emails}=    Get Emails    folder_name=OTPFTDH
    ${count}=     Get Length    ${emails}
    
        IF    ${count} > 0
            Log    Email Found
            ${OTP_Exists}=    Set Variable    True
            
            FOR    ${email}    IN    @{emails}
                Log    ${email['Body']}
                ${Email_Body}=   Set Variable    ${email['Body']}
                # ${otp_list}=    Get Regexp Matches    ${Email_Body}    \b\d{6}\b
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
    # Go To     https://10.95.8.162:4444/FTDH/DashboardIBFT_Refactored
    # Wait Until Page Contains Element    //td[contains(text(), 'Filters')]/select/option[contains(text(), 'Sender')]/..
    # Select From List By Label    //td[contains(text(), 'Filters')]/select/option[contains(text(), 'Sender')]/..    Beneficiary
    # Select From List By Label    //td[contains(text(), 'Filters')]/select/option[contains(text(), 'MMBL')]/..   MMBL
    # Get Value    //input[@id="MainContent_txtDtFrom"]
    # Input Text    //input[@id="MainContent_txtDtFrom"]    01/02/2026    clear: bool = True
    # Click Element When Visible    //input[@value="Apply Filters"]
	${table_html}=   Get Element Attribute    //table[@class="table table-bordered table-sm"]/..    innerHTML
    Log    ${table_html}
    ${table}=    html_to_datatable    ${table_html}  
    Log    ${table}
    FOR    ${item}    IN    @{table}
        Log    ${item}
        ${Beneficiary_AC}=    Set Variable   ${item}[Beneficiary A/C #]
        ${Stan_ID}=    Set Variable    ${item}[Stan/Transaction ID]

        ${Ticket_Count}=    Get Element Count    //td[contains(text(), '${Stan_ID}')]/../td[contains(text(),'${Beneficiary_AC}')]
        IF    ${Ticket_Count}>1
            FOR    ${ticket}    IN RANGE    ${Ticket_Count}
                Log    ${ticket}
                ${index_counter}=    Evaluate    ${ticket} + 1
                ${Dispute_ID}=    Get Text    (//td[contains(text(), '${Stan_ID}')]/../td[contains(text(),'${Beneficiary_AC}')]/../td[1])[${index_counter}]
                IF    '${Dispute_ID}'=='${item}[Dispute ID]'
                    Continue For Loop
                END
            END
            
        ELSE
            Log     I am here
        END

    END


*** Tasks ***
test Tasks
    # Run   start chrome.exe --remote-debugging-port=9223 --user-data-dir="C:\\Temp\\ChromeProfile"
    Attach Chrome Browser    9223
    # Open Available Browser    https://10.95.8.162:4444/FTDH/Login
    # Maximize Browser Window
    # Wait Until Keyword Succeeds    3x    2s    Login to OneLink Portal
    # ${OTP}=    Get OTP From Outlook
    # Input Text When Element Is Visible    //input[@placeholder="Enter OTP"]    ${OTP}
    # Click Element When Visible    //input[@value="Login Securely"]
    Get Tickets From OneLink
    # Login to OneLink Portal
    # FOR    ${counter}    IN RANGE    10
    #     Log    ${counter}
    #     ${OTP_Exists}=   Get OTP From Outlook
    #     IF    ${OTP_Exists}
    #         Exit For Loop
    #     END
        
        
    # END
    