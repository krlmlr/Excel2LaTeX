Attribute VB_Name = "Memento"
Option Explicit

Public dEncodings As New Scripting.Dictionary

Public Function ModelPropertyNames() As String()
    Const NAMES As String = "RangeAddress|Options|CellWidth|Indent|FileName|Encoding"
    ModelPropertyNames = Split(NAMES, "|")
End Function

Public Function ModelToCollection(ByVal pModel As IModel) As Collection
    Set ModelToCollection = New Collection
    
    Dim sName As Variant
    For Each sName In ModelPropertyNames()
        ModelToCollection.Add CallByName(pModel, sName, VbGet), sName
    Next
End Function

Public Function ModelToString(ByVal pModel As IModel) As String
    Dim sName As Variant
    For Each sName In ModelPropertyNames()
        ModelToString = ModelToString & Printf("%1=%2;", sName, CallByName(pModel, sName, VbGet))
    Next
End Function

Public Sub CollectionToModel(ByVal pModel As IModel, ByVal cCollection As Collection)
    Dim sName As Variant
    For Each sName In ModelPropertyNames()
        On Error Resume Next
        CallByName pModel, sName, VbLet, cCollection(sName)
        On Error GoTo 0
    Next
End Sub

Public Sub StringToModel(ByVal pModel As IModel, ByVal sSettings As String)
    Dim aSettings() As String
    aSettings = Split(sSettings, ";")
    
    Dim l1 As Long
    Dim sKey As String
    Dim sValue As String
    For l1 = 0 To UBound(aSettings)
        SplitKeyValue aSettings(l1), sKey, sValue
        
        On Error Resume Next
        CallByName pModel, sKey, VbLet, sValue
        On Error GoTo 0
    Next
End Sub

Public Function CollectionToNewModel(ByVal cSettings As Collection) As IModel
    Set CollectionToNewModel = NewModel()
    CollectionToModel CollectionToNewModel, cSettings
End Function

Public Function StringToNewModel(ByVal sSettings As String) As IModel
    Set StringToNewModel = NewModel()
    StringToModel StringToNewModel, sSettings
End Function


Public Function RangeToAddress(ByVal rRange As Range) As String
    If rRange Is Nothing Then Exit Function
    RangeToAddress = Printf("'%1'!%2", rRange.Worksheet.Name, rRange.Address)
End Function

Public Function AddressToRange(ByVal sRangeAddress As String) As Range
    Set AddressToRange = Nothing
    If sRangeAddress = "" Then Exit Function
    Set AddressToRange = Application.Range(sRangeAddress)
End Function


Public Sub SaveConversionResultToFile(ByVal pModel As IModel)
    Dim sFileName As String
    sFileName = pModel.AbsoluteFileName
    If sFileName = "" Then Exit Sub
    
    Dim sCodePageRemark As String
    sCodePageRemark = Printf("% codepage %1", pModel.Encoding)
    
    If pModel.Encoding = Application.DefaultWebOptions.Encoding Then
        Open sFileName For Output As 1
        Print #1, sCodePageRemark
        Print #1, pModel.GetConversionResult;
        Close #1
    Else
        Dim str As New ADODB.Stream
        str.Type = StreamTypeEnum.adTypeText
        ' https://docs.microsoft.com/en-us/sql/ado/reference/ado-api/charset-property-ado?view=sql-server-2017
        ' For a list of the character set names that are known by a system,
        ' see the subkeys of HKEY_CLASSES_ROOT\MIME\Database\Charset in the Windows Registry.
        str.Charset = dEncodings(pModel.Encoding)
        str.Open
        str.WriteText sCodePageRemark, StreamWriteEnum.adWriteLine
        str.WriteText pModel.GetConversionResult
        str.SaveToFile sFileName, SaveOptionsEnum.adSaveCreateOverWrite
        str.Close
        Set str = Nothing
    End If
End Sub

Public Sub SaveAllStoredItems(ByVal pStorage As IStorage)
    Dim cItems As Collection
    Set cItems = pStorage.GetItems
    
    Dim l1 As Long
    For l1 = 1 To cItems.Count
        SaveConversionResultToFile cItems(l1)
    Next
End Sub
