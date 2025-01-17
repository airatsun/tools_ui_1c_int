#Region Public

#Region TypeWorks

// This is an enumeration by type.
// 
// Parameters:
// 	Type - Type
// 
// Returns:
// 	Boolean - This is an enumeration by type
Function ThisEnumerationByType(Type) Export
	Return UT_Common.IsEnumbyType(Type);
EndFunction

Function ValueTableType() Export
	Return Type("ValueTable");	
EndFunction

#EndRegion

// Connect external data processors to the session.
// 
// Parameters:
// 	AddressDataProcessorsBinaryData - String - The address of the binary data of the processing
// 	DataProcessorName - Undefined, String - ProcessingName
Procedure ConnectExternalProcessingSession(AddressDataProcessorsBinaryData, DataProcessorName = Undefined) Export
	UT_Common.ConnectExternalDataProcessorToTheSession(AddressDataProcessorsBinaryData, DataProcessorName);
EndProcedure

// Common templates binary data address.
// 
// Parameters:
// 	TemplateName - String - template name
// 	FormUUID - UUID, Undefined - Form UUID
// 
// Returns:
// 	String - Common templates binary data address
Function CommonTemplatesBinaryDataAddress(TemplateName, FormUUID = Undefined) Export
	If FormUUID = Undefined Then
		Return PutToTempStorage(GetCommonTemplate(TemplateName));
	Else
		Return PutToTempStorage(GetCommonTemplate(TemplateName), FormUUID);
	EndIf;
EndFunction

// Session start parameters
//
// Returns:
//  Structure - Session start parameters:
// * ExtensionRightsAdded - Boolean - 
// * SessionNumber - Number - 
// * ConfigurationScriptVariant - String -
Function SessionStartParameters() export

	SessionStartParameters= New Structure;

	if Not UT_CommonClientServer.IsPortableDistribution() Then
		//@skip-check using-isinrole
		If AccessRight("Administration", Metadata) AND Not IsInRole("UT_UniversalTools")
			and InfoBaseUsers.GetUsers().Count() > 0 then
			
			SSLVersion = UT_Common.SSLVersion();
			If UT_CommonClientServer.CompareVersions(SSLVersion, "3.1.6.0") >= 0 Then
				//
				ResultRightsApplication = UT_Common.AccessRightsSettingResultForBSP_3_1_6_AndHigher();
			Else
				CurrentUser = InfoBaseUsers.CurrentUser();
				CurrentUser.Roles.Add(Metadata.Roles.UT_UniversalTools);
				CurrentUser.Write();
			
				ResultRightsApplication = True;
			EndIf;
			
			SessionStartParameters.Insert("ExtensionRightsAdded", ResultRightsApplication);
		else
			SessionStartParameters.Insert("ExtensionRightsAdded", False);
		endif;
	Else
		SessionStartParameters.Insert("ExtensionRightsAdded", False);	
	EndIf;

	SessionStartParameters.Insert("SessionNumber", InfoBaseSessionNumber());
	SessionStartParameters.Insert("ConfigurationScriptVariant", UT_CodeEditorServer.ConfigurationScriptVariant());

	Return SessionStartParameters;
EndFunction

// Sets the bold font for form group titles so they are correctly displayed in the 8.2 interface.2.
// In the Taxi interface, group titles with standard highlight and without one are displayed in large font.
// In the 8.2 interface such titles are displayed as regular labels and are not associated with titles.
// This function is designed for visually highlighting (in bold) of group titles in the mode of the 8.2 interface.
//
// Parameters:
//  Form - ManagedForm - a form where group title fonts are changed.
//  GroupNames - String - a list of the form group names separated with commas. If the group names 
//                        are not specified, the appearance will be applied to all groups on the form.
//
// Example:
//  Procedure OnCreateAtServer(Cancel, StandardProcessing)
//    StandardSubsystemsServer.SetGroupsTitlesRepresentation(ThisObject);
//
Procedure SetGroupTitleRepresentation(Form, GroupNames = "") Export
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		BoldFont = New Font(,, True);
		If NOT ValueIsFilled(GroupNames) Then 
			For Each Item In Form.Items Do 
				If Type(Item) = Type("FormGroup") AND Item.Type = FormGroupType.UsualGroup
					AND Item.ShowTitle = True AND (Item.Representation = UsualGroupRepresentation.NormalSeparation
					Or Item.Representation = UsualGroupRepresentation.None) Then 
						Item.TitleFont = BoldFont;
				EndIf;
			EndDo;
		Else
			TitleArray = UT_StringFunctionsClientServer.SplitStringIntoSubstringsArray(GroupNames,,, True);
			For Each TitleName In TitleArray Do
				Item = Form.Items[TitleName];
				If Item.Representation = UsualGroupRepresentation.NormalSeparation OR Item.Representation 
					= UsualGroupRepresentation.None Then 
					Item.TitleFont = BoldFont;
				EndIf;
			EndDo;
		EndIf;
	EndIf;

EndProcedure

// Defalut language code
//
// Returns:
//  String - default language code
Function DefaultLanguageCode() Export
	Return UT_CommonClientServer.DefaultLanguageCode();
EndFunction

// See StandardSubsystemsCached.RefsByPredefinedItemsNames
Function RefsByPredefinedItemsNames(FullMetadataObjectName) Export

	Return UT_CommonCached.RefsByPredefinedItemsNames(FullMetadataObjectName);

EndFunction

Function ObjectAttributesValues(Ref, Val Attributes, SelectAllowedItems = False) Export

	Return UT_Common.ObjectAttributesValues(Ref, Attributes, SelectAllowedItems);

EndFunction

// Returns attribute values retrieved from the infobase using the object reference.
//
// To read attribute values regardless of current user rights, enable privileged mode.
//
// Parameters:
//  Ref - AnyRef - the object whose attribute values will be read.
//      - String - full name of the predefined item whose attribute values will be read.
//  AttributeName - String - the name of the attribute.
//  SelectAllowedItems - Boolean - if True, user rights are considered when executing the object query.
//                                If a record-level restriction is set, return Undefined.
//                                if the user has no rights to access the table, an exception is raised.
//                                if False, an exception is raised if the user has no rights to 
//                                access the table or any attribute.
//
//
// Returns:
//  Arbitrary - depends on the type of the read atrribute value.
//            if a blank reference is passed to Ref, return Undefined.
//            if a reference to a nonexisting object (invalid reference) is passed to Ref, 
//            	return Undefined.
//
Function ObjectAttributeValue(Ref, AttributeName, SelectAllowedItems = False) Export

	Return UT_Common.ObjectAttributeValue(Ref, AttributeName, SelectAllowedItems);

EndFunction

Function StoredIBUserPasswordData(Username) Export
	Return UT_Users.StoredIBUserPasswordData(Username);
EndFunction

Procedure SetIBUserPassword(Username, Password) Export
	UT_Users.SetIBUserPassword(Username, Password);
EndProcedure

Procedure RestoreUserDataAfterUserSessionStart(UserName,
	StoredIBUserPasswordData) Export
	UT_Users.RestoreUserDataAfterUserSessionStart(UserName,
		StoredIBUserPasswordData);
EndProcedure

Procedure AddObjectsArrayToCompare(Objects) Export
	UT_Common.AddObjectsArrayToCompare(Objects);
EndProcedure

Procedure UploadObjectsToXMLonServer(ObjectsArray, FileURLInTempStorage, FormID=Undefined) Export
	UploadingDataProcessor = DataProcessors.UT_ExportImportDataXMLWithFilters.Create();
	UploadingDataProcessor.Initializing();
	UploadingDataProcessor.ExportDocumentWithItsRecords=Истина;
	UploadingDataProcessor.UseFastInfoSetFormat=Ложь;
	
	For Each CurrentObject In ObjectsArray Do
		NR=UploadingDataProcessor.AdditionalObjectsToExport.Add();
		NR.Object=CurrentObject;
		NR.ObjectForQueryName=UT_Common.TableNameByRef(CurrentObject);
	EndDo;
		
	TempFileName = GetTempFileName(".xml");
	
	UploadingDataProcessor.ExecuteExport(TempFileName, , New ValueTable);
		
	File = New File(TempFileName);

	If File.Exist() Then

		BinaryData = New BinaryData(TempFileName);
		FileURLInTempStorage = PutToTempStorage(BinaryData, FormID);
		DeleteFiles(TempFileName);

	EndIf;
	
EndProcedure

// Convert (serializes) any value to XML-string.
// Converted to may be only those objects for which the syntax helper indicate that they are serialized.
// См. также ValueFromStringXML.
//
// Parameters:
//  Value  - Arbitrary  - value that you want to serialize into an XML string..
//
//  Returns:
//  String - XML-string.
//
Function ValueToXMLString(Value) Export

	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, Value, XMLTypeAssignment.Explicit);

	Return XMLWriter.Close();
EndFunction

// Converts (deserializes) an XML string into a value.
// See also ValueToXMLString.
//
// Parameters:
//  XMLString - String - an XML string with a serialized object.
//
// Returns:
//  Arbitrary - the value extracted from an XML string.
//
Function ValueFromXMLString(XMLString, Type = Undefined) Export

	XMLReader = New XMLReader;
	XMLReader.SetString(XMLString);

	If Type = Undefined Then
		Return XDTOSerializer.ReadXML(XMLReader);
	Else
		Return XDTOSerializer.ReadXML(XMLReader, Type);
	EndIf;
EndFunction

Function ConfigurationMetadataDescriptionAdress() Export
	Возврат Undefined; // Obsolete. UT_Common.MetaDataAdressDescription() dont exist;
EndFunction

// Get password difficulty length check.
// 
// Parameters:
// 	ParametersStructure - Structure 
// * MinPasswordLength - Number - Minimum password length, save to set later
// * PasswordStrengthCheck - Boolean - Save the parameter to restore it later.
// Returns: 
// 	Structure - Return password complexity and length:   
// * MinPasswordLength - Number - Minimum password length, save to set later
// * PasswordStrengthCheck - Boolean - Save the parameter to restore it later. 
Function GetPasswordStrengthLengthCheck(ParametersStructure) Export
	ParametersStructure.Insert("MinPasswordLength", GetUserPasswordMinLength());
	ParametersStructure.Insert("PasswordStrengthCheck", GetUserPasswordStrengthCheck());
	Return ParametersStructure;
EndFunction


// Set password strength length complexity check.
// 
// Parameters:
// 	ParametersStructure - see GetPasswordStrengthLengthCheck 
//  ResetCheck - Boolean
//
Procedure SetPasswordStrengthLengthCheck(ParametersStructure, ResetCheck = False) Export
	If ResetCheck Then
		If ParametersStructure.MinPasswordLength > 12 Then
			SetUserPasswordMinLength(0);
		EndIf;
		If ParametersStructure.PasswordDifficultyCheck then
			SetUserPasswordStrengthCheck(False);
		EndIf;	
	Else
		If ParametersStructure.MinPasswordLength > 12 Then
			SetUserPasswordMinLength(ParametersStructure.MinPasswordLength);
		EndIf;
		If ParametersStructure.PasswordDifficultyCheck then
			SetUserPasswordStrengthCheck(ParametersStructure.PasswordDifficultyCheck);
		EndIf;		
	EndIf;				

EndProcedure
#Region JSON

Function mReadJSON(Value) Export
	Return UT_CommonClientServer.mReadJSON(Value);
EndFunction // ReadJSON()

Function mWriteJSON(DataStructure) Export
	Return UT_CommonClientServer.mWriteJSON(DataStructure);
EndFunction // WriteJSON()
#EndRegion




#Region StorageSettings

////////////////////////////////////////////////////////////////////////////////
// Saving, reading, and deleting settings from storages.

// Saves a setting to the common settings storage as the Save method of 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> object. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, data save fails and no error is raised.
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   Settings - Arbitrary - see the Syntax Assistant.
//   SettingsDetails - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//   UpdateCachedValues - Boolean - the flag that indicates whether to execute the method.
//
Procedure CommonSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDetails = Undefined, Username = Undefined, UpdateCachedValues = False) Export

	UT_Common.CommonSettingsStorageSave(ObjectKey, SettingsKey, Settings,SettingsDetails,
		Username,UpdateCachedValues = False);

EndProcedure

// Saves settings to the common settings storage as the Save method of 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> object. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, data save fails and no error is raised.
// 
// Parameters:
//   MultipleSettings - Array of Structure - 
//   	Structure with the following properties:
//     		Object - String - see the ObjectKey parameter in the Syntax Assistant.
//     		Setting - String - see the SettingsKey parameter in the Syntax Assistant.
//     		Value - Arbitrary - see the Settings parameter in the Syntax Assistant.
//
//   UpdateCachedValues - Boolean - the flag that indicates whether to execute the method.
//
Procedure CommonSettingsStorageSaveArray(MultipleSettings, UpdateCachedValues = False) Export
	
	UT_Common.CommonSettingsStorageSaveArray(MultipleSettings, UpdateCachedValues);

EndProcedure

// Loads a setting from the general settings storage as the Load method, 
// StandardSettingsStorageManager objects, or SettingsStorageManager.<Storage name>. The setting key 
// supports more than 128 characters by hashing the part that exceeds 96 characters.
// 
// If no settings are found, returns the default value.
// If the SaveUserData right is not granted, the default value is returned and no error is raised.
//
// References to database objects that do not exist are cleared from the return value:
// - The returned reference is replaced by the default value.
// - The references are deleted from the data of Array type.
// - Key is not changed for the data of Structure or Map types, and value is set to Undefined.
// - Recursive analysis of values in the data of Array, Structure, Map types is performed.
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   DefaultValue - Arbitrary - a value that is returned if no settings are found.
//                              If not specified, returns Undefined.
//   SettingsDetails - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//
// Returns:
//   Arbitrary - see the Syntax Assistant.
//
Function CommonSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined, 
	SettingsDetails = Undefined, Username = Undefined) Export
	Return UT_Common.CommonSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue, 
			SettingsDetails, Username)

EndFunction

// Removes a setting from the general settings storage as the Remove method, 
// StandardSettingsStorageManager objects, or SettingsStorageManager.<Storage name>. The setting key 
// supports more than 128 characters by hashing the part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, no data is deleted and no error is raised.
//
// Parameters:
//   ObjectKey - String, Undefined - see the Syntax Assistant.
//   SettingsKey - String, Undefined - see the Syntax Assistant.
//   UserName - String, Undefined - see the Syntax Assistant.
//
Procedure CommonSettingsStorageDelete(ObjectKey, SettingsKey, Username) Export

	UT_Common.CommonSettingsStorageDelete(ObjectKey, SettingsKey, Username);

EndProcedure

// Saves a setting to the system settings storage as the Save method of 
// StandardSettingsStorageManager object. Setting keys exceeding 128 characters are supported by 
// hashing the key part that exceeds 96 characters.
// If the SaveUserData right is not granted, data save fails and no error is raised.
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   Settings - Arbitrary - see the Syntax Assistant.
//   SettingsDetails - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//   UpdateCachedValues - Boolean - the flag that indicates whether to execute the method.
//
Procedure SystemSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDetails = Undefined, Username = Undefined, UpdateCachedValues = False) Export

	UT_Common.SystemSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDetails,Username,UpdateCachedValues);

EndProcedure

// Loads a setting from the system settings storage as the Load method or the 
// StandardSettingsStorageManager object. The setting key supports more than 128 characters by 
// hashing the part that exceeds 96 characters.
// If no settings are found, returns the default value.
// If the SaveUserData right is not granted, the default value is returned and no error is raised.
//
// The return value clears references to a non-existent object in the database, namely:
// - The returned reference is replaced by the default value.
// - The references are deleted from the data of Array type.
// - Key is not changed for the data of Structure or Map types, and value is set to Undefined.
// - Recursive analysis of values in the data of Array, Structure, Map types is performed.
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   DefaultValue - Arbitrary - a value that is returned if no settings are found.
//                                             If not specified, returns Undefined.
//   SettingsDetails - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//
// Returns:
//   Arbitrary - see the Syntax Assistant.
//
Function SystemSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined, 
			SettingsDetails = Undefined, Username = Undefined) Export

	Return UT_Common.SystemSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue, 
			SettingsDetails , Username );

EndFunction

// Removes a setting from the system settings storage as the Remove method or the 
// StandardSettingsStorageManager object. The setting key supports more than 128 characters by 
// hashing the part that exceeds 96 characters.
// If the SaveUserData right is not granted, no data is deleted and no error is raised.
//
// Parameters:
//   ObjectKey - String, Undefined - see the Syntax Assistant.
//   SettingsKey - String, Undefined - see the Syntax Assistant.
//   UserName - String, Undefined - see the Syntax Assistant.
//
Procedure SystemSettingsStorageDelete(ObjectKey, SettingsKey, Username) Export

	UT_Common.SystemSettingsStorageDelete(ObjectKey, SettingsKey, Username);

EndProcedure

// Saves a setting to the form data settings storage as the Save method of 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> object. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, data save fails and no error is raised.
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   Settings - Arbitrary - see the Syntax Assistant.
//   SettingsDetails - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//   UpdateCachedValues - Boolean - the flag that indicates whether to execute the method.
//
Procedure FormDataSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDetails = Undefined,Username = Undefined, UpdateCachedValues = False) Export

	UT_Common.FormDataSettingsStorageSave(ObjectKey, SettingsKey, Settings, SettingsDetails,
		Username, UpdateCachedValues);

EndProcedure

// Retrieves the setting from the form data settings storage using the Load method for 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> objects. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If no settings are found, returns the default value.
// If the SaveUserData right is not granted, the default value is returned and no error is raised.
//
// References to database objects that do not exist are cleared from the return value:
// - The returned reference is replaced by the default value.
// - The references are deleted from the data of Array type.
// - Key is not changed for the data of Structure or Map types, and value is set to Undefined.
// - Recursive analysis of values in the data of Array, Structure, Map types is performed.
//
// Parameters:
//   ObjectKey - String - see the Syntax Assistant.
//   SettingsKey - String - see the Syntax Assistant.
//   DefaultValue - Arbitrary - a value that is returned if no settings are found.
//                                             If not specified, returns Undefined.
//   SettingsDetails - SettingsDescription - see the Syntax Assistant.
//   UserName - String - see the Syntax Assistant.
//
// Returns:
//   Arbitrary - see the Syntax Assistant.
//
Function FormDataSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined, 
			SettingsDetails = Undefined, Username = Undefined) Export

	Return UT_Common.FormDataSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue,
		SettingsDetails, Username);

EndFunction

// Deletes the setting from the form data settings storage using the Delete method for 
// StandardSettingsStorageManager or SettingsStorageManager.<Storage name> objects. Setting keys 
// exceeding 128 characters are supported by hashing the key part that exceeds 96 characters.
// 
// If the SaveUserData right is not granted, no data is deleted and no error is raised.
//
// Parameters:
//   ObjectKey - String, Undefined - see the Syntax Assistant.
//   SettingsKey - String, Undefined - see the Syntax Assistant.
//   UserName - String, Undefined - see the Syntax Assistant.
//
Procedure FormDataSettingsStorageDelete(ObjectKey, SettingsKey, Username) Export
	
	UT_Common.FormDataSettingsStorageDelete(ObjectKey, SettingsKey, Username);

EndProcedure

#EndRegion

#Region Algorithms

Function GetRefCatalogAlgorithms(Algorithm) Export
	Return UT_Common.GetRefCatalogAlgorithms(Algorithm);
EndFunction

Function ExecuteAlgorithm(AlgorithmRef, IncomingParameters = Undefined, ExecutionError = False,
	ErrorMessage = "") Export
	Return UT_Common.ExecuteAlgorithm(AlgorithmRef, IncomingParameters, ExecutionError,
		ErrorMessage);
EndFunction

#EndRegion

#Region Debug

// Write data for debugging to the сatalog.
// 
// Parameters:
// 	DebuggingObjectType - String - Debug object type
// 	DebugData - Arbitrary - Debugging data
// 	Name - String - Name
// 
// Returns:
// 	String - Result of debugging data saving
// 	
//
Function SaveDebuggingDataToCatalog(DebuggingObjectType, DebugData, Name = "") Export
	
	IsTransactionActive = TransactionActive();
	If IsTransactionActive And UT_CommonClientServer.IsPortableDistribution() Then
		Return SaveDebuggingDataToFile(DebuggingObjectType, DebugData, Name);
	EndIf;
		
	SettingsKey = DebuggingObjectType + "/" + UserName() + "/" + Format(CurrentDate(), "DF=yyyyMMddHHmmss;");
	
	If ValueIsFilled(Name) Then
		SettingsKey = SettingsKey + "/" + Name;
	EndIf;
	
	DebuggingDataObjectKey=UT_CommonClientServer.DebuggingDataObjectDataKeyInSettingsStorage();
      If TransactionActive() Then
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("ObjectKey", DebuggingDataObjectKey);
		ProcedureParameters.Insert("SettingsKey", SettingsKey);
		ProcedureParameters.Insert("Settings", DebugData);

		ExecutionParameters = UT_TimeConsumingOperations.BackgroundExecutionParameters(Undefined);
		ExecutionParameters.Insert("RunInBackground", True);
		
		UT_TimeConsumingOperations.ExecuteInBackground("UT_Common.SystemSettingsStorageSaveInBackground", 
												ProcedureParameters, 
												ExecutionParameters);
		Message = NSTR("ru = 'Запись будет выполнена в фоне. Ключ настроек ';en = 'Write procedure will be executed in background mode. Settings key '") + SettingsKey;
	Else
		UT_Common.SystemSettingsStorageSave(DebuggingDataObjectKey, 
			SettingsKey, 
			DebugData);
		Message = NSTR("ru = 'Запись выполнена успешно. Ключ настроек ';en = 'Writing was completed successfully. Settings Key '") + SettingsKey;
	EndIf;
	Return Message;
EndFunction

// Write data for debugging to a file.
// 
// Parameters:
// 	DebuggingObjectType - String - Debug object type
// 	DebugData - Arbitrary - Debugging data
// 	Name - String - Name
// 
// Returns:
// 	String - Result of debugging data saving
//
Function SaveDebuggingDataToFile(DebuggingObjectType, DebugData, Name = "") Export
	InstrumentsCatalogAtServer = UT_Common.DebuggingDataDirectoryAtServer();
	
	CatalogName = String(New UUID);
	
	SaveDirectory = UT_CommonClientServer.MergePaths(InstrumentsCatalogAtServer, CatalogName);
	Try
		CreateDirectory(SaveDirectory);
	Except
		Return Undefined;
	EndTry;
	
	DataFileName = UT_CommonClientServer.MergePaths(SaveDirectory, "DATA.data");
	MetadataFileName = UT_CommonClientServer.MergePaths(SaveDirectory, "METADATA.json");
	
	SaveMetadata = New Structure;
	SaveMetadata.Insert("Author", UserName());
	SaveMetadata.Insert("Date", CurrentDate());
	SaveMetadata.Insert("DebuggingObjectType", DebuggingObjectType);
	SaveMetadata.Insert("Name", Name);
	
	UT_CommonClientServer.mWriteJSONFile(MetadataFileName, SaveMetadata);
	
	ValueToFile(DataFileName, SaveMetadata);
	
	Return "Recording was successful. Server catalog " + SaveDirectory;

EndFunction

Function DebuggingObjectDataStructureFromDebugDataCatalog(DataPath) Export
	Result = New Structure;
	Result.Insert("DebuggingObjectType", DataPath.DebuggingObjectType);
	Result.Insert("DebuggingObjectAddress", PutToTempStorage(
		DataPath.DebuggingObjectStorage.Get()));

	Return Result;
EndFunction

Function DebuggingObjectTempPathFromSystemSettingsStorage(SettingsKey,User=Undefined, 
	FormID=Undefined) Export
	DebuggingDataObjectKey=UT_CommonClientServer.DebuggingDataObjectDataKeyInSettingsStorage();
	DebugSettings=UT_Common.SystemSettingsStorageLoad(DebuggingDataObjectKey,
													  SettingsKey,
													  ,
													  ,
													  User);

	If DebugSettings = Undefined Then
		Return Undefined;
	EndIf;

	If FormID=Undefined Then
		DebuggingObjectAddress=PutToTempStorage(DebugSettings);
	Else
		DebuggingObjectAddress=PutToTempStorage(DebugSettings, FormID);
	EndIf;

	Return DebuggingObjectAddress;
EndFunction

Function DebuggingObjectTempPathFromDebugDataCatalog(DebugDataDirectory, FormID = Undefined) Export
	
	Files = FindFiles(DebugDataDirectory, "*.data");
	If Files.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	FileData = Files[0];
	
	If Not FileData.Exists() Then
		Return Undefined;
	EndIf;

	SettingsOptions = ValueFromFile(FileData.FullName);

	If FormID = Undefined Then
		DebuggingObjectAddress=PutToTempStorage(SettingsOptions);
	Else
		DebuggingObjectAddress=PutToTempStorage(SettingsOptions, FormID);
	EndIf;

	Return DebuggingObjectAddress;
EndFunction

Function SerializeDCSForDebug(DCS, DcsSettings, ExternalDataSets) Export
	ObjectStructure = New Structure;

	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, DCS, "dataCompositionSchema",
		"http://v8.1c.ru/8.1/data-composition-system/schema");

	ObjectStructure.Insert("DCSText", XMLWriter.Close());

	If DcsSettings = Undefined Then
		Settings=DCS.DefaultSettings;
	Else
		Settings=DcsSettings;
		
	EndIf;

	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, Settings, "Settings",
		"http://v8.1c.ru/8.1/data-composition-system/settings");
	ObjectStructure.Insert("DcsSettingsText", XMLWriter.Close());

	If TypeOf(ExternalDataSets) = Type("Structure") Then
		Sets = New Structure;

		For Each KeyValue In ExternalDataSets Do
			If TypeOf(KeyValue.Value) <> Type("ValueTable") Then
				Continue;
			EndIf;

			Sets.Insert(KeyValue.Key, ValueToStringInternal(KeyValue.Value));
		EndDo;

		If Sets.Count() > 0 Then
			ObjectStructure.Insert("ExternalDataSets", Sets);
		EndIf;
	EndIf;

	Return ObjectStructure;

EndFunction

Function TempTablesManagerTempTablesStructure(TempTablesManager) Export
	TempTablesStructure = New Structure;
	For each TempTable In TempTablesManager.Tables Do
		TempTablesStructure.Insert(TempTable.FullName, TempTable.GetData().Unload());
	EndDo;

	Return TempTablesStructure;
EndFunction

//https://infostart.ru/public/1207287/
Function ExecuteTwoValueTablesComparison(BaseTable, ComparisonTable, ListOfComparisonColumns) Export
	ColumsList = UT_StringFunctionsClientServer.SplitStringIntoSubstringsArray(ListOfComparisonColumns, ",", True);
	//The resulting table
	TempTable = New ValueTable;
	For Each Colum In ColumsList Do
		TempTable.Columns.Add(Colum);
		TempTable.Columns.Add(Colum + "Comparison");
	EndDo;
	TempTable.Columns.Add("NumberOfRow");
	TempTable.Columns.Add("NumberOfRow" + "Comparison");
	//---------
	ComparableTable = ComparisonTable.Copy();
	ComparableTable.Columns.Add("AlreadyUsing", New TypeDescription("Boolean"));

	For Each Row In BaseTable Do
		NewRow = TempTable.Add();
		FillPropertyValues(NewRow, Row);
		NewRow.NumberOfRow = Row.RowNumber;
		//forming a structure for searching by a given mapping
		SearchStringsFilter = New Structure("AlreadyUsing", False);
		For Each Colum In ColumsList Do
			SearchStringsFilter.Insert(Colum, Row[Colum]);
		EndDo;

		FindRows = ComparableTable.FindRows(SearchStringsFilter);
		If FindRows.Count() > 0 Then
			ComparisonString = FindRows[0];
			NewRow.NumberOfRowComparison = ComparisonString.RowNumber;
			For Each Colum In ColumsList Do
				Attribute = Colum + "Comparison";
				NewRow[Attribute] = ComparisonString[Colum];
			EndDo;
			ComparisonString.AlreadyUsing = True;
		EndIf;
	EndDo;
	//See what's left +++
	SearchStringFilter = New Structure("AlreadyUsing", False);
	FindRows = ComparableTable.FindRows(SearchStringFilter);
	For Each Row In FindRows Do
		NewRow = TempTable.Add();
		NewRow.NumberOfRowComparison = Row.RowNumber;
		For Each Colum In ColumsList Do
			Attribute = Colum + "Comparison";
			NewRow[Attribute] = Row[Colum];
		EndDo;
	EndDo;
	//We check what happened
	TablesIdentical = True;
	For Each Row In TempTable Do
		For Each Colum In ColumsList Do
			If (Not ValueIsFilled(Row[Colum])) Or (Not ValueIsFilled(Row[Colum + "Comparison"])) Then
				TablesIdentical = False;
				Break;
			EndIf;
		EndDo;
		If Not TablesIdentical Then
			Break;
		EndIf;
	EndDo;

	Return New Structure("IdenticalTables,DifferencesTable", TablesIdentical, TempTable);
EndFunction

#EndRegion


#Region SavingConsolesReadData

Function ConsolePreparedDataForFileWriting(ConsolesName, FileName, SaveDataDirectory,
	SavedFileDescriptionStructure) Export
	File = New File(FileName);

	If IsTempStorageURL(SaveDataDirectory) Then
		SaveData = GetFromTempStorage(SaveDataDirectory);
	Else
		SaveData = SaveDataDirectory;
	EndIf;

	ManagerConsoles = Undefined;

	If ManagerConsoles = Undefined Then
		If TypeOf(SaveData) = Type("String") Then
			NewSaveData = SaveData;
		Else
			NewSaveData = ValueToStringInternal(SaveData);
		EndIf;
	Else
		Try
			NewSaveData = ManagerConsoles.SerializedSaveData(File.Extension, SaveData);
		Except
			NewSaveData = ValueToStringInternal(SaveData);
		EndTry;
	EndIf;

	Stream = New MemoryStream;
	RecordText = New DataWriter(Stream);
	RecordText.WriteLine(NewSaveData);

	Return PutToTempStorage(Stream.CloseAndGetBinaryData());
	
// Return NewStorageData;	

EndFunction

#EndRegion

#EndRegion

#Region Internal

// Add information for support on the server.
// 
// Parameters:
//  InformationStructure - Structure - Information structure
Procedure AddInformationForSupportOnTheServer(InformationStructure) Export
	InformationStructure.Insert("Server", UT_CommonClientServer.DescriptionOSForTechnicalSupport());
	InformationStructure.Insert("IsFileBase", UT_Common.FileInfobase());
	InformationStructure.Insert("SSLVersion", UT_Common.SSLVersion());
	InformationStructure.Insert("Configuration", New Structure);
	InformationStructure.Configuration.Insert("Name", MetaData.Name);
	InformationStructure.Configuration.Insert("CompatibilityMode", String(MetaData.CompatibilityMode));
	InformationStructure.Configuration.Insert("Version", MetaData.Version);
	InformationStructure.Configuration.Insert("DefaultRunMode", String(MetaData.DefaultRunMode));
	InformationStructure.Configuration.Insert("ModalityUseMode", 
											  String(MetaData.ModalityUseMode));
	InformationStructure.Configuration.Insert("SynchronousExtensionAndAddInCallUseMode",
											  String(MetaData.SynchronousExtensionAndAddInCallUseMode));
	InformationStructure.Configuration.Insert("SynchronousPlatformExtensionAndAddInCallUseMode",
											  String(MetaData.SynchronousPlatformExtensionAndAddInCallUseMode));
	InformationStructure.Configuration.Insert("ModalityUseMode",
											  String(MetaData.ModalityUseMode));
	InformationStructure.Configuration.Insert("InterfaceCompatibilityMode",
											  String(MetaData.InterfaceCompatibilityMode));
	InformationStructure.Configuration.Insert("DataLockControlMode",
											  String(MetaData.DataLockControlMode));
	InformationStructure.Insert("Extensions", New Array);

	For Each CurrentExpansion In ConfigurationExtensions.Get() Do
		InformationStructure.Extensions.Add("" + CurrentExpansion.Name + "(" + CurrentExpansion.Version + ")");
	EndDo;
EndProcedure



#EndRegion