unit uscreenfile;

{$mode ObjFPC}{$H+}
{$notes off}


interface

uses
  Classes, SysUtils, fgl;

type
  TScreenType = (stNone, stMenu, stForm, stReport);
  TItemType = (itNone, itAction, itInput, itNumeric, itList, itYesNo);

  TItemScreen = class
    Caption: string;
    Name: string;
    ShortCut:string;
    Help: string;
    Action: string;
    Condition: string;
    ItemType: TItemType;
    Default: string;
    Required: boolean;
    Values: string;
    Value: string;
    constructor Create;
  end;

  TTItemsScreen = specialize TFPGList<TItemScreen>;

  TItemsScreen = class(TTItemsScreen);

  TScreen = Class
  private
    OldFileName: string;
    FName:string;
    FTitle: string;
    FParentFile: string;
    FLogConsole:boolean;
    FShortCut:string;
    FHelp: string;
    FAction: string;
    FScreenType: TScreenType;
    FItems:TItemsScreen;
  public
    Constructor Create;
    Destructor Destroy;override;
    procedure Clear;
    function IndexOfName(Const AName:string):integer;
    function NameExists(Const AName:string):boolean;
    procedure LoadFromFile(const FileName: string);
    property Name: string read FName;
    property Title: string read FTitle;
    property ParentFile: string read FParentFile;
    property LogConsole:boolean read FLogConsole write FLogConsole;
    property ShortCut:string read FShortCut;
    property Help: string read FHelp;
    property Action: string read FAction;
    property ScreenType: TScreenType read FScreenType;
    property Items:TItemsScreen read FItems;
  end;

  TShortCuts=class(TStringList)
  public
    procedure Load;
    procedure Build;
    function IndexOf(Const ShortCut:String):Integer;override;
    function Exists(Const ShortCut:string):boolean;
    function GetFileName(Const ShortCut:string):string;
  end;

var
  ShortCuts:TShortCuts;

function ScreenFileName(FileName:string):string;

implementation

function ScreenFileName(FileName:string):string;
begin
  Result:=ExtractFilePath(Paramstr(0))+'screens/'+FileName;
  if ExtractFileExt(Result)='' then
    Result:=Result+'.scr';
end;

procedure TShortCuts.Load;
begin
  if FileExists(ScreenFileName('shorcuts.dic')) then
    LoadFromFile(ScreenFileName('shorcuts.dic'));
end;

procedure TShortCuts.Build;
var
  io:integer;
  Files:TSearchRec;
  Screen:TScreen;
begin
  Clear;
  Add('#Do not modify, written by nssmitty!');
  Add('#Add a "shortcut" tag while waiting for your screen files');
  Screen:=TScreen.Create;
  try
    io:=FindFirst(ScreenFileName('*'),faAnyfile,Files);
    while io=0 do
    begin
      Screen.LoadFromFile(ScreenFileName(Files.Name));
      if Screen.ShortCut<>'' then
      begin
        if Exists(Screen.ShortCut) then
          Raise(Exception.Create(Format('The shortcut [%s] already exists in file %s',
            [Screen.ShortCut,Files.Name])));
        Add(Screen.ShortCut+'='+ChangeFileExt(Files.Name,''));
      end;
      io:=FindNext(Files);
    end;
    FindClose(Files);
    SaveToFile(ScreenFileName('shorcuts.dic'));
  finally
    Screen.Free;
  end;
end;

function TShortCuts.IndexOf(Const ShortCut:String):integer;
var
  i:integer;
begin
  for i:=0 to Count-1 do
    if Names[i]=ShortCut then
      exit(i);
  Result:=-1;
end;

function TShortCuts.Exists(Const ShortCut:string):boolean;
begin
  Result:=IndexOf(ShortCut)<>-1;
end;

function TShortCuts.GetFileName(Const ShortCut:string):string;
var
  ix:integer;
begin
  ix:=IndexOf(ShortCut);
  if ix=-1 then
    Result:=ShortCut
  else
    Result:=self.ValueFromIndex[ix];
end;

constructor TItemScreen.Create;
begin
  inherited;
  Caption := '';
  Name := '';
  ShortCut:='';
  Help := '';
  Action := '';
  Condition := '';
  ItemType := itNone;
  Default := '';
  Required := False;
  Values := '';
  Value := '';
end;

Constructor TScreen.Create;
begin
  inherited;
  FItems:=TItemsScreen.Create;
  Clear;
end;

Destructor TScreen.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TScreen.Clear;
begin
  FTitle:='';
  FParentFile:='';
  FLogConsole:=True;
  FShortCut:='';
  FHelp:='';
  FAction:='';
  FScreenType:=stnone;
  FItems.Clear;
end;

function TScreen.IndexOfName(Const AName:string):integer;
var
  i:integer;
begin
  for i:=0 to FItems.Count-1 do
    if FItems[i].Name=AName then
      Exit(i);
  Result:=-1;
end;

function TScreen.NameExists(Const AName:string):boolean;
begin
  Result:=IndexOfName(AName)<>-1;
end;

procedure TScreen.LoadFromFile(const FileName: string);
Const
  TMPLF=#255;
var
  FFile: TStringList;
  NLine: integer;
  Item: TItemScreen;

  procedure Error(Msg: string);
  begin
    raise(Exception.Create(Format('%s at line %d in file %s', [Msg, NLine+1, FileName])));
  end;

  procedure AssignedError(TagName: string);
  begin
    Error(Format('%s is already assigned', [TagName]));
  end;

  procedure TreatTagTitle(Value:string);
  begin
    if FItems.Count > 0 then
      Error('Not appropriate here');
    FTitle := Value;
  end;

  procedure TreatTagCaption(Value:string);
  begin
    if FScreenType = stNone then
      Error('The screen type in the first section has not been defined');
    if FScreenType = stReport then
      Error('This type of "report" screen does not support items');
    Item := TItemScreen.Create;
    Item.Caption := Value;
    FItems.Add(Item);
  end;

  procedure TreatTagType(Value: string);
  begin
    Value := LowerCase(Value);
    if FItems.Count = 0 then
    begin
      if Value = 'form' then
        FScreenType := stForm
      else if Value = 'menu' then
        FScreenType := stMenu
      else if Value = 'report' then
        FScreenType := stReport
      else
        Error('Incorrect type : ' + Value);
    end
    else
    begin
      if FScreenType = stMenu then
        Error('Not suitable with a menu screen');
      if Item.ItemType <> itNone then
        AssignedError('type');
      if Value = 'action' then
        Item.ItemType := itAction
      else if Value = 'input' then
        Item.ItemType := itInput
      else if Value = 'numeric' then
        Item.ItemType := itNumeric
      else if Value = 'list' then
        Item.ItemType := itList
      else if Value = 'yesno' then
        Item.ItemType := itYesNo
      else
        Error('Incorrect type : ' + Value);
    end;
  end;

  procedure TreatTagParent(Value: string);
  begin
    if Fitems.Count > 0 then
      Error('Not appropriate here');
    if FParentFile <> '' then
      AssignedError('parent');
    FParentFile := Value;
  end;

  procedure TreatTagName(Value: string);
  begin
    if FItems.Count = 0 then
      Error('Not appropriate here');
    if Item.Name <> '' then
      AssignedError('name');
    if NameExists(Value) then
       Error('Name ['+Value+'] already exists');
    Item.Name := Value;
  end;

  procedure TreatTagShortCut(Value: string);
  begin
    if FItems.Count > 0  then
      Error('Not appropriate here');
    if FShortCut <> '' then
      AssignedError('shortcut');
    FShortCut := Value;
  end;

  procedure TreatTagLogConsole(Value: string);
  begin
    if FItems.Count > 0  then
      Error('Not appropriate here');
    if FScreenType = stMenu then
      Error('incompatible type with screen menu');
    if FScreenType = stReport then
      Error('incompatible type with screen report');
    Value:=LowerCase(Value);
    if Value='yes' then
      FLogConsole := True
    else if Value='no' then
      FLogConsole := False
    else
      Error('Value error for LogConsole tag: yes or no expected');
  end;

  procedure TreatTagHelp(Value: string);
  begin
    if FItems.Count=0 then
    begin
      if FHelp<>'' then
         AssignedError('help');
      FHelp:=Value;
    end
    else
    begin
      if Item.Help <> '' then
        AssignedError('help');
      Item.Help := Value;
    end;
  end;

  procedure TreatTagDefault(Value: string);
  begin
    if FItems.Count = 0 then
      Error('Not appropriate here');
    if Item.Default <> '' then
      AssignedError('Default');
    Item.Default := Value;
  end;

  procedure TreatTagValues(Value: string);
  begin
    if FItems.Count = 0 then
      Error('Not appropriate here');
    if Item.Values <> '' then
      AssignedError('Values');
    Item.Values := Value;
  end;

  procedure TreatTagRequired(Value: string);
  begin
    if FItems.Count = 0 then
      Error('Not appropriate here');
    Value := LowerCase(Value);
    if Value = 'yes' then
      Item.Required := True
    else if Value = 'no' then
      Item.Required := False
    else
      Error('yes or no expected');
  end;

  procedure TreatTagAction(Value: string);
  begin
    if (FItems.Count = 0) and (FScreenType = stMenu) then
      Error('incompatible type with screen menu');
    if (FItems.Count > 0) and (FScreenType = stForm) then
      Error('incompatible type with screen Form');
    if (FItems.Count > 0) and (FScreenType = stForm) and (Item.ItemType = itNone) then
      Error('Prior declaration of type is mandatory');
    if FItems.Count=0 then
    begin
      if FAction <> '' then
        AssignedError('Action');
      FAction := Value;
    end
    else
    begin
      if Item.Action <> '' then
        AssignedError('Action');
      Item.Action := Value;
    end;
  end;

  procedure TreatTagCondition(Value: string);
  begin
    if FItems.Count = 0 then
      Error('Not appropriate here');
    if not NameExists(Value) then
      Error('The name ['+Value+'] does not exist statify the condition');
    Item.condition := Value;
  end;

  function GetLine:string;
  var
    p:integer;
    Line,SLine:string;
  begin
    Line := TrimRight(FFile[NLine]);
    p := pos('#', Line);
    if p > 0 then
      Line := Copy(Line, 1, p - 1);
    Line := TrimRight(Line);

    // For multilines....
    //xxxxxx = \
    //  if [ "$Confirm" = "yes" ]; then
    //    CMD="useradd -m -s $User_Shell"
    //    [ -n "$Home_Directory" ] && CMD="$CMD -d $Home_Directory"
    //    [ -n "$User_Groups" ] && CMD="$CMD -G $User_Groups"
    //    CMD="$CMD $Username"
    //    eval "$CMD"
    //  else
    //    echo "User creation cancelled."
    //  fi
    if copy(Line,Length(Line),1)='\' then
    begin
      p:=Length(Line)-1;
      while (p>1) and (Copy(Line,p,1)=' ') do
        dec(p);
      if Copy(Line,p,1)='=' then   // Is ok ?
      begin
        SLine:=Copy(Line,1,p);
        Inc(NLine);
        //concat while indent is good
        while (NLine<FFile.Count) and (Copy(FFile[NLine],1,2)='  ') do
        begin
          SLine:=SLine+Copy(FFile[NLine],3,Length(FFile[NLine]))+TMPLF;
          inc(NLine);
        end;
        Line:=SLine;
      end
      else  //Other multilines style :
            //xxxxxxxxx = abcde \
            //            aaaaaaaaa\
            //            bbbbbb
      begin
        while (Line<>'') and (Line[Length(Line)] = '\') and (NLine < FFile.Count - 1) do
        begin
          Delete(Line, Length(Line), 1);
          Inc(NLine);
          Line := Line + TrimLeft(FFile[NLine]);
        end;
      end;
    end;
    Result:=Line;
  end;

var
  Line, TagName, Value: string;
  p: integer;
begin
  if (FileName = OldFileName) and (FItems.Count > 0) then
    exit;
  OldFileName := FileName;
  FFile := TStringList.Create;
  try
    Clear;
    FName:=ExtractFileName(FileName);
    FFile.loadFromFile(FileName);
    NLine:=0;
    while NLine<FFile.Count do
    begin
      Line := GetLine;
      if Line <> '' then
      begin
        p := Pos('=', Line);
        if p = 0 then
          Error('= required');
        TagName := LowerCase(Trim(Copy(Line, 1, p - 1)));
        Value := Trim(Copy(Line, p + 1, Length(Line)));
        Value:=StringReplace(Value,TMPLF,#10,[rfReplaceAll]);
        if TagName = 'title' then
          TreatTagTitle(Value)
        else if TagName = 'caption' then
          TreatTagCaption(Value)
        else if Item = nil then
          Error('Title field required first')
        else if TagName = 'parent' then
          TreatTagParent(Value)
        else if TagName = 'type' then
          TreatTagType(Value)
        else if TagName = 'name' then
          TreatTagName(Value)
        else if TagName = 'shortcut' then
          TreatTagShortCut(Value)
        else if TagName = 'logconsole' then
          TreatTagLogConsole(Value)
        else if TagName = 'help' then
          TreatTagHelp(Value)
        else if TagName = 'default' then
          TreatTagDefault(Value)
        else if TagName = 'values' then
          TreatTagValues(Value)
        else if TagName = 'required' then
          TreatTagRequired(Value)
        else if TagName = 'action' then
          TreatTagAction(Value)
        else if TagName = 'condition' then
          TreatTagCondition(Value)
        else
          Error('Incorrect tag : "' + TagName+'"');
      end;
      inc(NLine);
    end;
  finally
    FFile.Free;
  end;
end;

initialization
  ShortCuts:=TShortCuts.Create;
finalization
  ShortCuts.Free;
end.
