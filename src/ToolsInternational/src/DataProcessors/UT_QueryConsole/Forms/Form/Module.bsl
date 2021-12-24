// Query console 9000 v 1.1.11
// (C) Alexander Kuznetsov 2019-2020
// hal@hal9000.cc
// Minimum platform version 8.3.12, minimum compatibility mode 8.3.8
// Translated by Neti Company

&AtClient
Var ConsoleSignature;
&AtClient
Var FormatVersion;
&AtClient
Var FilesExtension;
&AtClient
Var SaveFilter;
&AtClient
Var AutoSaveExtension;
&AtClient
Var AutoSaveFileDeletedFlag;//used in LoadQueryBatchAfterQuestion
&AtClient
Var StateFileDeletedFlag;//used in LoadQueryBatchAfterQuestion

//Container types in QueryParameters: 0 - none, 1 - value list, 2 - array, 3 - value table.

&AtClient
Function GetAutoSaveFileName(FileName)
	File = New File(FileName);
	Return File.Path + File.BaseName + "." + AutoSaveExtension;
EndFunction

&AtClient
Function TimeFromSeconds(Seconds)
	TimeSecondsString = Format(Seconds % 60, "ND=2; NZ=; NLZ=");
	Minutes = Int(Seconds / 60);
	TimeMinutesString = Format(Minutes % 60, "ND=2; NZ=; NLZ=");
	Hours = Int(Minutes / 60);
	TimeHoursString = Format(Hours, "NZ=00; NG=");
	Return StrTemplate("%1:%2:%3", TimeHoursString, TimeMinutesString, TimeSecondsString);
EndFunction

&AtServer
Function SetDataProcessorToServer(Address)

	File = New File(Object.DataProcessorFileName);
	DataProcessorServerFileNameString = TempFilesDir() + File.BaseName + "_" + Object.DataProcessorVersion
		+ File.Extension;
	BinaryData = GetFromTempStorage(Address);
	BinaryData.Wrtite(DataProcessorServerFileNameString);

	Return DataProcessorServerFileNameString;

EndFunction

&AtClient
Function GetDataProcessorServerFileName()

	If ValueIsFilled(DataProcessorServerFileName) Then
		Return DataProcessorServerFileName;
	EndIf;

	Try

		If ValueIsFilled(Object.DataProcessorFileName) Then
			Address = "";
			BeginPutFile(New NotifyDescription("PutDataProcessorToServerContinue", ThisForm), Address,
				Object.DataProcessorFileName, False);
		EndIf;

	Except
	EndTry;

	Return Undefined;

EndFunction

&AtClient
Procedure AllowHooking()
	Items.QueryBatchHookingSubmenu.Enabled = True;
EndProcedure

&AtClient
Procedure AllowBackgroundExecution()
	Items.CodeExecutionMethod.ChoiceList.Add(3, NStr("ru = 'простое в фоне (БСП 2.3)'; en = 'simple in background (SSL 2.3)'"));
	Items.CodeExecutionMethod.ChoiceList.Add(4, NStr("ru = 'построчно в фоне с индикацией (БСП 2.3)'; en = 'line by line in background with indication (SSL 2.3)'"));
EndProcedure

&AtClient
Procedure PutDataProcessorToServerContinue(Result, Address, FileName, AdditionalParameters) Export

	DataProcessorServerFileName = SetDataProcessorToServer(Address);
	
	// Data processor is putting to server. You can hook the query and execute it in background.
	AllowHooking();
	AllowBackgroundExecution();

EndProcedure

&AtClient
Function FormFullName(FormName)
	Return StrTemplate("%1.Form.%2", Object.MetadataPath, FormName);
EndFunction

&AtClient
Procedure ShowConsoleMessageBox(MessageText) Export
	ShowMessageBox( , MessageText, , Object.Title);
EndProcedure

&AtClient
Function FindInTree(TreeItem, AttributeName, Value, ExceptionRowID = Undefined)

	For Each Item In TreeItem.GetItems() Do

		Row = FindInTree(Item, AttributeName, Value, ExceptionRowID);
		If Row <> Undefined Then
			Return Row;
		EndIf;

		If Item[AttributeName] = Value Then
			RowID = Item.GetID();
			If RowID <> ExceptionRowID Then
				Return RowID;
			EndIf;
		EndIf;

	EndDo;

	Return Undefined;

EndFunction

&AtServerNoContext
Function FormatDuration(DurationInMilliseconds)

	Return StrTemplate("%1.%2", Format('00010101' + Int((DurationInMilliseconds) / 1000), "DLF=T; DE=12:00:00 AM"),
		Format(DurationInMilliseconds - Int((DurationInMilliseconds) / 1000) * 1000, "ND=3; NZ=; NLZ="));

EndFunction

&AtServerNoContext
Function TypeDescriptionByType(Type)
	arTypes = New Array;
	arTypes.Add(Type);
	Return New TypeDescription(arTypes);
EndFunction

&AtClientAtServerNoContext
Function NameIsCorrect(VerifyingName)

	If Not ValueIsFilled(VerifyingName) Then
		Return False;
	EndIf;

	Try
		//@skip-warning
		st = New Structure(VerifyingName);
	Except
		Return False;
	EndTry;

	Return True;

EndFunction

&AtServerNoContext
Function GetValueFormCode(Val Value)

	ValueType = ТипЗнч(Value);
	If ValueType = Type("Array") Then
		Return 2;
	ElsIf ValueType = Type("ValueList") Then
		Return 1;
	ElsIf ValueType = Type("ValueTable") Then
		Return 3;
	EndIf;

	Return 0;

EndFunction

&AtServerNoContext
Procedure DisassembleQueryError(ErrorString, LineNumber, ColumnNumber)

	arParts = StrSplit(ErrorString, ":");
	arCoordinates = Undefined;
	If arParts.Count() > 2 Then
		ErrorCoordinatesString = TrimAll(arParts[2]);
		If arParts.Count() > 2 And StrLen(ErrorCoordinatesString) > 5 And Left(ErrorCoordinatesString, 2) = "{(" Then
			arCoordinates = StrSplit(Mid(ErrorCoordinatesString, 3, StrLen(ErrorCoordinatesString) - 4), ",");
			arParts[0] = "";
			arParts[1] = "";
		Else
			arParts[0] = "";
		EndIf;
	EndIf;

	Splitter = ": ";
	ErrorString = StrConcat(arParts, Splitter);
	While Left(ErrorString, StrLen(Splitter)) = Splitter Do
		ErrorString = Right(ErrorString, StrLen(ErrorString) - StrLen(Splitter));
	EndDo;

	LineNumber = Undefined;
	ColumnNumber = Undefined;
	If arCoordinates <> Undefined Then
		LineNumber = Number(arCoordinates[0]);
		ColumnNumber = Number(arCoordinates[1]);
	EndIf;

EndProcedure

// Specifies the error location in the query text when trying to execute it.
// Parameters:
//	ErrorString - String - error description string.
//	Query - Query - query with parameters.
//	OriginalQueryText - Original query text.
//	LineNumber - number of error location line.
//	ColumnNumber - number of error location column.
//
&AtServerNoContext
Procedure DisassembleSpecifiedQueryError(ErrorString, Query, OriginalQueryText, LineNumber, ColumnNumber)

	DisassembleQueryError(ErrorString, LineNumber, ColumnNumber);
	RealErrorString = ErrorString;
	RealLineNumber = LineNumber;
	RealColumnNumber = ColumnNumber;

	Query.Текст = OriginalQueryText;
	Try
		Query.FindParameters();
		Query.Execute();
	Except
		ErrorString = ErrorDescription();
	EndTry;

	DisassembleQueryError(ErrorString, LineNumber, ColumnNumber);

	arRealStringParts = StrSplit(RealErrorString, ":");
	arSpecifiedStringParts = StrSplit(ErrorString, ":");
	If arRealStringParts.Count() = arSpecifiedStringParts.Count() And arRealStringParts.Count() > 1
		And arRealStringParts[1] = arSpecifiedStringParts[1] Then
		 	// The error is reproduced on the original query, messages and locattion are correct.
		Return;
	EndIf;

	ErrorString = RealErrorString;
	LineNumber = RealLineNumber;
	ColumnNumber = RealColumnNumber;

EndProcedure

&AtServerNoContext
Function FormatQueryTextAtServer(QueryText)
	Var LineNumber, ColumnNumber;

	QuerySchema = New QuerySchema;

	Try
		QuerySchema.SetQueryText(QueryText);
	Except

		ErrorString = ErrorDescription();
		DisassembleQueryError(ErrorString, LineNumber, ColumnNumber);
		Return New Structure("ErrorDescription, Row, Column", ErrorString, LineNumber, ColumnNumber);

	EndTry;

	Return QuerySchema.GetQueryText();

EndFunction

&AtServerNoContext
Function GetFileListAtServerFromTempFilesDir(Mask)

	arQueryFiles = FindFiles(TempFilesDir(), Mask);

	arFileNames = New Array;
	For Each File In arQueryFiles Do
		arFileNames.Add(File.FullName);
	EndDo;

	Return arFileNames;

EndFunction

&AtServerNoContext
Procedure DeleteFilesAtServer(arFiles)
	For Each FileName In arFiles Do
		DeleteFiles(FileName);
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Function ValueChoiceButtonEnabled(Value)

	arNoChoiceButtonTypes = New Array;
	arNoChoiceButtonTypes.Add(Type("String"));
	arNoChoiceButtonTypes.Add(Type("Number"));
	arNoChoiceButtonTypes.Add(Type("Boolean"));
	arNoChoiceButtonTypes.Add(Type("AccumulationRecordType"));
	arNoChoiceButtonTypes.Add(Type("AccountingRecordType"));
	arNoChoiceButtonTypes.Add(Type("AccountType"));
	NoChoiceButtonTypes = New TypeDescription(arNoChoiceButtonTypes);

	Return Not NoChoiceButtonTypes.ContainsType(TypeOf(Value));

EndFunction

&AtServerNoContext
Function GetErrorInfoPresentation(ErrorInfo)

	If ValueIsFilled(ErrorInfo.ModuleName) And ValueIsFilled(ErrorInfo.LineNumber) Then
		ErrorInfoPresentation = ErrorInfo.ModuleName + StrTemplate(NStr("ru = ' строка %1'; en = ' line %1'"),
			ErrorInfo.LineNumber) + "
									|";
	ElsIf ValueIsFilled(ErrorInfo.LineNumber) Then
		ErrorInfoPresentation = StrTemplate(NStr("ru = 'Строка %1'; en = 'Line %1'"), ErrorInfo.LineNumber) + "
																								   			  |";
	Else
		ErrorInfoPresentation = "";
	EndIf;

	ErrorInfoPresentation = ErrorInfoPresentation + ErrorInfo.Description + ":
																			|"
		+ ErrorInfo.SourceLine;

	If ErrorInfo.Cause <> Undefined Then
		ErrorInfoPresentation = ErrorInfoPresentation + "
														|"
			+ GetErrorInfoPresentation(ErrorInfo.Cause);
	EndIf;

	Return ErrorInfoPresentation;

EndFunction

&AtServer
Function QueryParametersFormOnChangeVLFromVT(Container)

	DataProcessor = FormAttributeToValue("Object");

	vtTable = DataProcessor.Container_RestoreValue(Container);
	vlList = New ValueList;
	If vtTable.Columns.Count() > 0 Then
		vlList.LoadValues(vtTable.UnloadColumn(0));
	EndIf;

	Return DataProcessor.Container_SaveValue(vlList);

EndFunction

&AtServerNoContext
Function PointInTimeSearchSubqueryText(MetadataName, RegisterName, ColumnName, TempTableName,
	TextINTO)
	Return StrTemplate(
		"SELECT
		|	%1%2.Period AS Date,
		|	%1%2.Recorder AS Ref,
		|	%1%2.PointInTime AS PointInTime %4
		|FROM
		|	%1.%2 AS %1%2 INNER JOIN %5_PointsData_%3 ON %1%2.Recorder = %5_PointsData_%3.Ref AND %1%2.Period = %5_PointsData_%3.Date
		|", MetadataName, RegisterName, ColumnName, TextINTO, TempTableName);

EndFunction

&AtServer
Procedure ПодготовитьВыборкуКолонокСТипомМоментВремени(тзДанные, ИмяПромежуточнойТаблицы, стНовыеВыраженияПолей,
	ДополнительныеИсточники, ДополнительныеЗапросы)
	
	//Обработка = РеквизитФормыВЗначение("Объект");

	маИменаКолонокМоментов = New Array;
	//маИменаТаблицМоментовПоля = New Array;
	маИменаКолонокДата = New Array;
	маИменаКолонокСсылка = New Array;
	маЗапросыДляПоискаМоментов = New Array;

	For Each Колонка Из тзДанные.Колонки Do

		If Колонка.ТипЗначения.СодержитТип(Тип("МоментВремени")) Then

			ИмяКолонки = Колонка.Имя;
			ИмяКолонкиДата = ИмяКолонки + "_Дата31415926";
			ИмяКолонкиСсылка = ИмяКолонки + "_Ссылка31415926";
			ИмяКолонкиВременной = ИмяКолонки + "_Вр31415926";

			маИменаКолонокМоментов.Добавить(ИмяКолонки);
			маИменаКолонокДата.Добавить(ИмяКолонкиДата);
			маИменаКолонокСсылка.Добавить(ИмяКолонкиСсылка);

			маВычитаемыеТипы = New Array;
			маВычитаемыеТипы.Добавить(Тип("МоментВремени"));
			маДобавляемыеТипы = New Array;
			маДобавляемыеТипы.Добавить(Тип("Null"));
			ТипБезТипаМомент = New ОписаниеТипов(Колонка.ТипЗначения, маДобавляемыеТипы, маВычитаемыеТипы);
			ТолькоМомент = ТипБезТипаМомент = New ОписаниеТипов("Null");//Значит, что в колонке был только момент времени.
			                                                               //Вообще, так должно быть всегда. Не представляю ситуации, когда в колонке с моментом времени может быть что-то еще.

			тзДанные.Колонки.Добавить(ИмяКолонкиДата, New ОписаниеТипов("Дата", , ,
				New КвалификаторыДаты(ЧастиДаты.ДатаВремя)));
			тзДанные.Колонки.Добавить(ИмяКолонкиСсылка, Документы.ТипВсеСсылки());

			If Не ТолькоМомент Then
				тзДанные.Колонки.Добавить(ИмяКолонкиВременной, ТипБезТипаМомент);
			EndIf;

			маТипыСсылокМоментов = New Array;

			If ТолькоМомент Then

				For Each СтрокаДанных Из тзДанные Do
					Значение = СтрокаДанных[ИмяКолонки];
					СтрокаДанных[ИмяКолонкиДата] = Значение.Дата;
					СтрокаДанных[ИмяКолонкиСсылка] = Значение.Ссылка;
					маТипыСсылокМоментов.Добавить(ТипЗнч(Значение.Ссылка));
				EndDo;

			Иначе

				For Each СтрокаДанных Из тзДанные Do
					Значение = СтрокаДанных[ИмяКолонки];
					If ТипЗнч(Значение) = Тип("МоментВремени") Then
						СтрокаДанных[ИмяКолонкиВременной] = Null;
						СтрокаДанных[ИмяКолонкиДата] = Значение.Дата;
						СтрокаДанных[ИмяКолонкиСсылка] = Значение.Ссылка;
						маТипыСсылокМоментов.Добавить(ТипЗнч(Значение.Ссылка));
					Иначе
						СтрокаДанных[ИмяКолонкиВременной] = Значение;
					EndIf;
				EndDo;

			EndIf;

			тзДанные.Колонки.Удалить(ИмяКолонки);
			If Не ТолькоМомент Then
				тзДанные.Колонки[ИмяКолонкиВременной].Имя = ИмяКолонки;
			EndIf;

			ИмяТаблицыМоментовПоля = ИмяПромежуточнойТаблицы + "_ТаблицаМоментов_" + ИмяКолонки;
			ТекстПоместить = "ПОМЕСТИТЬ " + ИмяТаблицыМоментовПоля;

			If ТолькоМомент Then
				стНовыеВыраженияПолей.Вставить(ИмяКолонки, StrTemplate("%1.МоментВремени КАК %2", ИмяТаблицыМоментовПоля,
					ИмяКолонки));
			Иначе
				стНовыеВыраженияПолей.Вставить(ИмяКолонки, StrTemplate("ISNULL(Таблица.%1, %2.МоментВремени) КАК %3",
					ИмяКолонки, ИмяТаблицыМоментовПоля, ИмяКолонки));
			EndIf;

			ДополнительныеИсточники = ДополнительныеИсточники + StrTemplate(
				" ЛЕВОЕ СОЕДИНЕНИЕ %1 КАК %1 ПО Таблица.%2 = %1.Дата И Таблица.%3 = %1.Ссылка", ИмяТаблицыМоментовПоля,
				ИмяКолонкиДата, ИмяКолонкиСсылка);

			маПодЗапросыДляПоискаМоментов = New Array;

			маМетаданныеДляПоискаМомента = New Array;
			маМетаданныеДляПоискаМомента.Добавить(Метаданные.РегистрыНакопления);
			маМетаданныеДляПоискаМомента.Добавить(Метаданные.РегистрыБухгалтерии);

			ТипыСсылокМоментов = New ОписаниеТипов(маТипыСсылокМоментов);
			маТипыСсылокМоментов = ТипыСсылокМоментов.Типы();

			For Each Регистры Из маМетаданныеДляПоискаМомента Do

				If Регистры = Метаданные.РегистрыНакопления Then
					ИмяМетаданныхДляЗапроса = "РегистрНакопления";
				ElsIf Регистры = Метаданные.РегистрыБухгалтерии Then
					ИмяМетаданныхДляЗапроса = "РегистрБухгалтерии";
				Иначе
					ИмяМетаданныхДляЗапроса = "?E001?";
				EndIf;

				For Each Регистр Из Регистры Do

					ТипРегистратора = Регистр.СтандартныеРеквизиты.Регистратор.Тип;
					For Each ТипСсылки Из маТипыСсылокМоментов Do

						If ТипРегистратора.СодержитТип(ТипСсылки) Then

							маПодЗапросыДляПоискаМоментов.Добавить(PointInTimeSearchSubqueryText(
								ИмяМетаданныхДляЗапроса, Регистр.Имя, ИмяКолонки, ИмяПромежуточнойТаблицы,
								ТекстПоместить));
							ТекстПоместить = "";
							Прервать;

						EndIf;

					EndDo;

				EndDo;

			EndDo;

			If маПодЗапросыДляПоискаМоментов.Количество() = 0 Then
				маПодЗапросыДляПоискаМоментов.Добавить(PointInTimeSearchSubqueryText(
					ИмяМетаданныхДляЗапроса, Регистр.Имя, ИмяКолонки, ИмяПромежуточнойТаблицы, ТекстПоместить));
			EndIf;

			ТекстЗапросаПоискаМоментов = StrConcat(маПодЗапросыДляПоискаМоментов, "
																					 |ОБЪЕДИНИТЬ
																					 |");

			If ValueIsFilled(ТекстЗапросаПоискаМоментов) Then
				маЗапросыДляПоискаМоментов.Добавить(ТекстЗапросаПоискаМоментов);
			EndIf;

		EndIf;

	EndDo;

	If маИменаКолонокДата.Количество() > 0 Then

		ТекстыЗапросовПоискаМоментов = StrConcat(маЗапросыДляПоискаМоментов, ";
																				|");

		маЗапросыДанныхМоментов = New Array;

		Для й = 0 По маИменаКолонокДата.ВГраница() Do
			маЗапросыДанныхМоментов.Добавить(StrTemplate(
				"ВЫБРАТЬ
				|	Таблица.%1 КАК Дата,
				|	Таблица.%2 КАК Ссылка
				|ПОМЕСТИТЬ %4_ДанныеМоментов_%3
				|ИЗ
				|	%4 КАК Таблица", маИменаКолонокДата[й], маИменаКолонокСсылка[й], маИменаКолонокМоментов[й],
				ИмяПромежуточнойТаблицы));
		EndDo;

		ТекстЗапросаДанныхМоментов = StrConcat(маЗапросыДанныхМоментов, ";
																		   |
																		   |");

		ДополнительныеЗапросы = ТекстЗапросаДанныхМоментов + "; 
															 |
															 |" + ТекстыЗапросовПоискаМоментов;

	EndIf;

EndProcedure

&AtServer
Procedure ПодготовитьВыборкуКолонокСТипомТип(тзДанные, ИмяПромежуточнойТаблицы, стНовыеВыраженияПолей,
	ДополнительныеИсточники, ДополнительныеЗапросы)

	Обработка = РеквизитФормыВЗначение("Object");

	For Each Колонка Из тзДанные.Колонки Do

		If Колонка.ТипЗначения.СодержитТип(Тип("Тип")) Then

			ИмяКолонки = Колонка.Имя;
			ИмяКолонкиТип = ИмяКолонки + "_Тип31415926";
			ИмяКолонкиВременной = ИмяКолонки + "_Вр31415926";

			маВычитаемыеТипы = New Array;
			маВычитаемыеТипы.Добавить(Тип("Тип"));
			маДобавляемыеТипы = New Array;
			маДобавляемыеТипы.Добавить(Тип("Null"));
			ТипБезТипаТип = New ОписаниеТипов(Колонка.ТипЗначения, маДобавляемыеТипы, маВычитаемыеТипы);
			ТолькоТип = ТипБезТипаТип = New ОписаниеТипов("Null");//Значит, что в колонке был только тип.
			                                                         //Вообще, так должно быть всегда. Не представляю ситуации, когда в колонке с типом может быть что-то еще.

			тзДанные.Колонки.Добавить(ИмяКолонкиТип);
			If Не ТолькоТип Then
				тзДанные.Колонки.Добавить(ИмяКолонкиВременной, ТипБезТипаТип);
			EndIf;

			маТипы = New Array;

			If ТолькоТип Then

				For Each СтрокаДанных Из тзДанные Do
					маТипы.Добавить(СтрокаДанных[ИмяКолонки]);
					ОписаниеТипа = TypeDescriptionByType(СтрокаДанных[ИмяКолонки]);
					Значение = ОписаниеТипа.ПривестиЗначение(Undefined);
					СтрокаДанных[ИмяКолонкиТип] = Значение;
				EndDo;

			Иначе

				For Each СтрокаДанных Из тзДанные Do
					If ТипЗнч(СтрокаДанных[ИмяКолонки]) = Тип("Тип") Then
						маТипы.Добавить(СтрокаДанных[ИмяКолонки]);
						ОписаниеТипа = TypeDescriptionByType(СтрокаДанных[ИмяКолонки]);
						Значение = ОписаниеТипа.ПривестиЗначение(Undefined);
						СтрокаДанных[ИмяКолонкиТип] = Значение;
						СтрокаДанных[ИмяКолонкиВременной] = Null;
					Иначе
						СтрокаДанных[ИмяКолонкиВременной] = СтрокаДанных[ИмяКолонки];
					EndIf;
				EndDo;

			EndIf;

			тзДанные.Колонки.Удалить(ИмяКолонки);
			If Не ТолькоТип Then
				тзДанные.Колонки[ИмяКолонкиВременной].Имя = ИмяКолонки;
			EndIf;

			ТипКолонкиТипа = New ОписаниеТипов(маТипы);
			Обработка.ChangeValueTableColumnType(тзДанные, ИмяКолонкиТип, ТипКолонкиТипа);
			
			//стВыраженияПолей.Вставить(стВыраженияПолей

			If ТолькоТип Then
				стНовыеВыраженияПолей.Вставить(ИмяКолонки, "ТИПЗНАЧЕНИЯ(Таблица." + ИмяКолонкиТип + ") КАК "
					+ ИмяКолонки);
			Иначе
				стНовыеВыраженияПолей.Вставить(ИмяКолонки, "ISNULL(Таблица." + ИмяКолонки + ", ТИПЗНАЧЕНИЯ(Таблица."
					+ ИмяКолонкиТип + ")) КАК " + ИмяКолонки);
			EndIf;

		EndIf;

	EndDo;

EndProcedure

&AtServer
Procedure УстановитьТипКолонокБезТипа(тзДанные)

	Обработка = РеквизитФормыВЗначение("Object");
	ПустойТип = New ОписаниеТипов;
	маНеЗначащиеТипы = New Array;
	маНеЗначащиеТипы.Добавить("Undefined");
	маНеЗначащиеТипы.Добавить("Null");

	маОбрабатываемыеКолонки = New Array;
	маТипыКолонок = New Array;
	For Each Колонка Из тзДанные.Колонки Do
		//маТипы = Колонка.ТипЗначения.Типы();
		If Колонка.ТипЗначения = ПустойТип Then
			маОбрабатываемыеКолонки.Добавить(Колонка.Имя);
			маТипыКолонок.Добавить(New Array);
		EndIf;
	EndDo;

	If маОбрабатываемыеКолонки.Количество() > 0 Then

		For Each Строка Из тзДанные Do
			Для й = 0 По маОбрабатываемыеКолонки.Количество() - 1 Do
				ИмяКолонки = маОбрабатываемыеКолонки[й];
				маТипыКолонок[й].Добавить(ТипЗнч(Строка[ИмяКолонки]));
			EndDo;
		EndDo;

		Для й = 0 По маОбрабатываемыеКолонки.Количество() - 1 Do

			ИмяКолонки = маОбрабатываемыеКолонки[й];
			//ИмяВременнойКолонки = ИмяКолонки + "_Вр31415926";

			СтарыйТипЗначения = тзДанные.Колонки[ИмяКолонки].ТипЗначения;
			NewТипКолонки = New ОписаниеТипов(маТипыКолонок[й], СтарыйТипЗначения.КвалификаторыЧисла,
				СтарыйТипЗначения.КвалификаторыСтроки, СтарыйТипЗначения.КвалификаторыДаты,
				СтарыйТипЗначения.КвалификаторыДвоичныхДанных);

			ЗначимыеТипы = New ОписаниеТипов(NewТипКолонки, , маНеЗначащиеТипы);
			If ЗначимыеТипы = ПустойТип Then
				NewТипКолонки = New ОписаниеТипов(NewТипКолонки, "Число");//нужно поставить хоть какой-то тип, иначе в запросе не загрузить...
				//Сообщить(Строка(ИмяКолонки) + " - тип колонки не определен, установлено число.");//отладка
			EndIf;

			Обработка.ChangeValueTableColumnType(тзДанные, ИмяКолонки, NewТипКолонки);

		EndDo;

	EndIf;

EndProcedure

&AtServer
Procedure ЗагрузитьВременнуюТаблицу(ИмяТаблицы, тзДанные, маЗапросыЗагрузки, ЗапросЗагрузкиТаблиц)

	УстановитьТипКолонокБезТипа(тзДанные);

	маПоляТаблицы = New Array;
	For Each Колонка Из тзДанные.Колонки Do
		маПоляТаблицы.Добавить(Колонка.Имя);
	EndDo;

	стНовыеВыраженияПолей = New Structure;
	ДополнительныеИсточники = "";
	ДополнительныеЗапросы = "";
	ИмяПромежуточнойТаблицы = ИмяТаблицы + "_Вр31415926";
	ПодготовитьВыборкуКолонокСТипомТип(тзДанные, ИмяПромежуточнойТаблицы, стНовыеВыраженияПолей,
		ДополнительныеИсточники, ДополнительныеЗапросы);
	ПодготовитьВыборкуКолонокСТипомМоментВремени(тзДанные, ИмяПромежуточнойТаблицы, стНовыеВыраженияПолей,
		ДополнительныеИсточники, ДополнительныеЗапросы);
	If стНовыеВыраженияПолей.Количество() > 0 Then

		маВыраженияПолей = New Array;
		For Each Колонка Из тзДанные.Колонки Do
			Выражение = "Таблица." + Колонка.Имя + " КАК " + Колонка.Имя;
			маВыраженияПолей.Добавить(Выражение);
		EndDo;
		ВыраженияПолей = StrConcat(маВыраженияПолей, ",
														|");

		маЗапросыЗагрузки.Добавить("
								   |ВЫБРАТЬ
								   |" + ВыраженияПолей + "
														 |ПОМЕСТИТЬ " + ИмяПромежуточнойТаблицы + "
																								  |ИЗ &" + ИмяТаблицы
			+ " КАК Таблица");

		If ValueIsFilled(ДополнительныеЗапросы) Then
			маЗапросыЗагрузки.Добавить(ДополнительныеЗапросы);
		EndIf;

		Источник = ИмяПромежуточнойТаблицы;

	Иначе
		Источник = "&" + ИмяТаблицы;
	EndIf;

	Выражение = Undefined;
	маВыраженияПолей = New Array;
	For Each ИмяКолонки Из маПоляТаблицы Do
		If Не стНовыеВыраженияПолей.Свойство(ИмяКолонки, Выражение) Then
			Выражение = "Таблица." + ИмяКолонки + " КАК " + ИмяКолонки;
		EndIf;
		маВыраженияПолей.Добавить(Выражение);
	EndDo;
	ВыраженияПолей = StrConcat(маВыраженияПолей, ",
													|");

	маЗапросыЗагрузки.Добавить("
							   |ВЫБРАТЬ
							   |" + ВыраженияПолей + "
													 |ПОМЕСТИТЬ " + ИмяТаблицы + "
																				 |ИЗ " + Источник + " КАК Таблица"
		+ " " + ДополнительныеИсточники);

	ЗапросЗагрузкиТаблиц.УстановитьПараметр(ИмяТаблицы, тзДанные);

EndProcedure

&AtServer
Function ЗагрузитьВременныеТаблицы()

	If TempTables.Количество() = 0 Then
		Return New МенеджерВременныхТаблиц;
	EndIf;

	ЗапросЗагрузкиТаблиц = New Запрос;
	ЗапросЗагрузкиТаблиц.МенеджерВременныхТаблиц = New МенеджерВременныхТаблиц;

	маЗапросыЗагрузки = New Array;
	For Each СтрокаВременнаяТаблица Из TempTables Do

		ИмяТаблицы = СтрокаВременнаяТаблица.Name;
		тзДанные = РеквизитФормыВЗначение("Object").Container_RestoreValue(СтрокаВременнаяТаблица.Контейнер);
		ЗагрузитьВременнуюТаблицу(ИмяТаблицы, тзДанные, маЗапросыЗагрузки, ЗапросЗагрузкиТаблиц);

	EndDo;

	ЗапросЗагрузкиТаблиц.Текст = StrConcat(маЗапросыЗагрузки, ";
																 |");

	ЗапросЗагрузкиТаблиц.Выполнить();

	Return ЗапросЗагрузкиТаблиц.МенеджерВременныхТаблиц;

EndFunction

&AtServer
Procedure ВыборкуВДерево(выбВыборка, Узел, й, фЕстьКонтейнеры, Обработка, фЕстьМакроколонки, стМакроколонки)

	ЭлементыУзла = Узел.ПолучитьЭлементы();

	Пока выбВыборка.Следующий() Do

		й = й + 1;

		If OutputLinesLimit > 0 И й > OutputLinesLimit Then
			Прервать;
		EndIf;

		РезультатЗапросаСтрока = ЭлементыУзла.Добавить();
		ЗаполнитьЗначенияСвойств(РезультатЗапросаСтрока, выбВыборка);

		If фЕстьКонтейнеры Then
			Обработка.AddContainers(РезультатЗапросаСтрока, выбВыборка, QueryResultContainerColumns);
		EndIf;

		If фЕстьМакроколонки Then
			Обработка.ProcessMacrocolumns(РезультатЗапросаСтрока, выбВыборка, стМакроколонки);
		EndIf;

		выбПодчиненные = выбВыборка.Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);
		If выбПодчиненные.Количество() > 0 Then
			ВыборкуВДерево(выбПодчиненные, РезультатЗапросаСтрока, й, фЕстьКонтейнеры, Обработка, фЕстьМакроколонки,
				стМакроколонки);
		EndIf;

	EndDo;

EndProcedure

&AtServer
Function ИзвлечьРезультатКакТаблицуЗначений()

	Обработка = РеквизитФормыВЗначение("Object");

	стРезультатЗапроса = ПолучитьИзВременногоХранилища(QueryResultAddress);
	маРезультатЗапроса = стРезультатЗапроса.Результат;
	стРезультатПакета = маРезультатЗапроса[Число(ResultInBatch) - 1];
	рзВыборка = стРезультатПакета.Результат;
	стМакроколонки = стРезультатПакета.Макроколонки;
	фЕстьМакроколонки = стМакроколонки.Количество() > 0;

	If фЕстьМакроколонки Then

		тзРезультат = New ТаблицаЗначений;

		For Each Колонка Из рзВыборка.Колонки Do
			тзРезультат.Колонки.Добавить(Колонка.Имя, Колонка.ТипЗначения);
		EndDo;

		выбВыборка = рзВыборка.Выбрать();
		Пока выбВыборка.Следующий() Do
			Строка = тзРезультат.Добавить();
			ЗаполнитьЗначенияСвойств(Строка, выбВыборка);
			Обработка.ProcessMacrocolumns(Строка, выбВыборка, стМакроколонки);
		EndDo;

	Иначе
		тзРезультат = рзВыборка.Выгрузить();
	EndIf;

	Return тзРезультат;

EndFunction

&AtServer
Function ИзвлечьРезультатКакКонтейнер(фУдалитьТипNull = True)

	Обработка = РеквизитФормыВЗначение("Object");

	тз = ИзвлечьРезультатКакТаблицуЗначений();
	Обработка.ValueTable_DeleteNullType(тз);

	Return Обработка.Container_SaveValue(тз);

EndFunction

&AtServer
Procedure StructureЗаписиРезультата_РаскрытьПодчиненныеУзлы(Строка)
	Var Картинки;

	Обработка = РеквизитФормыВЗначение("Object");

	СтрокаДерева = StructureЗаписиРезультата.НайтиПоИдентификатору(Строка);

	For Each ЭлементСтруктуры Из СтрокаДерева.ПолучитьЭлементы() Do

		If ТипЗнч(ЭлементСтруктуры.Тип) = Тип("ОписаниеТипов") Then

			соСчетчики = New Соответствие;
			соТипы = New Соответствие;

			ТипыБезПустых = Обработка.NoEmptyType(ЭлементСтруктуры.Тип);
			маТипы = ТипыБезПустых.Типы();
			For Each Тип Из маТипы Do

				МетаданныеЭлемента = Undefined;
				If Справочники.ТипВсеСсылки().СодержитТип(Тип) Или Документы.ТипВсеСсылки().СодержитТип(Тип)
					Или ПланыВидовХарактеристик.ТипВсеСсылки().СодержитТип(Тип)
					Или ПланыСчетов.ТипВсеСсылки().СодержитТип(Тип) Или ПланыВидовРасчета.ТипВсеСсылки().СодержитТип(Тип)
					Или БизнесПроцессы.ТипВсеСсылки().СодержитТип(Тип) Или Задачи.ТипВсеСсылки().СодержитТип(Тип)
					Или ПланыОбмена.ТипВсеСсылки().СодержитТип(Тип) Then
					МетаданныеЭлемента = TypeDescriptionByType(Тип).ПривестиЗначение(Undefined).Метаданные();
				EndIf;

				If МетаданныеЭлемента <> Undefined Then

					маКоллекцииРеквизитов = New Array;
					маКоллекцииРеквизитов.Добавить(МетаданныеЭлемента.СтандартныеРеквизиты);
					маКоллекцииРеквизитов.Добавить(МетаданныеЭлемента.Реквизиты);

					For Each КоллекцияРеквизитов Из маКоллекцииРеквизитов Do
						For Each Реквизит Из КоллекцияРеквизитов Do

							К = соСчетчики[Реквизит.Имя];
							К = ?(К = Undefined, 0, К);
							соСчетчики[Реквизит.Имя] = К + 1;

							Типы = соТипы[Реквизит.Имя];
							If Типы = Undefined Then
								Типы = New Array;
							EndIf;

							For Each Тип Из Реквизит.Тип.Типы() Do
								Типы.Добавить(Тип);
							EndDo;

							соТипы[Реквизит.Имя] = Типы;

						EndDo;
					EndDo;

				EndIf;

			EndDo;

			For Each кз Из соСчетчики Do

				If кз.Значение = маТипы.Количество() Then//Добавляем только те реквизиты, которые есть во всех типах составного типа.

					стрИмя = кз.Ключ;
					маТипы = соТипы[стрИмя];
					NewЭлементСтруктуры = ЭлементСтруктуры.ПолучитьЭлементы().Добавить();
					NewЭлементСтруктуры.Имя = стрИмя;
					NewЭлементСтруктуры.Тип = New ОписаниеТипов(маТипы);

					NewЭлементСтруктуры.Картинка = Обработка.GetPictureByType(NewЭлементСтруктуры.Тип,
						Картинки);

				EndIf;

			EndDo;

		EndIf;

	EndDo;

	СтрокаДерева.ПодчиненныеУзлыРаскрыты = True;

EndProcedure

&AtClient
Procedure StructureЗаписиРезультата_Развернуть()
	ЭлементыДерева = StructureЗаписиРезультата.ПолучитьЭлементы();
	Элементы.StructureЗаписиРезультата.Развернуть(ЭлементыДерева[0].ПолучитьИдентификатор());
	Элементы.StructureЗаписиРезультата.Развернуть(ЭлементыДерева[1].ПолучитьИдентификатор());
	
	#Region УИ_ПослеОбновленияСтруктурыЗаписиРезультата
	
	УИ_ДобавитьКонтекстСтруктурыРезультатаАлгоритм();
	#EndRegion
EndProcedure

&AtServer
//Заполняет структуру записи, используемую на странице выполнения кода.
Procedure StructureЗаписиРезультата_ЗаполнитьСтруктуруЗаписи(рзВыборка = Undefined)
	Var Картинки;

	StructureЗаписиРезультата.ПолучитьЭлементы().Очистить();

	If рзВыборка = Undefined Then
		Return;
	EndIf;

	Обработка = РеквизитФормыВЗначение("Object");
	
	//Свойства в выборке раскрывать не нужно. Все необходимое нужно выбирать в запросе.
	фРаскрыватьСвойстваВВыборке = False;
	
	//А в параметрах раскроем, это не так страшно.
	фРаскрыватьСвойстваВПараметрах = True;

	ЭлементСтруктурыВыборка = StructureЗаписиРезультата.ПолучитьЭлементы().Добавить();
	ЭлементСтруктурыВыборка.Имя = "Выборка";
	ЭлементСтруктурыВыборка.ПодчиненныеУзлыРаскрыты = Не фРаскрыватьСвойстваВВыборке;

	For Each Колонка Из рзВыборка.Колонки Do
		ЭлементСтруктуры = ЭлементСтруктурыВыборка.ПолучитьЭлементы().Добавить();
		ЭлементСтруктуры.Имя = Колонка.Имя;
		ЭлементСтруктуры.Тип = Колонка.ТипЗначения;
		ЭлементСтруктуры.Картинка = Обработка.GetPictureByType(Обработка.NoEmptyType(Колонка.ТипЗначения),
			Картинки);
		ЭлементСтруктуры.ПодчиненныеУзлыРаскрыты = Не фРаскрыватьСвойстваВВыборке;
	EndDo;

	ЭлементСтруктурыПараметры = StructureЗаписиРезультата.ПолучитьЭлементы().Добавить();
	ЭлементСтруктурыПараметры.Имя = "Параметры";
	ЭлементСтруктурыПараметры.ПодчиненныеУзлыРаскрыты = Не фРаскрыватьСвойстваВПараметрах;

	For Each СтрокаПараметра Из QueryParameters Do

		ЭлементСтруктуры = ЭлементСтруктурыПараметры.ПолучитьЭлементы().Добавить();
		ЭлементСтруктуры.Имя = СтрокаПараметра.Name;

		If СтрокаПараметра.ContainerType = 1 Then
			ТипЗначения = New ОписаниеТипов("СписокЗначений");
		ElsIf СтрокаПараметра.ContainerType = 2 Then
			ТипЗначения = New ОписаниеТипов("Array");
		Иначе
			ТипЗначения = СтрокаПараметра.ValueType;
		EndIf;

		ЭлементСтруктуры.Тип = ТипЗначения;
		ЭлементСтруктуры.Картинка = Обработка.GetPictureByType(Обработка.NoEmptyType(ТипЗначения), Картинки);
		ЭлементСтруктуры.ПодчиненныеУзлыРаскрыты = Не фРаскрыватьСвойстваВПараметрах;

	EndDo;

EndProcedure

&AtServer
Function ИзвлечьРезультат(чРезультат = Undefined)

	If чРезультат = ResultInForm Then
		Return 0;
	EndIf;

	If чРезультат <> Undefined Then
		ResultInForm = чРезультат;
	EndIf;

	КоличествоЗаписейРезультата = ИзвлечьРезультатВДанныеФормы(ResultInForm);

	ResultInBatch = ResultInForm;

	Элементы.QueryResultBatch.ТекущаяСтрока = QueryResultBatch[ResultInForm - 1].ПолучитьИдентификатор();

	For Each Строка Из QueryResultBatch Do
		Строка.Current = False;
	EndDo;
	QueryResultBatch[ResultInForm - 1].Current = True;

	Return КоличествоЗаписейРезультата;

EndFunction

&AtServer
Function ИзвлечьРезультатВДанныеФормы(РезультатВПакете)

	Обработка = РеквизитФормыВЗначение("Object");

	фДерево = ResultKind = "дерево";
	If фДерево Then
		ИмяРеквизитаРезультата = "РезультатЗапросаДерево";
	Иначе
		ИмяРеквизитаРезультата = "РезультатЗапроса";
	EndIf;

	Элементы.RefreshResult.Доступность = True;
	Элементы.QueryResult.Видимость = Не фДерево;
	Элементы.ResultCommandBar.Видимость = Не фДерево;
	Элементы.ResultCommandBar.Доступность = Не фДерево;
	Элементы.QueryResultTree.Видимость = фДерево;
	Элементы.ResultCommandBarTree.Видимость = фДерево;
	Элементы.ResultCommandBarTreeLeft.Видимость = фДерево;

	If Не ValueIsFilled(QueryResultAddress) Then
		StructureЗаписиРезультата_ЗаполнитьСтруктуруЗаписи();
		Return 0;
	EndIf;

	If Число(РезультатВПакете) <= 0 Then
		РеквизитФормыВЗначение("Object").CreateTableAttributesByColumns(ЭтаФорма, ИмяРеквизитаРезультата,
			"QueryResultColumnsMap", "QueryResultContainerColumns", Undefined);
		StructureЗаписиРезультата_ЗаполнитьСтруктуруЗаписи();
		Return 0;
	EndIf;

	Элементы.QueryResultControlGroup.Доступность = True;

	стРезультатЗапроса = ПолучитьИзВременногоХранилища(QueryResultAddress);
	маРезультатЗапроса = стРезультатЗапроса.Результат;
	стРезультат = маРезультатЗапроса[Число(РезультатВПакете) - 1];
	рзВыборка = стРезультат.Результат;
	стМакроколонки = стРезультат.Макроколонки;
	ЕстьМакроколонки = стМакроколонки.Количество() > 0;

	QueryResult.Очистить();
	QueryResultTree.ПолучитьЭлементы().Очистить();
	Обработка.CreateTableAttributesByColumns(ЭтаФорма, ИмяРеквизитаРезультата,
		"QueryResultColumnsMap", "QueryResultContainerColumns", ?(рзВыборка = Undefined,
		Undefined, рзВыборка.Колонки), False, стМакроколонки);

	If рзВыборка = Undefined Then
		StructureЗаписиРезультата_ЗаполнитьСтруктуруЗаписи();
		Return 0;
	EndIf;

	маСписокКолонок = New Array;
	For Each кзКолонка Из QueryResultColumnsMap Do
		маСписокКолонок.Добавить(кзКолонка.Значение);
	EndDo;
	СписокКолонокСтрокой = StrConcat(маСписокКолонок, ",");

	ЕстьКонтейнеры = QueryResultContainerColumns.Количество() > 0;
	If Не ЕстьМакроколонки И Не ЕстьКонтейнеры И (Не OutputLinesLimitEnabled Или OutputLinesLimit = 0) Then

		If фДерево Then

			тзРезультат = рзВыборка.Выгрузить(ОбходРезультатаЗапроса.ПоГруппировкам);
			ЗначениеВДанныеФормы(тзРезультат, QueryResultTree);
			ResultReturningRowsCount = рзВыборка.Выбрать().КОличество();

		Иначе

			тзРезультат = рзВыборка.Выгрузить();
			ЗначениеВДанныеФормы(тзРезультат, QueryResult);

			ResultReturningRowsCount = тзРезультат.Количество();

			If тзРезультат.Количество() > 0 Then
				тзРезультат.Свернуть("", СписокКолонокСтрокой);
				ЗаполнитьЗначенияСвойств(QueryResultTotals[0], тзРезультат[0]);
			EndIf;

		EndIf;

	Иначе

		If фДерево Then

			выбЗапрос = рзВыборка.Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);

			й = 0;
			ВыборкуВДерево(выбЗапрос, QueryResultTree, й, ЕстьКонтейнеры, Обработка, ЕстьМакроколонки,
				стМакроколонки);

			ResultReturningRowsCount = выбЗапрос.Количество();

		Иначе

			й = 0;
			выбЗапрос = рзВыборка.Выбрать();
			Пока выбЗапрос.Следующий() Do

				й = й + 1;

				If OutputLinesLimitEnabled И OutputLinesLimit > 0 И й > OutputLinesLimit Then
					Прервать;
				EndIf;

				РезультатЗапросаСтрока = QueryResult.Добавить();
				ЗаполнитьЗначенияСвойств(РезультатЗапросаСтрока, выбЗапрос);
				If ЕстьКонтейнеры Then
					Обработка.AddContainers(РезультатЗапросаСтрока, выбЗапрос, QueryResultContainerColumns);
				EndIf;

				If ЕстьМакроколонки Then
					Обработка.ProcessMacrocolumns(РезультатЗапросаСтрока, выбЗапрос, стМакроколонки);
				EndIf;

			EndDo;

			If OutputLinesLimitEnabled И OutputLinesLimit > 0 Then
				тзРезультат = ДанныеФормыВЗначение(QueryResult, Тип("ТаблицаЗначений"));
			Иначе
				тзРезультат = рзВыборка.Выгрузить();
			EndIf;

			If тзРезультат.Количество() > 0 Then
				тзРезультат.Свернуть("", СписокКолонокСтрокой);
				ЗаполнитьЗначенияСвойств(QueryResultTotals[0], тзРезультат[0]);
			EndIf;

			ResultReturningRowsCount = рзВыборка.Выбрать().Количество();

		EndIf;

	EndIf;

	Элементы.QueryPlan.Видимость = ValueIsFilled(стРезультат.ЗапросИД);

	Элементы.QueryResultBatchInfo.ГиперссылкаЯчейки = Элементы.QueryPlan.Видимость;

	StructureЗаписиРезультата_ЗаполнитьСтруктуруЗаписи(рзВыборка);

	Return ResultReturningRowsCount;

EndFunction

#Region СохраняемыеСостояния

//Сохраняемые состояния - Structure, предназначена для сохранения значений, которых нет в опциях (состояния флажков форм,
//разных значений, и т.д.). Записывается в файл. Из файла читается только при первом открытии.
//Это дублирование кода из модуля обработки, но If нужно получать и с сервера, и с клиента, 1С по другому не умеет. Лишний вызов сервера не нужен.

&AtClient
Procedure SavedStates_Save(ИмяЗначения, Значение) Экспорт

	If Не ValueIsFilled(Object.SavedStates) Then
		Object.SavedStates = New Structure;
	EndIf;

	Object.SavedStates.Вставить(ИмяЗначения, Значение);

EndProcedure

&AtClient
Function SavedStates_Get(ИмяЗначения, ЗначениеПоУмолчанию) Экспорт
	Var Значение;

	If Не ValueIsFilled(Object.SavedStates) Или Не Object.SavedStates.Свойство(ИмяЗначения,
		Значение) Then
		Return ЗначениеПоУмолчанию;
	EndIf;

	Return Значение;

EndFunction

&AtServer
Procedure СохраняемыеСостояния_СохранитьAtServer(ИмяЗначения, Значение) Экспорт

	If Не ValueIsFilled(Object.SavedStates) Then
		Object.SavedStates = New Structure;
	EndIf;

	Object.SavedStates.Вставить(ИмяЗначения, Значение);

EndProcedure

&AtServer
Function СохраняемыеСостояния_ПолучитьAtServer(ИмяЗначения, ЗначениеПоУмолчанию) Экспорт
	Var Значение;

	If Не ValueIsFilled(Object.SavedStates) Или Не Object.SavedStates.Свойство(ИмяЗначения,
		Значение) Then
		Return ЗначениеПоУмолчанию;
	EndIf;

	Return Значение;

EndFunction

#EndRegion

#Region ВыполнениеЗапроса

&AtServer
Function РазобратьВыражениеМакроКолонки(СтрокаМакроВыражения)

	стМакроколонка = Undefined;

	маЪ = StrSplit(СтрокаМакроВыражения, "_");
	If маЪ.Количество() > 1 Then

		стрТипМакро = маЪ[0];
		стрSourceColumn = Прав(СтрокаМакроВыражения, StrLen(СтрокаМакроВыражения) - StrLen(стрТипМакро) - 1);

		ТипЗначения = Undefined;
		If стрТипМакро = "УИД" Then
			ТипЗначения = New ОписаниеТипов("УникальныйИдентификатор");
		EndIf;

		If ТипЗначения <> Undefined Then
			стМакроколонка = New Structure("Тип, ТипЗначения, SourceColumn", стрТипМакро, ТипЗначения,
				стрSourceColumn);
		EndIf;

	EndIf;

	Return стМакроколонка;

EndFunction

&AtServer
Function ПолучитьМакроколонки(ЗапросСхемы)

	стМакроколонки = New Structure;
	If Не Object.OptionProcessing__ Then
		Return стМакроколонки;
	EndIf;

	СтрокаНачалаМакро = "&" + MacroParameter;
	For Each Колонка Из ЗапросСхемы.Колонки Do

		If Колонка.Поля.Количество() > 0 Then

			Выражение = Колонка.Поля[0];
			If СтрНачинаетсяС(Выражение, СтрокаНачалаМакро) Then

				стрМакроВыражение = Прав(Выражение, StrLen(Выражение) - StrLen(СтрокаНачалаМакро));
				стМакроколонка = РазобратьВыражениеМакроКолонки(стрМакроВыражение);
				If стМакроколонка <> Undefined Then
					стМакроколонки.Вставить(Колонка.Псевдоним, стМакроколонка);
				EndIf;

			EndIf;

		EndIf;

	EndDo;

	Return стМакроколонки;

EndFunction

&AtServer
//Выполняет запрос по схеме, извлекая информацию о каждом подзапросе пакета (тип подзапроса, имена временных таблиц, количество строк результата, и т.д.
Function ВыполнитьПакет(Запрос, СхемаЗапроса)
	
	//Обработка = РеквизитФормыВЗначение("Объект");

	маРезультатПакета = New Array;
	For Each ЗапросСхемы Из СхемаЗапроса.ПакетЗапросов Do

		If ТипЗнч(ЗапросСхемы) = Тип("ЗапросВыбораСхемыЗапроса") Then

			If TechLogEnabledAndRunning Then
				ЗапросИД = "i" + СтрЗаменить(New УникальныйИдентификатор, "-", "");
				Запрос.Текст = StrTemplate(
					"ВЫБРАТЬ ""%2_begin"" ПОМЕСТИТЬ %2_begin; %1; ВЫБРАТЬ ""%2_end"" ПОМЕСТИТЬ %2_end",
					ЗапросСхемы.ПолучитьТекстЗапроса(), ЗапросИД);
			Иначе
				ЗапросИД = Undefined;
				Запрос.Текст = ЗапросСхемы.ПолучитьТекстЗапроса();
			EndIf;

			стМакроколонки = ПолучитьМакроколонки(ЗапросСхемы);
			ВремяНачалаЗапроса = ТекущаяУниверсальнаяДатаВМиллисекундах();
			маРезультатЗапроса = Запрос.ВыполнитьПакет(); //6345bb7034de4ad1b14249d2d7ac26dd
			ВремяОкончанияЗапроса = ТекущаяУниверсальнаяДатаВМиллисекундах();
			ДлительностьВМиллисекундах = ВремяОкончанияЗапроса - ВремяНачалаЗапроса;

			If Object.TechLogEnabled Then
				рзРезультат = маРезультатЗапроса[1];
			Иначе
				рзРезультат = маРезультатЗапроса[0];
			EndIf;

			If ValueIsFilled(ЗапросСхемы.ТаблицаДляПомещения) Then

				чКоличествоЗаписей = Undefined;
				выбРезультат = рзРезультат.Выбрать();
				If выбРезультат.Следующий() Then
					чКоличествоЗаписей = выбРезультат.Количество;
				EndIf;

				Запрос.Текст = "ВЫБРАТЬ * ИЗ " + ЗапросСхемы.ТаблицаДляПомещения;
				рзРезультатТаблицы = Запрос.Выполнить();
				стРезультат = New Structure("Результат, ИмяТаблицы, ИмяРезультата, КоличествоЗаписей, Макроколонки, ВремяНачалаЗапроса, ДлительностьВМиллисекундах, СозданиеВременнойТаблицы, ЗапросИД",
					рзРезультатТаблицы, ЗапросСхемы.ТаблицаДляПомещения, ЗапросСхемы.ТаблицаДляПомещения,
					чКоличествоЗаписей, стМакроколонки, ВремяНачалаЗапроса, ДлительностьВМиллисекундах, True,
					ЗапросИД);
				маРезультатПакета.Добавить(стРезультат);

			Иначе

				стРезультат = New Structure("Результат, ИмяТаблицы, ИмяРезультата, КоличествоЗаписей, Макроколонки, ВремяНачалаЗапроса, ДлительностьВМиллисекундах, СозданиеВременнойТаблицы, ЗапросИД",
					рзРезультат, , "Результат" + СхемаЗапроса.ПакетЗапросов.Индекс(ЗапросСхемы),
					рзРезультат.Выбрать().Количество(), стМакроколонки, ВремяНачалаЗапроса, ДлительностьВМиллисекундах,
					False, ЗапросИД);
				маРезультатПакета.Добавить(стРезультат);

			EndIf;

		ElsIf ТипЗнч(ЗапросСхемы) = Тип("ЗапросУничтоженияТаблицыСхемыЗапроса") Then
			Запрос.Текст = "УНИЧТОЖИТЬ " + ЗапросСхемы.ИмяТаблицы;
			Запрос.Выполнить();
		Иначе
			Return "Неизвестный тип запроса схемы";
		EndIf;

	EndDo;

	Return маРезультатПакета;

EndFunction

&AtServer
Procedure УстановитьПараметрыМакроколонокЗапроса(Запрос)

	If Object.OptionProcessing__ Then

		КоллекцияПараметров = Запрос.НайтиПараметры();
		For Each ПараметрЗапроса Из КоллекцияПараметров Do

			If СтрНачинаетсяС(ПараметрЗапроса.Имя, MacroParameter) Then
				Запрос.УстановитьПараметр(ПараметрЗапроса.Имя, Null);
			EndIf;

		EndDo;

	EndIf;

EndProcedure

&AtServer
Function ВыполнитьЗапросAtServer(ТекстЗапроса)
	Var НомерСтроки, НомерКолонки;

	ВыполняемыйЗапрос = New Запрос;
	ВыполняемыйЗапрос.МенеджерВременныхТаблиц = ЗагрузитьВременныеТаблицы();

	For Each СтрокаПараметра Из QueryParameters Do

		If Object.OptionProcessing__ И СтрНачинаетсяС(СтрокаПараметра.Name, MacroParameter) Then
			Продолжить;
		EndIf;

		Значение = ПараметрыЗапроса_ПолучитьЗначение(СтрокаПараметра.ПолучитьИдентификатор());
		ВыполняемыйЗапрос.УстановитьПараметр(СтрокаПараметра.Name, Значение);

	EndDo;

	СхемаЗапроса = New СхемаЗапроса;

	Try
		ВыполняемыйЗапрос.Текст = ТекстЗапроса;
		УстановитьПараметрыМакроколонокЗапроса(ВыполняемыйЗапрос);
		СхемаЗапроса.УстановитьТекстЗапроса(ТекстЗапроса);
	Except
		СтрокаОшибки = ОписаниеОшибки();
		DisassembleSpecifiedQueryError(СтрокаОшибки, ВыполняемыйЗапрос, ТекстЗапроса, НомерСтроки, НомерКолонки);
		Return New Structure("ОписаниеОшибки, Строка, Колонка, ВремяНачала, ВремяОкончания", СтрокаОшибки,
			НомерСтроки, НомерКолонки);
	EndTry;

	If OutputLinesLimitTopEnabled И OutputLinesLimitTop > 0 Then

		For Each ЗапросСхемы Из СхемаЗапроса.ПакетЗапросов Do
			If ТипЗнч(ЗапросСхемы) = Тип("ЗапросВыбораСхемыЗапроса") И Не ValueIsFilled(
				ЗапросСхемы.ТаблицаДляПомещения) Then
				For Each Оператор Из ЗапросСхемы.Операторы Do
					If Не ValueIsFilled(Оператор.КоличествоПолучаемыхЗаписей) Then
						Оператор.КоличествоПолучаемыхЗаписей = OutputLinesLimitTop;
					EndIf;
				EndDo;
			EndIf;
		EndDo;

	EndIf;

	ВремяНачала = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Try
		маРезультатЗапроса = ВыполнитьПакет(ВыполняемыйЗапрос, СхемаЗапроса);
		ВремяОкончания = ТекущаяУниверсальнаяДатаВМиллисекундах();
		If ТипЗнч(маРезультатЗапроса) <> Тип("Array") Then
			ВызватьExcept маРезультатЗапроса;
		EndIf;
	Except
		ВремяОкончания = ТекущаяУниверсальнаяДатаВМиллисекундах();
		ВыполняемыйЗапрос.МенеджерВременныхТаблиц = ЗагрузитьВременныеТаблицы();
		СтрокаОшибки = ОписаниеОшибки();
		DisassembleSpecifiedQueryError(СтрокаОшибки, ВыполняемыйЗапрос, ТекстЗапроса, НомерСтроки, НомерКолонки);
		Return New Structure("ОписаниеОшибки, Строка, Колонка, ВремяНачала, ВремяОкончания", СтрокаОшибки,
			НомерСтроки, НомерКолонки, ВремяНачала, ВремяОкончания);
	EndTry;

	стРезультат = New Structure("Результат, Параметры", маРезультатЗапроса, ВыполняемыйЗапрос.Параметры);
	If ValueIsFilled(QueryResultAddress) Then
		QueryResultAddress = ПоместитьВоВременноеХранилище(стРезультат, QueryResultAddress);
	Иначе
		QueryResultAddress = ПоместитьВоВременноеХранилище(стРезультат, УникальныйИдентификатор);
	EndIf;

	Элементы.ResultInBatch.СписокВыбора.Очистить();
	QueryResultBatch.Очистить();
	Для й = 1 По маРезультатЗапроса.Количество() Do

		стРезультат = маРезультатЗапроса[й - 1];
		Элементы.ResultInBatch.СписокВыбора.Добавить(Строка(й), стРезультат.ИмяРезультата + " ("
			+ стРезультат.КоличествоЗаписей + ")");

		СтрокаПакета = QueryResultBatch.Добавить();
		СтрокаПакета.Name = стРезультат.ИмяРезультата;
		СтрокаПакета.ResultKind = ?(стРезультат.СозданиеВременнойТаблицы, 0, 1);
		СтрокаПакета.Info = StrTemplate("%1 / %2", стРезультат.КоличествоЗаписей, FormatDuration(
			стРезультат.ДлительностьВМиллисекундах));

	EndDo;

	Return New Structure("ОписаниеОшибки, Строка, Колонка, ВремяНачала, ВремяОкончания, КоличествоРезультатов", , ,
		, ВремяНачала, ВремяОкончания, маРезультатЗапроса.Количество());

EndFunction

#EndRegion

&AtClient
Function VarеститьСтрокуДерева(Дерево, VarещаемаяСтрока, ИндексВставки, NewРодитель, Уровень = 0)

	If Уровень = 0 Then

		If NewРодитель = Undefined Then
			НоваяСтрока = Дерево.ПолучитьЭлементы().Вставить(ИндексВставки);
		Иначе
			НоваяСтрока = NewРодитель.ПолучитьЭлементы().Вставить(ИндексВставки);
		EndIf;

		ЗаполнитьЗначенияСвойств(НоваяСтрока, VarещаемаяСтрока);
		VarеститьСтрокуДерева(Дерево, VarещаемаяСтрока, ИндексВставки, НоваяСтрока, Уровень + 1);

		VarещаемаяСтрокаРодитель = VarещаемаяСтрока.ПолучитьРодителя();
		If VarещаемаяСтрокаРодитель = Undefined Then
			Дерево.ПолучитьЭлементы().Удалить(VarещаемаяСтрока);
		Иначе
			VarещаемаяСтрокаРодитель.ПолучитьЭлементы().Удалить(VarещаемаяСтрока);
		EndIf;

	Иначе

		For Each Строка Из VarещаемаяСтрока.ПолучитьЭлементы() Do
			НоваяСтрока = NewРодитель.ПолучитьЭлементы().Добавить();
			ЗаполнитьЗначенияСвойств(НоваяСтрока, VarещаемаяСтрока);
			VarеститьСтрокуДерева(Дерево, Строка, НоваяСтрока, ИндексВставки, Уровень + 1);
		EndDo;

	EndIf;

	Return НоваяСтрока;

EndFunction

&AtClient
Procedure ОшибкаКонсоли(СтрокаОшибки)
	ВызватьExcept СтрокаОшибки;
EndProcedure

&AtClient
Procedure УстановитьQueriesFileName(стрПолноеИмя = "")

	QueriesFileName = стрПолноеИмя;
	If ValueIsFilled(QueriesFileName) Then
		Файл = New Файл(стрПолноеИмя);
		QueryBatch_DisplayingName = Файл.Имя;
		ПакетЗапросов_ИмяДляПодсказки = Файл.ПолноеИмя;
	Иначе
		QueryBatch_DisplayingName = "Имя";
		ПакетЗапросов_ИмяДляПодсказки = "Имя";
	EndIf;

	Элементы.QueryBatch.ПодчиненныеЭлементы.QueryListQuery.Заголовок = QueryBatch_DisplayingName;
	Элементы.QueryBatch.ПодчиненныеЭлементы.QueryListQuery.Подсказка = ПакетЗапросов_ИмяДляПодсказки;

EndProcedure

&AtClient
Function СохранитьСВопросом(ДополнительныеПараметры)

	If Модифицированность Then
		ПоказатьВопрос(
			New ОписаниеОповещения("ПослеВопросаСохранения", ЭтаФорма, ДополнительныеПараметры),
			"Имеется не сохраненный пакет запросов. Сохранить?", РежимДиалогаВопрос.ДаНетОтмена, ,
			КодReturnаДиалога.Да);
		Return False;
	EndIf;

	Return True;

EndFunction

&AtClient
Procedure ЗавершениеПослеВопроса(РезультатВопроса, ДополнительныеПараметры)

	If РезультатВопроса = КодReturnаДиалога.Да Then
		СохранитьПакетЗапросов(New Structure("Завершение", True));
	ElsIf РезультатВопроса = КодReturnаДиалога.Нет Then
		If ValueIsFilled(QueriesFileName) Then
			ОписаниеОповещения = New ОписаниеОповещения("ЗавершениеПослеУдаления", ЭтаФорма);
			НачатьУдалениеФайлов(ОписаниеОповещения, GetAutoSaveFileName(QueriesFileName));
		Иначе
			ОписаниеОповещения = New ОписаниеОповещения("ЗавершениеПослеУдаления", ЭтаФорма);
			НачатьУдалениеФайлов(ОписаниеОповещения, StateAutoSaveFileName);
		EndIf;
	ElsIf РезультатВопроса = КодReturnаДиалога.Отмена Then
	EndIf;

EndProcedure

&AtClient
Procedure ЗавершениеПослеУдаления(ДополнительныеПараметры) Экспорт
	Модифицированность = False;
	Закрыть();
EndProcedure

&AtClient
Procedure Автосохранить(Оповещение = Undefined)

	ПоместитьРедактируемыйЗапрос();

	If ValueIsFilled(QueriesFileName) Then
		ПакетЗапросов_Сохранить(Оповещение, GetAutoSaveFileName(QueriesFileName));
		ПакетЗапросов_Сохранить( , StateAutoSaveFileName, True);
	Иначе
		ПакетЗапросов_Сохранить(Оповещение, StateAutoSaveFileName);
	EndIf;

EndProcedure

&AtClient
Function ПараметрыЗапросаВСписокЗначений(ПараметрыДанныеФормыКоллекция)

	сзПараметрыЗапроса = New СписокЗначений;
	For Each СтрокаПараметра Из ПараметрыДанныеФормыКоллекция Do
		стПараметр = New Structure("Имя, ТипЗначения, Значение, ТипКонтейнера, Контейнер");
		ЗаполнитьЗначенияСвойств(стПараметр, СтрокаПараметра);
		сзПараметрыЗапроса.Добавить(стПараметр);
	EndDo;

	Return сзПараметрыЗапроса;

EndFunction

&AtClient
Function ВременныеТаблицыВСписокЗначений(ВременныеТаблицыДанныеФормыКоллекция)

	сзВременныеТаблицы = New СписокЗначений;
	For Each СтрокаТаблицы Из ВременныеТаблицыДанныеФормыКоллекция Do
		стТаблица = New Structure("Имя, Контейнер, Значение");
		ЗаполнитьЗначенияСвойств(стТаблица, СтрокаТаблицы);
		сзВременныеТаблицы.Добавить(стТаблица);
	EndDo;

	Return сзВременныеТаблицы;

EndFunction

&AtClient
Procedure ПараметрыЗапросаИзСпискаЗначений(сзПараметры, ПараметрыДанныеФормыКоллекция)

	ПараметрыДанныеФормыКоллекция.Очистить();

	If сзПараметры <> Undefined Then

		For Each кзПараметр Из сзПараметры Do
			ЗаполнитьЗначенияСвойств(ПараметрыДанныеФормыКоллекция.Добавить(), кзПараметр.Значение);
		EndDo;

	EndIf;

EndProcedure

&AtClient
Procedure ВременныеТаблицыИзСпискаЗначений(сзВременныеТаблицы, ВременныеТаблицыДанныеФормыКоллекция)

	ВременныеТаблицыДанныеФормыКоллекция.Очистить();

	If сзВременныеТаблицы <> Undefined Then

		For Each кзТаблица Из сзВременныеТаблицы Do
			ЗаполнитьЗначенияСвойств(ВременныеТаблицыДанныеФормыКоллекция.Добавить(), кзТаблица.Значение);
		EndDo;

	EndIf;

EndProcedure

&AtClient
Procedure ОбновитьСостояниеЭлементовФормыАлгоритма()
	
	//If BackgroundJobID заполнен - то происходит выполнение кода в фоновом задании.
	//В этом случае управление элементами происходит в Procedureх отображения прогресса.
	If Не ValueIsFilled(BackgroundJobID) Then

		If Элементы.QueryBatch.ТекущиеДанные <> Undefined И ResultQueryName
			= Элементы.QueryBatch.ТекущиеДанные.Name Then
			Элементы.ExecuteDataProcessor.Доступность = True;
			ExecutionStatus = "";
			Элементы.StructureЗаписиРезультата.Доступность = True;
		Иначе
			Элементы.ExecuteDataProcessor.Доступность = False;
			ExecutionStatus = "(запрос не выполнен)";
			Элементы.StructureЗаписиРезультата.Доступность = False;
		EndIf;
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Function ИмяОбработкиКонсоли(Форма)
	ArrayИмениФормы=StrSplit(Форма.ИмяФормы, ".");
	Return ArrayИмениФормы[1];
EndFunction

#Region ПараметрыЗапроса

//Работа с параметром запроса, хранимым в виде строки таблицы ПараметрыЗапроса. Далее везде параметр с именем "СтрокаИд" - это идентификатор строка этой таблицы.

&AtServer
Function ПараметрыЗапроса_ПолучитьЗначение(СтрокаИд)

	СтрокаПараметр = QueryParameters.НайтиПоИдентификатору(СтрокаИд);

	If СтрокаПараметр.ContainerType = 0 Или СтрокаПараметр.ContainerType = 1 Или СтрокаПараметр.ContainerType = 2
		Или СтрокаПараметр.ContainerType = 3 Then
		Return РеквизитФормыВЗначение("Object").Container_RestoreValue(СтрокаПараметр.Контейнер);
	Иначе
		ВызватьExcept "Ошибка в типе контейнера параметра";
	EndIf;

EndFunction

&AtServer
Procedure ПараметрыЗапроса_СохранитьЗначение(СтрокаИд, Знач Значение)

	СтрокаПараметр = QueryParameters.НайтиПоИдентификатору(СтрокаИд);

	If СтрокаПараметр.ContainerType = 0 Then
		СтрокаПараметр.Контейнер = РеквизитФормыВЗначение("Object").Container_SaveValue(Значение);
		If ТипЗнч(СтрокаПараметр.Контейнер) = Тип("Structure") Then
			СтрокаПараметр.Value = СтрокаПараметр.Контейнер.Представление;
		Иначе
			СтрокаПараметр.Value = Значение;
		EndIf;
	ElsIf СтрокаПараметр.ContainerType = 1 Then
		СтрокаПараметр.Контейнер = РеквизитФормыВЗначение("Object").Container_SaveValue(Значение);
		СтрокаПараметр.Value = СтрокаПараметр.Контейнер.Представление;
	ElsIf СтрокаПараметр.ContainerType = 2 Then
		СтрокаПараметр.Контейнер = РеквизитФормыВЗначение("Object").Container_SaveValue(Значение);
		СтрокаПараметр.Value = СтрокаПараметр.Контейнер.Представление;
	ElsIf СтрокаПараметр.ContainerType = 3 Then
		СтрокаПараметр.ValueType = "Таблица значений";
		СтрокаПараметр.Контейнер = РеквизитФормыВЗначение("Object").Container_SaveValue(Значение);
		СтрокаПараметр.Value = СтрокаПараметр.Контейнер.Представление;
	Иначе
		ВызватьExcept "Ошибка в типе контейнера параметра";
	EndIf;

	Модифицированность = True;

EndProcedure

&AtServer
//Контейнер типа 1 и типа 2 (список значений или Array) возвращаем в виде Arrayа
Function Контейнер12ВArray(Контейнер)

	Значение = РеквизитФормыВЗначение("Object").Container_RestoreValue(Контейнер);

	If ТипЗнч(Значение) = Тип("СписокЗначений") Then
		Return Значение.ВыгрузитьЗначения();
	ElsIf ТипЗнч(Значение) = Тип("Array") Then
		Return Значение;
	EndIf;

	Return Undefined;

EndFunction

&AtServer
Procedure ПараметрыЗапроса_УстановитьТип(СтрокаИд, ТипКонтейнера, ТипЗначения)

	СтрокаПараметр = QueryParameters.НайтиПоИдентификатору(СтрокаИд);
	Контейнер = СтрокаПараметр.Контейнер;

	If ТипКонтейнера = 1 Или ТипКонтейнера = 2 Then

		If СтрокаПараметр.ContainerType = 1 Или СтрокаПараметр.ContainerType = 2 Then
			КонтейнерArray = Контейнер12ВArray(Контейнер);
		ElsIf СтрокаПараметр.ContainerType = 3 Then
			//Была ТЗ, теперь СЗ. Надо достать первую ячейку.
			Таблица = РеквизитФормыВЗначение("Object").Container_RestoreValue(Контейнер);
			КонтейнерArray = Таблица.ВыгрузитьКолонку(0);
		ElsIf СтрокаПараметр.ContainerType = 0 Then

			КонтейнерArray = New Array;

			КонтейнерArray.Добавить(РеквизитФормыВЗначение("Object").Container_RestoreValue(Контейнер));
			//If ValueIsFilled(СтрокаПараметр.Значение) Then
			//	КонтейнерArray.Добавить(СтрокаПараметр.Значение);
			//EndIf;

			СтрокаПараметр.Value = Undefined;

		EndIf;

		If ТипКонтейнера = 1 Then
			NewСписок = New СписокЗначений;
			NewСписок.ЗагрузитьЗначения(КонтейнерArray);
			NewСписок.ТипЗначения = ТипЗначения;
			СтрокаПараметр.Контейнер = РеквизитФормыВЗначение("Object").Container_SaveValue(NewСписок);
		ElsIf ТипКонтейнера = 2 Then
			NewСписок = New СписокЗначений;
			NewСписок.ЗагрузитьЗначения(КонтейнерArray);
			NewСписок.ТипЗначения = ТипЗначения;
			КонтейнерArray = NewСписок.ВыгрузитьЗначения();
			СтрокаПараметр.Контейнер = РеквизитФормыВЗначение("Object").Container_SaveValue(КонтейнерArray);
		EndIf;

	ElsIf ТипКонтейнера = 3 Then

		If СтрокаПараметр.ContainerType = 1 Или СтрокаПараметр.ContainerType = 2 Then
			Таблица = РеквизитФормыВЗначение("Object").Container_RestoreValue(ТипЗначения);
			Значение = РеквизитФормыВЗначение("Object").Container_RestoreValue(Контейнер);
			If ТипЗнч(Значение) = Тип("СписокЗначений") Then
				Значение = Значение.ВыгрузитьЗначения();
			EndIf;
			For Each ъ Из Значение Do
				Таблица.Добавить()[0] = ъ;
			EndDo;
			NewКонтейнер = РеквизитФормыВЗначение("Object").Container_SaveValue(Таблица);
		ElsIf СтрокаПараметр.ContainerType = 3 Then
			Контейнер = ТипЗначения;
			//Теперь не копируем, преобразование уже выполняет редактор типа!
			//СкопироватьДанныеКонтейнераТипа3(Контейнер, СтрокаПараметр.Контейнер);
			NewКонтейнер = Контейнер;
		ElsIf СтрокаПараметр.ContainerType = 0 Then
			Таблица = РеквизитФормыВЗначение("Object").Container_RestoreValue(ТипЗначения);
			Таблица.Добавить()[0] = СтрокаПараметр.Value;
			NewКонтейнер = РеквизитФормыВЗначение("Object").Container_SaveValue(Таблица);
		EndIf;

		СтрокаПараметр.Контейнер = NewКонтейнер;

	ElsIf ТипКонтейнера = 0 Then

		If СтрокаПараметр.ContainerType = 1 Или СтрокаПараметр.ContainerType = 2 Then
			КонтейнерArray = Контейнер12ВArray(Контейнер);
			If КонтейнерArray.Количество() > 0 Then
				СтрокаПараметр.Контейнер = РеквизитФормыВЗначение("Object").Container_SaveValue(
					ТипЗначения.ПривестиЗначение(КонтейнерArray[0]));
			EndIf;
		ElsIf СтрокаПараметр.ContainerType = 3 Then
			сз = QueryParametersFormOnChangeVLFromVT(Контейнер);
			If сз.Количество() > 0 Then
				СтрокаПараметр.Контейнер = РеквизитФормыВЗначение("Object").Container_SaveValue(
					ТипЗначения.ПривестиЗначение(сз.СписокЗначений[0].Значение));
			EndIf;
		ElsIf СтрокаПараметр.ContainerType = 0 Then
			СтрокаПараметр.Контейнер = РеквизитФормыВЗначение("Object").Container_SaveValue(
				ТипЗначения.ПривестиЗначение(РеквизитФормыВЗначение("Object").Container_RestoreValue(
				СтрокаПараметр.Контейнер)));
		EndIf;

	EndIf;

	СтрокаПараметр.ContainerType = ТипКонтейнера;
	If СтрокаПараметр.ContainerType = 3 Then
		СтрокаПараметр.ValueType = "Таблица значений";
	Иначе
		СтрокаПараметр.ValueType = ТипЗначения;
	EndIf;

	Модифицированность = True;

	If ТипЗнч(СтрокаПараметр.Контейнер) = Тип("Structure") Then
		СтрокаПараметр.Value = СтрокаПараметр.Контейнер.Представление;
	Иначе
		СтрокаПараметр.Value = СтрокаПараметр.Контейнер;
	EndIf;

EndProcedure

//@skip-warning
&AtServer
Procedure СкопироватьДанныеКонтейнераТипа3(КонтейнерNew, КонтейнерСтарый)

	Обработка = РеквизитФормыВЗначение("Object");
	ТаблицаНовая = Обработка.StringToValue(КонтейнерNew.Значение);
	ТаблицаСтарая = Обработка.StringToValue(КонтейнерСтарый.Значение);

	ТаблицаНовая.Очистить();
	
	//If одинаковых колонок нет, то копировать нечего.
	фОдинаковыеЕсть = False;
	For Each КолонкаНовая Из ТаблицаНовая.Колонки Do
		If ТаблицаСтарая.Колонки.Найти(КолонкаНовая.Имя) <> Undefined Then
			фОдинаковыеЕсть = True;
			Прервать;
		EndIf;
	EndDo;

	If фОдинаковыеЕсть Then
		For Each СтрокаСтарая Из ТаблицаСтарая Do
			СтрокаНовая = ТаблицаНовая.Добавить();
			ЗаполнитьЗначенияСвойств(СтрокаНовая, СтрокаСтарая);
		EndDo;
		КонтейнерNew.КоличествоСтрок = КонтейнерСтарый.КоличествоСтрок;
	Иначе
		КонтейнерNew.КоличествоСтрок = 0;
	EndIf;

	КонтейнерNew.Значение = Обработка.ValueToString(ТаблицаНовая);
	КонтейнерNew.Представление = Обработка.Container_GetPresentation(КонтейнерNew);

EndProcedure

&AtServer
Function ПараметрыЗапроса_ПолучитьКакСтроку()

	тзПараметры = New ТаблицаЗначений;
	тзПараметры.Колонки.Добавить("Имя", New ОписаниеТипов("Строка"));
	тзПараметры.Колонки.Добавить("Значение");
	For Each СтрокаПараметра Из QueryParameters Do
		СтрокаТаблицы = тзПараметры.Добавить();
		СтрокаТаблицы.Имя = СтрокаПараметра.Name;
		СтрокаТаблицы.Значение = ПараметрыЗапроса_ПолучитьЗначение(СтрокаПараметра.ПолучитьИдентификатор());
	EndDo;

	Return РеквизитФормыВЗначение("Object").ValueToString(тзПараметры);

EndFunction

#EndRegion //ПараметрыЗапроса

#Region ПакетЗапросов

&AtClient
Procedure ИнициализироватьЗапрос(ТекущаяСтрока)

	If Не ValueIsFilled(ТекущаяСтрока.Name) Then
		QueryCount = QueryCount + 1;
		ТекущаяСтрока.Name = "Запрос" + QueryCount;
	EndIf;

	ТекущаяСтрока.Initialized = True;

EndProcedure

&AtClient
Procedure ПоместитьРедактируемыйЗапрос()
	If EditingQuery >= 0 Then
		стрТекстЗапроса = QueryText;
		стрТекстАлгоритм = ТекущийТекстАлгоритма();
		
		ГраницыВыделенияАлгоритма = ГраницыВыделенияАлгоритма();	
		ГраницыВыделенияЗапроса = ГраницыВыделенияЗапроса();	
			
		Запрос_ПоместитьДанныеЗапроса(EditingQuery, стрТекстЗапроса, стрТекстАлгоритм, CodeExecutionMethod,
			ПараметрыЗапросаВСписокЗначений(QueryParameters), ВременныеТаблицыВСписокЗначений(TempTables),
			ГраницыВыделенияЗапроса.НачалоСтроки, ГраницыВыделенияЗапроса.НачалоКолонки,
			ГраницыВыделенияЗапроса.КонецСтроки, ГраницыВыделенияЗапроса.КонецКолонки,
			ГраницыВыделенияАлгоритма.НачалоСтроки, ГраницыВыделенияАлгоритма.НачалоКолонки,
			ГраницыВыделенияАлгоритма.КонецСтроки, ГраницыВыделенияАлгоритма.КонецКолонки);
	EndIf;

EndProcedure

&AtClient
Procedure УстановитьДоступностьРедактированияЗапроса(Доступность)
	Элементы.QueryText.ТолькоПросмотр = Не Доступность;
	Элементы.QueryCommandBarGroup.Доступность = Доступность;
EndProcedure

&AtClient
Procedure ИзвлечьРедактируемыйЗапрос(ЗапросКроме = Undefined, ВосстановитьПозийиюРедактирования = True)
	ТекущаяСтрока = Элементы.QueryBatch.ТекущаяСтрока;

	If EditingQuery <> ЗапросКроме Then
		ПоместитьРедактируемыйЗапрос();
	EndIf;

	If ТекущаяСтрока = Undefined Then
		QueryText = "";
		УстановитьТекстАлгоритма("");
		УстановитьДоступностьРедактированияЗапроса(False);
		Элементы.QueryGroupPages.ПодчиненныеЭлементы.QueryPage.Заголовок = "Запрос";
		QueryParameters.Очистить();
		TempTables.Очистить();
		Return;
	EndIf;

	стДанныеЗапроса = Запрос_ПолучитьДанныеЗапроса(ТекущаяСтрока);

	QueryText = стДанныеЗапроса.Запрос;

	УстановитьТекстАлгоритма(стДанныеЗапроса.ТекстКод);
	CodeExecutionMethod = стДанныеЗапроса.CodeExecutionMethod;

	ПараметрыЗапросаИзСпискаЗначений(стДанныеЗапроса.Параметры, QueryParameters);
	ВременныеТаблицыИзСпискаЗначений(стДанныеЗапроса.TempTables, TempTables);

	If стДанныеЗапроса.InWizard Then
		УстановитьДоступностьРедактированияЗапроса(False);
		Элементы.QueryGroupPages.ПодчиненныеЭлементы.QueryPage.Заголовок = "Запрос (в конструкторе)";
	Иначе
		УстановитьДоступностьРедактированияЗапроса(True);
		Элементы.QueryGroupPages.ПодчиненныеЭлементы.QueryPage.Заголовок = "Запрос";
	EndIf;

	EditingQuery = Элементы.QueryBatch.ТекущаяСтрока;

	ОбновитьСостояниеЭлементовФормыАлгоритма();

	If ВосстановитьПозийиюРедактирования Then
		ПодключитьОбработчикОжидания("ВосстановлениеПозицииРедактирования", 0.01, True);
	EndIf;

EndProcedure

&AtClient
Procedure ВосстановлениеПозицииРедактирования()

	ТекущаяСтрока = Элементы.QueryBatch.ТекущаяСтрока;
	стДанныеЗапроса = Запрос_ПолучитьДанныеЗапроса(ТекущаяСтрока);

	УстановитьГраницыВыделенияЗапроса(стДанныеЗапроса.CursorBeginRow, стДанныеЗапроса.CursorBeginColumn,
		стДанныеЗапроса.CursorEndRow, стДанныеЗапроса.CursorEndColumn);

	УстановитьГраницыВыделенияАлгоритма(стДанныеЗапроса.CodeCursorBeginRow, стДанныеЗапроса.CodeCursorBeginColumn,
		стДанныеЗапроса.CodeCursorEndRow, стДанныеЗапроса.CodeCursorEndColumn);

	If Элементы.QueryGroupPages.ТекущаяСтраница = Элементы.QueryPage Then
		ТекущийЭлемент = Элементы.QueryText;
	ElsIf Элементы.QueryGroupPages.ТекущаяСтраница = Элементы.AlgorithmPage Then
		ТекущийЭлемент = Элементы.AlgorithmText;
	EndIf;

EndProcedure

&AtClient
Procedure ПакетЗапросов_Инициализировать(Элемент = Undefined)

	If Элемент = Undefined Then
		Элемент = QueryBatch;
	EndIf;

	For Each ПодчиненныйЭлемент Из Элемент.ПолучитьЭлементы() Do
		ПодчиненныйЭлемент.InWizard = False;
		ПакетЗапросов_Инициализировать(ПодчиненныйЭлемент);
	EndDo;

EndProcedure

&AtClient
Procedure ПакетЗапросов_New()

	QueryBatch.ПолучитьЭлементы().Очистить();
	QueryCount = 0;
	ИнициализироватьЗапрос(QueryBatch.ПолучитьЭлементы().Добавить());
	ПакетЗапросов_Инициализировать();
	Модифицированность = False;
	УстановитьQueriesFileName();
	EditingQuery = -1;

	AutoSaveIntervalOption = 60;
	SaveCommentsOption = True;
	AutoSaveBeforeQueryExecutionOption = True;
	//AlgorithmExecutionUpdateIntervalOption = 1000;
	TechLogSwitchingPollingPeriodOption = 3;
	Object.OptionProcessing__ = True;
	Object.AlgorithmExecutionUpdateIntervalOption = 1000;

EndProcedure

&AtClient
Function ПакетЗапросов_СтрокиВArray(Строки)

	маСтроки = New Array;

	For Each Элемент Из Строки.ПолучитьЭлементы() Do
		стЭлемент = New Structure("Имя, ТекстЗапроса, ТекстКод, CodeExecutionMethod, QueryParameters, TempTables, Строки, Инфо,
									|CursorBeginRow, CursorBeginColumn, CursorEndRow, CursorEndColumn,
									|CodeCursorBeginRow, CodeCursorBeginColumn, CodeCursorEndRow, CodeCursorEndColumn");
		ЗаполнитьЗначенияСвойств(стЭлемент, Элемент);
		стЭлемент.Строки = ПакетЗапросов_СтрокиВArray(Элемент);
		маСтроки.Добавить(стЭлемент);
	EndDo;

	Return маСтроки;

EndFunction

&AtServerNoContext
Function ПакетЗапросов_СохранитьAtServer(Знач стДанныеДляЗаписи)
	Запись = New ЗаписьXML;
	Запись.УстановитьСтроку();
	СериализаторXDTO.ЗаписатьXML(Запись, стДанныеДляЗаписи, НазначениеТипаXML.Явное);
	Return Запись.Закрыть();
EndFunction

&AtClient
Procedure ПакетЗапросов_Сохранить(Оповещение, стрИмяФайла, фТолькоЗаголовок = False)

	ТекущаяСтрока = Элементы.QueryBatch.ТекущаяСтрока;

	ТекущаяСтрокаПакета = Undefined;
	If ТекущаяСтрока <> Undefined Then
		ТекущаяСтрокаПакета = QueryBatch.НайтиПоИдентификатору(ТекущаяСтрока);
	EndIf;
	
	//сохраняемые состояния ++
	SavedStates_Save("ResultKind", ResultKind);
	SavedStates_Save("OutputLinesLimit", OutputLinesLimit);
	SavedStates_Save("OutputLinesLimitEnabled", OutputLinesLimitEnabled);
	SavedStates_Save("OutputLinesLimitTop", OutputLinesLimitTop);
	SavedStates_Save("OutputLinesLimitTopEnabled", OutputLinesLimitTopEnabled;
	//сохраняемые состояния --
	
	//стПакетЗапросов = New Array;

	стОпции = New Structure("
							  |SaveCommentsOption,
							  |ОпцияАвтосохранениеПередВыполнениемЗапроса,
							  |TechLogSwitchingPollingPeriodOption,
							  |OptionProcessing__,
							  |AlgorithmExecutionUpdateIntervalOption,
							  |ОпцияИнтервалАвтосохранения", SaveCommentsOption,
		AutoSaveBeforeQueryExecutionOption, TechLogSwitchingPollingPeriodOption,
		Object.OptionProcessing__, Object.AlgorithmExecutionUpdateIntervalOption, AutoSaveIntervalOption);

	стДанныеДляЗаписи = New Structure("
										|Формат,      
										|Версия,
										|QueryCount,
										|ИмяФайла,
										|SavedStates,
										|ТекущийЗапрос,
										|Опции", ConsoleSignature, FormatVersion, QueryCount, QueriesFileName,
		Object.SavedStates, ?(ТекущаяСтрокаПакета <> Undefined, ТекущаяСтрокаПакета.Name, Undefined),
		стОпции);

	If Не фТолькоЗаголовок Then
		стДанныеДляЗаписи.Вставить("ПакетЗапросов", ПакетЗапросов_СтрокиВArray(QueryBatch));
	EndIf;

	ДанныеДляЗаписи = ПакетЗапросов_СохранитьAtServer(стДанныеДляЗаписи);

	ДокументЗапись = New ТекстовыйДокумент;
	ДокументЗапись.УстановитьТекст(ДанныеДляЗаписи);
	ДокументЗапись.НачатьЗапись(Оповещение, стрИмяФайла);

EndProcedure

&AtClient
Procedure ПакетЗапросов_ДобавитьСтрокиИзArrayа(Строка, маЭлементы)

	ЭлементыСтроки = Строка.ПолучитьЭлементы();

	For Each стЭлемент Из маЭлементы Do
		Элемент = ЭлементыСтроки.Добавить();
		ЗаполнитьЗначенияСвойств(Элемент, стЭлемент);
		ПакетЗапросов_ДобавитьСтрокиИзArrayа(Элемент, стЭлемент.Строки);
	EndDo;

EndProcedure

&AtServerNoContext
Function ПакетЗапросов_ЗагрузитьAtServer(Знач стрЗагруженныеДанные)

	Чтение = New ЧтениеXML;
	Чтение.УстановитьСтроку(стрЗагруженныеДанные);
	стЗагруженныеДанные = СериализаторXDTO.ПрочитатьXML(Чтение);
	Чтение.Закрыть();

	Return стЗагруженныеДанные;

EndFunction

&AtClient
Function ПакетЗапросов_ТекущийЗапрос()
	Return Элементы.QueryBatch.ТекущаяСтрока;
EndFunction

//Загружает пакет запросов.
//If файл содержит только заголовок, ничего не грузить, только возвращает заголовок (кроме сохраняемых состояний, If они еще пустые).
&AtClient
Procedure ПакетЗапросов_Загрузить(ДополнительныеПараметры)
	ЧитаемыйДокумент = New ТекстовыйДокумент;
	ДополнительныеПараметры.Вставить("Чтение", ЧитаемыйДокумент);
	Оповещение = New ОписаниеОповещения("ПакетЗапросов_ЗагрузитьЗавершение", ЭтаФорма, ДополнительныеПараметры,
		"ПакетЗапросов_ЗагрузитьОшибка", ЭтаФорма);
	ЧитаемыйДокумент.НачатьЧтение(Оповещение, ДополнительныеПараметры.ИмяФайла);
EndProcedure

&AtClient
Procedure ПакетЗапросов_ЗагрузитьОшибка(ИнформацияОбОшибке, СтандартнаяОбработка, ДополнительныеПараметры) Экспорт
	ДополнительныеПараметры.Вставить("ЗагруженныеДанные");
	ДополнительныеПараметры.Вставить("ИнформацияОбОшибке", ИнформацияОбОшибке);
	ВыполнитьПродолжение(ДополнительныеПараметры);
EndProcedure

&AtClient
Procedure ПакетЗапросов_ЗагрузитьЗавершение(ДополнительныеПараметры) Экспорт

	стрЗагруженныеДанные = ДополнительныеПараметры.Чтение.ПолучитьТекст();

	стЗагруженныеДанные = ПакетЗапросов_ЗагрузитьAtServer(стрЗагруженныеДанные);

	фОК = True;
	фОК = фОК И стЗагруженныеДанные.Свойство("Формат");
	фОК = фОК И стЗагруженныеДанные.Формат = ConsoleSignature;
	фОК = фОК И стЗагруженныеДанные.Свойство("Версия");

	If Не фОК Then
		ОшибкаКонсоли("Не верный формат файла!");
	EndIf;

	If стЗагруженныеДанные.Версия > FormatVersion Then
		ОшибкаКонсоли("Используется более новая версия формата. Обновите консоль запросов!");
	EndIf;
	
	//Сохраняемые состояния - Structure, предназначена для сохранения значений, которых нет в опциях (состояния флажков форм,
	//разных значений, и т.д.). Записывается в файл. Из файла читается только при первом открытии.
	If Не ValueIsFilled(Object.SavedStates) Then
		If стЗагруженныеДанные.Версия >= 11 Then
			Object.SavedStates = стЗагруженныеДанные.СохраняемыеСостояния;
		Иначе
			Object.SavedStates = New Structure;
		EndIf;
	EndIf;

	If Не стЗагруженныеДанные.Свойство("ПакетЗапросов") Then
		ДополнительныеПараметры.Вставить("ЗагруженныеДанные", стЗагруженныеДанные);
		ВыполнитьПродолжение(ДополнительныеПараметры);
		Return;
	EndIf;

	If стЗагруженныеДанные.Версия >= 2 Then
		стОпции = стЗагруженныеДанные.Опции;
		SaveCommentsOption = стОпции.SaveCommentsOption;
	Иначе
		SaveCommentsOption = True;
	EndIf;

	If стЗагруженныеДанные.Версия >= 3 Then
		AutoSaveIntervalOption = стОпции.ОпцияИнтервалАвтосохранения;
	Иначе
		AutoSaveIntervalOption = 60;
	EndIf;

	If стЗагруженныеДанные.Версия >= 6 Then
		AutoSaveBeforeQueryExecutionOption = стОпции.ОпцияАвтосохранениеПередВыполнениемЗапроса;
	Иначе
		AutoSaveBeforeQueryExecutionOption = True;
	EndIf;

	If стЗагруженныеДанные.Версия >= 8 Then
		Object.OptionProcessing__ = стОпции.OptionProcessing__;
	Иначе
		Object.OptionProcessing__ = True;
	EndIf;

	If стЗагруженныеДанные.Версия >= 10 Then
		Object.AlgorithmExecutionUpdateIntervalOption = стОпции.AlgorithmExecutionUpdateIntervalOption;
	Иначе
		Object.AlgorithmExecutionUpdateIntervalOption = 1000;
	EndIf;

	If стЗагруженныеДанные.Версия >= 12 Then
		TechLogSwitchingPollingPeriodOption = стОпции.TechLogSwitchingPollingPeriodOption;
	Иначе
		TechLogSwitchingPollingPeriodOption = 3;
	EndIf;

	If стЗагруженныеДанные.Версия >= 13 Then
		ИмяТекущегоЗапроса = стЗагруженныеДанные.ТекущийЗапрос;
	Иначе
		ИмяТекущегоЗапроса = Undefined;
	EndIf;

	QueryCount = стЗагруженныеДанные.QueryCount;

	QueryBatch.ПолучитьЭлементы().Очистить();
	ПакетЗапросов_ДобавитьСтрокиИзArrayа(QueryBatch, стЗагруженныеДанные.ПакетЗапросов);

	For Each ЭлементПакета Из QueryBatch.ПолучитьЭлементы() Do
		Элементы.QueryBatch.Развернуть(ЭлементПакета.ПолучитьИдентификатор(), True);
	EndDo;

	ПакетЗапросов_Инициализировать();

	ТекущаяСтрока = ПакетЗапросов_НайтиПоИмени(ИмяТекущегоЗапроса);
	If ТекущаяСтрока <> Undefined
		И Элементы.QueryBatch.ТекущаяСтрока <> ТекущаяСтрока Then
		Элементы.QueryBatch.ТекущаяСтрока = ТекущаяСтрока;
	EndIf;

	Модифицированность = False;

	ВосстановлениеПозицииРедактирования();

	ДополнительныеПараметры.Вставить("ЗагруженныеДанные", стЗагруженныеДанные);
	ВыполнитьПродолжение(ДополнительныеПараметры);

EndProcedure

Function ПакетЗапросов_НайтиПоИмени(ИмяЗапроса, Знач Узел = Undefined)

	If Узел = Undefined Then
		Узел = QueryBatch;
	EndIf;

	For Each Строка Из Узел.ПолучитьЭлементы() Do

		If Строка.Name = ИмяЗапроса Then
			Return Строка.ПолучитьИдентификатор();
		EndIf;

		ъ = ПакетЗапросов_НайтиПоИмени(ИмяЗапроса, Строка);
		If ъ <> Undefined Then
			Return ъ;
		EndIf;

	EndDo;

	Return Undefined;

EndFunction

#EndRegion

#Region Запрос

&AtClient
Function Запрос_ПолучитьДанныеЗапроса(идЗапрос)

	If идЗапрос = Undefined Then
		Return New Structure("Имя, Запрос, ТекстКод, CodeExecutionMethod, Параметры, InWizard, CursorBeginRow, CursorBeginColumn, CursorEndRow, CursorEndColumn, CodeCursorBeginRow, CodeCursorBeginColumn, CodeCursorEndRow, CodeCursorEndColumn",
			"", "", "", 2, Undefined, False, 1, 1, 1, 1, 1, 1, 1, 1);
	EndIf;

	СтрокаЗапроса = QueryBatch.НайтиПоИдентификатору(идЗапрос);
	Return New Structure("Имя, Запрос, ТекстКод, CodeExecutionMethod, Параметры, TempTables, InWizard, CursorBeginRow, CursorBeginColumn, CursorEndRow, CursorEndColumn, CodeCursorBeginRow, CodeCursorBeginColumn, CodeCursorEndRow, CodeCursorEndColumn",
		СтрокаЗапроса.Name, СтрокаЗапроса.ТекстЗапроса, СтрокаЗапроса.ТекстКод, СтрокаЗапроса.CodeExecutionMethod,
		СтрокаЗапроса.QueryParameters, СтрокаЗапроса.TempTables, СтрокаЗапроса.InWizard,
		СтрокаЗапроса.CursorBeginRow + 1, СтрокаЗапроса.CursorBeginColumn + 1, СтрокаЗапроса.CursorEndRow
		+ 1, СтрокаЗапроса.CursorEndColumn + 1, СтрокаЗапроса.CodeCursorBeginRow + 1,
		СтрокаЗапроса.CodeCursorBeginColumn + 1, СтрокаЗапроса.CodeCursorEndRow + 1,
		СтрокаЗапроса.CodeCursorEndColumn + 1);

EndFunction

&AtClient
Procedure Запрос_ПоместитьДанныеЗапроса(идЗапрос, стрТекстЗапроса, стрТекстКод = Undefined,
	CodeExecutionMethod = Undefined, сзПараметрыЗапроса = Undefined, сзВременныеТаблицы = Undefined,
	CursorBeginRow = Undefined, CursorBeginColumn = Undefined, CursorEndRow = Undefined,
	CursorEndColumn = Undefined, CodeCursorBeginRow = Undefined, CodeCursorBeginColumn = Undefined,
	CodeCursorEndRow = Undefined, CodeCursorEndColumn = Undefined)

	СтрокаЗапроса = QueryBatch.НайтиПоИдентификатору(идЗапрос);
	If СтрокаЗапроса = Undefined Then
		Return;
	EndIf;

	СтрокаЗапроса.ТекстЗапроса = стрТекстЗапроса;

	If стрТекстКод <> Undefined Then
		СтрокаЗапроса.ТекстКод = стрТекстКод;
	EndIf;

	If сзПараметрыЗапроса <> Undefined Then
		СтрокаЗапроса.QueryParameters = сзПараметрыЗапроса;
	EndIf;

	If сзВременныеТаблицы <> Undefined Then
		СтрокаЗапроса.TempTables = сзВременныеТаблицы;
	EndIf;

	If CodeExecutionMethod <> Undefined Then
		СтрокаЗапроса.CodeExecutionMethod = CodeExecutionMethod;
	EndIf;

	If CursorBeginRow <> Undefined Then
		СтрокаЗапроса.CursorBeginRow = CursorBeginRow - 1;
	EndIf;

	If CursorBeginColumn <> Undefined Then
		СтрокаЗапроса.CursorBeginColumn = CursorBeginColumn - 1;
	EndIf;

	If CursorEndRow <> Undefined Then
		СтрокаЗапроса.CursorEndRow = CursorEndRow - 1;
	EndIf;

	If CursorEndColumn <> Undefined Then
		СтрокаЗапроса.CursorEndColumn = CursorEndColumn - 1;
	EndIf;

	If CodeCursorBeginRow <> Undefined Then
		СтрокаЗапроса.CodeCursorBeginRow = CodeCursorBeginRow - 1;
	EndIf;

	If CodeCursorBeginColumn <> Undefined Then
		СтрокаЗапроса.CodeCursorBeginColumn = CodeCursorBeginColumn - 1;
	EndIf;

	If CodeCursorEndRow <> Undefined Then
		СтрокаЗапроса.CodeCursorEndRow = CodeCursorEndRow - 1;
	EndIf;

	If CodeCursorEndColumn <> Undefined Then
		СтрокаЗапроса.CodeCursorEndColumn = CodeCursorEndColumn - 1;
	EndIf;

EndProcedure

&AtClient
Procedure Запрос_УстановитьВКонструкторе(идЗапрос, фВКонструкторе)
	QueryBatch.НайтиПоИдентификатору(идЗапрос).InWizard = фВКонструкторе;
EndProcedure

&AtClient
Function Запрос_ПолучитьВКонструкторе(идЗапрос)
	Return QueryBatch.НайтиПоИдентификатору(идЗапрос).InWizard;
EndFunction

#EndRegion

#Region ОбработкаКомментариевЗапроса

&AtClient
Procedure КомментарииЗапроса_СохранитьДанныеИсходногоЗапроса(стрТекстЗапроса)

	If Не SaveCommentsOption Then
		Return;
	EndIf;

	CommentsData = стрТекстЗапроса;

EndProcedure

&AtClient
Function КомментарииЗапроса_СтрокаБезКомментариев(стр)

	чПозицияКомментария = Найти(стр, "//");

	If чПозицияКомментария = 0 Then
		Return стр;
	EndIf;

	Return Лев(стр, чПозицияКомментария - 1);

EndFunction

&AtClient
Function КомментарииЗапроса_КомментарийСтроки(стр)

	чПозицияКомментария = Найти(стр, "//");

	If чПозицияКомментария = 0 Then
		Return "";
	EndIf;

	Return Прав(стр, StrLen(стр) - чПозицияКомментария + 1);

EndFunction

&AtClient
Procedure КомментарииЗапроса_Восстановить(стрТекстЗапроса)

	If Не SaveCommentsOption Then
		Return;
	EndIf;

	чГлубинаПоиска = 50;

	ИсходныйЗапрос = New ТекстовыйДокумент;
	ИсходныйЗапросУпр = New Array;
	NewЗапрос = New ТекстовыйДокумент;
	РезультатЗапрос = New ТекстовыйДокумент;
	ИсходныйЗапрос.УстановитьТекст(CommentsData);
	NewЗапрос.УстановитьТекст(стрТекстЗапроса);
	чКоличествоСтрокНового = NewЗапрос.КоличествоСтрок();
	чКоличествоСтрокИсходного = ИсходныйЗапрос.КоличествоСтрок();

	Для й = 1 По чКоличествоСтрокИсходного Do
		ИсходныйЗапросУпр.Добавить(ВРег(СокрЛП(КомментарииЗапроса_СтрокаБезКомментариев(ИсходныйЗапрос.ПолучитьСтроку(
			й)))));
	EndDo;

	чСтрокаИсходного = 1;
	чСтрокаНового = 1;
	
	//начальные комментарии переносим до поиска
	Пока чСтрокаИсходного <= чКоличествоСтрокИсходного Do
		стрИсходного = ИсходныйЗапрос.ПолучитьСтроку(чСтрокаИсходного);
		If Лев(СокрЛП(стрИсходного), 2) = "//" Then
			РезультатЗапрос.ДобавитьСтроку(стрИсходного);
		Иначе
			Прервать;
		EndIf;
		чСтрокаИсходного = чСтрокаИсходного + 1;
	EndDo;

	Пока чСтрокаНового <= чКоличествоСтрокНового Do

		стрНового = NewЗапрос.ПолучитьСтроку(чСтрокаНового);

		чНайденнаяСтрокаИсходного = 0;
		If ValueIsFilled(стрНового) Then
			чСтрокИскать = ?(чСтрокаИсходного + чГлубинаПоиска < чКоличествоСтрокИсходного, чГлубинаПоиска,
				чКоличествоСтрокИсходного - чСтрокаИсходного);
			стрНовогоУпр = ВРег(СокрЛП(стрНового));
			Для й = чСтрокаИсходного По чСтрокаИсходного + чСтрокИскать Do
				If стрНовогоУпр = ИсходныйЗапросУпр[й - 1] Then
					чНайденнаяСтрокаИсходного = й;
					Прервать;
				EndIf;
			EndDo;
		EndIf;

		If чНайденнаяСтрокаИсходного > 0 Then

			Для й = 0 По чНайденнаяСтрокаИсходного - чСтрокаИсходного - 1 Do

				стрИсходного = ИсходныйЗапрос.ПолучитьСтроку(чСтрокаИсходного + й);

				If Лев(СокрЛ(стрИсходного), 2) = "//" Then
					If Не ПустаяСтрока(СтрЗаменить(стрИсходного, "/", "")) Then
						РезультатЗапрос.ДобавитьСтроку(стрИсходного);
					EndIf;
					Продолжить;
				EndIf;

				If ValueIsFilled(КомментарииЗапроса_КомментарийСтроки(стрИсходного)) Then
					If Лев(СокрЛП(стрИсходного), 2) = "//" Then
						РезультатЗапрос.ДобавитьСтроку(стрИсходного);
					Иначе
						РезультатЗапрос.ДобавитьСтроку("//" + стрИсходного);
					EndIf;
				EndIf;

			EndDo;

			стрКомментарий = КомментарииЗапроса_КомментарийСтроки(ИсходныйЗапрос.ПолучитьСтроку(
				чНайденнаяСтрокаИсходного));
			РезультатЗапрос.ДобавитьСтроку(стрНового + стрКомментарий);
			чСтрокаИсходного = чНайденнаяСтрокаИсходного + 1;

		Иначе
			РезультатЗапрос.ДобавитьСтроку(стрНового);
		EndIf;

		чСтрокаНового = чСтрокаНового + 1;

	EndDo;
	
	//теперь все что осталось из исходного
	Для й = чСтрокаИсходного По чКоличествоСтрокИсходного Do
		стрИсходного = ИсходныйЗапрос.ПолучитьСтроку(й);
		If ValueIsFilled(КомментарииЗапроса_КомментарийСтроки(стрИсходного)) Then
			If Лев(СокрЛП(стрИсходного), 2) = "//" Then
				РезультатЗапрос.ДобавитьСтроку(стрИсходного);
			Иначе
				РезультатЗапрос.ДобавитьСтроку("//" + стрИсходного);
			EndIf;
		EndIf;
	EndDo;

	стрТекстЗапроса = РезультатЗапрос.ПолучитьТекст();

EndProcedure

#EndRegion

#Region ОбработкаПараметровВТекстеЗапроса

&AtClient
Function ПолучитьСимволыКонцаПараметра()
	Return ",+-*/<>=) " + Символы.ПС + Символы.ВК + Символы.Таб;
EndFunction

&AtClient
Function ЕстьПараметр(стрТекстЗапроса, стрИмяПараметра)

	стрСимволыКонцаПараметра = ПолучитьСимволыКонцаПараметра();
	чДлиннаПараметра = StrLen(стрИмяПараметра);
	чДлиннаТекста = StrLen(стрТекстЗапроса);
	п = 1;
	Пока п <= чДлиннаТекста Do
		п = СтрНайти(стрТекстЗапроса, стрИмяПараметра, , п);
		If п = 0 Then
			Прервать;
		EndIf;
		с = Сред(стрТекстЗапроса, п + чДлиннаПараметра, 1);
		If с = "" Или Найти(стрСимволыКонцаПараметра, с) > 0 Then
			Return True;
		EndIf;
		п = п + чДлиннаПараметра;
	EndDo;

	Return False;

EndFunction

&AtClient
Function ЗаменитьПараметр(стрТекстЗапроса, стрСтароеИмяПараметра, стрНовоеИмяПараметра)

	стрСимволыКонцаПараметра = ПолучитьСимволыКонцаПараметра();
	чДлиннаПараметра = StrLen(стрСтароеИмяПараметра);
	чДлиннаТекста = StrLen(стрТекстЗапроса);
	маЧасти = New Array;
	п = 1;
	Пока п <= чДлиннаТекста Do
		п1 = СтрНайти(стрТекстЗапроса, стрСтароеИмяПараметра, , п);
		If п1 = 0 Then
			маЧасти.Добавить(Сред(стрТекстЗапроса, п));
			Прервать;
		EndIf;
		с = Сред(стрТекстЗапроса, п1 + чДлиннаПараметра, 1);
		If с = "" Или Найти(стрСимволыКонцаПараметра, с) > 0 Then
			маЧасти.Добавить(Сред(стрТекстЗапроса, п, п1 - п));
			маЧасти.Добавить(стрНовоеИмяПараметра);
		Иначе
			маЧасти.Добавить(Сред(стрТекстЗапроса, п, п1 - п + чДлиннаПараметра));
		EndIf;
		п = п1 + чДлиннаПараметра;
	EndDo;

	Return StrConcat(маЧасти);

EndFunction

#EndRegion

#Region СобытияФормы

&AtClient
Procedure ПодключитьОбработчикАвтосохранения()
	If AutoSaveIntervalOption > 0 Then
		ПодключитьОбработчикОжидания("ОбработчикАвтосохранения", AutoSaveIntervalOption);
	Иначе
		ОтключитьОбработчикОжидания("ОбработчикАвтосохранения");
	EndIf;
EndProcedure

&AtClient
Procedure ЗакончитьПолучениеРабочегоКаталогаДанныхПользователя(UserDataDirectory, ДополнительныеПараметры) Экспорт
	ДополнительныеПараметры.Вставить("UserDataDirectory", UserDataDirectory);
	ВыполнитьПродолжение(ДополнительныеПараметры);
EndProcedure

&AtClient
Procedure ЗакончитьПроверкуСуществования(Существует, ДополнительныеПараметры) Экспорт
	ДополнительныеПараметры.Вставить("Существует", Существует);
	ВыполнитьПродолжение(ДополнительныеПараметры);
EndProcedure

&AtClient
Procedure OnOpen(Отказ)
	
	//If Доступность выключить в веб-клиенте при создании на сервере, она работает по другому, чем для обычных клиентов.
	//Поэтому только так.
	Доступность = False;

#If ВебКлиент Then

	Оповещение = New ОписаниеОповещения("ПослеЗавершенияПодключенияРасширенияРаботыСФайлами", ЭтотОбъект);
	НачатьПодключениеРасширенияРаботыСФайлами(Оповещение);

	ОтобразитьСостояниеВыполненияАлгоритма();

#Иначе

		ОтобразитьСостояниеВыполненияАлгоритма();
		ПриОткрытииПродолжение();

#EndIf

EndProcedure

&AtClient
Procedure ПослеЗавершенияПодключенияРасширенияРаботыСФайлами(Подключено, ДополнительныеПараметры) Экспорт

	FileExtensionConnected = Подключено;

	If Не FileExtensionConnected Then
		ShowConsoleMessageBox("Для работы консоли необходимо установить расширение работы с файлами.");
		НачатьУстановкуРасширенияРаботыСФайлами();
		Закрыть();
		Return;
	EndIf;

	ПриОткрытииПродолжение();

EndProcedure

&AtClient
Procedure ПриОткрытииПродолжение(ДополнительныеПараметры = Undefined) Экспорт

	If Не ValueIsFilled(ДополнительныеПараметры) Then

		ДополнительныеПараметры = New Structure("Продолжение, ТочкаПродолжения", "ПриОткрытииПродолжение",
			"ПослеПолученияРабочегоКаталога");
		ОписаниеОповещения = New ОписаниеОповещения("ЗакончитьПолучениеРабочегоКаталогаДанныхПользователя", ЭтаФорма,
			ДополнительныеПараметры);
		НачатьПолучениеРабочегоКаталогаДанныхПользователя(ОписаниеОповещения);
		Return;

	ElsIf ДополнительныеПараметры.ТочкаПродолжения = "ПослеПолученияРабочегоКаталога" Then

		UserDataDirectory = ДополнительныеПараметры.UserDataDirectory;
		StateAutoSaveFileName = UserDataDirectory + ConsoleSignature + "." + AutoSaveExtension;

		стрИмяФайлаАвтосохраненияТемп = StateAutoSaveFileName;
		Файл = New Файл(стрИмяФайлаАвтосохраненияТемп);
		ДополнительныеПараметры = New Structure("Продолжение, ТочкаПродолжения", "ПриОткрытииПродолжение",
			"ПослеПроверкиСуществованияСохранения");
		ОписаниеОповещения = New ОписаниеОповещения("ЗакончитьПроверкуСуществования", ЭтаФорма,
			ДополнительныеПараметры);
		Файл.НачатьПроверкуСуществования(ОписаниеОповещения);
		Return;

	ElsIf ДополнительныеПараметры.ТочкаПродолжения = "ПослеПроверкиСуществованияСохранения" Then
		If UT_Debug Then
			УстановитьQueriesFileName();
			ПриОткрытииЗавершение();
			Return;
		EndIf;

		If Не ДополнительныеПараметры.Существует Then
			ПакетЗапросов_New();
			ПриОткрытииЗавершение();
			Return;
		EndIf;

		стрИмяФайлаАвтосохраненияТемп = StateAutoSaveFileName;
		Try
			ДополнительныеПараметры = New Structure("Продолжение, ТочкаПродолжения, ИмяФайла",
				"ПриОткрытииПродолжение", "ПослеЗагрузкиЗаголовка", стрИмяФайлаАвтосохраненияТемп);
			ПакетЗапросов_Загрузить(ДополнительныеПараметры);
		Except
			//Состояние прочитать не удалось, файл испорчен.
			ПакетЗапросов_New();
			ПриОткрытииЗавершение();
		EndTry;

		Return;

	ElsIf ДополнительныеПараметры.ТочкаПродолжения = "ПослеЗагрузкиЗаголовка" Then

		стЗаголовок = ДополнительныеПараметры.ЗагруженныеДанные;
		If стЗаголовок = Undefined Then
			//Состояние прочитать не удалось, файл испорчен.
			ПакетЗапросов_New();
			ПриОткрытииЗавершение();
			Return;
		EndIf;

		If стЗаголовок.Свойство("ПакетЗапросов") Then

			Модифицированность = True;
			ПриОткрытииЗавершение();//Загружено автосохранение из темп, список запросов в файл не сохранялся.
			Return;

		Иначе

			QueriesFileName = стЗаголовок.ИмяФайла;
			УстановитьQueriesFileName(QueriesFileName);
			стрИмяФайлаАвтосохранения = GetAutoSaveFileName(QueriesFileName);

			Файл = New Файл(стрИмяФайлаАвтосохранения);
			ДополнительныеПараметры = New Structure("Продолжение, ТочкаПродолжения, ИмяФайлаАвтосохранения",
				"ПриОткрытииПродолжение", "ПослеПроверкиСуществованияАвтосохранения", стрИмяФайлаАвтосохранения);
			ОписаниеОповещения = New ОписаниеОповещения("ЗакончитьПроверкуСуществования", ЭтаФорма,
				ДополнительныеПараметры);
			Файл.НачатьПроверкуСуществования(ОписаниеОповещения);
			Return;

		EndIf;

	ElsIf ДополнительныеПараметры.ТочкаПродолжения = "ПослеПроверкиСуществованияАвтосохранения" Then

		Try
			If ДополнительныеПараметры.Существует Then
				стрИмяФайлаАвтосохранения = ДополнительныеПараметры.ИмяФайлаАвтосохранения;
				ДополнительныеПараметры = New Structure("Продолжение, ТочкаПродолжения, ИмяФайла",
					"ПриОткрытииПродолжение", "ПослеЗагрузкиАвтосохранения", стрИмяФайлаАвтосохранения);
				ПакетЗапросов_Загрузить(ДополнительныеПараметры);
				Return;
			EndIf;
		Except
			//Автосохранение не загрузили - файл испорчен. Грузим основной файл.
		EndTry;

		ДополнительныеПараметры = New Structure("Продолжение, ТочкаПродолжения, ЗагруженныеДанные",
			"ПриОткрытииПродолжение", "ПослеЗагрузкиАвтосохранения");
		ВыполнитьПродолжение(ДополнительныеПараметры);
		Return;

	ElsIf ДополнительныеПараметры.ТочкаПродолжения = "ПослеЗагрузкиАвтосохранения" Then

		If ДополнительныеПараметры.ЗагруженныеДанные <> Undefined Then
			Модифицированность = True;
			ПриОткрытииЗавершение();//Загружено из автосохранения измененного файла.
			Return;
		EndIf;

		Файл = New Файл(QueriesFileName);
		ДополнительныеПараметры = New Structure("Продолжение, ТочкаПродолжения", "ПриОткрытииПродолжение",
			"ПослеПроверкиСуществованияФайла");
		ОписаниеОповещения = New ОписаниеОповещения("ЗакончитьПроверкуСуществования", ЭтаФорма,
			ДополнительныеПараметры);
		Файл.НачатьПроверкуСуществования(ОписаниеОповещения);

	ElsIf ДополнительныеПараметры.ТочкаПродолжения = "ПослеПроверкиСуществованияФайла" Then

		If ДополнительныеПараметры.Существует Then
			ДополнительныеПараметры = New Structure("Продолжение, ТочкаПродолжения, ИмяФайла",
				"ПриОткрытииПродолжение", "ПослеЗагрузкиОсновногоФайла", QueriesFileName);
			ПакетЗапросов_Загрузить(ДополнительныеПараметры);
			Return;
		Иначе
			ПакетЗапросов_New();
			ПриОткрытииЗавершение();//Не найден файл, который в информации последнего состояния (Varещен или удален). Значит, будет New пакет.
			Return;
		EndIf;

	ElsIf ДополнительныеПараметры.ТочкаПродолжения = "ПослеЗагрузкиОсновногоФайла" Then

		If ДополнительныеПараметры.ЗагруженныеДанные = Undefined Then
			ПакетЗапросов_New();
		EndIf;

		ПриОткрытииЗавершение();//Загружено из основного файла.
		Return;

	EndIf;

EndProcedure

&AtServer
Procedure ПриОткрытииЗавершениеAtServer()

	Обработка = РеквизитФормыВЗначение("Object");
	
	//Сохраняемые значения +++

	ResultKind = СохраняемыеСостояния_ПолучитьAtServer("ResultKind", "таблица");
	OutputLinesLimit = СохраняемыеСостояния_ПолучитьAtServer("OutputLinesLimit", "1000");
	OutputLinesLimitEnabled = СохраняемыеСостояния_ПолучитьAtServer("OutputLinesLimitEnabled", True);
	OutputLinesLimitTop = СохраняемыеСостояния_ПолучитьAtServer("OutputLinesLimitTop", 1000);
	OutputLinesLimitTopEnabled = СохраняемыеСостояния_ПолучитьAtServer("OutputLinesLimitTopEnabled",
		False);

	фВидимостьПакетаРезультатаЗапроса = СохраняемыеСостояния_ПолучитьAtServer("ВидимостьПакетаРезультатаЗапроса", False);
	If Элементы.ShowHideQueryResultBatch.Пометка <> фВидимостьПакетаРезультатаЗапроса Then
		Элементы.ShowHideQueryResultBatch.Пометка = фВидимостьПакетаРезультатаЗапроса;
		Элементы.QueryResultBatch.Видимость = фВидимостьПакетаРезультатаЗапроса;
		Элементы.ResultInBatchGroup.Видимость = Не фВидимостьПакетаРезультатаЗапроса;
	EndIf;

	фПараметрыЗапросаРядомСТекстом = СохраняемыеСостояния_ПолучитьAtServer("ПараметрыЗапросаРядомСТекстом", True);
	If Элементы.QueryParametersNextToText.Пометка <> фПараметрыЗапросаРядомСТекстом Then
		Элементы.QueryParametersNextToText.Пометка = фПараметрыЗапросаРядомСТекстом;
		ПараметрыЗапросаРядомСТекстомAtServer();
	EndIf;
	
	//Сохраняемые значения ---
	
	//При проверке ТЖ в момент запуска маскируем все исключения.
	//Может быть нехватка прав, или что-то другое, а ТЖ реально вообще не нужен.
	Try
		If Обработка.TechnologicalLog_ConsoleLogExists() Then
			Элементы.TechnologicalLog.Пометка = True;
		EndIf;
	Except
	EndTry;

	ЗначениеВРеквизитФормы(Обработка, "Object");

EndProcedure

&AtClient
Procedure ПриОткрытииЗавершение()

	ПриОткрытииЗавершениеAtServer();
	GetDataProcessorServerFileName();
	ПодключитьОбработчикАвтосохранения();
	УстановитьСостоянияЭлементов();

	If Элементы.TechnologicalLog.Пометка Then
		TechLogBeginEndTime = ТекущаяУниверсальнаяДатаВМиллисекундах();
		TechnologicalLog_Enabled(); // Что бы выполнился тестовый запрос, а через 1 секунду уже проверим результат.
		ПодключитьОбработчикОжидания("ТехнологическийЖурнал_ОжиданиеВключения", 1, True);
	EndIf;
	
	//Почему-то релиз 8.3.17 без режима совместимости не устанавливает изначально текущую строку.
	If Элементы.QueryBatch.ТекущаяСтрока = Undefined И QueryBatch.ПолучитьЭлементы().Количество() > 0 Then
		Элементы.QueryBatch.ТекущаяСтрока = QueryBatch.ПолучитьЭлементы()[0].ПолучитьИдентификатор();
	EndIf;

	If Не Object.ExternalDataProcessorMode Then
		AllowHooking();
		AllowBackgroundExecution();
	EndIf;

	Доступность = True;

#Region УИ_ПриОткрытии
	If UT_CommonClientServer.HTMLFieldBasedOnWebkit() Then
		Элементы.CodeCommandBarGroup.Видимость = False;
	EndIf;
	UT_CodeEditorClient.ФормаПриОткрытии(ЭтотОбъект);
#EndRegion

EndProcedure

&AtServer
Procedure OnCreateAtServer(Отказ, СтандартнаяОбработка)

	ОбъектОбработки = РеквизитФормыВЗначение("Object");
	ОбъектОбработки.Initializing(ЭтаФорма);
	ЗначениеВРеквизитФормы(ОбъектОбработки, "Object");

	QueryInWizard = -1;
	EditingQuery = -1;
	
	//UsedFileName = РеквизитФормыВЗначение("Объект").UsedFileName;

	Элементы.TempTablesValue.КартинкаКнопкиВыбора = БиблиотекаКартинок.Изменить;

	Object.Title = "Консоль запросов 9000 v" + Object.DataProcessorVersion;

	MacroParameter = "__";
	
	//Это нужно для правильной отрисовки области результата запроса до его выполнения.
	маДобавляемыеРеквизиты = New Array;
	Реквизит = New РеквизитФормы("Пустой", New ОписаниеТипов, "РезультатЗапроса");
	маДобавляемыеРеквизиты.Добавить(Реквизит);
	ИзменитьРеквизиты(маДобавляемыеРеквизиты);
	Элемент = Элементы.Добавить("Пустой", Тип("ПолеФормы"), Элементы.QueryResult);
	Элемент.ПутьКДанным = "РезультатЗапроса.Пустой";
	Элемент.ОтображатьВШапке = False;

	ContainerAttributeSuffix=ОбъектОбработки.ContainerAttributeSuffix();

#Region УИ_ПриСозданииAtServer
	UT_IsPartOfUniversalTools = ОбъектОбработки.DataProcessorIsPartOfUniversalTools();
	If UT_IsPartOfUniversalTools Then
		UT_Common.ФормаИнструментаПриСозданииAtServer(ЭтотОбъект, Отказ, СтандартнаяОбработка,
			Элементы.FormCommandBarRight);

		Object.Title="";
		Заголовок="";
		АвтоЗаголовок=True;
		Элементы.QueryBatchHookingSubmenu.Видимость=False;
		Элементы.QueryCommandBarGroupRightHooking.Видимость=False;
		Элементы.ResultKindCommandBar.ЦветФона=New Цвет;

		Элементы.UT_EditValue.Видимость=True;
		Элементы.QueryResultContextMenuUT_EditValue.Видимость=True;
		Элементы.QueryResultTreeContextMenuUT_EditValue.Видимость=True;

		УИ_ЗаполнитьДаннымиОтладки();

		UT_CodeEditorServer.ФормаПриСозданииAtServer(ЭтотОбъект);
		UT_CodeEditorServer.СоздатьЭлементыРедактораКода(ЭтотОбъект, "Алгоритм", Элементы.AlgorithmText);
	EndIf;
#EndRegion

EndProcedure

&AtClient
Procedure ОбработчикАвтосохранения() Экспорт

	If Модифицированность Then
		Автосохранить();
	EndIf;

EndProcedure

&AtClient
Procedure BeforeClose(Отказ, ЗавершениеРаботы, ТекстПредупреждения, СтандартнаяОбработка)

#If ВебКлиент Then
	If Не FileExtensionConnected Then
		Return;
	EndIf;
#EndIf

	If ЗавершениеРаботы = True Then
		
		//Тут серверные вызовы запрещены. Максимум, что можно сделать - это предупреждения.

		ТекстПредупреждения = "";
		If Модифицированность Then
			//Тут будет предупреждение о не сохраненном запросе.
			ТекстПредупреждения = "В консоли запросов 9000 имеется не сохраненный пакет запросов! ";
			Отказ = True;
		EndIf;

		If Элементы.TechnologicalLog.Пометка Then
			ТекстПредупреждения = ТекстПредупреждения + "Технологический журнал не выключен! ";
			Отказ = True;
		EndIf;

		If Не ValueIsFilled(ТекстПредупреждения) Then
			//Лучше всегда консоль закрывать руками, для сохранения состояния.
			ТекстПредупреждения = "Для сохранения состояний консоль запросов 9000 рекомендуется закрывать вручную.";
			Отказ = True;
		EndIf;

	Иначе
		
		//Сохраним состояние.
		ПакетЗапросов_Сохранить( , StateAutoSaveFileName, True);

		If Не СохранитьСВопросом("Завершение") Then
			Отказ = True;
		EndIf;

		If Не Отказ И Элементы.TechnologicalLog.Пометка Then
			Команда_ТехнологическийЖурнал(Undefined);
		EndIf;

	EndIf;

EndProcedure

#EndRegion

#Region СобытияЭлементовФормы

&AtClient
Procedure ИзменитьИмяПараметраВТекстеЗапроса(РезультатВопроса, ДополнительныеПараметры) Экспорт
	If РезультатВопроса = КодReturnаДиалога.Да Then
		QueryText = ЗаменитьПараметр(QueryText, "&" + ДополнительныеПараметры.PreviousValueParameterName, "&"
			+ ДополнительныеПараметры.ИмяПараметра);
	EndIf;
EndProcedure

&AtClient
Procedure ОбработатьИзменениеИмениПараметра(НоваяСтрока, ОтменаРедактирования, Отказ)

	If ОтменаРедактирования Then
		Return;
	EndIf;

	стрИмяПараметра = Элементы.QueryParameters.ТекущиеДанные.Имя;
	If ValueIsFilled(стрИмяПараметра) И стрИмяПараметра = PreviousValueParameterName Then
		Return;
	EndIf;

	If Не NameIsCorrect(стрИмяПараметра) Then
		ShowConsoleMessageBox(
			"Неверное имя параметра! Имя должно состоять из одного слова, начинаться с буквы и не содержать специальных символов кроме ""_"".");
		Отказ = True;
		Return;
	EndIf;

	маСтрокиИмени = QueryParameters.НайтиСтроки(New Structure("Имя", стрИмяПараметра));
	If маСтрокиИмени.Количество() > 1 Then
		ShowConsoleMessageBox("Параметр с таким именем уже есть! Введите другое имя.");
		Отказ = True;
		Return;
	EndIf;

	If Не НоваяСтрока И ValueIsFilled(PreviousValueParameterName) Then
		стрТекстЗапроса = QueryText;
		If ЕстьПараметр(стрТекстЗапроса, "&" + PreviousValueParameterName) Then
			ДополнительныеПараметры = New Structure("PreviousValueParameterName, ИмяПараметра",
				PreviousValueParameterName, стрИмяПараметра);
			ПоказатьВопрос(
				New ОписаниеОповещения("ИзменитьИмяПараметраВТекстеЗапроса", ЭтаФорма, ДополнительныеПараметры),
				"Запрос содержит изменяемое мия параметра. Изменить имя параметра в тексте запроса?",
				РежимДиалогаВопрос.ДаНет, , КодReturnаДиалога.Да);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure QueryParametersBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)

	ОбработатьИзменениеИмениПараметра(NewRow, CancelEdit, Cancel);

EndProcedure

//&AtClient
//Procedure ПараметрыЗапросаПриНачалеРедактирования(Элемент, НоваяСтрока, Копирование)
//EndProcedure

&AtClient
Procedure QueryBatchOnEditEnd(Item, NewRow, CancelEdit)
	PreviousValueParameterName = "";
EndProcedure

&AtClient
Procedure QueryBatchBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)

	ИмяЗапроса = Item.ТекущиеДанные.Name;

	Строка = FindInTree(QueryBatch, "Имя", ИмяЗапроса, Item.ТекущаяСтрока);
	If Строка <> Undefined Then
		ShowConsoleMessageBox("Запрос с таким именем уже есть! Введите другое имя.");
		Cancel = True;
		Return;
	EndIf;

EndProcedure

&AtClient
Procedure QueryBatchOnActivateRow(Item)

	ТекущиеДанные = Элементы.QueryBatch.ТекущиеДанные;

	If Элементы.QueryBatch.ТекущаяСтрока = EditingQuery Then
		Return;
	EndIf;

	If ТекущиеДанные <> Undefined И Не ТекущиеДанные.Initialized Then
		ИнициализироватьЗапрос(Элементы.QueryBatch.ТекущиеДанные);
		ИзвлечьРедактируемыйЗапрос( , False);
	Иначе
		ИзвлечьРедактируемыйЗапрос();
	EndIf;

EndProcedure

&AtClient
Procedure QueryBatchSelection(Item, SelectedRow, Field, StandardProcessing)
	ВыполнитьЗапрос(False);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure QueryTextOnChange(Item)
	ПоместитьРедактируемыйЗапрос();
EndProcedure

&AtClient
Procedure QueryParametersOnChange(Item)
	ПоместитьРедактируемыйЗапрос();
EndProcedure

&AtClient
Procedure QueryParametersValueStartChoice(Item, ChoiceData, StandardProcessing)

	ТекущиеДанные = Item.Родитель.ТекущиеДанные;

	If ТекущиеДанные.ТипКонтейнера > 0 Then

		StandardProcessing = False;
		ПараметрыОповещения = New Structure("Таблица, Строка, Поле", "QueryParameters",
			Item.Родитель.ТекущаяСтрока, "Контейнер");
		ОписаниеОповещенияОЗакрытииОткрываемойФормы = New ОписаниеОповещения("ОкончаниеРедактированияСтроки",
			ЭтаФорма, ПараметрыОповещения);
		ПараметрыОткрытия = New Structure("Объект, ТипЗначения, Заголовок, Значение, ТипКонтейнера", Object,
			ТекущиеДанные.ТипЗначения, ТекущиеДанные.Имя, ТекущиеДанные.Контейнер, ТекущиеДанные.ТипКонтейнера);

		If ТекущиеДанные.ТипКонтейнера = 3 Then
			ИмяФормыРедактирования = "РедактированиеТаблицы";
		Иначе
			ИмяФормыРедактирования = "ПодборВСписок";
		EndIf;

		ОткрытьФорму(FormFullName(ИмяФормыРедактирования), ПараметрыОткрытия, ЭтаФорма, False, , ,
			ОписаниеОповещенияОЗакрытииОткрываемойФормы, РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);

	ElsIf ТипЗнч(ТекущиеДанные.Контейнер) = Тип("Structure") Then

		If ТекущиеДанные.Контейнер.Тип = "МоментВремени" Или ТекущиеДанные.Контейнер.Тип = "Граница" Then
			StandardProcessing = False;
			ПараметрыОповещения = New Structure("Таблица, Строка, Поле", "QueryParameters",
				Item.Родитель.ТекущаяСтрока, "Контейнер");
			ОписаниеОповещенияОЗакрытииОткрываемойФормы = New ОписаниеОповещения("ОкончаниеРедактированияСтроки",
				ЭтаФорма, ПараметрыОповещения);
			ПараметрыОткрытия = New Structure("Объект, Значение", Object, ТекущиеДанные.Контейнер);
			ОткрытьФорму(FormFullName("РедактированиеГраницыМомента"), ПараметрыОткрытия, ЭтаФорма, False, , ,
				ОписаниеОповещенияОЗакрытииОткрываемойФормы, РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);
		ElsIf ТекущиеДанные.Контейнер.Тип = "Тип" Then
			StandardProcessing = False;
			ПараметрыОповещения = New Structure("Таблица, Строка, Поле", "QueryParameters",
				Item.Родитель.ТекущаяСтрока, "КонтейнерКакТип");
			ОписаниеОповещенияОЗакрытииОткрываемойФормы = New ОписаниеОповещения("ОкончаниеРедактированияСтроки",
				ЭтаФорма, ПараметрыОповещения);
			ПараметрыОткрытия = New Structure("Объект, ТипЗначения, ТипКонтейнера", Object, ТекущиеДанные.Контейнер,
				ТекущиеДанные.ТипКонтейнера);
			ОткрытьФорму(FormFullName("РедактированиеТипа"), ПараметрыОткрытия, ЭтаФорма, True, , ,
				ОписаниеОповещенияОЗакрытииОткрываемойФормы, РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);
		EndIf;

	Иначе
		If ТипЗнч(ТекущиеДанные.Значение) = Тип("УникальныйИдентификатор") Then
			StandardProcessing = False;
			ПараметрыОповещения = New Structure("Таблица, Строка, Поле", "QueryParameters",
				Item.Родитель.ТекущаяСтрока, "Значение");
			ОписаниеОповещенияОЗакрытииОткрываемойФормы = New ОписаниеОповещения("ОкончаниеРедактированияСтроки",
				ЭтаФорма, ПараметрыОповещения);
			ПараметрыОткрытия = New Structure("Объект, Значение", Object, ТекущиеДанные.Значение);
			ОткрытьФорму(FormFullName("РедактированиеУникальногоИдентификатора"), ПараметрыОткрытия, ЭтаФорма,
				True, , , ОписаниеОповещенияОЗакрытииОткрываемойФормы,
				РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure УстановитьПараметрыВводаЗначения()

	ТекущиеДанные = Элементы.QueryParameters.ТекущиеДанные;

	If ТекущиеДанные <> Undefined Then

		Элементы.QueryParametersValue.КартинкаКнопкиВыбора = New Картинка;

		If ValueIsFilled(ТекущиеДанные.ТипКонтейнера) Then

			Элементы.QueryParametersValue.КнопкаОчистки = False;
			Элементы.QueryParametersValue.КнопкаВыбора = True;
			Элементы.QueryParametersValue.ВыбиратьТип = False;
			Элементы.QueryParametersValue.РедактированиеТекста = False;
			Элементы.QueryParametersValue.ОграничениеТипа = New ОписаниеТипов("Строка");
			Элементы.QueryParametersValue.КартинкаКнопкиВыбора = БиблиотекаКартинок.Изменить;

		ElsIf ТипЗнч(ТекущиеДанные.Контейнер) = Тип("Structure") Then

			Элементы.QueryParametersValue.КнопкаОчистки = False;
			Элементы.QueryParametersValue.КнопкаВыбора = True;
			Элементы.QueryParametersValue.ВыбиратьТип = False;
			Элементы.QueryParametersValue.КартинкаКнопкиВыбора = БиблиотекаКартинок.Изменить;
			Элементы.QueryParametersValue.РедактированиеТекста = False;
			Элементы.QueryParametersValue.ОграничениеТипа = New ОписаниеТипов("Строка");

		Иначе

			Элементы.QueryParametersValue.РедактированиеТекста = True;
			If ValueIsFilled(ТекущиеДанные.ТипЗначения) Then
				Элементы.QueryParametersValue.ОграничениеТипа = ТекущиеДанные.ТипЗначения;
			Иначе
				Элементы.QueryParametersValue.ОграничениеТипа = New ОписаниеТипов;
			EndIf;

			If ТекущиеДанные.Value = Undefined
				И Элементы.QueryParametersValue.ОграничениеТипа.Типы().Количество() > 1 Then

				Элементы.QueryParametersValue.ВыбиратьТип = True;
				Элементы.QueryParametersValue.КнопкаВыбора = True;
				Элементы.QueryParametersValue.КнопкаОчистки = False;
				Элементы.QueryParametersValue.КартинкаКнопкиВыбора = Элементы.Picture_ChooseType.Картинка;

			Иначе

				Элементы.QueryParametersValue.ВыбиратьТип = False;
				Элементы.QueryParametersValue.КнопкаОчистки = True;
				Элементы.QueryParametersValue.КнопкаВыбора = ValueChoiceButtonEnabled(ТекущиеДанные.Value);

			EndIf;

		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure QueryParametersOnActivateRow(Item)
	УстановитьПараметрыВводаЗначения();
EndProcedure

&AtClient
Function ДобавитьПараметрСКонтролемИмени(ИмяПараметра)

	стрИспользуемоеИмяПараметра = ИмяПараметра;
	й = 1;
	Пока True Do

		маЪ = QueryParameters.НайтиСтроки(New Structure("Имя", стрИспользуемоеИмяПараметра));
		If маЪ.Количество() = 0 Then
			Прервать;
		EndIf;

		стрИспользуемоеИмяПараметра = ИмяПараметра + й;
		й = й + 1;

	EndDo;

	НоваяСтрока = QueryParameters.Добавить();
	НоваяСтрока.Name = стрИспользуемоеИмяПараметра;

	Return НоваяСтрока;

EndFunction

&AtClient
Procedure ОкончаниеРедактированияСтроки(РезультатЗакрытия, ДополнительныеПараметры) Экспорт

	If РезультатЗакрытия <> Undefined Then

		If ДополнительныеПараметры.Поле = "Контейнер" Then
			If ДополнительныеПараметры.Таблица = "QueryParameters" Then
				ПараметрыЗапроса_СохранитьЗначение(ДополнительныеПараметры.Строка, РезультатЗакрытия.Значение);
			ElsIf ДополнительныеПараметры.Таблица = "TempTables" Then
				СтрокаТаблицы = TempTables.НайтиПоИдентификатору(ДополнительныеПараметры.Строка);
				СтрокаТаблицы.Контейнер = РезультатЗакрытия.Значение;
				СтрокаТаблицы.Value = СтрокаТаблицы.Контейнер.Представление;
				Модифицированность = True;
			EndIf;
		ElsIf ДополнительныеПараметры.Поле = "КонтейнерКакТип" Then
			ПараметрыЗапроса_СохранитьЗначение(ДополнительныеПараметры.Строка, РезультатЗакрытия.ОписаниеКонтейнера);
		ElsIf ДополнительныеПараметры.Поле = "ТипЗначения" Then

			ОписаниеКонтейнера = РезультатЗакрытия.ОписаниеКонтейнера;

			идСтрокаПараметра = ДополнительныеПараметры.Строка;
			If идСтрокаПараметра = Undefined Then
				//добавление нового параметра
				СтрокаПараметра = ДобавитьПараметрСКонтролемИмени(РезультатЗакрытия.ИмяПараметра);
				СтрокаПараметра.ContainerType = РезультатЗакрытия.ТипКонтейнера;
				идСтрокаПараметра = СтрокаПараметра.ПолучитьИдентификатор();
			EndIf;

			ПараметрыЗапроса_УстановитьТип(идСтрокаПараметра, РезультатЗакрытия.ТипКонтейнера, ОписаниеКонтейнера);

			стрТекстЗапроса = Undefined;
			If РезультатЗакрытия.Свойство("ТекстЗапроса", стрТекстЗапроса) Then

				If СтрокаПараметра <> Undefined И СтрокаПараметра.Name <> РезультатЗакрытия.ИмяПараметра Then
					стрТекстЗапроса = СтрЗаменить(стрТекстЗапроса, "&" + РезультатЗакрытия.ИмяПараметра, "&"
						+ СтрокаПараметра.Name);
				EndIf;

				чРазмерТекста = StrLen(QueryText);
				Элементы.QueryText.УстановитьГраницыВыделения(чРазмерТекста + 1, чРазмерТекста + 1);
				Элементы.QueryText.ВыделенныйТекст = стрТекстЗапроса;

				Элементы.QueryGroupPages.ТекущаяСтраница = Элементы.QueryPage;
				ТекущийЭлемент = Элементы.QueryText;

			EndIf;

			УстановитьПараметрыВводаЗначения();

		ElsIf ДополнительныеПараметры.Поле = "Значение" Then
			Элементы.QueryParameters.ТекущиеДанные.Value = РезультатЗакрытия.Значение;
			Элементы.QueryParameters.ТекущиеДанные.Контейнер = РезультатЗакрытия.Значение;
			Модифицированность = True;
		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure QueryParametersParameterTypeStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	ТекущиеДанные = Элементы.QueryParameters.ТекущиеДанные;

	If ТекущиеДанные.ТипКонтейнера < 3 Then
		ТипЗначения = ТекущиеДанные.ТипЗначения;
	Иначе
		ТипЗначения = ТекущиеДанные.Контейнер;
	EndIf;

	ПараметрыОповещения = New Structure("Таблица, Строка, Поле", "ПараметрыЗапроса",
		Элементы.QueryParameters.ТекущаяСтрока, "ТипЗначения");
	ОписаниеОповещенияОЗакрытииОткрываемойФормы = New ОписаниеОповещения("ОкончаниеРедактированияСтроки", ЭтаФорма,
		ПараметрыОповещения);
	ПараметрыОткрытия = New Structure("Объект, ТипЗначения, ТипКонтейнера, Имя, ВЗапросРазрешено", Object,
		ТипЗначения, ТекущиеДанные.ТипКонтейнера, ТекущиеДанные.Имя, True);
	ОткрытьФорму(FormFullName("РедактированиеТипа"), ПараметрыОткрытия, ЭтаФорма, True, , ,
		ОписаниеОповещенияОЗакрытииОткрываемойФормы, РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);

EndProcedure

&AtClient
Procedure QueryParametersValueOnChange(Item)

	ТекущиеДанные = Элементы.QueryParameters.ТекущиеДанные;

	If ТекущиеДанные.ТипКонтейнера = 0 Then

		ТекущиеДанные.Контейнер = ТекущиеДанные.Value;
		If Не ValueIsFilled(ТекущиеДанные.ТипЗначения) Then
			ТекущиеДанные.ТипЗначения = TypeDescriptionByType(ТипЗнч(ТекущиеДанные.Value));
		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure TempTablesValueStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;

	ТекущиеДанные = Элементы.TempTables.ТекущиеДанные;

	ПараметрыОповещения = New Structure("Таблица, Строка, Поле", "TempTables",
		Элементы.TempTables.ТекущаяСтрока, "Контейнер");
	ОписаниеОповещенияОЗакрытииОткрываемойФормы = New ОписаниеОповещения("ОкончаниеРедактированияСтроки", ЭтаФорма,
		ПараметрыОповещения);
	ПараметрыОткрытия = New Structure("Объект, ТипЗначения, Заголовок, Значение, ТипКонтейнера", Object, ,
		ТекущиеДанные.Name, ТекущиеДанные.Контейнер, 3);

	ОткрытьФорму(FormFullName("РедактированиеТаблицы"), ПараметрыОткрытия, ЭтаФорма, False, , ,
		ОписаниеОповещенияОЗакрытииОткрываемойФормы, РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);

EndProcedure

&AtClient
Procedure QueryBatchBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)

	If Clone Then

		Cancel = True;

		ТекущаяСтрока = QueryBatch.НайтиПоИдентификатору(Элементы.QueryBatch.ТекущаяСтрока);
		Parent = ТекущаяСтрока.ПолучитьРодителя();
		If Parent = Undefined Then
			Parent = ТекущаяСтрока;
		EndIf;

		НоваяСтрока = Parent.ПолучитьЭлементы().Добавить();
		ЗаполнитьЗначенияСвойств(НоваяСтрока, ТекущаяСтрока);
		Элементы.QueryBatch.ТекущаяСтрока = НоваяСтрока.ПолучитьИдентификатор();

	EndIf;

EndProcedure

&AtClient
Procedure SaveCommentsOptionOnChange(Item)
	Модифицированность = True;
EndProcedure

&AtClient
Procedure AutoSaveIntervalOptionOnChange(Item)
	ПодключитьОбработчикАвтосохранения();
	Модифицированность = True;
EndProcedure

&AtClient
Procedure QueryResultSelection(Item, SelectedRow, Field, StandardProcessing)

	ИмяКолонки = QueryResultColumnsMap[Field.Имя];

	Значение = Item.ТекущиеДанные[ИмяКолонки];

	If QueryResultContainerColumns.Свойство(ИмяКолонки) Then

		Контейнер = ЭтаФорма[Item.Имя].НайтиПоИдентификатору(Item.ТекущаяСтрока)[ИмяКолонки
			+ ContainerAttributeSuffix];

		If Контейнер.Тип = "ТаблицаЗначений" Then
			ПараметрыОткрытия = New Structure("Объект, Заголовок, Значение, ТолькоПросмотр", Object, ИмяКолонки,
				Контейнер, True);
			ОткрытьФорму(FormFullName("РедактированиеТаблицы"), ПараметрыОткрытия, ЭтаФорма, False, , , ,
				РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);
		ElsIf Контейнер.Тип = Undefined Then
			//Это пустой контейнер, значит, значение лежит в основном поле.
			ПоказатьЗначение( , Значение);
		Иначе
			ПоказатьЗначение( , Контейнер.Представление);
		EndIf;

	Иначе
		ПоказатьЗначение( , Значение);
	EndIf;

EndProcedure

&AtClient
Procedure ResultInBatchOnChange(Item)
	If ИзвлечьРезультат(ResultInBatch) > 0 Then
		StructureЗаписиРезультата_Развернуть();
	EndIf;
EndProcedure

&AtClient
Procedure УстановитьСостоянияЭлементов()

	Элементы.OutputLinesLimitTopOption.Доступность = OutputLinesLimitTopEnabled;
	Элементы.OutputLinesLimitOption.Доступность = OutputLinesLimitEnabled;

EndProcedure

&AtClient
Procedure OutputLinesLimitTopEnabledOptionOnChange(Item)
	УстановитьСостоянияЭлементов();
EndProcedure

&AtClient
Procedure OutputLinesLimitEnabledOptionOnChange(Item)
	УстановитьСостоянияЭлементов();
EndProcedure

&AtClient
Procedure QueryParametersValueChoiceProcessing(Item, SelectedValue, StandardProcessing)

	If ТипЗнч(SelectedValue) = Тип("Тип") Then
		ОграничениеТипа = Элементы.QueryParametersValue.ОграничениеТипа;
		маТипы = New Array;
		маТипы.Добавить(SelectedValue);
		ТипЗначения = New ОписаниеТипов(маТипы, ОграничениеТипа.КвалификаторыЧисла,
			ОграничениеТипа.КвалификаторыСтроки, ОграничениеТипа.КвалификаторыДаты);
		Значение = ТипЗначения.ПривестиЗначение(Элементы.QueryParameters.ТекущиеДанные.Value);
		Элементы.QueryParameters.ТекущиеДанные.Value = Значение;
		StandardProcessing = False;
	EndIf;

	УстановитьПараметрыВводаЗначения();

EndProcedure

&AtClient
Procedure QueryParametersValueTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
	StandardProcessing)
	ТекущиеДанные = Элементы.QueryParameters.ТекущиеДанные;
	If ТипЗнч(ТекущиеДанные.Контейнер) = Тип("Structure") И ТекущиеДанные.Контейнер.Тип = "УникальныйИдентификатор" Then
		Try
			Значение = New УникальныйИдентификатор(Text);
		Except
			ВызватьExcept "Не корректное значение уникального идентификатора";
		EndTry;
		ПараметрыЗапроса_СохранитьЗначение(Элементы.QueryParameters.ТекущаяСтрока, Значение);
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure QueryParametersValueClearing(Item, StandardProcessing)

	ТекущиеДанные = Элементы.QueryParameters.ТекущиеДанные;

	If ТекущиеДанные.ТипКонтейнера = 0 Then
		чКоличествоТипов = ТекущиеДанные.ТипЗначения.Типы().Количество();
		If чКоличествоТипов = 0 Или чКоличествоТипов > 1 Then
			ТекущиеДанные.Value = Undefined;
		Иначе
			ТекущиеДанные.Value = ТекущиеДанные.ТипЗначения.ПривестиЗначение(Undefined);
		EndIf;
	ElsIf ТекущиеДанные.ТипКонтейнера = 3 Then
	EndIf;

	УстановитьПараметрыВводаЗначения();

EndProcedure

&AtClient
Procedure OptionProcessing__OnChange(Item)
	Модифицированность = True;
EndProcedure

&AtClient
Procedure AlgorithmExecutionUpdateIntervalOptionOnChange(Item)
	Модифицированность = True;
EndProcedure

&AtClient
Procedure QueryResultBatchOnActivateRow(Item)
	ПодключитьОбработчикОжидания("ПакетРезультатаЗапросаОбработчикОжиданияПриАктивизацииСтроки", 0.01, True);
EndProcedure

&AtClient
Procedure ResultRecordStructureBeforeExpand(Item, Row, Cancel)

	СтрокаДерева = ResultRecordStructure.НайтиПоИдентификатору(Row);

	If Не СтрокаДерева.ПодчиненныеУзлыРаскрыты Then
		StructureЗаписиРезультата_РаскрытьПодчиненныеУзлы(Row);
	EndIf;

EndProcedure

&AtClient
Function StructureЗаписиРезультатаПолучитьТекстВставки(Строка)

	маТекстЗначения = New Array;

	Строка = StructureЗаписиРезультата.НайтиПоИдентификатору(Строка);
	Пока Строка <> Undefined Do
		маТекстЗначения.Вставить(0, Строка.Имя);
		Строка = Строка.ПолучитьРодителя();
	EndDo;

	Return StrConcat(маТекстЗначения, ".");

EndFunction

&AtClient
Procedure ResultRecordStructureDragStart(Item, DragParameters, Perform)

	маЧасти = New Array;
	For Each Значение Из DragParameters.Значение Do
		маЧасти.Добавить(StructureЗаписиРезультатаПолучитьТекстВставки(Значение));
	EndDo;

	DragParameters.Значение = StrConcat(маЧасти, ";");

EndProcedure

&AtClient
Procedure ResultRecordStructureSelection(Item, SelectedRow, Field, StandardProcessing)
	ВставитьТекстПоПозицииКурсораАлгоритма(StructureЗаписиРезультатаПолучитьТекстВставки(SelectedRow));
EndProcedure

&AtClient
Procedure QueryResultBatchSelection(Item, SelectedRow, Field, StandardProcessing)

	If Item.ТекущийЭлемент.Имя = "ПакетРезультатаЗапросаИнфо" Then

		ОтключитьОбработчикОжидания("ПакетРезультатаЗапросаОбработчикОжиданияПриАктивизацииСтроки");
		ТекущаяСтрока = Элементы.QueryResultBatch.ТекущаяСтрока;
		If ТекущаяСтрока <> Undefined Then
			If ИзвлечьРезультат(QueryResultBatch.Индекс(QueryResultBatch.НайтиПоИдентификатору(
				ТекущаяСтрока)) + 1) > 0 Then
				StructureЗаписиРезультата_Развернуть();
			EndIf;
		EndIf;

		Команда_ПланЗапроса(Undefined);

	ElsIf Item.ТекущийЭлемент.Имя = "ПакетРезультатаЗапросаИмя" Then

		ОтключитьОбработчикОжидания("ПакетРезультатаЗапросаОбработчикОжиданияПриАктивизацииСтроки");
		ТекущаяСтрока = Элементы.QueryResultBatch.ТекущаяСтрока;
		If ТекущаяСтрока <> Undefined Then
			If ИзвлечьРезультат(QueryResultBatch.Индекс(QueryResultBatch.НайтиПоИдентификатору(
				ТекущаяСтрока)) + 1) > 0 Then
				StructureЗаписиРезультата_Развернуть();
			EndIf;
		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure ПакетРезультатаЗапросаОбработчикОжиданияПриАктивизацииСтроки()
	ТекущаяСтрока = Элементы.QueryResultBatch.ТекущаяСтрока;
	If ТекущаяСтрока <> Undefined Then
		If ИзвлечьРезультат(QueryResultBatch.Индекс(QueryResultBatch.НайтиПоИдентификатору(
			ТекущаяСтрока)) + 1) > 0 Then
			StructureЗаписиРезультата_Развернуть();
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region ЗаполнениеИзПерехваченногоЗапроса

&AtServer
Function ЗаполнитьИзЧтениеXML(ЧтениеXML)
	Var стрОшибка, стрТекстЗапроса, стПараметрыЗапроса;

	Обработка = РеквизитФормыВЗначение("Object");

	Try

		StructureПараметров = СериализаторXDTO.ПрочитатьXML(ЧтениеXML);
		If StructureПараметров.Количество() >= 2 Then
			стрТекстЗапроса = Undefined;
			If Не StructureПараметров.Свойство("Текст", стрТекстЗапроса) Или Не StructureПараметров.Свойство(
				"Параметры", стПараметрыЗапроса) Then
				стрОшибка = "Ошибка структуры.";
			EndIf;
		Иначе
			стрОшибка = "Ошибка структуры.";
		EndIf;

	Except
		стрОшибка = КраткоеПредставлениеОшибки(ИнформацияОбОшибке());
	EndTry;

	ЧтениеXML.Закрыть();

	If ValueIsFilled(стрОшибка) Then
		Return "Не возможно сформировать запрос - ошибка структуры введенного XML.
				|Техническая информация: " + стрОшибка;
	EndIf;
	
	//Чтение параметров запроса
	QueryText = стрТекстЗапроса;
	стОшибка = ПараметрыЗаполнитьИзЗапросаAtServer();
	If ValueIsFilled(стОшибка) Then
		Сообщить(
			"Не удалось получить параметры из текста запроса. Параметры будут заполнены только по объекту запроса("
			+ стОшибка.ОписаниеОшибки + ").", СтатусСообщения.Информация);
	EndIf;

	For Each кзПараметр Из стПараметрыЗапроса Do

		маСтрокиПараметра = QueryParameters.НайтиСтроки(New Structure("Имя", кзПараметр.Ключ));
		If маСтрокиПараметра.КОличество() > 0 Then
			СтрокаПараметра = маСтрокиПараметра[0];
		Иначе
			СтрокаПараметра = QueryParameters.Добавить();
		EndIf;

		СтрокаПараметра.Name = кзПараметр.Ключ;
		СтрокаПараметра.ContainerType = GetValueFormCode(кзПараметр.Значение);

		ТипЗначенияИзЗапроса = СтрокаПараметра.ValueType;

		If СтрокаПараметра.ContainerType = 0 Then
			ТипЗначения = ТипЗнч(кзПараметр.Значение);
		ElsIf СтрокаПараметра.ContainerType = 1 Then
			ТипЗначения = кзПараметр.Значение.ТипЗначения;
		ElsIf СтрокаПараметра.ContainerType = 2 И кзПараметр.Значение.Количество() > 0 Then
			ТипЗначения = ТипЗнч(кзПараметр.Значение[0]);
		Иначе
			ТипЗначения = Undefined;
		EndIf;

		If ValueIsFilled(ТипЗначения) И (Не ValueIsFilled(ТипЗначенияИзЗапроса) Или (ТипЗнч(ТипЗначения)
			= Тип("Тип") И Не ТипЗначенияИзЗапроса.СодержитТип(ТипЗначения))) Then
			If ТипЗнч(ТипЗначения) = Тип("Тип") Then
				СтрокаПараметра.ValueType = TypeDescriptionByType(ТипЗначения);
			Иначе
				СтрокаПараметра.ValueType = ТипЗначения;
			EndIf;
		EndIf;

		ПараметрыЗапроса_СохранитьЗначение(СтрокаПараметра.ПолучитьИдентификатор(), кзПараметр.Значение);

	EndDo;
	
	//Чтение временных таблиц.
	маТаблицы = Undefined;
	If StructureПараметров.Свойство("TempTables", маТаблицы) Then

		For Each стТаблица Из маТаблицы Do

			тзТаблица = стТаблица.Таблица;

			стНовыеТипыКолонок = New Structure;
			For Each Колонка Из тзТаблица.Колонки Do

				маТипы = Колонка.ТипЗначения.Типы();
				маНовыеТипыКолонок = New Array;
				фЕстьНеизвестныйОбъект = False;
				For Each Тип Из маТипы Do
					If Строка(Тип) <> "НеизвестныйОбъект" Then
						маНовыеТипыКолонок.Добавить(Тип);
					Иначе
						фЕстьНеизвестныйОбъект = True;
					EndIf;
				EndDo;

				If фЕстьНеизвестныйОбъект Then

					NewТипКолонки = New ОписаниеТипов(маНовыеТипыКолонок, Колонка.ТипЗначения.КвалификаторыЧисла,
						Колонка.ТипЗначения.КвалификаторыСтроки, Колонка.ТипЗначения.КвалификаторыДаты,
						Колонка.ТипЗначения.КвалификаторыДвоичныхДанных);

					стНовыеТипыКолонок.Вставить(Колонка.Имя, NewТипКолонки);

				EndIf;

			EndDo;

			For Each кз Из стНовыеТипыКолонок Do
				Обработка.ChangeValueTableColumnType(тзТаблица, кз.Ключ, кз.Значение);
			EndDo;

			СтрокаТаблицы = TempTables.Добавить();
			СтрокаТаблицы.Name = стТаблица.Имя;
			СтрокаТаблицы.Контейнер = РеквизитФормыВЗначение("Object").Container_SaveValue(тзТаблица);
			СтрокаТаблицы.Value = СтрокаТаблицы.Контейнер.Представление;

		EndDo;

	EndIf;

EndFunction

&AtServer
Procedure ЗаполнитьИзФайла(стрИмяФайла)
	ЧтениеXML = New ЧтениеXML;
	ЧтениеXML.ОткрытьФайл(стрИмяФайла);
	ЗаполнитьИзЧтениеXML(ЧтениеXML);
EndProcedure

&AtServer
Function ЗаполнитьИзXMLAtServer()

	стрСигнатураЗапросаВСтроке = "<Structure xmlns=""http://v8.1c.ru/8.1/data/core""";
	стрТекстВОкнеЗапроса = QueryText;
	If Лев(стрТекстВОкнеЗапроса, StrLen(стрСигнатураЗапросаВСтроке)) <> стрСигнатураЗапросаВСтроке Then
		Return "В поле текста запроса должна быть строка, кодирующая запрос с параметрами. Подробности на закладке ""Информация"".";
	EndIf;

	ЧтениеXML = New ЧтениеXML;
	ЧтениеXML.УстановитьСтроку(стрТекстВОкнеЗапроса);

	ЗаполнитьИзЧтениеXML(ЧтениеXML);

EndFunction

#EndRegion

#Region ИнтерактивныеКоманды

&AtClient
Procedure ЗагрузитьПакетЗапросов(ДополнительныеПараметры = Undefined) Экспорт

	Диалог = New ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Открытие);
	Диалог.Фильтр = SaveFilter;

	ОписаниеОповещения = New ОписаниеОповещения("ПослеВыбораФайлаДляЗагрузкиПакетаЗапросов", ЭтаФорма);
	Диалог.Показать(ОписаниеОповещения);

EndProcedure

&AtClient
Procedure ПослеВыбораФайлаДляЗагрузкиПакетаЗапросов(ВыбранныеФайлы, ДополнительныеПараметры) Экспорт

	If ВыбранныеФайлы = Undefined Then
		Return;
	EndIf;

	стрИмяФайла = ВыбранныеФайлы[0];

	ДополнительныеПараметры = New Structure("Продолжение, ИмяФайла",
		"ПослеВыбораФайлаДляЗагрузкиПакетаЗапросовЗавершение", стрИмяФайла);
	ПакетЗапросов_Загрузить(ДополнительныеПараметры);

EndProcedure

&AtClient
Procedure ПослеВопросаСохранения(РезультатВопроса, ДополнительныеПараметры) Экспорт

	If ДополнительныеПараметры = "Загрузка" Then
		LoadQueryBatchAfterQuestion(РезультатВопроса, ДополнительныеПараметры);
	ElsIf ДополнительныеПараметры = "Завершение" Then
		ЗавершениеПослеВопроса(РезультатВопроса, ДополнительныеПараметры);
	ElsIf ДополнительныеПараметры = "New" Then
		NewПакетЗапросовПослеВопроса(РезультатВопроса, ДополнительныеПараметры);
	EndIf;

EndProcedure

&AtClient
Procedure LoadQueryBatchAfterQuestion(РезультатВопроса, ДополнительныеПараметры)

	If РезультатВопроса = КодReturnаДиалога.Да Then
		СохранитьПакетЗапросов(New Structure);
		ЗагрузитьПакетЗапросов();
	ElsIf РезультатВопроса = КодReturnаДиалога.Нет Then

		AutoSaveFileDeletedFlag = False;
		StateFileDeletedFlag = False;

		ДополнительныеПараметры = New Structure("ТипФайла, Продолжение", "Автосохранение", "ЗагрузитьПакетЗапросов");
		ОписаниеОповещения = New ОписаниеОповещения("Завершить_ПослеУдаления", ЭтаФорма, ДополнительныеПараметры);
		НачатьУдалениеФайлов(ОписаниеОповещения, GetAutoSaveFileName(QueriesFileName));

		ДополнительныеПараметры = New Structure("ТипФайла, Продолжение", "Состояние", "ЗагрузитьПакетЗапросов");
		ОписаниеОповещения = New ОписаниеОповещения("Завершить_ПослеУдаления", ЭтаФорма, ДополнительныеПараметры);
		НачатьУдалениеФайлов(ОписаниеОповещения, StateAutoSaveFileName);

	ElsIf РезультатВопроса = КодReturnаДиалога.Отмена Then
	EndIf;

EndProcedure

&AtClient
Procedure Завершить_ПослеУдаления(ДополнительныеПараметры) Экспорт

	If ДополнительныеПараметры.ТипФайла = "Автосохранение" Then
		AutoSaveFileDeletedFlag = True;
	ElsIf ДополнительныеПараметры.ТипФайла = "Состояние" Then
		StateFileDeletedFlag = True;
	EndIf;

	If AutoSaveFileDeletedFlag И StateFileDeletedFlag Then
		ВыполнитьПродолжение(ДополнительныеПараметры);
	EndIf;

EndProcedure

&AtClient
Procedure NewПакетЗапросовПослеВопроса(РезультатВопроса, ДополнительныеПараметры)

	If РезультатВопроса = КодReturnаДиалога.Да Then
		СохранитьПакетЗапросов(New Structure("New", True));
	ElsIf РезультатВопроса = КодReturnаДиалога.Нет Then

		AutoSaveFileDeletedFlag = False;
		StateFileDeletedFlag = False;

		ДополнительныеПараметры = New Structure("ТипФайла, Продолжение", "Автосохранение",
			"ПродолжениеПакетЗапросов_New");
		ОписаниеОповещения = New ОписаниеОповещения("Завершить_ПослеУдаления", ЭтаФорма, ДополнительныеПараметры);
		НачатьУдалениеФайлов(ОписаниеОповещения, GetAutoSaveFileName(QueriesFileName));

		ДополнительныеПараметры = New Structure("ТипФайла, Продолжение", "Состояние",
			"ПродолжениеПакетЗапросов_New");
		ОписаниеОповещения = New ОписаниеОповещения("Завершить_ПослеУдаления", ЭтаФорма, ДополнительныеПараметры);
		НачатьУдалениеФайлов(ОписаниеОповещения, StateAutoSaveFileName);

	ElsIf РезультатВопроса = КодReturnаДиалога.Отмена Then
	EndIf;

EndProcedure

&AtClient
Procedure УстановитьГраницыВыделенияДляОбработкиСтрок(ЭлементТекст, НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока,
	КонечнаяКолонка)

	ЭлементТекст.ПолучитьГраницыВыделения(НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка);

	If НачальнаяСтрока = КонечнаяСтрока И НачальнаяКолонка = КонечнаяКолонка Then
		ЭлементТекст.УстановитьГраницыВыделения(1, 1, 1000000000, 1);
	Иначе

		If НачальнаяКолонка > 1 Then
			НачальнаяКолонка = 1;
		EndIf;

		If КонечнаяКолонка > 1 Then
			КонечнаяСтрока = КонечнаяСтрока + 1;
			КонечнаяКолонка = 1;
		EndIf;

		ЭлементТекст.УстановитьГраницыВыделения(НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка);

	EndIf;

EndProcedure

&AtClient
Procedure QueryBatchNew_Command(Command)

	If Не СохранитьСВопросом("New") Then
		Return;
	EndIf;

	ПакетЗапросов_New();

EndProcedure

&AtClient
Procedure LoadQueryBatch_Command(Command)

	If Не СохранитьСВопросом("Загрузка") Then
		Return;
	EndIf;

	ЗагрузитьПакетЗапросов();

EndProcedure

&AtClient
Procedure СохранитьПакетЗапросов(Контекст)

	If Не ValueIsFilled(QueriesFileName) Then
		ОписаниеОповещения = New ОписаниеОповещения("СохранитьПакетЗапросовПродолжение", ЭтаФорма, Контекст);
		Автосохранить(ОписаниеОповещения);
		Return;
	EndIf;

	Контекст.Вставить("ProcedureОповещенияЗавершенияСохранения", "ПослеСохраненияПакетаЗапросов");
	Контекст.Вставить("ИмяФайлаСохранения", GetAutoSaveFileName(QueriesFileName));
	Контекст.Вставить("QueriesFileName", QueriesFileName);
	ОписаниеОповещения = New ОписаниеОповещения("ЗакончитьСохранениеФайла", ЭтаФорма, Контекст);
	Автосохранить(ОписаниеОповещения);

EndProcedure

&AtClient
Procedure СохранитьПакетЗапросовПродолжение(Результат, Контекст) Экспорт
	ПакетЗапросовСохранитьКак(Контекст);
EndProcedure

&AtClient
Procedure QueryBatchSave_Command(Command)
	СохранитьПакетЗапросов(New Structure);
EndProcedure

&AtClient
Procedure ПакетЗапросовСохранитьКак(Контекст)

	ПоместитьРедактируемыйЗапрос();

	Диалог = New ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Сохранение);
	Диалог.Фильтр = SaveFilter;

	ОписаниеОповещения = New ОписаниеОповещения("ПакетЗапросовСохранитьКак_ПослеВыбораФайла", ЭтаФорма, Контекст);
	Диалог.Показать(ОписаниеОповещения);

EndProcedure

&AtClient
Procedure QueryBatchSaveAs_Command(Command)
	ПакетЗапросовСохранитьКак(New Structure);
EndProcedure

&AtClient
Procedure ПакетЗапросовСохранитьКак_ПослеВыбораФайла(ВыбранныеФайлы, ДополнительныеПараметры) Экспорт

	If ВыбранныеФайлы = Undefined Then
		Return;
	EndIf;

	стрИмяФайла = ВыбранныеФайлы[0];
	
	//В вебе, в браузере под линуксом почему-то теряет расширение файлов после диалога записи.
	Файл = New Файл(стрИмяФайла);
	If ВРег(Файл.Расширение) <> "." + ВРег(FilesExtension) Then
		Сообщить(Файл.Расширение);
		стрИмяФайла = StrTemplate("%1.%2", стрИмяФайла, FilesExtension);
	EndIf;

	УстановитьQueriesFileName(стрИмяФайла);

	ДополнительныеПараметры = New Structure("ProcedureОповещенияЗавершенияСохранения, ИмяФайлаСохранения, QueriesFileName",
		"ПослеСохраненияПакетаЗапросов", GetAutoSaveFileName(QueriesFileName), QueriesFileName);
	ОписаниеОповещения = New ОписаниеОповещения("ЗакончитьСохранениеФайла", ЭтаФорма, ДополнительныеПараметры);
	Автосохранить(ОписаниеОповещения);

EndProcedure
&AtClient
Procedure ЗакончитьСохранениеФайла(Результат, ДополнительныеПараметры) Экспорт
	ОписаниеОповещение = New ОписаниеОповещения(ДополнительныеПараметры.ProcedureОповещенияЗавершенияСохранения,
		ЭтаФорма, ДополнительныеПараметры);
	НачатьVarещениеФайла(ОписаниеОповещение, ДополнительныеПараметры.ИмяФайлаСохранения,
		ДополнительныеПараметры.QueriesFileName);
EndProcedure

&AtClient
Procedure ПослеСохраненияПакетаЗапросов(VarещаемыйФайл, ДополнительныеПараметры) Экспорт

	Модифицированность = False;

	If ДополнительныеПараметры.Свойство("Завершение") Then
		Закрыть();
	ElsIf ДополнительныеПараметры.Свойство("New") Then
		ПакетЗапросов_New();
	EndIf;

EndProcedure

#Region Команда_КонструкторЗапроса

&AtClient
Function ПолучитьКонструкторЗапроса(СтрТекстЗапроса)
	Var СтрокаОшибки, НомерСтроки, НомерКолонки;

	Try
		КонструкторЗапроса = New КонструкторЗапроса(СтрТекстЗапроса);
	Except

		СтрокаОшибки = ОписаниеОшибки();
		DisassembleQueryError(СтрокаОшибки, НомерСтроки, НомерКолонки);

		ShowConsoleMessageBox(СтрокаОшибки);
		If ValueIsFilled(НомерСтроки) Then
			Элементы.QueryText.УстановитьГраницыВыделения(НомерСтроки, НомерКолонки, НомерСтроки, НомерКолонки);
		EndIf;

		Return Undefined;

	EndTry;

	Return КонструкторЗапроса;

EndFunction

&AtClient
Procedure QueryWizard_Command(Command)

	стрТекстЗапроса = QueryText;
	КомментарииЗапроса_СохранитьДанныеИсходногоЗапроса(стрТекстЗапроса);

	If ValueIsFilled(стрТекстЗапроса) Then
		КонструкторЗапроса = ПолучитьКонструкторЗапроса(стрТекстЗапроса);
		If КонструкторЗапроса = Undefined Then
			Return;
		EndIf;
	Иначе
		КонструкторЗапроса = New КонструкторЗапроса;
	EndIf;

#If ТолстыйКлиентУправляемоеПриложение Then
	If КонструкторЗапроса.ОткрытьМодально() Then
		стрТекстЗапроса = КонструкторЗапроса.Текст;
		КомментарииЗапроса_Восстановить(стрТекстЗапроса);
		QueryText = стрТекстЗапроса;
		ПоместитьРедактируемыйЗапрос();
		Модифицированность = True;
	EndIf;
#Иначе

		If QueryInWizard > 0 Then
			Запрос_УстановитьВКонструкторе(QueryInWizard, False);
			QueryInWizard = -1;
		EndIf;

		ТекущийЗапрос = ПакетЗапросов_ТекущийЗапрос();
		Запрос_УстановитьВКонструкторе(ТекущийЗапрос, True);
		ИзвлечьРедактируемыйЗапрос();
		КонструкторЗапроса.Показать(
			New ОписаниеОповещения("Команда_КонструкторЗапроса_ОповещениеЗакрытияКонструктора", ЭтаФорма,
			ТекущийЗапрос));

#EndIf

EndProcedure

&AtClient
Procedure Команда_КонструкторЗапроса_ОповещениеЗакрытияКонструктора(стрТекстЗапроса, ТекущийЗапрос) Экспорт

	If Не Запрос_ПолучитьВКонструкторе(ТекущийЗапрос) Then
		Return;
	EndIf;

	Запрос_УстановитьВКонструкторе(ТекущийЗапрос, False);
	QueryInWizard = -1;

	If стрТекстЗапроса <> Undefined Then
		КомментарииЗапроса_Восстановить(стрТекстЗапроса);
		Запрос_ПоместитьДанныеЗапроса(EditingQuery, стрТекстЗапроса);
		Модифицированность = True;
	EndIf;

	ИзвлечьРедактируемыйЗапрос(ТекущийЗапрос);

EndProcedure

#EndRegion

&AtClient
Procedure ВыполнитьЗапрос(фИспользоватьВыделение)

	Var НачалоСтроки, НачалоКолонки, КонецСтроки, КонецКолонки;

	Элементы.QueryText.ПолучитьГраницыВыделения(НачалоСтроки, НачалоКолонки, КонецСтроки, КонецКолонки);
	фВесьТекст = Не фИспользоватьВыделение Или (НачалоСтроки = КонецСтроки И НачалоКолонки = КонецКолонки);
	If фВесьТекст Then
		стрТекстЗапроса = QueryText;
	Иначе
		стрТекстЗапроса = Элементы.QueryText.ВыделенныйТекст;
	EndIf;

	If AutoSaveBeforeQueryExecutionOption И Модифицированность Then
		Автосохранить();
	EndIf;

	стРезультат = ВыполнитьЗапросAtServer(стрТекстЗапроса);
	If ValueIsFilled(стРезультат.ОписаниеОшибки) Then
		ShowConsoleMessageBox(стРезультат.ОписаниеОшибки);
		ТекущийЭлемент = Элементы.QueryText;
		If ValueIsFilled(стРезультат.Строка) Then
			If фВесьТекст Then
				Элементы.QueryText.УстановитьГраницыВыделения(стРезультат.Строка, стРезультат.Колонка,
					стРезультат.Строка, стРезультат.Колонка);
			Иначе
			EndIf;
		EndIf;
	Иначе

		ResultInForm = -1;
		ResultReturningRowsCount = ИзвлечьРезультат(стРезультат.КоличествоРезультатов);
		StructureЗаписиРезультата_Развернуть();

		ТекущаяСтрокаПакета = QueryBatch.НайтиПоИдентификатору(Элементы.QueryBatch.ТекущаяСтрока);
		ТекущаяСтрокаПакета.ResultRowCount = QueryResult.Количество();
		ВремяВыполнения = FormatDuration(стРезультат.ВремяОкончания - стРезультат.ВремяНачала);
		Элементы.QueryBatch.ТекущиеДанные.Info = Строка(ResultReturningRowsCount) + " / "
			+ ВремяВыполнения;

	EndIf;

	ResultQueryName = Элементы.QueryBatch.ТекущиеДанные.Name;
	ОбновитьСостояниеЭлементовФормыАлгоритма();

EndProcedure

&AtClient
Procedure ExecuteQuery_Command(Command)
	If Элементы.QueryBatch.ТекущаяСтрока <> Undefined Then
		ВыполнитьЗапрос(True);
	EndIf;
EndProcedure

&AtServer
Function ПараметрыЗаполнитьИзЗапросаAtServer()
	Var НомерСтроки, НомерКолонки;

	Запрос = New Запрос(QueryText);
	Try
		Запрос.МенеджерВременныхТаблиц = ЗагрузитьВременныеТаблицы();
		НайденныеПараметры = Запрос.НайтиПараметры();
	Except
		СтрокаОшибки = ОписаниеОшибки();
		DisassembleQueryError(СтрокаОшибки, НомерСтроки, НомерКолонки);
		Return New Structure("ОписаниеОшибки, Строка, Колонка", СтрокаОшибки, НомерСтроки, НомерКолонки);
	EndTry;

	For Each Параметр Из НайденныеПараметры Do

		If Object.OptionProcessing__ И СтрНачинаетсяС(Параметр.Имя, MacroParameter) Then
			Продолжить;
		EndIf;

		маСтрокиПараметра = QueryParameters.НайтиСтроки(New Structure("Имя", Параметр.Имя));
		If маСтрокиПараметра.Количество() > 0 Then
			СтрокаПараметра = маСтрокиПараметра[0];
		Иначе
			СтрокаПараметра = QueryParameters.Добавить();
			СтрокаПараметра.Name = Параметр.Имя;
			ПараметрыЗапроса_СохранитьЗначение(СтрокаПараметра.ПолучитьИдентификатор(),
				Параметр.ТипЗначения.ПривестиЗначение(Undefined));
		EndIf;

		If Не ValueIsFilled(СтрокаПараметра.ValueType) Then
			СтрокаПараметра.ValueType = Параметр.ТипЗначения;
		EndIf;

	EndDo;

	Return Undefined;

EndFunction

&AtClient
Procedure FillParametersFromQuery_Command(Command)

	стОшибка = ПараметрыЗаполнитьИзЗапросаAtServer();

	If ValueIsFilled(стОшибка) Then

		ShowConsoleMessageBox(стОшибка.ОписаниеОшибки);
		ТекущийЭлемент = Элементы.QueryText;

		If ValueIsFilled(стОшибка.Строка) Then
			Элементы.QueryText.УстановитьГраницыВыделения(стОшибка.Строка, стОшибка.Колонка, стОшибка.Строка,
				стОшибка.Колонка);
		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure FillFromXML_Command(Command)

	стрОшибка = ЗаполнитьИзXMLAtServer();
	If ValueIsFilled(стрОшибка) Then
		ShowConsoleMessageBox(стрОшибка);
	EndIf;

EndProcedure

&AtClient
Procedure ClearParameters_Command(Command)
	QueryParameters.Очистить();
EndProcedure

&AtClient
Procedure ДобавитьПереносСтрокВТекст(ЭлементТекст)
	Var НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка;

	УстановитьГраницыВыделенияДляОбработкиСтрок(ЭлементТекст, НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока,
		КонечнаяКолонка);

	ОбрабатываемыйТекст = New ТекстовыйДокумент;
	ОбрабатываемыйТекст.УстановитьТекст(ЭлементТекст.ВыделенныйТекст);

	Для й = 1 По ОбрабатываемыйТекст.КоличествоСтрок() Do
		ОбрабатываемыйТекст.ЗаменитьСтроку(й, "|" + ОбрабатываемыйТекст.ПолучитьСтроку(й));
	EndDo;

	ЭлементТекст.ВыделенныйТекст = ОбрабатываемыйТекст.ПолучитьТекст();
	ЭлементТекст.УстановитьГраницыВыделения(НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка);

EndProcedure

&AtClient
Procedure AddLineFeedsToText_Command(Command)
	If Элементы.QueryGroupPages.ТекущаяСтраница = Элементы.QueryPage Then
		ДобавитьПереносСтрокВТекст(Элементы.QueryText);
	ElsIf Элементы.QueryGroupPages.ТекущаяСтраница = Элементы.AlgorithmPage Then
		ДобавитьПереносСтрокВТекст(Элементы.AlgorithmText);
	EndIf;
EndProcedure

&AtClient
Procedure УбратьПереносСтрокИзТекста(ЭлементТекст)
	Var НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка;

	УстановитьГраницыВыделенияДляОбработкиСтрок(ЭлементТекст, НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока,
		КонечнаяКолонка);

	ОбрабатываемыйТекст = New ТекстовыйДокумент;
	ОбрабатываемыйТекст.УстановитьТекст(ЭлементТекст.ВыделенныйТекст);

	Для й = 1 По ОбрабатываемыйТекст.КоличествоСтрок() Do
		стр = ОбрабатываемыйТекст.ПолучитьСтроку(й);
		If Лев(СокрЛ(стр), 1) = "|" Then
			ъ = Найти(стр, "|");
			ОбрабатываемыйТекст.ЗаменитьСтроку(й, Лев(стр, ъ - 1) + Прав(стр, StrLen(стр) - ъ));
		EndIf;
	EndDo;

	ЭлементТекст.ВыделенныйТекст = ОбрабатываемыйТекст.ПолучитьТекст();
	ЭлементТекст.УстановитьГраницыВыделения(НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка);

EndProcedure

&AtClient
Procedure RemoveLineFeedsFromText_Command(Command)
	If Элементы.QueryGroupPages.ТекущаяСтраница = Элементы.QueryPage Then
		УбратьПереносСтрокИзТекста(Элементы.QueryText);
	ElsIf Элементы.QueryGroupPages.ТекущаяСтраница = Элементы.AlgorithmPage Then
		УбратьПереносСтрокИзТекста(Элементы.AlgorithmText);
	EndIf;
EndProcedure

&AtClient
Procedure ДобавитьКомментированиеСтрокВТекст(ЭлементТекст)
	Var НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка;

	УстановитьГраницыВыделенияДляОбработкиСтрок(ЭлементТекст, НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока,
		КонечнаяКолонка);

	ОбрабатываемыйТекст = New ТекстовыйДокумент;
	ОбрабатываемыйТекст.УстановитьТекст(ЭлементТекст.ВыделенныйТекст);

	Для й = 1 По ОбрабатываемыйТекст.КоличествоСтрок() Do
		ОбрабатываемыйТекст.ЗаменитьСтроку(й, "//" + ОбрабатываемыйТекст.ПолучитьСтроку(й));
	EndDo;

	ЭлементТекст.ВыделенныйТекст = ОбрабатываемыйТекст.ПолучитьТекст();
	ЭлементТекст.УстановитьГраницыВыделения(НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка);

EndProcedure

&AtClient
Procedure AddCommentsToText_Command(Command)
	If Элементы.QueryGroupPages.ТекущаяСтраница = Элементы.QueryPage Then
		ДобавитьКомментированиеСтрокВТекст(Элементы.QueryText);
	ElsIf Элементы.QueryGroupPages.ТекущаяСтраница = Элементы.AlgorithmPage Then
		ДобавитьКомментированиеСтрокВТекст(Элементы.AlgorithmText);
	EndIf;
EndProcedure

&AtClient
Procedure УбратьКомментированиеСтрокИзТекста(ЭлементТекст)
	Var НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка;

	УстановитьГраницыВыделенияДляОбработкиСтрок(ЭлементТекст, НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока,
		КонечнаяКолонка);

	ОбрабатываемыйТекст = New ТекстовыйДокумент;
	ОбрабатываемыйТекст.УстановитьТекст(ЭлементТекст.ВыделенныйТекст);

	Для й = 1 По ОбрабатываемыйТекст.КоличествоСтрок() Do
		стр = ОбрабатываемыйТекст.ПолучитьСтроку(й);
		If Лев(СокрЛ(стр), 2) = "//" Then
			ъ = Найти(стр, "//");
			ОбрабатываемыйТекст.ЗаменитьСтроку(й, Лев(стр, ъ - 1) + Прав(стр, StrLen(стр) - ъ - 1));
		EndIf;
	EndDo;

	ЭлементТекст.ВыделенныйТекст = ОбрабатываемыйТекст.ПолучитьТекст();
	ЭлементТекст.УстановитьГраницыВыделения(НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка);

EndProcedure

&AtClient
Procedure RemoveCommentsFromText_Command(Command)
	If Элементы.QueryGroupPages.ТекущаяСтраница = Элементы.QueryPage Then
		УбратьКомментированиеСтрокИзТекста(Элементы.QueryText);
	ElsIf Элементы.QueryGroupPages.ТекущаяСтраница = Элементы.AlgorithmPage Then
		УбратьКомментированиеСтрокИзТекста(Элементы.AlgorithmText);
	EndIf;
EndProcedure

&AtClient
Procedure QuerySyntaxCheck_Command(Command)

	If Элементы.QueryGroupPages.ТекущаяСтраница <> Элементы.QueryPage Then
		Return;
	EndIf;

	Результат = FormatQueryTextAtServer(QueryText);

	If ТипЗнч(Результат) <> Тип("Строка") Then
		ShowConsoleMessageBox(Результат.ОписаниеОшибки);
		ТекущийЭлемент = Элементы.QueryText;
		If ValueIsFilled(Результат.Строка) Then
			Элементы.QueryText.УстановитьГраницыВыделения(Результат.Строка, Результат.Колонка, Результат.Строка,
				Результат.Колонка);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure Команда_ФорматироватьТекстЗапроса(Команда)

	If Элементы.QueryGroupPages.ТекущаяСтраница <> Элементы.QueryPage Then
		Return;
	EndIf;

	стрТекстЗапроса = QueryText;
	КомментарииЗапроса_СохранитьДанныеИсходногоЗапроса(стрТекстЗапроса);
	Результат = FormatQueryTextAtServer(стрТекстЗапроса);

	If ТипЗнч(Результат) <> Тип("Строка") Then

		ShowConsoleMessageBox(Результат.ОписаниеОшибки);
		ТекущийЭлемент = Элементы.QueryText;
		If ValueIsFilled(Результат.Строка) Then
			Элементы.QueryText.УстановитьГраницыВыделения(Результат.Строка, Результат.Колонка, Результат.Строка,
				Результат.Колонка);
		EndIf;

		Return;

	EndIf;

	КомментарииЗапроса_Восстановить(Результат);

	ТекстКоличество = New ТекстовыйДокумент;
	ТекстКоличество.УстановитьТекст(QueryText);
	Элементы.QueryText.УстановитьГраницыВыделения(1, 1, ТекстКоличество.КоличествоСтрок() + 1, 1);
	Элементы.QueryText.ВыделенныйТекст = Результат;
	ПоместитьРедактируемыйЗапрос();
	Модифицированность = True;

EndProcedure

&AtClient
Procedure GetCodeForTrace_Command(Command)

	If Object.ExternalDataProcessorMode Then

		стрDataProcessorServerFileName = GetDataProcessorServerFileName();
		//"ВнешниеОбработки.Создать(""" + стрDataProcessorServerFileName + """, False).SaveQuery(" + Формат(Объект.SessionID, "ЧГ=0") + ", Запрос)";
		стрКод = StrTemplate("ВнешниеОбработки.Создать(""%1"", False).SaveQuery(%2, Запрос)",
			стрDataProcessorServerFileName, Формат(Object.SessionID, "ЧГ=0"));
	Иначе

		стрКод = StrTemplate("Обработки.%1.Создать().SaveQuery(%2, Запрос)", Object.DataProcessorName, Формат(
			Object.SessionID, "ЧГ=0"));

	EndIf;

	ПараметрыОткрытия = New Structure("
										|Объект,
										|Заголовок,
										|КодДляКопирования,
										|Информация", Object, "Код для перехвата запроса в отладчике", стрКод, "Для перехвата запроса в отладчике скопируйте и выполните по Shift+F9 указанный код.
																											   |Консоль запросов должна быть запущена в той же информационной базе под тем же пользователем.
																											   |Для получения запросов в консоль используйте команду на закладке текста запроса ""Перехват | Получить перехваченные запросы (Ctrl+F9)""
																											   |В настройках пользователя должна быть отключена защита от опасных действий.");

	ОткрытьФорму(FormFullName("Информация"), ПараметрыОткрытия, ЭтаФорма, False, , , ,
		РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);

EndProcedure

&AtClient
Procedure GetHookedQueries_Command(Command)

	стрПояснение = "Загрузка перехваченных запросов";

	ПоместитьРедактируемыйЗапрос();

	маФайлыЗапросов = GetFileListAtServerFromTempFilesDir("*." + Object.LockedQueriesExtension);

	й = 1;
	For Each стрФайл Из маФайлыЗапросов Do
		Состояние("Загрузка перехваченного запроса: " + й + " из " + маФайлыЗапросов.Количество(), (й - 1) * 100
			/ маФайлыЗапросов.Количество(), стрПояснение);
		NewЗапрос = QueryBatch.ПолучитьЭлементы().Добавить();
		Элементы.QueryBatch.ТекущаяСтрока = NewЗапрос.ПолучитьИдентификатор();
		ЗаполнитьИзФайла(стрФайл);
		ПоместитьРедактируемыйЗапрос();
		й = й + 1;
	EndDo;

	Состояние("Удаление временных файлов...", 100, стрПояснение);
	DeleteFilesAtServer(маФайлыЗапросов);
	ShowConsoleMessageBox("Загруженно перехваченных запросов: " + маФайлыЗапросов.Количество());
	Модифицированность = Модифицированность Или маФайлыЗапросов.Количество() > 0;

EndProcedure

&AtClient
Procedure DeleteHookedQueries_Command(Command)

	ПоместитьРедактируемыйЗапрос();

	маФайлыЗапросов = GetFileListAtServerFromTempFilesDir("*." + Object.LockedQueriesExtension);

	Состояние("Удаление временных файлов...", 100);
	DeleteFilesAtServer(маФайлыЗапросов);
	ShowConsoleMessageBox("Удалено перехваченных запросов: " + маФайлыЗапросов.Количество());

EndProcedure

&AtClient
Procedure QueryBatchAdd_Command(Command)
	Элементы.QueryBatch.ТекущаяСтрока = QueryBatch.ПолучитьЭлементы().Добавить().ПолучитьИдентификатор();
	Элементы.QueryBatch.ТекущийЭлемент = Элементы.QueryListQuery;
	Элементы.QueryBatch.ИзменитьСтроку();
	Модифицированность = True;
EndProcedure

&AtClient
Procedure QueryBatchLevelUp_Command(Command)

	Строка = QueryBatch.НайтиПоИдентификатору(Элементы.QueryBatch.ТекущаяСтрока);
	Родитель = Строка.ПолучитьРодителя();

	If Родитель <> Undefined Then
		РодительРодителя = Родитель.ПолучитьРодителя();
		If РодительРодителя = Undefined Then
			ИндексВставки = QueryBatch.ПолучитьЭлементы().Индекс(Родитель) + 1;
		Иначе
			ИндексВставки = РодительРодителя.ПолучитьЭлементы().Индекс(Родитель) + 1;
		EndIf;
		НоваяСтрока = VarеститьСтрокуДерева(QueryBatch, Строка, ИндексВставки, РодительРодителя);
		Элементы.QueryBatch.ТекущаяСтрока = НоваяСтрока.ПолучитьИдентификатор();
	EndIf;

	Модифицированность = True;

EndProcedure

&AtClient
Procedure QueryBatchCopy_Command(Command)

	Строка = QueryBatch.НайтиПоИдентификатору(Элементы.QueryBatch.ТекущаяСтрока);
	НоваяСтрока = Строка.ПолучитьЭлементы().Добавить();
	ЗаполнитьЗначенияСвойств(НоваяСтрока, Строка, ,
		"InWizard, Инфо, ResultReturningRowsCount, ResultRowCount, RowCountDifference");
	НоваяСтрока.Name = "Копия " + НоваяСтрока.Name;
	Элементы.QueryBatch.ТекущаяСтрока = НоваяСтрока.ПолучитьИдентификатор();
	Элементы.QueryBatch.ТекущийЭлемент = Элементы.QueryListQuery;
	Элементы.QueryBatch.ИзменитьСтроку();

	Модифицированность = True;

EndProcedure

&AtClient
Procedure RefreshResult_Command(Command)
	If ИзвлечьРезультат() > 0 Then
		StructureЗаписиРезультата_Развернуть();
	EndIf;
EndProcedure

&AtClient
Procedure QueryResultTreeExpandAll_Command(Command)
	For Each ЭлементДерева Из QueryResultTree.ПолучитьЭлементы() Do
		Элементы.QueryResultTree.Развернуть(ЭлементДерева.ПолучитьИдентификатор(), True);
	EndDo;
EndProcedure

&AtClient
Procedure QueryResultTreeCollapseAll_Command(Command)
	For Each ЭлементДерева Из QueryResultTree.ПолучитьЭлементы() Do
		Элементы.QueryResultTree.Свернуть(ЭлементДерева.ПолучитьИдентификатор());
	EndDo;
EndProcedure

&AtClient
Procedure ResultToSpreadsheetDocument_Command(Command)

	ПараметрыОткрытия = New Structure("Объект, QueryResultAddress, РезультатВПакете, ИмяЗапроса, ResultKind",
		Object, QueryResultAddress, ResultInBatch, ResultQueryName, ResultKind);
	ФормаТабличногоДокумента = ОткрытьФорму(FormFullName("ФормаТабличногоДокумента"), ПараметрыОткрытия, ЭтаФорма,
		False);

	If Не ФормаТабличногоДокумента.Инициализированна Then
		//Обновление уже открытой формы
		Оповестить("Обновить", ПараметрыОткрытия);
	EndIf;

EndProcedure

&AtClient
Procedure ShowHideResultPanelTotals_Command(Command)
	фОтображатьИтоги = Не Элементы.ShowHideResultPanelTotals.Пометка;
	Элементы.ShowHideResultPanelTotals.Пометка = фОтображатьИтоги;
	Элементы.QueryResult.Подвал = фОтображатьИтоги;
EndProcedure

#Region Команда_ВыполнитьОбработку

&AtServer
Function ЗапуститьОбработкуAtServer(Алгоритм, фПострочно = True)

	ИмяМодуляДлительныеОперации = "ДлительныеОперации";
	ИмяМодуляСтандартныеПодсистемыСервер = "СтандартныеПодсистемыСервер";
	If Метаданные.ОбщиеМодули.Найти(ИмяМодуляДлительныеОперации) = Undefined Или Метаданные.ОбщиеМодули.Найти(
		ИмяМодуляСтандартныеПодсистемыСервер) = Undefined Then
		Return New Structure("Успешно, ОписаниеОшибки", False, "Модули БСП не найдены");
	EndIf;

	МодульСтандартныеПодсистемыСервер = Вычислить(ИмяМодуляСтандартныеПодсистемыСервер);
	Try
		Версия = МодульСтандартныеПодсистемыСервер.ВерсияБиблиотеки();
	Except
		Return New Structure("Успешно, ОписаниеОшибки", False, "Модули БСП не найдены");
	EndTry;

	маВерсия = StrSplit(Версия, ".");
	If Число(маВерсия[0]) <= 2 И Не (Число(маВерсия[0]) = 2 И Число(маВерсия[1]) >= 3) Then
		Return New Structure("Успешно, ОписаниеОшибки", False, StrTemplate(
			"Необходима БСП версии не ниже 2.3 (версия БСП текущей конфигурации %1)", Версия));
	EndIf;

	BackgroundJobResultAddress = ПоместитьВоВременноеХранилище(Undefined, УникальныйИдентификатор);

	стРезультатЗапроса = ПолучитьИзВременногоХранилища(QueryResultAddress);

	ПараметрыВыполнения = New Array;
	ПараметрыВыполнения.Добавить(стРезультатЗапроса);
	ПараметрыВыполнения.Добавить(ResultInBatch);
	ПараметрыВыполнения.Добавить(Алгоритм);
	ПараметрыВыполнения.Добавить(фПострочно);
	ПараметрыВыполнения.Добавить(Object.AlgorithmExecutionUpdateIntervalOption);

	If Object.ExternalDataProcessorMode Then
		ПараметрыМетода = New Structure("
										  |ЭтоВнешняяОбработка,
										  |ДополнительнаяОбработкаСсылка,
										  |DataProcessorName,
										  |ИмяМетода,
										  |ПараметрыВыполнения", True, Undefined, DataProcessorServerFileName,
			"ExecuteUserAlgorithm", ПараметрыВыполнения);
	Иначе
		ПараметрыМетода = New Structure("
										  |ЭтоВнешняяОбработка,
										  |ДополнительнаяОбработкаСсылка,
										  |DataProcessorName,
										  |ИмяМетода,
										  |ПараметрыВыполнения", False, Undefined, Object.DataProcessorName,
			"ExecuteUserAlgorithm", ПараметрыВыполнения);
	EndIf;

	BackgroundJobProgressState = Undefined;
	ПараметрыФоновогоЗадания = New Array;
	ПараметрыФоновогоЗадания.Добавить(ПараметрыМетода);
	ПараметрыФоновогоЗадания.Добавить(BackgroundJobResultAddress);
	Задание = ФоновыеЗадания.Выполнить("ДлительныеОперации.ВыполнитьПроцедуруМодуляОбъектаОбработки",
		ПараметрыФоновогоЗадания, , Object.Title);
	BackgroundJobID = Задание.УникальныйИдентификатор;

	Return New Structure("Успешно", True);

EndFunction

&AtServer
Function ПолучитьСостояниеФоновогоЗадания()

	ФоновоеЗадание = ФоновыеЗадания.НайтиПоУникальномуИдентификатору(
		New УникальныйИдентификатор(BackgroundJobID));
	СостояниеЗадания = New Structure("СостояниеПрогресса, Начало, Состояние, ИнформацияОбОшибке, СообщенияПользователю");
	ЗаполнитьЗначенияСвойств(СостояниеЗадания, ФоновоеЗадание, "Начало, Состояние, ИнформацияОбОшибке");

	If CodeExecutionMethod = 2 Или CodeExecutionMethod = 4 Then
		СостояниеЗадания.СостояниеПрогресса = BackgroundJobProgressState;
	EndIf;

	СообщенияПользователю = ФоновоеЗадание.ПолучитьСообщенияПользователю(True);
	СостояниеЗадания.СообщенияПользователю = New Array;
	For Each Сообщение Из СообщенияПользователю Do
		If СтрНачинаетсяС(Сообщение.Текст, BackgroundJobResultAddress) Then
			СостояниеИзСообщения = РеквизитФормыВЗначение("Object").StringToValue(Прав(Сообщение.Текст, StrLen(
				Сообщение.Текст) - StrLen(BackgroundJobResultAddress)));
			СостояниеЗадания.СостояниеПрогресса = СостояниеИзСообщения;
			BackgroundJobProgressState = СостояниеИзСообщения;
		Иначе
			СостояниеЗадания.СообщенияПользователю.Добавить(Сообщение);
		EndIf;
	EndDo;

	If ФоновоеЗадание.Состояние = СостояниеФоновогоЗадания.Активно Then
		СостояниеЗадания.Состояние = 0;
	ElsIf ФоновоеЗадание.Состояние = СостояниеФоновогоЗадания.Завершено Then
		СостояниеЗадания.Состояние = 1;
	ElsIf ФоновоеЗадание.Состояние = СостояниеФоновогоЗадания.ЗавершеноАварийно Then
		СостояниеЗадания.Состояние = 2;
	ElsIf ФоновоеЗадание.Состояние = СостояниеФоновогоЗадания.Отменено Then
		СостояниеЗадания.Состояние = 3;
	EndIf;

	If ФоновоеЗадание.ИнформацияОбОшибке <> Undefined Then
		СостояниеЗадания.ИнформацияОбОшибке = GetErrorInfoPresentation(ФоновоеЗадание.ИнформацияОбОшибке);
	EndIf;

	Return СостояниеЗадания;

EndFunction

&AtClient
Procedure ОтобразитьСостояниеВыполненияАлгоритма(СостояниеПрогресса = Undefined, Секунды = Undefined,
	фЧерезСостояние = False)

	If Секунды = Undefined Then
		ExecutionStatus = "";
		Элементы.ExecuteDataProcessor.Заголовок = "Выполнить";
		Элементы.ExecuteDataProcessor.Картинка = БиблиотекаКартинок.СформироватьОтчет;
		ОбновитьСостояниеЭлементовФормыАлгоритма();
	Иначе

		стрВремяВыполнения = TimeFromSeconds(Секунды);

		If СостояниеПрогресса <> Undefined Then
			стрПрогресс = Формат(СостояниеПрогресса.Прогресс, "ЧЦ=3; ЧДЦ=0; ЧН=") + "%";
			If СостояниеПрогресса.Прогресс > 0 И СостояниеПрогресса.ДлительностьНаМоментПрогресса > 1000 Then
				стрВремяОсталось = StrTemplate("осталось примерно %1", TimeFromSeconds(Окр(
					СостояниеПрогресса.ДлительностьНаМоментПрогресса / СостояниеПрогресса.Прогресс * (100
					- СостояниеПрогресса.Прогресс) / 1000)));
			Иначе
				стрВремяОсталось = "";
			EndIf;
			стрПояснение = StrTemplate("%1 прошло %2 %3", стрПрогресс, стрВремяВыполнения, стрВремяОсталось);
		Иначе
			стрПрогресс = "";
			стрПояснение = StrTemplate("%1 прошло %2", стрПрогресс, стрВремяВыполнения);
		EndIf;

		If фЧерезСостояние Then
			Состояние("Выполнение алгоритма", СостояниеПрогресса.Прогресс, стрПояснение);
		Иначе
			ExecutionStatus = стрПояснение;
		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure ОтобразитьСостояниеФоновогоЗадания() Экспорт

	If Не ValueIsFilled(BackgroundJobID) Then
		ОтобразитьСостояниеВыполненияАлгоритма();
		Return;
	EndIf;

	СостояниеЗадания = ПолучитьСостояниеФоновогоЗадания();

	If СостояниеЗадания.СообщенияПользователю <> Undefined Then
		For Each СообщениеПользователю Из СостояниеЗадания.СообщенияПользователю Do
			СообщениеПользователю.Сообщить();
		EndDo;
	EndIf;

	If СостояниеЗадания.Состояние = 0 Then
		ОтобразитьСостояниеВыполненияАлгоритма(СостояниеЗадания.СостояниеПрогресса, ТекущаяДата()
			- СостояниеЗадания.Начало);
		ПодключитьОбработчикОжидания("ОтобразитьСостояниеФоновогоЗадания",
			Object.AlgorithmExecutionUpdateIntervalOption / 1000 / 2, True);
	ElsIf СостояниеЗадания.Состояние = 2 Then
		ShowConsoleMessageBox(СостояниеЗадания.ИнформацияОбОшибке);
		BackgroundJobID = "";
		ОтобразитьСостояниеВыполненияАлгоритма();
	Иначе
		BackgroundJobID = "";
		ОтобразитьСостояниеВыполненияАлгоритма();
	EndIf;

EndProcedure

&AtServerNoContext
Procedure ВыполнитьКод(ЭтотКод, Выборка, Параметры)
	Выполнить (ЭтотКод);
EndProcedure

&AtServer
Function ВыполнитьАлгоритм(Алгоритм)

	стРезультатЗапроса = ПолучитьИзВременногоХранилища(QueryResultAddress);
	маРезультатЗапроса = стРезультатЗапроса.Результат;
	стРезультат = маРезультатЗапроса[Число(ResultInBatch) - 1];
	рзВыборка = стРезультат.Результат;
	выбВыборка = рзВыборка.Выбрать();

	Try
		ВыполнитьКод(Алгоритм, выбВыборка, стРезультатЗапроса.Параметры);
	Except
		стрСообщениеОбОшибке = ОписаниеОшибки();
		Return New Structure("Успешно, Продолжать, ОписаниеОшибки", False, False, стрСообщениеОбОшибке);
	EndTry;

	Return New Structure("Успешно, Продолжать, ОписаниеОшибки", True);

EndFunction

&AtServerNoContext
Function ВыполнитьАлгоритмПострочно(QueryResultAddress, РезультатВПакете, ТекстАлгоритма)

	стРезультатЗапроса = ПолучитьИзВременногоХранилища(QueryResultAddress);
	маРезультатЗапроса = стРезультатЗапроса.Результат;
	стРезультат = маРезультатЗапроса[Число(РезультатВПакете) - 1];
	рзВыборка = стРезультат.Результат;
	выбВыборка = рзВыборка.Выбрать();

	Try
		Пока выбВыборка.Следующий() Do
			ВыполнитьКод(ТекстАлгоритма, выбВыборка, стРезультатЗапроса.Параметры);
		EndDo;
	Except
		стрСообщениеОбОшибке = ОписаниеОшибки();
		Return New Structure("Успешно, Продолжать, ОписаниеОшибки", False, False, стрСообщениеОбОшибке);
	EndTry;

	Return New Structure("Успешно, Продолжать, ОписаниеОшибки, Прогресс", True, False, Undefined, 100);

EndFunction

&AtServerNoContext
Function ВыполнитьАлгоритмAtServerПострочно(StateAddress, QueryResultAddress, РезультатВПакете, ТекстАлгоритма,
	ОпцияИнтервалОбновленияВыполненияАлгоритма)

	стСостояние = ПолучитьИзВременногоХранилища(StateAddress);

	If стСостояние = Undefined Then
		стРезультатЗапроса = ПолучитьИзВременногоХранилища(QueryResultAddress);
		маРезультатЗапроса = стРезультатЗапроса.Результат;
		стРезультат = маРезультатЗапроса[Число(РезультатВПакете) - 1];
		рзВыборка = стРезультат.Результат;
		выбВыборка = рзВыборка.Выбрать();
		стСостояние = New Structure("Выборка, Параметры, КоличествоВсего, КоличествоСделано, Начало, НачалоВМиллисекундах",
			выбВыборка, стРезультатЗапроса.Параметры, выбВыборка.Количество(), 0, ТекущаяДата(),
			ТекущаяУниверсальнаяДатаВМиллисекундах());
	EndIf;

	выбВыборка = стСостояние.Выборка;
	чКоличествоСделано = стСостояние.КоличествоСделано;
	чМоментОкончанияПорции = ТекущаяУниверсальнаяДатаВМиллисекундах() + ОпцияИнтервалОбновленияВыполненияАлгоритма;

	Try

		фПродолжать = False;
		Пока выбВыборка.Следующий() Do

			ВыполнитьКод(ТекстАлгоритма, выбВыборка, стСостояние.Параметры);
			чКоличествоСделано = чКоличествоСделано + 1;

			If ТекущаяУниверсальнаяДатаВМиллисекундах() >= чМоментОкончанияПорции Then
				фПродолжать = True;
				Прервать;
			EndIf;

		EndDo;

		стСостояние.КоличествоСделано = чКоличествоСделано;

	Except
		стрСообщениеОбОшибке = ОписаниеОшибки();
		Return New Structure("Успешно, Продолжать, ОписаниеОшибки", False, False, стрСообщениеОбОшибке);
	EndTry;

	If фПродолжать Then
		стСостояние.Выборка = выбВыборка;
		ПоместитьВоВременноеХранилище(стСостояние, StateAddress);
	Иначе
		ПоместитьВоВременноеХранилище(Undefined, StateAddress);
	EndIf;

	Return New Structure("Успешно, Продолжать, ОписаниеОшибки, Прогресс, Начало, ДлительностьНаМоментПрогресса",
		True, фПродолжать, Undefined, стСостояние.КоличествоСделано * 100 / стСостояние.КоличествоВсего,
		стСостояние.Начало, ТекущаяУниверсальнаяДатаВМиллисекундах() - стСостояние.НачалоВМиллисекундах);

EndFunction

&AtClient
Function ВыполнитьАлгоритмПострочноСИндикацией()

	If Не ValueIsFilled(StateAddress) Then
		StateAddress = ПоместитьВоВременноеХранилище(Undefined, УникальныйИдентификатор);
	Иначе
		ПоместитьВоВременноеХранилище(Undefined, StateAddress);
	EndIf;

	Пока True Do

		стРезультат = ВыполнитьАлгоритмAtServerПострочно(StateAddress, QueryResultAddress, ResultInBatch,
			ТекущийТекстАлгоритма(), Object.AlgorithmExecutionUpdateIntervalOption);

		If Не стРезультат.Успешно Then
			Прервать;
		EndIf;

		ОтобразитьСостояниеВыполненияАлгоритма(стРезультат, ТекущаяДата() - стРезультат.Начало, True);
		ОбработкаПрерыванияПользователя();

		If Не стРезультат.Продолжать Then
			Прервать;
		EndIf;

	EndDo;

	ОтобразитьСостояниеВыполненияАлгоритма();

	Return стРезультат;

EndFunction

&AtServer
Procedure ПрерватьФоновоеЗадание()
	ФоновоеЗадание = ФоновыеЗадания.НайтиПоУникальномуИдентификатору(
		New УникальныйИдентификатор(BackgroundJobID));
	ФоновоеЗадание.Отменить();
	BackgroundJobID = "";
EndProcedure

&AtClient
Procedure ExecuteDataProcessor_Command(Command)

	If Не ValueIsFilled(ResultInBatch) Или Число(ResultInBatch) <= 0 Then
		ShowConsoleMessageBox("Выполнение невозможно - результат запроса отсутствует");
		Return;
	EndIf;

	If Не ПустаяСтрока(BackgroundJobID) Then
		//прерывание выполнения
		ПрерватьФоновоеЗадание();
		ОтобразитьСостояниеФоновогоЗадания();
		ShowConsoleMessageBox("Выполнение прервано пользователем!");
		Return;
	EndIf;

	If CodeExecutionMethod = 0 Then
		стРезультат = ВыполнитьАлгоритм(ТекущийТекстАлгоритма());
	ElsIf CodeExecutionMethod = 1 Then
		стРезультат = ВыполнитьАлгоритмПострочно(QueryResultAddress, ResultInBatch, ТекущийТекстАлгоритма());
	ElsIf CodeExecutionMethod = 2 Then
		стРезультат = ВыполнитьАлгоритмПострочноСИндикацией();
	ElsIf CodeExecutionMethod = 3 Then
		//простое выполнение в фоне
		стРезультат = ЗапуститьОбработкуAtServer(ТекущийТекстАлгоритма(), False);
	ElsIf CodeExecutionMethod = 4 Then
		//построчное выполнение в фоне с индикацией
		стРезультат = ЗапуститьОбработкуAtServer(ТекущийТекстАлгоритма(), True);
	Иначе
		стРезультат = New Structure("Успешно, ОписаниеОшибки", False, "Неверный метод исполнения кода");
	EndIf;

	If CodeExecutionMethod = 3 Или CodeExecutionMethod = 4 Then
		If стРезультат.Успешно Then
			Элементы.ExecuteDataProcessor.Заголовок = "Прервать";
			//Pictures = ПолучитьИзВременногоХранилища(Объект.Pictures);
			//Элементы.ВыполнитьОбработку.Картинка = Pictures.ПрогрессВыполнения;
			Элементы.ExecuteDataProcessor.Картинка = БиблиотекаКартинок.Остановить;
			ОтобразитьСостояниеФоновогоЗадания();
		EndIf;
	EndIf;

	If Не стРезультат.Успешно Then
		ShowConsoleMessageBox(стРезультат.ОписаниеОшибки);
	EndIf;

EndProcedure

#EndRegion

&AtClient
Procedure ОкончаниеВыбораПредопределенного(РезультатЗакрытия, ДополнительныеПараметры) Экспорт
	If ValueIsFilled(РезультатЗакрытия) Then
		FormDataChoicePredefined = РезультатЗакрытия.ДанныеФормы;
		Элементы.QueryText.ВыделенныйТекст = РезультатЗакрытия.Результат;
	EndIf;
EndProcedure

&AtClient
Procedure InsertPredefinedValue_Command(Command)
	Var НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка;

	Элементы.QueryText.ПолучитьГраницыВыделения(НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка);
	ПараметрыОповещения = New Structure("НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка",
		НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка);
	ОписаниеОповещенияОЗакрытииОткрываемойФормы = New ОписаниеОповещения("ОкончаниеВыбораПредопределенного",
		ЭтаФорма, ПараметрыОповещения);
	ПараметрыОткрытия = New Structure("Объект, ДанныеФормы, ТекстЗапроса, НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока, КонечнаяКолонка",
		Object, FormDataChoicePredefined, QueryText, НачальнаяСтрока, НачальнаяКолонка, КонечнаяСтрока,
		КонечнаяКолонка);

	ОткрытьФорму(FormFullName("ВыборПредопределенного"), ПараметрыОткрытия, ЭтаФорма, True, , ,
		ОписаниеОповещенияОЗакрытииОткрываемойФормы, РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);

EndProcedure

//&AtServer
//Procedure ПолучитьТаблицуЗнвченийРезультата(Команда)
//EndProcedure

&AtClient
Procedure ResultToParameter_Command(Command)

	тзТаблица = ИзвлечьРезультатКакКонтейнер();

	ПараметрыОповещения = New Structure("Таблица, Строка, Поле", "ПараметрыЗапроса", Undefined, "ТипЗначения");
	ОписаниеОповещенияОЗакрытииОткрываемойФормы = New ОписаниеОповещения("ОкончаниеРедактированияСтроки", ЭтаФорма,
		ПараметрыОповещения);
	ПараметрыОткрытия = New Structure("Объект, ТипЗначения, ТипКонтейнера, Имя, ВЗапросРазрешено, ВПараметр", Object,
		тзТаблица, 3, ResultQueryName, False, True);
	ОткрытьФорму(FormFullName("РедактированиеТипа"), ПараметрыОткрытия, ЭтаФорма, True, , ,
		ОписаниеОповещенияОЗакрытииОткрываемойФормы, РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);

EndProcedure

&AtClient
Procedure AlgorithmInfo_Command(Command)
	ПараметрыОткрытия = New Structure("ИмяМакета, Заголовок", "AlgorithmInfo", "Обработка результата запроса кодом");
	ОткрытьФорму(FormFullName("Справка"), ПараметрыОткрытия, ЭтаФорма);
EndProcedure

#Region Команда_ПолучитьКодСПараметрами

&AtClient
Procedure GetCodeWithParameters_Command(Command)

	If Элементы.QueryBatch.ТекущиеДанные = Undefined Then
		Return;
	EndIf;
	
	//В качестве имени запроса попробуем использовать его название. If не получится - Then просто "Запрос".
	ИмяЗапроса = Элементы.QueryBatch.ТекущиеДанные.Name;
	If Не NameIsCorrect(ИмяЗапроса) Then
		ИмяЗапроса = "Запрос";
	EndIf;

	ПараметрыОткрытия = New Structure("
										|Объект,
										|ИмяЗапроса,
										|ТекстЗапроса,
										|ПараметрыЗапроса,
										|Заголовок,
										|Содержание", Object, ИмяЗапроса, QueryText,
		ПараметрыЗапроса_ПолучитьКакСтроку(), "Код для выполнения запроса на встроенном языке 1С");

	ОткрытьФорму(FormFullName("ФормаКода"), ПараметрыОткрытия, ЭтаФорма, False, , , ,
		РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);

EndProcedure

#EndRegion //Команда_ПолучитьКодСПараметрами

&AtClient
Procedure ShowHideQueryResultBatch_Command(Command)
	фВидимостьПакетаРезультатаЗапроса = Не Элементы.ShowHideQueryResultBatch.Пометка;
	Элементы.ShowHideQueryResultBatch.Пометка = фВидимостьПакетаРезультатаЗапроса;
	Элементы.QueryResultBatch.Видимость = фВидимостьПакетаРезультатаЗапроса;
	Элементы.ResultInBatchGroup.Видимость = Не фВидимостьПакетаРезультатаЗапроса;
	Object.SavedStates.Вставить("ВидимостьПакетаРезультатаЗапроса", фВидимостьПакетаРезультатаЗапроса);
EndProcedure

&AtServer
Procedure ПараметрыЗапросаРядомСТекстомAtServer()
	If Элементы.QueryParametersNextToText.Пометка Then
		Элементы.Varестить(Элементы.QueryParameters, Элементы.ГруппаПараметры);
	Иначе
		Элементы.Varестить(Элементы.QueryParameters, Элементы.ParametersPage);
	EndIf;
EndProcedure

&AtClient
Procedure QueryParametersNextToText_Command(Command)
	Элементы.QueryParametersNextToText.Пометка = Не Элементы.QueryParametersNextToText.Пометка;
	SavedStates_Save("QueryParametersNextToText", Элементы.QueryParametersNextToText.Пометка);
	ПараметрыЗапросаРядомСТекстомAtServer();
EndProcedure

#Region Команда_ТехнологическийЖурнал

&AtServer
Procedure TechnologicalLog_Disable()
	Обработка = РеквизитФормыВЗначение("Object");
	Обработка.TechnologicalLog_Disable();
	ЗначениеВРеквизитФормы(Обработка, "Object");
EndProcedure

&AtServer
Procedure TechnologicalLog_Enable()
	Обработка = РеквизитФормыВЗначение("Object");
	Обработка.TechnologicalLog_Enable();
	ЗначениеВРеквизитФормы(Обработка, "Object");
EndProcedure

&AtServer
Function TechnologicalLog_Enabled()
	Обработка = РеквизитФормыВЗначение("Object");
	фРезультат = Обработка.TechnologicalLog_Enabled();
	ЗначениеВРеквизитФормы(Обработка, "Object");
	Return фРезультат;
EndFunction

&AtServer
Function TechnologicalLog_Disabled()
	Обработка = РеквизитФормыВЗначение("Object");
	фРезультат = Обработка.TechnologicalLog_Disabled();
	ЗначениеВРеквизитФормы(Обработка, "Object");
	Return фРезультат;
EndFunction

&AtClient
Procedure ТехнологическийЖурнал_ОжиданиеВключения() Экспорт

	If Не Элементы.TechnologicalLog.Пометка Then
		Return;
	EndIf;

	If TechnologicalLog_Enabled() Then
		ТехнологическийЖурнал_ИндикацияВключения(True);
	Иначе
		If ТекущаяУниверсальнаяДатаВМиллисекундах() - TechLogBeginEndTime < 60 * 1000 Then
			ПодключитьОбработчикОжидания("ТехнологическийЖурнал_ОжиданиеВключения",
				TechLogSwitchingPollingPeriodOption, True);
		Иначе
			//Технологический журнал включить не получилось.
			TechnologicalLog_Disable();
			Элементы.TechnologicalLog.Пометка = False;
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure ТехнологическийЖурнал_ИндикацияВключения(фВключен)
	If фВключен Then
		Элементы.TechnologicalLog.ЦветФона = New Цвет(220, 0, 0);
		Элементы.TechnologicalLog.ЦветТекста = New Цвет(255, 255, 255);
		TechLogEnabledAndRunning = Object.TechLogEnabled
			И Элементы.TechnologicalLog.Пометка;
	Иначе
		Элементы.TechnologicalLog.ЦветФона = New Цвет;
		Элементы.TechnologicalLog.ЦветТекста = New Цвет;
		TechLogEnabledAndRunning = False;
	EndIf;
EndProcedure

&AtClient
Procedure ТехнологическийЖурнал_ОжиданиеВыключения() Экспорт

	If Элементы.TechnologicalLog.Пометка Then
		Return;
	EndIf;

	If TechnologicalLog_Disabled() Then
		ТехнологическийЖурнал_ИндикацияВключения(False);
	Иначе
		If ТекущаяУниверсальнаяДатаВМиллисекундах() - TechLogBeginEndTime < 60 * 1000 Then
			ПодключитьОбработчикОжидания("ТехнологическийЖурнал_ОжиданиеВыключения",
				TechLogSwitchingPollingPeriodOption, True);
		Иначе
			//Не удалось удалить папку с файлами технологического журнала. Довольно странная ситуация.
			//Но конфиг исправлен, прошло 60 секунд. Будем считать, что он выключен, других вариантов нет.
			ТехнологическийЖурнал_ИндикацияВключения(False);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure TechnologicalLog_Command(Command)
	If Элементы.TechnologicalLog.Пометка Then
		TechnologicalLog_Disable();
		Элементы.TechnologicalLog.Пометка = False;
		Элементы.QueryPlan.Видимость = False;
		Элементы.QueryResultBatchInfo.ГиперссылкаЯчейки = False;
		TechLogBeginEndTime = ТекущаяУниверсальнаяДатаВМиллисекундах();
		ПодключитьОбработчикОжидания("ТехнологическийЖурнал_ОжиданиеВыключения",
			TechLogSwitchingPollingPeriodOption, True);
	Иначе
		TechnologicalLog_Enable();
		TechLogEnabledAndRunning = False;
		Элементы.TechnologicalLog.Пометка = True;
		ТехнологическийЖурнал_ИндикацияВключения(False);
		TechLogBeginEndTime = ТекущаяУниверсальнаяДатаВМиллисекундах();
		ПодключитьОбработчикОжидания("ТехнологическийЖурнал_ОжиданиеВключения",
			TechLogSwitchingPollingPeriodOption, True);
	EndIf;
EndProcedure

&AtClient
Procedure QueryPlan_Command(Command)

	ТекущаяСтрока = Элементы.QueryResultBatch.ТекущаяСтрока;
	If ТекущаяСтрока = Undefined Then
		Return;
	EndIf;

	ПараметрыОткрытия = New Structure("Объект, QueryResultAddress, РезультатВПакете", Object,
		QueryResultAddress, QueryResultBatch.Индекс(QueryResultBatch.НайтиПоИдентификатору(
		ТекущаяСтрока)) + 1);
	Форма = ОткрытьФорму(FormFullName("ФормаПланаЗапроса"), ПараметрыОткрытия, ЭтаФорма, False, , , ,
		РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);

	If Форма = Undefined Then
		ShowConsoleMessageBox("Не удалось получить информацию о запросе");
	EndIf;

EndProcedure

#EndRegion //Команда_ТехнологическийЖурнал

&AtClient
Procedure ВыполнитьПродолжение(ДополнительныеПараметры)

	If ДополнительныеПараметры.Продолжение = "ПриОткрытииПродолжение" Then
		ПриОткрытииПродолжение(ДополнительныеПараметры);
		Return;
	ElsIf ДополнительныеПараметры.Продолжение = "ЗагрузитьПакетЗапросов" Then
		ЗагрузитьПакетЗапросов(ДополнительныеПараметры);
		Return;
	ElsIf ДополнительныеПараметры.Продолжение = "ПродолжениеПакетЗапросов_New" Then
		ПродолжениеПакетЗапросов_New(ДополнительныеПараметры);
		Return;
	ElsIf ДополнительныеПараметры.Продолжение = "ПослеВыбораФайлаДляЗагрузкиПакетаЗапросовЗавершение" Then
		ПослеВыбораФайлаДляЗагрузкиПакетаЗапросовЗавершение(ДополнительныеПараметры);
		Return;
	EndIf;
	
	//Везде, кроме веб-клиенат замечательно работает вот это:
	Выполнить (ДополнительныеПараметры.Продолжение + "(ДополнительныеПараметры);");
	//Но в веб-клиенте "Выполнить" не работает, поэтому потребовалась эта Procedure.
	//If в вебе выдаст ошибку на этой строке, значит, забыли что-то добавить в условие выше. В тонком и толстом клиенте ошибки не будет в любом случае.

EndProcedure

&AtClient
Procedure ПослеВыбораФайлаДляЗагрузкиПакетаЗапросовЗавершение(ДополнительныеПараметры) Экспорт
	УстановитьQueriesFileName(ДополнительныеПараметры.ИмяФайла);
	EditingQuery = -1;
	ПакетЗапросов_Сохранить( , StateAutoSaveFileName, True);
EndProcedure

&AtClient
Procedure ПродолжениеПакетЗапросов_New(ДополнительныеПараметры)
	ПакетЗапросов_New();
EndProcedure

#EndRegion //ИнтерактивныеКоманды

#Region ПолучитьФайлыТехнологическогоЖурналаКонсоли

&AtClient
Procedure GetConsoleTechLogFiles(Directory)

	маЛоги = ПолучитьСписокФайловЖурнала();
	For Each ФайлЛога Из маЛоги Do
		Сообщить(ФайлЛога.ПолноеИмя);
	EndDo;

EndProcedure

&AtServer
Function ПолучитьСписокФайловЖурнала()
	маЛоги = НайтиФайлы(Object.TechLogFolder, "*.log", True);
	Return маЛоги;
EndFunction

#EndRegion //Команда_ПолучитьФайлыТехнологическогоЖурналаКонсоли

#Region Алгоритмы

&AtClient
Procedure УстановитьТекстАлгоритма(NewТекст)
	If UT_IsPartOfUniversalTools Then
		UT_CodeEditorClient.УстановитьТекстРедактора(ЭтотОбъект, "Алгоритм", NewТекст);
	Иначе
		AlgorithmText = NewТекст;
	EndIf;
EndProcedure

&AtClient
Function ТекущийТекстАлгоритма()
	If UT_IsPartOfUniversalTools Then
		Return UT_CodeEditorClient.ТекстКодаРедактора(ЭтотОбъект, "Алгоритм");
	Иначе
		Return AlgorithmText;
	EndIf;
EndFunction

&AtClient
Function ТекущийТекстЗапроса()
	Return QueryText;
EndFunction

&AtClient
Function ГраницыВыделенияЭлемента(Элемент)
	Границы = New Structure;
	Границы.Вставить("НачалоСтроки", 0);
	Границы.Вставить("НачалоКолонки", 0);
	Границы.Вставить("КонецСтроки", 0);
	Границы.Вставить("КонецКолонки", 0);

	Элемент.ПолучитьГраницыВыделения(Границы.НачалоСтроки, Границы.НачалоКолонки, Границы.КонецСтроки,
		Границы.КонецКолонки);

	Return Границы;
EndFunction

&AtClient
Procedure УстановитьГраницыВыделенияАлгоритма(НачалоСтроки, НачалоКолонки, КонецСтроки, КонецКолонки)
	If UT_IsPartOfUniversalTools Then
		UT_CodeEditorClient.УстановитьГраницыВыделения(ЭтотОбъект, "Алгоритм", НачалоСтроки, НачалоКолонки,
			КонецСтроки, КонецКолонки);
	Иначе
		Элементы.AlgorithmText.УстановитьГраницыВыделения(НачалоСтроки, НачалоКолонки, КонецСтроки, КонецКолонки);
	EndIf;
EndProcedure

&AtClient
Procedure УстановитьГраницыВыделенияЗапроса(НачалоСтроки, НачалоКолонки, КонецСтроки, КонецКолонки)
	
	Элементы.QueryText.УстановитьГраницыВыделения(НачалоСтроки, НачалоКолонки, КонецСтроки, КонецКолонки);
	
EndProcedure

&AtClient 
Function ГраницыВыделенияАлгоритма()
	If UT_IsPartOfUniversalTools Then
		Return UT_CodeEditorClient.ГраницыВыделенияРедактора(ЭтотОбъект, "Алгоритм");
	Иначе
		Return ГраницыВыделенияЭлемента(Элементы.AlgorithmText);	
	EndIf;
EndFunction

&AtClient 
Function ГраницыВыделенияЗапроса()
//	If UT_IsPartOfUniversalTools Then
//		Return УИ_РедакторКодаКлиент.ГраницыВыделенияРедактора(ЭтотОбъект, "Алгоритм");
//	Иначе
		Return ГраницыВыделенияЭлемента(Элементы.QueryText);	
//	EndIf;
EndFunction

&AtClient
Procedure ВставитьТекстПоПозицииКурсораАлгоритма(Текст)
	If UT_IsPartOfUniversalTools Then
		UT_CodeEditorClient.ВставитьТекстПоПозицииКурсора(ЭтотОбъект, "Алгоритм", Текст);
	Иначе
		ВставитьТекстПоПозицииКурсораЭлемента(Элементы.AlgorithmText, Текст);	
	EndIf;
	
EndProcedure

&AtClient
Procedure ВставитьТекстПоПозицииКурсораЭлемента(Элемент, Текст)
	Элемент.ВыделенныйТекст = Текст;
EndProcedure

#EndRegion

#Region УИ

&AtClient
Procedure UT_EditValue(Command)
	ЭлементФормы=Элементы.QueryResult;
	If ResultKind = "дерево" Then
		ЭлементФормы=Элементы.QueryResultTree;
	EndIf;

	ТекДанные=ЭлементФормы.ТекущиеДанные;
	ТекКолонка=ЭлементФормы.ТекущийЭлемент;

	ИмяКолонки=СтрЗаменить(ТекКолонка.Имя, ЭлементФормы.Имя, "");

	ЗначениеКолонки=ТекДанные[ИмяКолонки];

	Try
		МодульОбщегоНазначениеКлиент=Вычислить("UT_CommonClient");
	Except
		МодульОбщегоНазначениеКлиент=Undefined;
	EndTry;

	If МодульОбщегоНазначениеКлиент = Undefined Then
		Return;
	EndIf;

	If ЗначениеКолонки = "<ХранилищеЗначения>" Then
		МодульОбщегоНазначениеКлиент.РедактироватьХранилищеЗначения(ЭтотОбъект, ТекДанные[ИмяКолонки
			+ ContainerAttributeSuffix].Хранилище);
	Иначе
		МодульОбщегоНазначениеКлиент.РедактироватьОбъект(ЗначениеКолонки);
	EndIf;

EndProcedure

&AtServer
Procedure УИ_ЗаполнитьДаннымиОтладки()
	If Не Параметры.Свойство("ДанныеОтладки") Then
		Return;
	EndIf;

	If Object.SavedStates = Undefined Then
		Object.SavedStates = New Structure;
	EndIf;

	Модифицированность = False;

	AutoSaveIntervalOption = 60;
	SaveCommentsOption = True;
	AutoSaveBeforeQueryExecutionOption = True;
	ОпцияИнтервалОбновленияВыполненияАлгоритма = 1000;
	Object.OptionProcessing__ = True;
	Object.AlgorithmExecutionUpdateIntervalOption = 1000;

	ОбработкаОбъект=РеквизитФормыВЗначение("Object");

	UT_Debug=True;

	ДанныеОтладки=ПолучитьИзВременногоХранилища(Параметры.ДанныеОтладки);

	СтрокиДерева=QueryBatch.ПолучитьЭлементы();

	НоваяСтрока=СтрокиДерева.Добавить();
	НоваяСтрока.Name="Отладка";
	НоваяСтрока.ТекстЗапроса=ДанныеОтладки.Текст;
	НоваяСтрока.ПараметрыЗапроса=New СписокЗначений;

	If ДанныеОтладки.Свойство("Параметры") Then
		For Each ТекПараметр Из ДанныеОтладки.Параметры Do

			NewПараметр=New Structure;
			NewПараметр.Вставить("Имя", ТекПараметр.Ключ);
			NewПараметр.Вставить("ТипКонтейнера", GetValueFormCode(ТекПараметр.Значение));

			NewПараметр.Вставить("Контейнер", ОбработкаОбъект.Container_SaveValue(ТекПараметр.Значение));

			If NewПараметр.ТипКонтейнера = 2 Then
				ArrayТипов=New Array;

				For Each ЗначениеArrayа Из ТекПараметр.Значение Do
					ТекТип=ТипЗнч(ЗначениеArrayа);
					If ArrayТипов.Найти(ТекТип) = Undefined Then
						ArrayТипов.Добавить(ТекТип);
					EndIf;
				EndDo;

				NewПараметр.Вставить("ТипЗначения", New ОписаниеТипов(ArrayТипов));
				NewПараметр.Вставить("Значение", NewПараметр.Контейнер.Представление);
			ElsIf NewПараметр.ТипКонтейнера = 1 Then
				ArrayТипов=New Array;

				For Each ЭлементСписка Из ТекПараметр.Значение Do
					ТекТип=ТипЗнч(ЭлементСписка.Значение);
					If ArrayТипов.Найти(ТекТип) = Undefined Then
						ArrayТипов.Добавить(ТекТип);
					EndIf;
				EndDo;

				NewПараметр.Вставить("ТипЗначения", New ОписаниеТипов(ArrayТипов));
				NewПараметр.Вставить("Значение", NewПараметр.Контейнер.Представление);
			ElsIf NewПараметр.ТипКонтейнера = 3 Then
				NewПараметр.Вставить("ТипЗначения", "Таблица значений");
				NewПараметр.Вставить("Значение", NewПараметр.Контейнер.Представление);
			Иначе
				NewПараметр.Вставить("ТипЗначения", TypeDescriptionByType(ТипЗнч(ТекПараметр.Значение)));
				NewПараметр.Вставить("Значение", NewПараметр.Контейнер);

			EndIf;
			НоваяСтрока.ПараметрыЗапроса.Добавить(NewПараметр);
		EndDo;
	EndIf;

	If ДанныеОтладки.Свойство("TempTables") Then
		НоваяСтрока.TempTables=New СписокЗначений;

		For Each КлючЗначение Из ДанныеОтладки.TempTables Do
			ВременнаяТаблица=New Structure;
			ВременнаяТаблица.Вставить("Имя", КлючЗначение.Ключ);
			ВременнаяТаблица.Вставить("Контейнер", ОбработкаОбъект.Container_SaveValue(КлючЗначение.Значение));
			ВременнаяТаблица.Вставить("Значение", ВременнаяТаблица.Контейнер.Представление);

			НоваяСтрока.TempTables.Добавить(ВременнаяТаблица);
		EndDo;
	EndIf;

EndProcedure

//@skip-warning
&AtClient
Procedure Подключаемый_ВыполнитьОбщуюКомандуИнструментов(Команда)
	UT_CommonClient.Подключаемый_ВыполнитьОбщуюКомандуИнструментов(ЭтотОбъект, Команда);
EndProcedure

//@skip-warning
&AtClient
Procedure Подключаемый_ПолеРедактораДокументСформирован(Элемент)
	UT_CodeEditorClient.ПолеРедактораHTMLДокументСформирован(ЭтотОбъект, Элемент);
EndProcedure

//@skip-warning
&AtClient
Procedure Подключаемый_ПолеРедактораПриНажатии(Элемент, ДанныеСобытия, СтандартнаяОбработка)
	UT_CodeEditorClient.ПолеРедактораHTMLПриНажатии(ЭтотОбъект, Элемент, ДанныеСобытия, СтандартнаяОбработка);
EndProcedure

//@skip-warning
&AtClient
Procedure Подключаемый_РедакторКодаОтложеннаяИнициализацияРедакторов()
	UT_CodeEditorClient.РедакторКодаОтложеннаяИнициализацияРедакторов(ЭтотОбъект);
EndProcedure

&AtClient
Procedure Подключаемый_РедакторКодаЗавершениеИнициализации() Экспорт
	ТекущаяСтрока = Элементы.QueryBatch.ТекущаяСтрока;
	If ТекущаяСтрока = Undefined Then
		Return;
	EndIf;

	стДанныеЗапроса = Запрос_ПолучитьДанныеЗапроса(ТекущаяСтрока);

	УстановитьТекстАлгоритма(стДанныеЗапроса.ТекстКод);
	
	
EndProcedure

&AtClient
Procedure УИ_ДобавитьКонтекстСтруктурыРезультатаАлгоритм()
	StructureДополнительногоКонтекста = New Structure;
	
	For Each ДоступнаяVarенная Из StructureЗаписиРезультата.ПолучитьЭлементы() Do
		StructureVarенной = New Structure;
		If ДоступнаяVarенная.Имя="Выборка" Then
			StructureVarенной.Вставить("Тип", "ВыборкаИзРезультатаЗапроса");
		Иначе
			StructureVarенной.Вставить("Тип", "Structure");
		EndIf;
		
		StructureVarенной.Вставить("ПодчиненныеСвойства", New Array);
		
		For Each ТекРеквизитVarенной ИЗ ДоступнаяVarенная.ПолучитьЭлементы() Do
			НовоеСвойство = New Structure;
			НовоеСвойство.Вставить("Имя", ТекРеквизитVarенной.Имя);
			НовоеСвойство.Вставить("Тип", ТекРеквизитVarенной.Тип);
			
			StructureVarенной.ПодчиненныеСвойства.Добавить(НовоеСвойство);
		EndDo;
		
		StructureДополнительногоКонтекста.Вставить(ДоступнаяVarенная.Имя, StructureVarенной);
	EndDo;
	
	UT_CodeEditorClient.ДобавитьКонтекстРедактораКода(ЭтотОбъект, "Алгоритм", StructureДополнительногоКонтекста);


EndProcedure
#EndRegion

#If Клиент Then

FilesExtension = "q9";
ConsoleSignature = ИмяОбработкиКонсоли(ЭтотОбъект);
SaveFilter = "Файл запросов (*." + FilesExtension + ")|*." + FilesExtension;
AutoSaveExtension = "q9save";
FormatVersion = 13;

#EndIf