*** Settings ***
Library    Autosphere.Browser.Selenium
Library    Pythonhandler.py
Library    Collections
Library    DateTime
Library    String





*** Keywords ***
Validation for cps login
    [Arguments]     ${CPS_Username}    ${CPS_Password}
    Reload Page
    Run Keyword And Return Status    Wait Until Page Contains Element     (//ul/li/span[contains(text(), 'Search')])[1]    8s
    ${CPS_already_login}=   Does Page Contain Element     (//ul/li/span[contains(text(), 'Search')])[1]
    IF   '${CPS_already_login}'=='False'
        Wait Until Keyword Succeeds    3x    2s    Login CPS Portal    ${CPS_Username}    ${CPS_Password}
    ELSE
            Log    CPS is already loggedIn
    END
    

Login CPS Portal
    [Arguments]    ${CPS_Username}    ${CPS_Password}
    Go To    ${CPS_URL}
    # Go To    https://mmtest.jazzcash.com.pk:31102/payment/login.action
    Run Keyword And Return Status    Wait Until Page Contains Element    //td[contains(text(),'User Name')]/../td/input
    ${Advance_Button}=    Does Page Contain Element      //button[contains (text(), 'Advanced')]
    IF    ${Advance_Button}
        Click Element When Visible    //button[contains (text(), 'Advanced')]
        Click Element When Visible    //a[contains (text(), 'Proceed to')]
    END
    Wait Until Page Contains Element     //td[contains(text(),'User Name')]/../td/input    20s
    Input Text When Element Is Visible    //td[contains(text(), 'User Name')]/../td/input    ${CPS_Username}
    sleep  1s
    Input Text When Element Is Visible    //td[contains(text(), 'Password')]/../td/input    ${CPS_Password}
    sleep  1s
    Run Keyword And Return Status    Remove File    ${CURDIR}\\Captcha.png
    Capture Element Screenshot    //img[@id="validateimg"]/..    ${CURDIR}\\Captcha.png
    ${code}=    get_captcha_text    ${CURDIR}\\Captcha.png
    Input Text    //td[contains(text(), 'Verification Code')]/../td/ul/li/input    ${code}
    Click Element When Visible    //div[contains(text(), 'Login')]
    Wait Until Page Contains Element    (//ul/li/span[contains(text(), 'Search')])[1]
    # ${Login_Status}=    Run Keyword And Return Status    Wait Until Page Contains Element    (//ul/li/span[contains(text(), 'Search')])[1]
    # [Return]    ${Login_Status}
	
Search MISDN in Organization Tab
    [Arguments]    ${Fraudulent_MSISDN}
    Unselect Frame
    Wait Until Page Contains Element    (//ul/li/span[contains(text(), 'Search')])[1]
    Mouse Over    (//ul/li/span[contains(text(), 'Search')])[1]
    Click Element When Visible    //li[@id="c_20007"]/div/a[normalize-space(text())='Organization Operator']
    Select Frame    //iframe[@id="tabPage_20007_iframe"]
    Input Text   //div[contains (text(), 'MSISDN')]/..//input      ${Fraudulent_MSISDN}      clear: bool = True
    Click Element When Visible    //div[contains (text(), 'Search')]
    Run Keyword And Return Status    Wait Until Page Contains Element    //td/img
    ${record_exists}=    Does Page Contain Element     //td[contains(text(), 'No records found')]
    [Return]    ${record_exists}

Search MISDN IN Customer Tab
    [Arguments]    ${Fraudulent_MSISDN}
    Wait Until Page Contains Element    (//ul/li/span[contains(text(), 'Search')])[1]
    Mouse Over    (//ul/li/span[contains(text(), 'Search')])[1]
    Click Element When Visible    //li[@id="c_20004"]/div/a[normalize-space(text())='Customer']
    Select Frame    //iframe[@id="tabPage_20004_iframe"]
    Input Text    //div[contains(text(), 'MSISDN')]/../div/div/div/input    ${Fraudulent_MSISDN}    clear: bool = True
    Click Element When Visible    //div[contains(text(), 'Search')]
    Run Keyword And Return Status    Wait Until Page Contains Element    //a/img
    ${record_exists}=    Does Page Contain Element     //td[contains(text(), 'No records found')]
    [Return]    ${record_exists}

Get Results Against Fraudlant MISDN
    [Arguments]     ${Fraudulent_MSISDN}
    ${Customer_Exists}=    Set Variable    False
    ${record_exists}=    Search MISDN IN Customer Tab    ${Fraudulent_MSISDN}
    IF  not ${record_exists}
        ${Customer_Exists}=    Set Variable    CustomerTabTrue
        Click Element When Visible    //a/img
        Unselect Frame
        Wait Until Page Contains Element    //iframe[contains (@id, "managecustomer")]    20s
        Select Frame    //iframe[contains (@id, "managecustomer")]
        Log    Customer exists
    ELSE
        ${record_exists}=    Search MISDN in Organization Tab    ${Fraudulent_MSISDN}
        IF  not ${record_exists}
            ${Customer_Exists}=    Set Variable    OrganizationTabTrue
            Click Element When Visible    //td/img
            Unselect Frame
            Wait Until Page Contains Element    //iframe[@id="tabPage_203100000003115764_iframe"]
            Select Frame    //iframe[@id="tabPage_203100000003115764_iframe"]
            Log    Customer exists
        END
    END
    [Return]    ${Customer_Exists}


Get Account Status
    # Click Element When Visible    //a/img
    # Unselect Frame
    # Sleep    4s
    # Wait Until Page Contains Element    //iframe[contains (@id, "managecustomer")]    20s
    # Select Frame    //iframe[contains (@id, "managecustomer")]
    # Select Frame    //iframe[contains (@id, "managecustomer")]
    Unselect Frame
    Select Frame    //iframe[contains (@id, "managecustomer")]
    Click Element When Visible    //a[contains (text(), 'Info')]
    Select Frame    //iframe[@id="operatorConfigIframe"]
    Wait Until Element Is Visible    //div[contains(text(),'Identity Status')]/../div/label    20s
    ${account_status}=      Autosphere.Browser.Selenium.Get Text      //div[contains(text(),'Identity Status')]/../div/label
    Unselect Frame
    [Return]    ${account_status}

Authrization Steps on CPS
    Mouse Over    (//ul/li/span[contains(text(), 'My Tasks')])[1]
    Wait Until Page Contains Element    //a[contains (text(), 'Group Task')]    10s
    Click Element When Visible    //a[contains (text(), 'Group Task')]
    Wait Until Page Contains Element    //iframe[@id="tabPage_20023_iframe"]    8s
    Select Frame    //iframe[@id="tabPage_20023_iframe"]
    Click Element When Visible    //div[@id="searchTask"]//div[contains(text(), 'Search')]
    Wait Until Page Contains Element    //td[contains(text(),'Phantom')]/..//input[@type="checkbox"]      20s
    ${Bot_Records}=    Get Element Count    //td[contains(text(),'Phantom')]/../td/input
    # ${MISDN_Number}=    Set Variable    ${Ticket_Dict}[Fraudulent MSISDN]
    # ${MISDN_Number}=    Evaluate    __import__('re').search(r'(\d{10})$', '''${MISDN_Number}''').group(1)
    FOR    ${Record}    IN RANGE    ${Bot_Records}
        Log    ${Record}
        # Click Element When Visible    //td[contains(text(),'Phantom')]/../td[contains(text(), '${MISDN_Number}')]/..//input[@type="checkbox"]
        Click Element When Visible    (//td[contains(text(),'Phantom')]/..//input[@type="checkbox"])[1]
        Exit For Loop
    END
    Click Element When Visible  //cite[contains(text(), 'Process')]/../img
    Unselect Frame
    Wait Until Page Contains Element    //*[@class="popwin_iframe"]
    Select Frame     //*[@class="popwin_iframe"]
    # Click Element When Visible    //td[contains(text(),'Phantom')]/../td/a
    Click Element When Visible    //label[contains(text(), 'Approve')]/../input
    Input Text When Element Is Visible    //div[contains(text(), 'Comments')]/..//textarea    Approved
    Click Element When Visible    //div[contains(text(), 'Submit')]
    Unselect Frame
    Wait Until Page Contains Element    //iframe[@class="popwin_iframe"]
    Select Frame    //iframe[@class="popwin_iframe"]
    Wait Until Page Contains Element    //*[contains(text(), '100.000%')]    20s
    ${Authorization_Status}=    Does Page Contain Element    //*[contains(text(), '100.000%')]
    IF   ${Authorization_Status}
        Log   Authorization Success
        Set To Dictionary    ${Ticket_Dict}      Authorization Complete=Authorization Completed Succesfully
    END
    Click Element When Visible    //*[contains(text(), 'Return')]
    [Return]    ${Authorization_Status}
    
Coverion of amount to Integer
    [Arguments]    ${amount}
    # ${amount}    Set Variable    PKR18,853.00
    ${amount}    Replace String    ${amount}    PKR    ${EMPTY}
    ${amount}    Replace String    ${amount}    -    ${EMPTY}
    ${amount}    Replace String    ${amount}    ,      ${EMPTY}
    ${amount}    Convert To Number    ${amount}
    ${amount}    Convert To Integer   ${amount}
    [Return]    ${amount}

Lien mark the amount in CPS
    [Arguments]    ${Fraudlent_TID}
    Unselect Frame
    Select Frame    //iframe[contains (@id, "managecustomer")]
    Click Element When Visible    //a[contains (text(), 'Info')]
    Select Frame    //iframe[@id="operatorConfigIframe"]
    Click Element When Visible    //*[contains (text(), 'Raise Dispute')]
    Input Text When Element Is Visible    //div[contains (text(), 'Receipt No.')]/../div/div/div/input    ${Fraudlent_TID}
    # Click Element When Visible  //div[contains (text(), 'Receipt No.')]/..//div[contains (text(), 'Search')]
    Select From List By Label    //div[contains (text(), 'Reason')]/..//select      Others
    Input Text When Element Is Visible    //div[contains (text(), 'Remark')]/..//textarea    FTDH
    Click Element When Visible    //div[contains (text(), 'Submit')]
    Unselect Frame
    Wait Until Page Contains Element    //div[contains (text(), 'Are you sure to submit')]
    Click Element When Visible    //div[contains (text(), 'Yes')]
    Unselect Frame
    Run Keyword And Return Status    Wait Until Page Contains Element    //iframe[contains (@id, "managecustomer")]
    Select Frame    //iframe[contains (@id, "managecustomer")]
    Select Frame    //iframe[@id="operatorConfigIframe"]
    Run Keyword And Return Status    Wait Until Page Contains Element    //div[contains (text(), 'The request must be approved by another operator.')]    8s
    ${Lien_Mark_Status}=    Does Page Contain Element    //div[contains (text(), 'The request must be approved by another operator.')]
    [Return]    ${Lien_Mark_Status}

Update KYC Info Of Customer
    ${Block_Success}=   Set Variable      False
    Select Frame    //iframe[contains(@id,'managecustomer') or @id='tabPage_203100000003115764_iframe']
    Click Element When Visible    //a[contains (text(), 'Info')]
    Select Frame    //iframe[@id="operatorConfigIframe"]
    Click Element When Visible    //label[contains (text(), 'KYC Info')]
    ${Edit_Button}=    Run Keyword And Return Status   Wait Until Page Contains Element     //*[contains (text(), 'KYC information of')]/..//div[@title='Edit']/div/img    20s
    IF    ${Edit_Button}
        Click Element When Visible    //label[contains (text(), 'KYC Info')]
        Wait Until Page Contains Element     //*[contains (text(), 'KYC information of')]/..//div[@title='Edit']/div/img    20s
    END
    Unselect Frame
    Select Frame    //iframe[contains(@id,'managecustomer') or @id='tabPage_203100000003115764_iframe']
    Select Frame    //iframe[@id="operatorConfigIframe"]
    Click Element When Visible    //*[contains (text(), 'KYC information of')]/..//div[@title='Edit']/div/img
    Wait Until Element Is Not Visible    //*[contains (text(), 'KYC information of')]/..//div[@title='Edit']    20s
    Scroll Element Into View    //div[contains (text(), 'Suspension Reason')]/../div//input
    Input Text When Element Is Visible    //div[contains (text(), 'Suspension Reason')]/../div//input       ${Ticket_Dict}[Dispute ID]
    ${current_date}   Get Current Date   result_format=%d-%m-%Y
    ${current_date1}=    Replace String Using Regexp    ${current_date}    -0    -
    ${current_date1}=    Replace String Using Regexp    ${current_date1}    ^0    ${EMPTY}
    ${splitted_current_date}  Split String  ${current_date1}  -
    Click Element When Visible    //div[contains (text(), 'Date of Suspension')]/../div/div/div[@title="Select Date"]
    Wait Until Page Contains Element    //Select[@class="datetimepicker_newMonth"]
    Select From List By Label    //Select[@class="datetimepicker_newMonth"]       ${splitted_current_date}[1]
    Select From List By Label    //Select[@class="datetimepicker_newYear"]       ${splitted_current_date}[2]
    Click Element When Visible    //td[@title="${current_date}"]
    Input Text When Element Is Visible    //div[contains (text(), 'Reason')]/..//textarea        FTDH Case
    Click Element When Visible    //span[@class="bc_btn bc_ui_ele bc"]//div[contains(text(), 'Submit')]
    Unselect Frame
    Wait Until Page Contains Element    //div[contains (text(), 'Are you sure to submit')]    10s
    Click Element When Visible    //div[contains (text(), 'Yes')]
    Wait Until Page Contains Element    //div[contains(text(), 'Confirm')]    10s
    Click Element When Visible    //div[contains(text(), 'Confirm')]
    sleep    4s
    # sleep    6s

Suspend Or Block Account On CPS
    ${Block_Success}=    Set Variable    False
    Select Frame    //iframe[contains(@id,'managecustomer') or @id='tabPage_203100000003115764_iframe']
    Click Element When Visible    //a[contains (text(), 'Info')]
    Select Frame    //iframe[@id="operatorConfigIframe"]
    Click Element When Visible    //div[contains (text(), 'Identity Status')]/../div/div/div/div/div/img
    Unselect Frame
    Wait Until Page Contains Element    //div[contains(text(), 'Edit Identity Status')]    20s
    Select Frame    //iframe[@class="popwin_iframe"]
    # Wait Until Page Contains Element      //*[contains (text(), 'Edit Identity Status')]
    Select From List By Label    //div[contains (text(), 'New Identity Status')]/../div//select    Suspended
    Select From List By Label    //div[contains (text(), 'Reason')]/../div//select    Suspicious Activity
    Input Text When Element Is Visible    //div[contains (text(), 'Remark')]/..//textarea    Fraud Attempt Case
    Click Element When Visible    //div[contains (text(), 'Submit')]
    Unselect Frame
    Wait Until Page Contains Element    //div[contains(text(), 'Confirm')]    20s
    ${Confirm_Popup_Exists}=    Does Page Contain Element    //div[contains(text(), 'Confirm')]
    IF    ${Confirm_Popup_Exists}
        Click Element When Visible    //div[contains(text(), 'Confirm')]
        ${Block_Success}=   Set Variable      True
        Set To Dictionary    ${Ticket_Dict}    Account Suspended=Account Suspended Succesfully
    ELSE
        Log    Send email
        Set To Dictionary    ${Ticket_Dict}    Account Suspended=Failed To Suspend Account
    END
    [Return]      ${Block_Success}


Block CNIC From CPS
    [Arguments]    ${Ticket_ID}
    # Select Frame    //iframe[@id="tabPage_20004_iframe"]
    Select Frame    //iframe[contains (@id, "managecustomer")]
    Select Frame    //iframe[@id="operatorConfigIframe"]
    ${CNIC}=    Get Text    //div[contains (text() , 'Person')]/../div//a
    ${CNIC}=    Replace String Using Regexp    ${CNIC}    \\D    ${EMPTY}
    Log    ${CNIC}
    Unselect Frame
    Mouse Over    (//span[contains (text(), 'My Functions')])[1]
    Click Element When Visible    //div[@class="titlecontainer"]/a[contains(text(), 'Operations')]
    Select Frame    //iframe[@id="tabPage_20019_iframe"]
    Click Element When Clickable    //div[contains (text(), "ID Blacklist")]
    Select Frame    (//iframe[@id="operatorConfigIframe"])[1]
    Input Text When Element Is Visible    //div[contains (text(), "ID Number")]/..//input    ${CNIC}
    Click Element When Visible   //div[contains(text(),'Search')]
    Wait Until Page Contains Element    //tbody[@id="review_data_databody"]//td[contains (text(), "No records found.")]    20s
    ${Record_Exists}=      Does Page Contain Element    //tbody[@id="review_data_databody"]//td[contains (text(), "No records found.")]
    IF    ${Record_Exists}
        Log     Record Not Exists
        Wait Until Keyword Succeeds    3x    3s    Click Element When Visible   //div[@title="Add"]//img[@class="bc_toggleable "]
        Unselect Frame
        # Select Frame    //iframe[@id="tabPage_20019_iframe"]
        Wait Until Keyword Succeeds    3x    2s    Select Frame    //iframe[@class="popwin_iframe"]
        Input Text When Element Is Visible    //div[contains(text(), 'ID Number')]/..//input    ${CNIC}
        Input Text When Element Is Visible    //div[contains(text(), 'Comments')]/..//textarea          ${Ticket_ID}
        Click Element When Visible    //div[contains (text(), "Submit" )]
        Unselect Frame
        Run Keyword And Return Status    Wait Until Page Contains Element    //div[contains (text(), 'Are you sure to add it')]    10s
        Click Element When Visible    //div[contains(text(), 'Yes')]
        Run Keyword And Return Status    Wait Until Page Contains Element    //div[contains (text(), 'Operation succeeded.')]
        Click Element When Visible    //div[contains (text(), 'Operation succeeded.')]/..//div[contains(text(), 'Confirm')]
        Set To Dictionary    ${Ticket_Dict}    CNIC Blacklist=CNIC Blacklisted Succesfully
    ELSE
        #check of fraudlent and customer MISDN
        Log    Records Exists
        Set To Dictionary    ${Ticket_Dict}    CNIC Blacklist=Already CNIC Blacklisted
    END
    



Search by TID in CPS
    # here search by using TID
    Mouse Over    (//span[contains (text(), 'Transaction')])[1]
    Click Element When Visible    //a[contains (text(), 'Search by Receipt No.')]
    Select Frame    //iframe[@id="tabPage_20032_iframe"]
    # Variable of TID
    Input Text When Element Is Visible    //div[contains (text(), 'Receipt No.')]/..//input    010720339146


Identifiy the Amount in CPS
    [Arguments]   ${Fraudulant_TID}    ${Fraud_Date}
    click Element    (//div[@title="Select Date"])[1]
    ${Fraud_Date}=    Convert Date    ${Fraud_Date}    result_format=%d-%m-%Y
    ${split_fraud_date}=    Split String    ${Fraud_Date}    -
    Select From List By Label    //select[@class="datetimepicker_newMonth"]       ${split_fraud_date}[1]
    Select From List By Label    //select[@class="datetimepicker_newYear"]      ${split_fraud_date}[2]
    Log     Add Variable
    Click Element When Visible    //td[@title="${Fraud_Date}"]
    Click Element When Visible    //div[contains(text(),'OK')]
    Click Element When Visible    (//div[@title="Select Date"])[2]
    ${current_date}   Get Current Date   result_format=%d-%m-%Y
    ${current_date}=   Set Variable    16-12-2025
    ${splitted_current_date}  Split String  ${current_date}  -
    Select From List By Label    //select[@class="datetimepicker_newMonth"]       ${splitted_current_date}[1]
    Select From List By Label    //select[@class="datetimepicker_newYear"]      ${splitted_current_date}[2]
    Click Element When Visible    //td[@title="${current_date}"]
    Click Element When Visible       //div[contains(text(),'OK')]
    Wait Until Page Contains Element    (//label[contains(text(),'Both')]/ancestor::div//input[@type="radio"])[1]    20s
    Click Element When Visible    (//label[contains(text(),'Both')]/ancestor::div//input[@type="radio"])[1]
    Click Element When Visible    //span[@id="aeSigleSearch"]/div/div[contains(text(),'Search')]
    Sleep    4s
    Select From List By Label    //span[contains(text(), 'records')]/parent::*//following-sibling::select[@id="dgLogs_0_page_recordPerPage"]    100
    ${page_count}=      Autosphere.Browser.Selenium.Get Text    ((//span[@class="pcontrol"])[2]/span)[2]
    FOR    ${page}    IN RANGE    1    ${page_count}+1
        Log    ${page}
        Log    Add variable of transaction number
        ${is_transaction_exists}=    Does Page Contain Element    //a[contains (text(), '${Fraudulant_TID}')]
        IF    ${is_transaction_exists}
            Log  transaction exists
            Return From Keyword    True
            # Exit For Loop


        ELSE
            Log   continue to other pages
            Click Element When Visible    (//div[@class="pGroupnext"]/div[@title="Next"])[3]

        END
        
        
    END
    #add variables from service desk of transaction id
    ${transaction_type_cps}=   Autosphere.Browser.Selenium.Get Text    //a[contains (text(), '010720339146')]/../../td/span/label
    ${transaction_amount_cps}=     Autosphere.Browser.Selenium.Get Text     (//a[contains (text(), '010720339146')]/../../td)[8]
    Unselect Frame

Valdate Transaction In CPS
    [Arguments]    ${TRX_Date_1Link}    ${TRX_Time}    ${TRX Amount}
    ${Fraudlent_TID}=    Set Variable    None
    Unselect Frame
    Select Frame    //iframe[contains (@id, "managecustomer")]
    Click Element    //a[contains(text(),'Review Transaction')]
    Select Frame    //iframe[@id="operatorConfigIframe"]
    Wait Until Page Contains Element     //div[contains(text(),'Account Type')]/../div/div/div/select    10s
    ${items}=    Get List Items    //div[contains(text(),'Account Type')]/../div/div/div/select
    Log    ${items}
    Select From List By Index    //div[contains(text(),'Account Type')]/../div/div/div/select    1
    Wait Until Page Contains Element    (//tbody/tr[@class="bc_block_row even"]/td//table/tbody/tr/td)[6]
    ${available_amount}=    Autosphere.Browser.Selenium.Get Text    (//tbody/tr[@class="bc_block_row even"]/td//table/tbody/tr/td)[6]
    ${available_amount}=    Coverion of amount to Integer     ${available_amount}
    click Element    (//div[@title="Select Date"])[1]
    # ${Transaction_Date}=    Convert Date     17-Dec-2025   result_format=%d-%m-%Y
    ${Transaction_Date}=    Convert Date    ${TRX_Date_1Link}    date_format=%d-%b-%Y    result_format=%d-%m-%Y
    ${Previous_Date_Transaction}    ${Next_Seven_Date_Transaction}=    Get Previous And Next    ${TRX_Date_1Link}
    ${split_fraud_date}=    Split String    ${Previous_Date_Transaction}    -
    ${From_Month}=    Convert To Integer    ${split_fraud_date}[1]
    Select From List By Label    //select[@class="datetimepicker_newMonth"]       ${From_Month}
    Select From List By Label    //select[@class="datetimepicker_newYear"]      ${split_fraud_date}[2]
    Click Element When Visible    //td[@title="${Transaction_Date}"]
    Click Element When Visible    //div[contains(text(),'OK')]
    Click Element When Visible    (//div[@title="Select Date"])[2]
    ${Splitted_To_Date}  Split String  ${Next_Seven_Date_Transaction}  -
    ${To_Month}=    Convert To Integer    ${Splitted_To_Date}[1]
    Select From List By Label    //select[@class="datetimepicker_newMonth"]       ${To_Month}
    Select From List By Label    //select[@class="datetimepicker_newYear"]      ${Splitted_To_Date}[2]
    Click Element When Visible    //td[@title="${Next_Seven_Date_Transaction}"]
    Click Element When Visible       //div[contains(text(),'OK')]
    Wait Until Page Contains Element    (//label[contains(text(),'Both')]/ancestor::div//input[@type="radio"])[1]    20s
    # Click Element When Visible    (//label[contains(text(),'Both')]/ancestor::div//input[@type="radio"])[1]
    Click Element When Visible    //tr[@class="bc_block_row even"]//label[contains (text(), 'Credit') and @title="Credit"]/../input
    Click Element When Visible    //span[@id="aeSigleSearch"]/div/div[contains(text(),'Search')]
    # Sleep    4s
    ${Transaction_Time}=    convert_to_24hr_format    ${TRX_Time}
    ${Transaction_Date_Time}=    Catenate    ${Transaction_Date}   ${Transaction_Time}
    ${Transaction_Date_Time_Prv_Min}    ${Transaction_Date_Time_Next_Min}=    Adjust Time    ${Transaction_Date_Time}
    sleep    2s
    Wait Until Page Does Not Contain Element    //div[contains(text(), 'Query Progress')]    20s
    Wait Until Element Is Enabled    //span[@id="aeSigleSearch"]/div/div[contains(text(),'Search')]    60s
    Scroll Element Into View    //span[contains(text(), 'records')]/parent::*//following-sibling::select[@id="dgLogs_0_page_recordPerPage"]
    Select From List By Label    //span[contains(text(), 'records')]/parent::*//following-sibling::select[@id="dgLogs_0_page_recordPerPage"]    100
    sleep    4s
    ${page_count}=      Autosphere.Browser.Selenium.Get Text    ((//span[@class="pcontrol"])[2]/span)[2]
    Run Keyword And Return Status    Wait Until Page Contains Element    //td[contains(text(),'PKR${TRX Amount}')]/../td/label[ contains(text(),'${Transaction_Date_Time_Prv_Min}') or contains(text(),'${Transaction_Date_Time}') or contains(text(),'${Transaction_Date_Time_Next_Min}')]
    ${Transation_Exists}=    Does Page Contain Element    //td[contains(text(),'PKR${TRX Amount}')]/../td/label[ contains(text(),'${Transaction_Date_Time_Prv_Min}') or contains(text(),'${Transaction_Date_Time}') or contains(text(),'${Transaction_Date_Time_Next_Min}')]
    # sleep    200s
    IF    ${Transation_Exists}
            Log  transaction exists
            ${Fraudlent_TID}=    Get Text    (//td[contains(text(),'PKR${TRX Amount}')]/../td/label[ contains(text(),'${Transaction_Date_Time_Prv_Min}') or contains(text(),'${Transaction_Date_Time}') or contains(text(),'${Transaction_Date_Time_Next_Min}')]/../../td)[1]
    END
    FOR    ${page}    IN RANGE    1    ${page_count}
        Log    ${page}
        Log    Add variable of transaction number
        Run Keyword And Return Status    Wait Until Page Contains Element    //td[contains(text(),'PKR${TRX Amount}')]/../td/label[ contains(text(),'${Transaction_Date_Time_Prv_Min}') or contains(text(),'${Transaction_Date_Time}') or contains(text(),'${Transaction_Date_Time_Next_Min}')]
        ${Transation_Exists}=    Does Page Contain Element    //td[contains(text(),'PKR${TRX Amount}')]/../td/label[ contains(text(),'${Transaction_Date_Time_Prv_Min}') or contains(text(),'${Transaction_Date_Time}') or contains(text(),'${Transaction_Date_Time_Next_Min}')]
        IF    ${Transation_Exists}
            Log  transaction exists
            ${Fraudlent_TID}=    Get Text    (//td[contains(text(),'PKR${TRX Amount}')]/../td/label[ contains(text(),'${Transaction_Date_Time_Prv_Min}') or contains(text(),'${Transaction_Date_Time}') or contains(text(),'${Transaction_Date_Time_Next_Min}')]/../../td)[1]
            Exit For Loop
        ELSE
            Log   continue to other pages
            Click Element When Visible    (//div[@class="pGroupnext"]/div[@title="Next"])[3]
        END
    END
    [Return]    ${Transation_Exists}    ${available_amount}    ${Fraudlent_TID}