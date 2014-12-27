Attribute VB_Name = "SheetUtil"
'===========================
'--- Module Contract     ---
'===========================
' This encompases both Workbook and Worksheet utilities
' Sheet and Worksheet are synonyms, and so are Book and Workbook
' There is one caveat when creating sheets in Excel
' * Sheet Names can only have 31 characters at most
'       Functions handle it by first triming it, then giving it another name until satisfied

'===========================
'--- Constants           ---
'===========================
Public Const SHEET_NAME_LENGTH_LIMIT As Integer = 31
Public Const ELLIPSIS As String = "..."
'===========================
'--- Functions     ---
'===========================

'# Checks if an worksheet exists
'? Reference: http://www.mrexcel.com/forum/excel-questions/3228-visual-basic-applications-check-if-worksheet-exists.html
Public Function DoesSheetExists(Book As Workbook, SheetName As String) As Boolean
    DoesSheetExists = False
    
    Dim Index As Integer, Sheet As Worksheet
    For Index = 1 To Book.Sheets.Count
        Set Sheet = Book.Worksheets(Index)
        DoesSheetExists = (Sheet.Name = SheetName)
        If DoesSheetExists Then Exit Function
    Next
End Function

'# Produce a sheet name that doesn't exceed the character limit
Public Function AsShortenedSheetName(SheetName As String) As String
    If Len(SheetName) <= SHEET_NAME_LENGTH_LIMIT Then
        AsShortenedSheetName = SheetName
    Else
        AsShortenedSheetName = Left(SheetName, SHEET_NAME_LENGTH_LIMIT - Len(ELLIPSIS)) & ELLIPSIS
    End If
End Function

'# Make a pseudo unique sheet name based on the time
'! If by some weird reason, a workbook has all 9999 Sheet-* names in the book, grab a gun
Private Function GenerateRandomSheetName() As String
    Randomize
    GenerateRandomSheetName = "Sheet-" & CStr(Int(Rnd * 9000) + 1000)
End Function

'# Renames the sheet with options, returns true if the sheet was renamed
'@ Param(TrimLongName): If the name is too long, it chops it to 31 characters with 3 inclusive ellipsis
'@                      If this is set to False and the name is too long, the output will be False
'@ Param(GenerateRandomName): If the name is not unique, an unique random name will be given
Public Function RenameSheetSafely(Book As Workbook, Sheet As Worksheet, SheetName As String, _
                    Optional TrimLongName As Boolean = True, _
                    Optional GenerateRandomName As Boolean = True, _
                    Optional GenerateUntilUnique As Boolean = True) As Boolean
    Dim ShortName As String
    ShortName = AsShortenedSheetName(SheetName)
    If Not TrimLongName And ShortName <> SheetName Then
        RenameSheetSilently = False
        Exit Function
    End If
    
    If IsSheetNameUnique(Book, ShortName) Then
        Sheet.Name = ShortName
        RenameSheetSilently = True
    Else
        If Not GenerateRandomName Then
            RenameSheetSilently = False
            Exit Function
        Else
            ShortName = GenerateRandomSheetName
            While GenerateUntilUnique And Not IsSheetNameUnique(Book, ShortName)
                ShortName = GenerateRandomSheetName
            Wend
            
            Sheet.Name = ShortName
            RenameSheetSilently = True
        End If
    End If
End Function

'# This adds the worksheet with the specified name
'# This follows the flow of RenameSheetSafely()
'# However, if the renaming returns false, you will get the sheet with the default name
'# GenerateUntilUnique is set to False as the original name might be the most original
'# However resort to RenameSheetSafely if it fails
Public Function AddSheet(Book As Workbook, SheetName As String, _
                    Optional TrimLongName As Boolean = True, _
                    Optional GenerateRandomName As Boolean = True) As Worksheet
    Set AddSheet = Book.Worksheets.Add
    RenameSheetSafely Book, AddSheet, SheetName, _
        TrimLongName:=TrimLongName, _
        GenerateRandomName:=GenerateRandomName, _
        GenerateUntilUnique:=False
End Function


'# This checks if a sheet name is unique in a book.
'# This is used for safely renaming a sheet
'! SheetName however should comply with the 31 character rule
'!  This just checks the name, handling it is someone elses work
Public Function IsSheetNameUnique(Book As Workbook, SheetName As String) As Boolean
    IsSheetNameUnique = Not DoesSheetExists(Book, SheetName)
End Function

'# Quietly delete a sheet without the clutter
'# Used in programatic deletes without the user interaction
Public Sub DeleteSheetSilently(Sheet As Worksheet)
On Error Resume Next
    Dim HasNoError As Boolean
    HasNoError = (Err.Number = 0)
    
    Application.DisplayAlerts = False
    Sheet.Delete
    Application.DisplayAlerts = True
    
    If HasNoError Then Err.Clear
End Sub

'# This removes all sheets in a workbook except the first N, where N is an integer
'# This also assumes the sheets are already ordered to what gets deleted and not
'@ Param(Count): This assumes N is greater than 0, else it does nothing
'@              So if this is 1, this removes all sheet but the first
Public Sub RemoveAllSheetExceptFirstFew(Book As Workbook, Count As Integer)
    Application.DisplayAlerts = False ' Remove alerts for deleting a sheet
    Do While ActiveWorkbook.Sheets.Count > Count
        ActiveWorkbook.Sheets(Count + 1).Delete
    Loop
    Application.DisplayAlerts = True
End Sub

'# Gets the last sheet in a workbook
Public Function GetLastSheet(Book As Workbook)
    Set GetLastSheet = Book.Worksheets(Book.Worksheets.Count)
End Function

'# Moves a sheet to the end, nothing fancy
Public Sub MoveSheetToEnd(Book As Workbook, Sheet As Worksheet)
    Sheet.Move After:=GetLastSheet(Book)
End Sub
