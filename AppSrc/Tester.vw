Use Windows.pkg
Use DFClient.pkg
Use cCJGrid.pkg
Use cCJGridColumn.pkg
Use cJsonObject.pkg
Use Variant.pkg
Use cJsonObject.pkg
Use cRESTHttpTransfer.pkg

// Local
//Define C_remoteHost for "localhost"
//Define C_callPath   for "Contacts/REST/"
//Define C_callPath   for "ContactsMixed/REST/"

// UIG
Define C_remoteHost for "www.unicorninterglobal.com"
Define C_callPath   for "RESTContactsDemo/REST/"

Define C_authCred   for "BASIC: LetMeInIAmAValidUser"

Struct tErrorResponse
    Integer code
    String  message
    String  data
End_Struct

Struct tShortContact
    String  email
    String  name
End_Struct

Struct tFullContact
    String  email
    String  name
    String  address
    String  city
    String  postcode
    String  telHome
    String  telMobile
    String  telWork
    Date    birthday
End_Struct

Struct tContactList    
    tShortContact[] contacts
End_Struct

Class cContactHttp is a cRESTHttpTransfer
    
    Procedure Construct_Object
        Boolean bOK
        
        Forward Send Construct_Object
        Set psRemoteHost to C_remoteHost
        Set psCallPath   to C_callPath
        
        Get AddHeader "Authorization" C_authCred to bOK        
    End_Procedure

End_Class

Deferred_View Activate_oTester for ;
Object oTester is a dbView

    Set Border_Style to Border_Thick
    Set Size to 132 452
    Set piMinSize to 132 452
    Set Location to 0 0
    Set Label to "Contacts"
    
    Property Boolean pbCreating False    
   
    Procedure ShowContact String sEmail
        tFullContact tCont
        Handle hoHttp hoJson
        
        Get Create (RefClass(cContactHttp)) to hoHttp
        Move (MakeCall(hoHttp, "GET", "Contact/" + sEmail, "", False)) to hoJson
        Send Destroy of hoHttp
        
        If hoJson Begin
            Get JsonToDataType of hoJson to tCont
            Send Destroy of hoJson
            
            Set Value of oEmail     to tCont.email
            Set Value of oName      to tCont.name
            Set Value of oAddress   to tCont.address
            Set Value of oCity      to tCont.city
            Set Value of oPostcode  to tCont.postcode
            Set Value of oTelHome   to tCont.telHome
            Set Value of oTelMobile to tCont.telMobile
            Set Value of oTelWork   to tCont.telWork
            Set Value of oBirthday  to tCont.birthday
            
            Set pbCreating to False
        End
        
    End_Procedure
    
    Procedure UpdateContact
        tFullContact     tCont
        tErrorResponse   tResp
        tDataSourceRow[] tData
        String  sEmail sVerb
        Integer iRow iLast i
        Handle  hoSrc hoHttp hoJson
        
        If (pbCreating(Self)) Begin
            Get Value of oEmail      to sEmail
            Move "PUT" to sVerb
        End
        Else Begin
            Get Value of oContacts 1 to sEmail
            Move "PATCH" to sVerb
        End
        
        Get Value of oEmail     to tCont.email
        Get Value of oName      to tCont.name
        Get Value of oAddress   to tCont.address
        Get Value of oCity      to tCont.city
        Get Value of oPostcode  to tCont.postcode
        Get Value of oTelHome   to tCont.telHome
        Get Value of oTelMobile to tCont.telMobile
        Get Value of oTelWork   to tCont.telWork
        Get Value of oBirthday  to tCont.birthday

        Get Create (RefClass(cContactHttp)) to hoHttp
        Move (MakeCall(hoHttp, sVerb, "Contact/" + sEmail, tCont, True)) to hoJson
        Send Destroy of hoHttp
        
        If hoJson Begin
            Get JsonToDataType of hoJson to tResp
            Send Destroy of hoJson                
            
            Send InitializeMyGrid of oContacts
            
            Get phoDataSource of oContacts to hoSrc
            Get DataSource of hoSrc to tData
            Move (SizeOfArray(tData) - 1) to iLast
            
            For i from 0 to iLast
                If (Lowercase(tData[i].sValue[1]) = tCont.email) Move i to iRow
            Loop
            
            Send MoveToRow of oContacts iRow
    
            Send Info_Box tResp.data tResp.message
        End
        
    End_Procedure
    
    Procedure NewContact
        Set Value of oEmail     to ""
        Set Value of oName      to ""
        Set Value of oAddress   to ""
        Set Value of oCity      to ""
        Set Value of oPostcode  to ""
        Set Value of oTelHome   to ""
        Set Value of oTelMobile to ""
        Set Value of oTelWork   to ""
        Set Value of oBirthday  to ""
        
        Set pbCreating to True
        Send Activate of oEmail
    End_Procedure
    
    Procedure DeleteContact
        String sEmail
        tErrorResponse tResp
        Handle hoHttp hoJson
        
        Get Value of oContacts 1 to sEmail
        
        Get Create (RefClass(cContactHttp)) to hoHttp
        Move (MakeCall(hoHttp, "DELETE", "Contact/" + sEmail, "", False)) to hoJson
        Send Destroy of hoHttp
        
        If hoJson Begin
            Get JsonToDataType of hoJson to tResp
            Send InitializeMyGrid of oContacts
            Send Info_Box tResp.data tResp.message
        End
        
    End_Procedure

    Object oFilter is a Group
        Set Size to 22 215
        Set Location to 2 7
        Set Label to "Filter on Name:"
        Set peAnchors to anNone

        Object oFrom is a Form
            Set Size to 9 78
            Set Location to 10 28
            Set Label to "From:"
            Set Label_Col_Offset to 22
            Set peAnchors to anNone

            Procedure OnChange
                String sValue
            
                Get Value to sValue
                Send InitializeMyGrid of oContacts
            End_Procedure

        End_Object
        
        Object oTo is a Form
            Set Size to 9 78
            Set Location to 10 131
            Set Label to "To:"
            Set Label_Col_Offset to 14
            Set peAnchors to anNone
        
            Procedure OnChange
                String sValue
            
                Get Value to sValue
                Send InitializeMyGrid of oContacts
            End_Procedure
        
        End_Object

    End_Object

    Object oContacts is a cCJGrid
        Set Size to 105 214
        Set Location to 25 7
        Set peAnchors to anAll
        Set pbReadOnly to True
        Set pbSelectionEnable to True

        Object oNameCol is a cCJGridColumn
            Set piWidth to 199
            Set psCaption to "Name"
        End_Object

        Object oEmailCol is a cCJGridColumn
            Set piWidth to 336
            Set psCaption to "Email"
        End_Object
        
        Procedure OnRowChanged Integer iOldRow Integer iNewSelectedRow
            String  sEmail
            
            Get Value 1 to sEmail
            Send ShowContact sEmail
        End_Procedure
    
        Procedure InitializeMyGrid
            tDataSourceRow[] tData
            tContactList tConts
            tErrorResponse tErr
            Integer i iLast
            String  sFirst sLast sQuery
            Handle  hoHttp hoJson
            Boolean bOK
            
            Get Value of oFrom to sFirst
            Get Value of oTo   to sLast

            If (sFirst <> "") Begin
                Move ("?start=" + sFirst) to sQuery
            End
            
            If (sLast <> "") Begin
                If (sQuery = "") Move "?" to sQuery
                Else Move (sQuery + "&")  to sQuery

                Move (sQuery + "end=" + sLast) to sQuery
            End
            
            Get Create (RefClass(cContactHttp)) to hoHttp
            
            Move (MakeCall(hoHttp, "GET", "ContactList" + sQuery, "", False)) to hoJson
            Send Destroy of hoHttp
            
            If hoJson Begin
                Get JsonToDataType of hoJson to tErr
                
                If (tErr.code = 0) Begin
                    Get JsonToDataType of hoJson to tConts
                    Send Destroy of hoJson
        
                    Move (SizeOfArray(tConts.contacts) - 1) to iLast
                    
                    For i from 0 to ILast
                        Move tConts.contacts[i].name  to tData[i].sValue[0]
                        Move tConts.contacts[i].email to tData[i].sValue[1]
                    Loop
                   
                End
                Else Begin
                    Send Info_Box tErr.data ("Error" * String(tErr.code) + ":" * tErr.message)
                End
                
            End
            
            Send InitializeData tData
        End_Procedure

        Procedure Activating
            Forward Send Activating
            Send InitializeMyGrid
        End_Procedure

    End_Object

    Object oContactText is a TextBox
        Set Size to 9 50
        Set Location to 4 225
        Set Label to 'Contact Details:'
        Set peAnchors to anTopRight
    End_Object

    Object oEmail is a Form
        Set Size to 9 168
        Set Location to 16 280
        Set Label to "Email address:"
        Set peAnchors to anTopRight
        Set Label_Col_Offset to 50
    End_Object

    Object oName is a Form
        Set Size to 9 168
        Set Location to 27 280
        Set Label to "Name:"
        Set peAnchors to anTopRight
        Set Label_Col_Offset to 50
    End_Object

    Object oAddress is a Form
        Set Size to 9 168
        Set Location to 38 280
        Set Label to "Address:"
        Set peAnchors to anTopRight
        Set Label_Col_Offset to 50
    End_Object

    Object oCity is a Form
        Set Size to 9 84
        Set Location to 49 280
        Set Label to "City:"
        Set peAnchors to anTopRight
        Set Label_Col_Offset to 50
    End_Object

    Object oPostcode is a Form
        Set Size to 9 84
        Set Location to 60 280
        Set Label to "Postcode:"
        Set peAnchors to anTopRight
        Set Label_Col_Offset to 50
    End_Object

    Object oTelHome is a Form
        Set Size to 9 84
        Set Location to 71 280
        Set Label to "Home Tel:"
        Set peAnchors to anTopRight
        Set Label_Col_Offset to 50
    End_Object

    Object oTelMobile is a Form
        Set Size to 9 84
        Set Location to 82 280
        Set Label to "Mobile Tel:"
        Set peAnchors to anTopRight
        Set Label_Col_Offset to 50
    End_Object

    Object oTelWork is a Form
        Set Size to 9 84
        Set Location to 93 280
        Set Label to "Work Tel:"
        Set peAnchors to anTopRight
        Set Label_Col_Offset to 50
    End_Object

    Object oBirthday is a Form
        Set Size to 9 46
        Set Location to 104 280
        Set Label to "Birthday:"
        Set peAnchors to anTopRight
        Set Label_Col_Offset to 50
        Set Form_Datatype to Date_Window
    End_Object

    Object oCreate is a Button
        Set Size to 12 50
        Set Location to 117 280
        Set Label to 'Clear/New'
        Set peAnchors to anTopRight
    
        Procedure OnClick
            Send NewContact
        End_Procedure
    
    End_Object

    Object oUpdate is a Button
        Set Size to 12 50
        Set Location to 117 335
        Set Label to 'Save/Update'
        Set peAnchors to anTopRight
    
        Procedure OnClick
            Send UpdateContact
        End_Procedure
    
    End_Object

    Object oDelete is a Button
        Set Size to 12 50
        Set Location to 117 390
        Set Label to 'Delete'
        Set peAnchors to anTopRight
    
        Procedure OnClick
            Send DeleteContact
        End_Procedure
    
    End_Object

CD_End_Object
