*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault
Suite Teardown    Close All Browsers

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    Certificate_2
    ${url}=    Set Variable    ${secret}[order_url]
    Open Available Browser    ${url}

*** Keywords ***
Get orders
    Add text input    url    Orders CSV Download URL?    https://robotsparebinindustries.com/orders.csv
    ${response}=    Run dialog
    Download    url=${response.url}    overwrite=true
    ${ret}=    Read table from CSV    path=orders.csv    header=true
    [Return]    ${ret}

*** Keywords ***
Close the annoying modal
    Click Button    OK

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value   name:head    ${row}[Head]
    Select Radio Button    group_name=body    value=id-body-${row}[Body]
    Input Text    locator=class:form-control    text=${row}[Legs]
    Input Text    address    ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button    id:preview

*** Keywords ***
Submit the order
    Wait Until Keyword Succeeds    5x    0s    Try to Click Order

*** Keywords ***
Try to Click Order
    Click Button    id:order
    Wait Until Page Contains Element    id:order-completion    1s

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_html}=    Get Element Attribute    id:order-completion    outerHTML
    ${ret}=    Set Variable    ${CURDIR}${/}output${/}receipts${/}${order_number}_receipt.pdf
    Html To Pdf    ${receipt_html}    ${ret}
    [Return]    ${ret}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${ret}=    Set Variable    ${CURDIR}${/}output${/}${order_number}_preview.png
    Screenshot    id:robot-preview-image    ${ret}
    [Return]    ${ret}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${preview_path}    ${receipt_path}
    ${files}=    Create List    ${preview_path}:align=center
    Add Files To Pdf    ${files}    ${receipt_path}    True

*** Keywords ***
Go to order another robot
    Click Button    id:order-another

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipts    ${CURDIR}${/}output${/}receipts.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
