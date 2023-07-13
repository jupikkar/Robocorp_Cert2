*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    OperatingSystem
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive

*** Variables ***
${PDF_DOWNLOAD_PATH}  ${OUTPUT_DIR}${/}receipts${/}
${SCR_DOWNLOAD_PATH}  ${OUTPUT_DIR}${/}screens${/}
${ORDERS_DOWNLOAD_PATH}  downloads${/}orders.csv

*** Keywords ***
Open the robot order website
    Open Available Browser  https://robotsparebinindustries.com/#/robot-order

Get Orders
    Download  https://robotsparebinindustries.com/orders.csv  
    ...  ${ORDERS_DOWNLOAD_PATH}  
    ...  overwrite=True
    ${orders}=  Read table from CSV  ${ORDERS_DOWNLOAD_PATH}
    [Return]  ${orders}

Close the annoying modal
    Wait and Click Button  css:.btn-danger

Fill the Form
    [Arguments]  ${order}
    Select From List By Index    css:[name="head"]  ${order}[Head]
    Click Element    css:input#id-body-${order}[Body]
    Input Text    css:[placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    css:input#address    ${order}[Address]

Preview Robot
    Click Button  css:#preview

Submit Form
    Click Button    css:#order    
    Element Should Be Visible    css:#order-another

Store the receipt as a PDF file
    [Arguments]  ${order_no}
    ${receipt_loc}  Set Variable  css:div#receipt
    Wait Until Element Is Visible    ${receipt_loc}
    ${receipt_html}=  Get Element Attribute    ${receipt_loc}    outerHTML
    ${pdf_path}  Set Variable  ${PDF_DOWNLOAD_PATH}${order_no}.pdf
    ${pdf}=  HTML To Pdf  ${receipt_html}  ${pdf_path}
    [Return]  ${pdf_path}

Take a screenshot of the robot
    [Arguments]  ${order_no}
    ${scr_path}  Set Variable  ${SCR_DOWNLOAD_PATH}${order_no}.png
    Screenshot  css:div#robot-preview-image  ${scr_path}
    [Return]  ${scr_path}

Order Another Robot
    Click Button  css:#order-another

Embed the robot screenshot to the receipt PDF file
    [Arguments]  ${pdf_path}  ${scr_path}
    @{files_to_add}  Create List  ${scr_path}
    Open Pdf    ${pdf_path}
    Add Files To Pdf   ${files_to_add}  ${pdf_path}  append=True
    Close Pdf  ${pdf_path}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get Orders
    FOR  ${o}  IN  @{orders}
        Close the annoying modal
        Fill the Form  ${o}
        Preview Robot
        Wait until Keyword Succeeds  5  1s  Submit Form
        ${pdf}=    Store the receipt as a PDF file    ${o}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${o}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${pdf}  ${screenshot}
        Order Another Robot
    END
    Archive Folder With Zip    ${PDF_DOWNLOAD_PATH}    receipts.zip
    # [Teardown]  Remove Directory  downloads  recursive=True