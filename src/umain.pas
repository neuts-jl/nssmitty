{
  *****************************************************************************
   Program     : nssmitty
   Author      : NEUTS JL
   License     : GPL (GNU General Public License)
   Date        : 01/02/2025

   Description : NSMITTY is nostalgically and heavily inspired by SMITTY AIX.
                 NSSMITY is an interactive interface application designed to
                 simplify system management tasks. The nssmitty command displays
                 a hierarchy of menus that can lead to interactive dialogs.
                 NSSMITY creates and executes commands according to the user's
                 instructions. Since NSSMITTY executes commands, you must have
                 the necessary authority to execute the commands it executes.

   Features    : - Interactive menu interface
                 - User assistance
                 - Traceability of operations
                 - Shortcuts to screens example: nsmitty chuser
                 - Scalable system: some programs also install nssmitty menu
                   entries
                 - Possibility of displaying online commands performed
                   (to be able to make scripts later for example)

   WARNING     : This program does not use the CRT unit, because it disrupts
                 the proper functioning of the console, especially for launched
                 shells.

   This program is free software: you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation, either version 3 of the License, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along with
   this program. If not, see <https://www.gnu.org/licenses/>.
  *****************************************************************************
}
unit umain;

{$mode ObjFPC}{$H+}
{$notes off}

interface

uses
  {$IFDEF LINUX}
  baseunix,
  {$ENDIF}
  {$IFDEF WINDOWS}
  windows,
  {$ENDIF}
  Classes, SysUtils, process, uscreenfile,
  uttyansi, uttyconsole, uttykeyboard, uttylist,
  uttyeditfields, ucsvttytable, uttybox;

const
  KVersion = 'V0.0.1';

procedure Main;

implementation

var
  WSL, NoLog: boolean;
  LogFileName, ScriptFilename: string;

function WordWrap(const InputStr: string; MaxWidth: integer): string;
var
  Words: TStringList;
  i: integer;
  word, NewLine, ResultStr: string;
begin
  Words := TStringList.Create;
  try
    Words.Delimiter := ' ';
    Words.StrictDelimiter := True;
    Words.DelimitedText := InputStr;

    NewLine := '';
    ResultStr := '';

    for i := 0 to Words.Count - 1 do
    begin
      word := Words[i];

      if (NewLine = '') then
        NewLine := word
      else if (Length(NewLine) + Length(word) + 1 <= MaxWidth) then
        NewLine := NewLine + ' ' + word
      else
      begin
        if ResultStr <> '' then
          ResultStr := ResultStr + sLineBreak;
        ResultStr := ResultStr + NewLine;
        NewLine := word;
      end;
    end;

    if NewLine <> '' then
    begin
      if ResultStr <> '' then
        ResultStr := ResultStr + sLineBreak;
      ResultStr := ResultStr + NewLine;
    end;

    Result := ResultStr;
  finally
    Words.Free;
  end;
end;

procedure AddLog(Log: string; const Raw: boolean = False);
var
  FS: TFileStream;
  LogEntry: string;
begin
  if NoLog then
    Exit;
  if LogFileName = '' then
  begin
    LogFileName := ChangeFileExt(ParamStr(0), '.log');
    {$IFDEF LINUX}
      LogFileName:=GetUserDir+ExtractFileName(LogFileName);
    {$ENDIF}
  end;
  if not Raw then
    LogEntry := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + Log + sLineBreak
  else
    LogEntry := Log;

  if FileExists(LogFileName) then
    FS := TFileStream.Create(LogFileName, fmOpenReadWrite or fmShareDenyNone)
  else
    FS := TFileStream.Create(LogFileName, fmCreate);

  try
    FS.Seek(0, soEnd);
    FS.WriteBuffer(LogEntry[1], Length(LogEntry) * SizeOf(char));
  finally
    FS.Free;
  end;
end;

function GetScriptShell(Script: string; Screen: TScreen;
  const DoLog: boolean = False): string;

  function DoubleQuotedStr(const S: string): string;
  begin
    Result := '"' + StringReplace(S, '"', '\"', [rfReplaceAll]) + '"';
  end;

var
  FFile: TStringStream;
  i: integer;
  FVars: TStringList;
begin
  FVars := TStringList.Create;
  for i := 0 to Screen.Items.Count - 1 do
    if Pos('$' + Screen.Items[i].Name, Script) > 0 then
      FVars.Add(Screen.Items[i].Name + '=' + DoubleQuotedStr(Screen.Items[i].Value));
  Script := FVars.Text + Script;
  FVars.Free;
  if DoLog then
    AddLog(Screen.Name + #10 + Script);
  {$IFDEF WINDOWS}
    if WSL then
    begin
      if ScriptFilename='' then
        ScriptFilename:=ChangeFileExt(ParamStr(0),'.sh');
      Script:='#!/bin/bash'+#10+Script;
      Script:=StringReplace(Script, #13#10, #10, [rfReplaceAll]);
      Result:='wsl.exe ./'+ExtractFileName(ScriptFilename)
    end
    else
    begin
      if ScriptFilename='' then
        ScriptFilename:=ChangeFileExt(ParamStr(0),'.bat');
      Result:='cmd.exe /c '+ScriptFilename;
    end;
  {$ENDIF}
  {$IFDEF LINUX}
    if ScriptFilename='' then
      ScriptFilename:=GetUserDir+ExtractFileName(ChangeFileExt(ParamStr(0),'.sh'));
    Script:='#!/bin/bash'+#10+Script;
    Script:=StringReplace(Script, #13#10, #10, [rfReplaceAll]);
    Result:='/bin/bash -c '+ScriptFilename;
  {$ENDIF}
  FFile := TStringStream.Create(Script);
  FFile.SaveToFile(ScriptFilename);
  FFile.Free;
  {$IFDEF LINUX}
    FpChmod(ScriptFilename, &755);
  {$ENDIF}
end;

function GetExecConsole(Command: string; Screen: TScreen): string;
var
  Process: TProcess;
  Error: string;
  Content: string;
  ExitStatus: integer;
begin
  Result := '';
  Process := DefaultTProcess.Create(nil);
  Content := '';
  Error := '';
  try
    Process.ShowWindow := swoHide;
    {%H-}
    Process.Commandline := GetScriptShell(Command, Screen);
    {%H+}
    Process.RunCommandLoop(Content, Error, ExitStatus);
    Result := Content;
  except
    on e: Exception do
      Result := 'Error : ' + e.Message;
  end;
  Process.Free;
end;

procedure DrawBBox(x1, y1, x2, y2: integer;
  Title, Text1, Text2, Text3, Text4, Text5, Text6, Text7, Text8: string);

  procedure DrawFootText(x1, y, x2: integer; Text1, Text2, Text3, Text4: string);
  var
    SectionWidth: integer;
  begin
    SectionWidth := (x2 - x1 - 1) div 4;

    GotoXY(x1 + 1, y);
    Write(Copy(Text1, 1, SectionWidth - 1));

    GotoXY(SectionWidth + x1 + 1, y);
    Write(Copy(Text2, 1, SectionWidth - 1));

    GotoXY(2 * SectionWidth + x1 + 1, y);
    Write(Copy(Text3, 1, SectionWidth - 1));

    GotoXY(3 * SectionWidth + x1 + 1, y);
    Write(Copy(Text4, 1, SectionWidth));
  end;

var
  Size: TPoint;
begin
  Size := GetConsoleSize;
  CursorOff;
  DrawBox(x1, y1, x2, y2);
  gotoXY(x1 + 1, y1 + 1);
  Write(StringOfChar(' ', x2 - x1 - 1));
  gotoXY((x2 + x1 - length(Title)) div 2, y1 + 1);
  Write(Title);
  DrawHLine(x1, x2, y1 + 2, True);
  DrawHLine(x1, x2, y2 - 3, True);

  ClrScr(x1 + 1, y2 - 2, x2, y2 - 1);
  DrawFootText(x1, y2 - 2, x2, Text1, Text2, Text3, Text4);
  DrawFootText(x1, y2 - 1, x2, Text5, Text6, Text7, Text8);
end;

function MsgBox(Msg1, Msg2: string): char;
var
  Size: TPoint;
begin
  Size := GetConsoleSize;
  ClrScr(2, Size.y - 3, Size.x - 1, Size.y - 2);
  CursorOff;
  GotoXY((Size.x - length(Msg1)) div 2, Size.y - 3);
  Write(Msg1);
  GotoXY((Size.x - length(Msg2)) div 2, Size.y - 2);
  Write(Msg2);
  Result := Chr(ReadKeyboard);
end;

function Confirm(Msg: string): boolean;
begin
  Result := LowerCase(MsgBox(Msg + ' ? (y/n) ', '')) = 'y';
end;

function ShowBoxInfo(Title, Content: string; var index: integer;
  Select, Wrap: boolean): integer;
const
  MinWidth = 60;
var
  Size: TPoint;
  i, w, x1, y1, x2, y2: integer;
  ListViewer: TListViewer;
begin
  ListViewer := TListViewer.Create;
  try
    Size := GetConsoleSize;
    w := (Size.x div 3) * 2;
    if w < MinWidth then
      w := MinWidth;
    if w > Size.x - 4 then
    begin
      x1 := 1;
      x2 := Size.x;
    end
    else
    begin
      x1 := (Size.x - w) div 2;
      x2 := x1 + w - 1;
    end;
    y1 := Size.y div 3;
    y2 := size.y - 2;
    if Wrap then
      Content := WordWrap(Content, x2 - x1 - 1);
    ListViewer.x1 := x1 + 1;
    ListViewer.y1 := y1 + 3;
    ListViewer.x2 := x2 - 1;
    ListViewer.y2 := y2 - 4;
    if Select then
    begin
      DrawBBox(x1, y1, x2, y2, Title,
        'F3=Back', 'Enter=Select', '', '',
        '', '', '', '');

      ListViewer.ExitKeys := [vkReturn, vkF3, vkEscape];
      ListViewer.ShowFilter := True;
      ListViewer.List.Text := Content;
      ListViewer.SelectedIndex := Index;
      Result := ListViewer.Show;
      Index := ListViewer.SelectedIndex;
    end
    else
    begin
      DrawBBox(x1, y1, x2, y2, Title,
        'F3=Back', '', '', '',
        '', '', '', '');
      ListViewer.ExitKeys := [vkF3, vkEscape];
      ListViewer.ShowFilter := False;
      ListViewer.List.Text := Content;
      ListViewer.SelectedIndex := 0;
      Result := ListViewer.Show;
      Index := 0;
    end;
  finally
    ListViewer.Free;
  end;
end;

procedure ExecDo(var index: integer; var FileName: string; Screen: TScreen);
const
  BUF_SIZE = 4096;
var
  BytesRead: longint;
  Buffer: array[1..BUF_SIZE + 1] of char;
  Line: string;
  i: integer;
begin
  if Index < 0 then
    Exit;
  if Screen.ScreenType = stMenu then
  begin
    FileName := Screen.Items[index].Action;
    Index := 0;
  end
  else
  begin
    for i := 0 to Screen.Items.Count - 1 do
    begin
      if Screen.Items[i].Required and (Screen.Items[i].Value = '') then
      begin
        MsgBox('Warning this field is required', '"' + Screen.Items[i].Caption + '"');
        Index := i;
        exit;
      end;
    end;
    if Confirm('Confirm the execution of the command') then
    begin
      ClearConsole;
      with TProcess.Create(nil) do
      begin
        {%H-}
        CommandLine := GetScriptShell(Screen.Action, Screen, True);
        {%H+}
        if not Screen.LogConsole or NoLog then
        begin
          Options := [];
          Execute;
        end
        else
        begin
          writeln('Output :');
          AddLog('Output : '#10, True);
          Options := [poUsePipes];
          Execute;
          while Running or (Output.NumBytesAvailable > 0) do
          begin
            if Output.NumBytesAvailable > 0 then
            begin
              BytesRead := Output.Read(Buffer, SizeOf(Buffer) - 1);
              Line := '';
              for i := 1 to BytesRead do
                if Buffer[i] = #10 then
                  Line := Line + #13#10
                else
                  Line := Line + Buffer[i];
              Write(Line);
              AddLog(Line, True);
            end;
            if KeyPressed then
            begin
              ReadLn(Line);
              Line := Line + #13#10;
              Input.Write(Line[1], Length(Line));
              AddLog(Line, True);
            end;
            Sleep(20);
          end;
        end;
        WaitOnExit;
        AddLog(Screen.Name + #10 + 'Exit code : ' + IntToStr(ExitCode) + #10);
        writeln(chr(13));
        if ExitCode <> 0 then
        begin
          InvVideo;
          writeln('Error return code=', ExitCode, ' ');
          NormVideo;
        end
        else
          Write('Ended, ');
        writeln('press any key to return previous screen.');
        Free;
      end;
      CursorOff;
      ReadKeyboard;
      clrscr;
    end;
  end;
end;

procedure ExecList(Index: integer; Screen: TScreen);
var
  List: TStringList;
  SelectedIndex, Key, i: integer;
  Values, Command: string;
  Dyn: boolean;
begin
  if Screen.Items[Index].ItemType in [itList, itYesNo] then
  begin
    List := TStringList.Create;
    try
      Dyn := False;
      if Screen.Items[Index].ItemType = itYesNo then
      begin
        List.Add('yes');
        List.Add('no');
      end
      else
      begin
        Values := Trim(Screen.Items[Index].Values);
        if Pos('$(', Values) = 0 then
          List.CommaText := Values
        else
        begin
          Command := Trim(Copy(Values, 3, Length(Values)));
          if Copy(Command, Length(Command)) = ')' then
            Command := Copy(Command, 1, Length(Command) - 1);
          List.Text := GetExecConsole(Command, Screen);
          Dyn := True;
        end;
      end;
      SelectedIndex := List.IndexOf(Screen.Items[Index].Value);
      Key := ShowBoxInfo('List for ' + Screen.Items[Index].Caption,
        List.Text, SelectedIndex, True, False);
      if Key = vkReturn then
      begin
        if Dyn then
          for i := 0 to Screen.Items.Count - 1 do
            Screen.Items[i].Value := '';
        if SelectedIndex <> -1 then
          Screen.Items[Index].Value := List[SelectedIndex];
      end;
    finally
      List.Free;
    end;
  end;
end;

function ConfirmStop: boolean;
begin
  Result := Confirm('Do you confirm the exit');
end;

function ExecBack(var Index: integer; var FileName: string; Screen: TScreen): boolean;
begin
  if Screen.ParentFile <> '' then
  begin
    FileName := Screen.ParentFile;
    Index := 0;
    Result := False;
  end
  else
    Result := ConfirmStop;
end;

function ShowScreenForm(var Index: integer; Screen: TScreen): integer;

  function GetValue(Value: string): string;
  var
    Command: string;
  begin
    if Pos('$(', Value) = 0 then
      Result := Value
    else
    begin
      Command := Trim(Copy(Value, 3, Length(Value)));
      if Copy(Command, Length(Command)) = ')' then
        Command := Copy(Command, 1, Length(Command) - 1);
      Result := GetExecConsole(Command, Screen);
      if Pos('Error :', Result) = 1 then
        Result := '';
    end;
    Result := StringReplace(Result, #13, '', [rfReplaceAll]);
    Result := StringReplace(Result, #10, ' ', [rfReplaceAll]);
  end;

  function IsDisplayable(Item: TItemScreen): boolean;
  var
    ix: integer;
  begin
    Result := True;
    if Item.Condition <> '' then
    begin
      ix := Screen.IndexOfName(Item.Condition);
      Result := (ix > -1) and (Screen.Items[ix].Value <> '');
    end;
  end;

var
  i, y, w: integer;
  Field: TFieldEdit;
  FieldsEditor: TFieldsEditor;
  Size: TPoint;
  Item: TItemScreen;
begin
  FieldsEditor := TFieldsEditor.Create;
  FieldsEditor.ExitKeys := [vkReturn, vkEscape, vkF1, vkF2, vkF3, vkF4, vkF5, vkF6];
  try

    Size := GetConsoleSize;
    DrawBBox(1, 1, Size.x, Size.y - 1, Screen.Title,
      'F1=Help', 'F2=Refresh', 'F3=Back', 'F4=List +',
      'F5=Shorcut', 'F6=Shell', 'Enter=Do', 'Esc=Exit');
    ClrScr(2, 4, Size.x, Size.Y - 5);
    CursorOff;

    for i := 0 to Screen.Items.Count - 1 do   //Into 2 pass for visual aspect
    begin
      Item := Screen.Items[i];
      if IsDisplayable(Item) then
      begin
        y := i + 4;
        w := Size.X div 3;
        GotoXY(2, y);
        Write(Copy(Item.Caption, 1, (w * 2) - 2));
        GotoXY((w * 2) - 2, y);
        if Item.ItemType in [itList, itYesNo] then
          Write('+[')
        else if Item.Required then
          Write('*[')
        else if Item.ItemType = itNumeric then
          Write('#[')
        else
          Write(' [');
        GotoXY((w * 3) - 1, y);
        Write(']');
      end;
    end;
    for i := 0 to Screen.Items.Count - 1 do
    begin
      Item := Screen.Items[i];
      if IsDisplayable(Item) then
      begin
        y := i + 4;
        w := Size.X div 3;
        Field := TFieldEdit.Create;
        Field.Name := Item.Name;
        Field.Row := y;
        Field.Col := w * 2;
        Field.Size := w - 1;
        Field.Value := Item.Value;
        if Field.Value = '' then
          Field.Value := GetValue(Item.Default);
        if Item.ItemType = itNumeric then
          Field.FieldType := ftInteger
        else
          Field.FieldType := ftString;
        Field.ReadOnly := Item.ItemType in [itList, itYesNo];
        FieldsEditor.Fields.Add(Field);
      end;
    end;
    FieldsEditor.FieldIndex := Index;
    Result := FieldsEditor.Edit;
    Index := FieldsEditor.FieldIndex;
    for i := 0 to Screen.Items.Count - 1 do
      if i < FieldsEditor.Fields.Count then
        Screen.Items[i].Value := Trim(FieldsEditor.Fields[i].Value)
      else
        Screen.Items[i].Value := '';
  finally
    FieldsEditor.Free;
  end;
end;

function ShowScreenMenu(var Index: integer; Screen: TScreen): integer;
var
  i: integer;
  ListViewer: TListViewer;
  Size: TPoint;
begin
  ListViewer := TListViewer.Create;
  try
    for i := 0 to Screen.Items.Count - 1 do
      ListViewer.List.Add(Screen.Items[i].Caption);

    Size := GetConsoleSize;
    DrawBBox(1, 1, Size.x, size.y - 1, Screen.Title,
      'F1=Help', 'F2=Refresh', 'F3=Back', '',
      'F5=Shorcut', 'F6=Shell', 'Enter=Do', 'Esc=Exit');

    ListViewer.x1 := 2;
    ListViewer.y1 := 4;
    ListViewer.x2 := Size.x - 1;
    ListViewer.y2 := Size.y - 5;
    ListViewer.SelectedIndex := Index;
    ListViewer.ExitKeys := [vkReturn, vkEscape, vkF1, vkF2, vkF3, vkF5, vkF6];
    Result := ListViewer.Show;
    Index := ListViewer.SelectedIndex;
  finally
    ListViewer.Free;
  end;
end;

function ShowScreenReport(var Index: integer; Screen: TScreen;
  const simpleReport: boolean = True): integer;
var
  i: integer;
  ListViewer: TListViewer;
  Size: TPoint;
  Table: TCsvTTYTable;
  Content: string;
begin
  ListViewer := TListViewer.Create;
  Table := TCsvTTYTable.Create;
  try
    Size := GetConsoleSize;
    DrawBBox(1, 1, Size.x, size.y - 1, Screen.Title,
      'F1=Help', 'F2=Refresh', 'F3=Back', '',
      'F5=Shorcut', 'F6=Shell', '', 'Esc=Exit');
    Content := GetExecConsole(Screen.Action, Screen);
    if (Pos('Error :', Content) = 0) and not SimpleReport then
    begin
      Table.WidthMin := Size.x - 1;
      Table.DisplayMode := dmPartialTable;
      Table.LoadFromString(Content);
      ListViewer.List.Text := Table.GetOutputString;
    end
    else
      ListViewer.List.Text := Content;
    ListViewer.x1 := 2;
    ListViewer.y1 := 4;
    ListViewer.x2 := Size.x - 1;
    ListViewer.y2 := Size.y - 5;
    ListViewer.SelectedIndex := Index;
    ListViewer.ExitKeys := [vkEscape, vkF1, vkF2, vkF3, vkF5, vkF6];
    ListViewer.ShowFilter := True;
    Result := ListViewer.Show;
    Index := 0;
  finally
    Table.Free;
    ListViewer.Free;
  end;
end;

procedure ShowHelp(Index: integer; Screen: TScreen);
var
  Dummy: integer;
  Content: string;
begin
  Dummy := 0;
  if Screen.ScreenType = stMenu then
    Content := Screen.Help
  else
    Content := Screen.Items[Index].Help;
  ShowBoxInfo('Help', Content, Dummy, False, True);
end;

procedure ShowShortCuts(FileName: string; Screen: TScreen);
var
  Dummy: integer;
  ExeFile, Content: string;
begin
  Dummy := 0;
  ExeFile := ExtractFileName(ParamStr(0));
  Content := 'Shortcut    : ' + ExeFile + ' ' + FileName;
  if Screen.ShortCut <> '' then
    Content := Content + #10 + 'Shortcut    : ' + ExeFile + ' ' + Screen.ShortCut;
  Content := Content + #10 + 'Screen file : ' +
    ExtractFileName(ScreenFileName(FileName));
  ShowBoxInfo('Shortcuts', Content, Dummy, False, False);
end;

procedure ShowShellCommand(Index: integer; Screen: TScreen);
var
  Dummy: integer;
  Content: string;
begin
  Dummy := 0;
  if Screen.ScreenType = stMenu then
    Content := Screen.Items[Index].Action
  else
    Content := Screen.Action;
  ShowBoxInfo('Shell command', Content, Dummy, False, False);
end;

function GetAppName: string;
begin
  Result := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
end;

procedure UpdateScreenFiles;

  function DecodeCaption(Caption: string): string;
  begin
    Result := StringReplace(Caption, '_', ' ', [rfReplaceAll]);
    Result := StringReplace(Result, 'mgmt', 'management', [rfReplaceAll]);
  end;

  procedure Proceed;
  var
    Files: TSearchRec;
    io, i: integer;
    Screen, ScreenP: TScreen;
    Action, ParentFile, ParentFileName: string;
    Found: boolean;
    FFile: TStringList;
  begin
    FFile := TStringList.Create;
    Screen := TScreen.Create;
    ScreenP := TScreen.Create;
    io := FindFirst(ScreenFileName('*'), faAnyfile, Files);
    while io = 0 do
    begin
      Screen.LoadFromFile(ScreenFileName(Files.Name));
      if Files.Name <> 'main_menu.scr' then
      begin
        ParentFile := Screen.ParentFile;
        if ParentFile = '' then
          ParentFile := 'main_menu';
        ParentFileName := ScreenFileName(ParentFile);
        if not FileExists(ParentFileName) then
        begin
          writeln('Create menu file ' + ParentFile);
          FFile.Clear;
          FFile.Add('#Menu added by ' + GetAppName);
          FFile.Add('title = ' + DecodeCaption(ParentFile));
          FFile.Add('type = menu');
          if ParentFile <> 'main_menu' then
            FFile.Add('parent = main_menu');
          FFile.Add('');
          FFile.SaveToFile(ParentFileName);
        end;
        ScreenP.LoadFromFile(ParentFileName);
        if ScreenP.ScreenType <> stMenu then
        begin
          writeln('Error parent, is not menu');
          break;
        end;
        Found := False;
        Action := ChangeFileExt(Files.Name, '');
        for i := 0 to ScreenP.Items.Count - 1 do
          if ScreenP.Items[i].Action = Action then
            Found := True;
        if not Found then
        begin
          Writeln('Add ' + Action + ' to ' + Screen.ParentFile);
          FFile.LoadFromFile(ParentFileName);
          FFile.Add('#Item added by ' + GetAppName);
          FFile.Add('caption = ' + DecodeCaption(Screen.Title));
          if Screen.Help <> '' then
            FFile.Add('help = ' + Screen.Help);
          FFile.Add('action = ' + Action);
          FFile.Add('');
          FFile.SaveToFile(ParentFileName);
        end;
      end;
      io := FindNext(Files);
    end;
    FindClose(Files);
    FFile.Free;
    Screen.Free;
    ScreenP.Free;
  end;

begin
  writeln('Update screen files');
  writeln('Pass 1');
  Proceed;
  writeln('Pass 2');
  Proceed;
  writeln('Procedure terminated');
  halt(0);
end;

procedure VerifyScreenFiles;

  procedure Proceed;
  var
    io, i: integer;
    Files: TSearchRec;
    Screen: TScreen;
    FileName:String;
  begin
    Screen := TScreen.Create;
    try
      io := FindFirst(ScreenFileName('*'), faAnyfile, Files);
      while io = 0 do
      begin
        writeln('Verify ' + Files.Name);
        Screen.LoadFromFile(ScreenFileName(Files.Name));
        if Screen.ScreenType=stMenu then
        begin
          for i:=0 to Screen.Items.Count-1 do
          begin
            FileName:=ScreenFileName(Screen.Items[i].Action);
            if Not FileExists(FileName) then
              Raise(Exception.Create(FileName+' not found in '+ScreenFileName(Files.Name)));
          end;
        end;
        io := FindNext(Files);
      end;
      FindClose(Files);
    finally
      Screen.Free;
    end;
  end;

begin
  writeln('Verify screen files');
  Proceed;
  writeln('Procedure terminated, no error détected');
  halt(0);
end;

procedure BuildShortCuts;
begin
  writeln('Build shorcuts');
  ShortCuts.Build;
  writeln('Procedure terminated');
  halt(0);
end;

procedure ShowSysHelp;
begin
  WriteLn('Usage: ' + GetAppName + ' [options] [shortcut]');
  WriteLn('Available options:');
  WriteLn('  -h, --help      Show this help');
  WriteLn('  -v, --version   Show the version');
  WriteLn('  -a, --ascii     Run in ascii characters');
  WriteLn('  -n, --nolog     No log file generation, for console trouble or other');
  WriteLn('  -w, --wsl       Use Windows Subsystem for Linux');
  WriteLn('  -l, --log       (-l File) Redirects the nssmitty.log file to the specified File.');
  WriteLn('  -s, --script    (-s File) Redirects the nssmitty.sh script file to the specified File.');
  WriteLn('  -U, --update    Build screens database, connects new screens to existing menus');
  WriteLn('  -V, --verify    Verify screens database');
  WriteLn('  -B, --build     Build shortcuts dico');
end;

procedure CheckParameters(var FileName: string);
var
  Option: string;
  i: integer;
begin
  i := 1;
  while i <= ParamCount do
  begin
    Option := ParamStr(i);
    if (Option = '-h') or (Option = '--help') then
    begin
      ShowSysHelp;
      halt(0);
    end
    else if (Option = '-v') or (Option = '--version') then
    begin
      Write('@Copyright (C) 2025 Written by NEUTS JL ');
      WriteLn(GetAppName + ' ' + KVersion);
      halt(0);
    end
    else if (Option = '-a') or (Option = '--ascii') then
      CurrentBorderStyle := bsAscii
    else if (Option = '-n') or (Option = '--nolog') then
      NoLog := True
    else if (Option = '-w') or (Option = '--wsl') then
    begin
      {$IFDEF WINDOWS}
        WSL:=true;
      {$ENDIF}
      {$IFDEF LINUX}
        writeln('Only for windows');
        halt(0);
      {$ENDIF}
    end
    else if (Option = '-l') or (Option = '--log') then
    begin
      Inc(i);
      LogFileName := ParamStr(i);
    end
    else if (Option = '-s') or (Option = '--script') then
    begin
      Inc(i);
      ScriptFileName := ParamStr(i);
    end
    else if (Option = '-U') or (Option = '--update') then
      UpdateScreenFiles
    else if (Option = '-V') or (Option = '--verify') then
      VerifyScreenFiles
    else if (Option = '-B') or (Option = '--build') then
      BuildShortCuts
    else if Copy(Option, 1, 1) = '-' then
    begin
      WriteLn('Unknown option : ', Option);
      halt(0);
    end
    else
      FileName := ShortCuts.GetFileName(Option);
    Inc(i);
  end;
end;

procedure Main;
var
  Key, Index: integer;
  FileName: string;
  Screen: TScreen;
  Stop, Interactive: boolean;
begin
  CurrentBorderStyle := bsSimple;
  NoLog := False;
  LogFilename := '';
  ScriptFilename := '';
  FileName := '';
  WSL := False;
  Index := -1;
  Stop := False;
  Interactive := False;
  Screen := TScreen.Create;
  try
    ShortCuts.Load;
    CheckParameters(FileName);
    if (LogFilename <> '') and NoLog then
      raise(Exception.Create('-l,--log option not compatible with -n,nolog option'));
    if FileName = '' then
      FileName := 'main_menu';
    Interactive := True;
    repeat
      Screen.LoadFromFile(ScreenFileName(FileName));
      case Screen.screenType of
        stMenu:
          Key := ShowScreenMenu(Index, Screen);
        stForm:
          Key := ShowScreenForm(Index, Screen);
        stReport:
          Key := ShowScreenReport(Index, Screen);
        stDisplay:
          Key := ShowScreenReport(Index, Screen, True);
      end;
      case Key of
        vkF1:
          ShowHelp(Index, Screen);
        vkF2:
          ClrScr;
        vkF3:
          Stop := ExecBack(Index, FileName, Screen);
        vkF4:
          ExecList(Index, Screen);
        vkF5:
          ShowShortCuts(FileName, Screen);
        vkF6:
          ShowShellCommand(Index, Screen);
        vkReturn:
          ExecDo(Index, FileName, Screen);
        vkEscape:
          Stop := ConfirmStop;
      end;
    until Stop;
    ClearConsole;
  except
    on E: Exception do
    begin
      if Interactive then
        ClearConsole;
      writeln(e.message);
    end;
  end;
  Screen.Free;
  CursorOn;
end;

end.
