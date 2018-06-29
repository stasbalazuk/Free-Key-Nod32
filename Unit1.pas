unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  HttpSend, ssl_openssl,
  IniFiles,
  StrUtils,
  clipbrd,
  XPMan,
  RegExpr,
  UrlMon, MSHTML, activex,
  Dialogs, StdCtrls, ComCtrls, CoolTrayIcon, Menus;

type
  TForm1 = class(TForm)
    btn1: TButton;
    cbb1: TComboBox;
    stat1: TStatusBar;
    chk1: TCheckBox;
    TrayIcon1: TCoolTrayIcon;
    pm1: TPopupMenu;
    Exit1: TMenuItem;
    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbb1Change(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Exit1Click(Sender: TObject);
  private
    status: Boolean;
    procedure WMQueryEndSession(var Message: TMessage); message WM_QUERYENDSESSION;
  public
    ips,ports: string;
  end;

var
  Form1: TForm1;
  s: string;
  strings,s0,s1: TStrings;
  sx,TMPERR,TMPKOD,TMPINF: TStringList;

implementation

{$R *.dfm}

//Удачно выйти из Винды
procedure TForm1.WMQueryEndSession(var Message: TMessage);
begin
  Message.Result := 1;
  Application.Terminate;
end;

procedure CreateFormInRightBottomCorner;
var
 r : TRect;
begin
 SystemParametersInfo(SPI_GETWORKAREA, 0, Addr(r), 0);
 Form1.Left := r.Right-Form1.Width;
 Form1.Top := r.Bottom-Form1.Height;
end;

Procedure IniFileLoad;
var
   Ini : TIniFile;
begin
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0))+'settings.ini');
  Form1.ips:=Ini.ReadString('PROXY','IP','');
  Form1.ports:=Ini.ReadString('PROXY','PORT','');
  Ini.Free;
end;

Procedure IniFileProc;
Var
  Ini : TIniFile;
  dt,dt1,dt2: string;
Begin
  dt:=Copy(DateToStr(Date),1,2);
  dt1:=Copy(DateToStr(Date),4,2);
  dt2:=Copy(DateToStr(Date),7,4);
  dt:=dt2+dt1+dt;
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0))+'settings.ini');
  Ini.WriteString('PROXY','IP','127.0.0.1');
  Ini.WriteString('PROXY','PORT','3128');
  Ini.WriteString('DATE','NOW',dt);
  Ini.Free;
end;

//Защита от отладчика
function DebuggerPresent:boolean;
type
  TDebugProc = function:boolean; stdcall;
var
   Kernel32:HMODULE;
   DebugProc:TDebugProc;
begin
   Result:=false;
   Kernel32:=GetModuleHandle('kernel32.dll');
   if kernel32 <> 0 then
    begin
      @DebugProc:=GetProcAddress(kernel32, 'IsDebuggerPresent');
      if Assigned(DebugProc) then
         Result:=DebugProc;
    end;                                  
end;

Function SetClipboardText(Wnd: HWND; Value: String): BooLean;
Var hData: HGlobal; pData: Pointer; Len: Integer;
Begin
Result:=True;
If OpenClipboard(Wnd) Then
      Begin
      Try
            Len:=Length(Value)+1;
            hData:=GlobalAlloc(GMEM_MOVEABLE Or GMEM_DDESHARE, Len);
            Try
                  pData:=GlobalLock(hData);
                  Try
                        Move(PChar(Value)^, pData^, Len);
                        EmptyClipboard;
                        SetClipboardData(CF_Text, hData);
                  Finally
                        GlobalUnlock(hData);
                  End;
            Except
                  GlobalFree(hData);
                  Raise
            End;
      Finally
            CloseClipboard;
            End;
      End
Else
      Result:=False;
End;

function StrCut(SourceString,StartStr,EndStr:String):String;
Var I:Integer; Strn:String;
begin
Result:='';
strn:=SourceString;
i:=Pos(StartStr,Strn);
   if i > 0 then
   Strn:=Copy(Strn,i+Length(StartStr),Length(Strn)-Length(StartStr));
   i:=Pos(EndStr,Strn);
   if i=0 then
    begin
     i:=Length(Strn);
    end;
   Strn:=Copy(Strn,1,i);
 Result:=Strn;
end;

function Parse(const tag1, tag2, source: string): TStrings;
var
 s: string;
 p, p2, len: Integer;
begin
 Result := nil;
 p := Pos(tag1, source);
 len := Length(tag1);
 p2 := PosEx(tag2, source, p + len + 1);
 if (p = 0) or (p2 = 0) then Exit;
 Result := TStringList.Create;
 while (p > 0) and (p2 > 0) do
  begin
     if p2 > p then begin
        //Result.Add(Trim(Copy(source, p + len, p2 - p - len)));
        s:=Trim(Copy(source, p + len, p2 - p - len));
        s:=Copy(s,0,29);
        Result.Add(Trim(s));
     end;
     if (s = '<strong>Логин</strong>') or (s = '<strong>Пароль</strong>') then begin
         Result.Delete(Result.Count-1);
     end;
        p := PosEx(tag1, source, p2);
        p2 := PosEx(tag2, source, p + len + 1);
  end;
end;

function ParseDel(const tag1, tag2, source: string): TStrings;
var
 p, p2, len: Integer;
begin
 Result := nil;
 p := Pos(tag1, source);
 len := Length(tag1);
 p2 := PosEx(tag2, source, p + len + 1);
 if (p = 0) or (p2 = 0) then Exit;
 Result := TStringList.Create;
 while (p > 0) and (p2 > 0) do
  begin
     if p2 > p then begin
        Result.Add(Trim(Copy(source, p + len, p2 - p - len)));
        Result.Delete(Result.Count-1);
     end;
        p := PosEx(tag1, source, p2);
        p2 := PosEx(tag2, source, p + len + 1);
  end;
end;

function ParseM(const tag1, tag2, source: string): TStrings;
label vx;
var
 q,q1: Integer;
 s,s1,s2: string;
 p, p2, len: Integer;
begin
 Result := nil;
 p := Pos(tag1, source);
 len := Length(tag1);
 p2 := PosEx(tag2, source, p + len + 1);
 if (p = 0) or (p2 = 0) then Exit;
 Result := TStringList.Create;
 while (p > 0) and (p2 > 0) do
  begin
     if p2 > p then
        s:=Trim(Copy(source, p + len, p2 - p - len));
        q1:=Pos(s2,s);
     if (s1 <> s) and (s <> '') and (q1 = 0) then begin
        q:=Pos('Username',s);
        if q > 0 then begin
        q:=Pos('<br />',s);
        if q > 0 then
           s1:=Trim(Copy(s,1,q-1));
           Result.Add(s1);
           s2:=Trim(Copy(s,q+6,Length(s)));
           Result.Add(s2);
        end;
        vx:
        q:=Pos('<br />',s);
        if q > 0 then begin
        s1:=Copy(s,1,q-1);
        Delete(s,1,q+6);
        Result.Add(s1);
        end;
        q:=Pos('<br />',s);
        if q > 0 then goto vx
        else Result.Add(s);
     end;
        p := PosEx(tag1, source, p2);
        p2 := PosEx(tag2, source, p + len + 1);
  end;
end;

// запись в реестра
function RegWriteStr(RootKey: HKEY; Key, Name, Value: string): Boolean;
var
  Handle: HKEY;
  Res: LongInt;
begin
  Result := False;
  Res := RegCreateKeyEx(RootKey, PChar(Key), 0, nil, REG_OPTION_NON_VOLATILE,
    KEY_ALL_ACCESS, nil, Handle, nil);
  if Res <> ERROR_SUCCESS then
    Exit;
  Res := RegSetValueEx(Handle, PChar(Name), 0, REG_SZ, PChar(Value),
    Length(Value) + 1);
  Result := Res = ERROR_SUCCESS;
  RegCloseKey(Handle);
end;

procedure TForm1.btn1Click(Sender: TObject);
var
  http:THttpSend;
  x: integer;
  //////////////////////////
  r: TRegExpr;
begin
btn1.Enabled:=False;
HTTP:=THTTPSend.Create;
if chk1.Checked then begin
  if (ips <> '') and (ports <> '') then begin
     stat1.Panels[0].Text:='Используем прокси ...';
     Application.ProcessMessages;
     HTTP.ProxyHost := ips;
     HTTP.ProxyPort := ports;
  end;
end;
if not FileExists(ExtractFilePath(ParamStr(0))+'logKey.txt') then  //logKey.txt
HTTP.HTTPMethod('GET','https://pefelie.org/nod/')  //https://pefelie.org/nod/ http://tehnic.org/nod/category/nod32/ https://pefelie.org/eset-nod32-keys/ https://pefeli.net/6/some-keys/
else begin
sx.LoadFromFile(ExtractFilePath(ParamStr(0))+'logKey.txt');  //logKey.txt
s:=sx.Text;
if sx.Text <> '' then begin
r := TRegExpr.Create;
r.InputString := s;
r.Expression := '>(.*?)<';
if r.Exec(s) then
repeat
cbb1.Items.Add(Trim(r.Match[1]));
until not r.ExecNext;
r.Free;
x:=Pos('license key',cbb1.Items.Text);
s:=cbb1.Items.Text;
if x > 0 then Delete(s,1,x-1);
x:=Pos('write down',s);
if x > 0 then Delete(s,x-1,Length(s));
x:=Pos('&#8211; ',s);
if x > 0 then Delete(s,x,Length('&#8211; '));
AnsiReplaceStr(s, ' ', '');
cbb1.Items.Text:=Trim(s);
if s <> '' then status:=True;
end;
if (s <> '') or (sx <> nil) then
     stat1.Panels[0].Text:='Данные получены!'
else begin
     stat1.Panels[0].Text:='Нет данных с сайта!';
end;
end;
if http.ResultCode = 200 then begin
sx.LoadFromStream(HTTP.Document);
//sx.SaveToFile(ExtractFilePath(ParamStr(0))+'logKey.txt');  //Для теста
//sx.LoadFromFile(ExtractFilePath(ParamStr(0))+'logKey.txt');  //logKey.txt
s:=sx.Text; //Utf8ToAnsi(sx.Text)
if sx.Text <> '' then begin
r := TRegExpr.Create;
r.InputString := s;
r.Expression := '>(.*?)<';
if r.Exec(s) then
repeat
cbb1.Items.Add(Trim(r.Match[1]));
until not r.ExecNext;
r.Free;
x:=Pos('license key',cbb1.Items.Text);
s:=cbb1.Items.Text;
if x > 0 then Delete(s,1,x-1);
x:=Pos('write down',s);
if x > 0 then Delete(s,x-1,Length(s));
x:=Pos('&#8211; ',s);
if x > 0 then Delete(s,x,Length('&#8211; '));
AnsiReplaceStr(s, ' ', '');
cbb1.Items.Text:=Trim(s);
if s <> '' then status:=True;
end;
if (s <> '') or (sx <> nil) then
     stat1.Panels[0].Text:='Данные получены!'
else begin
     stat1.Panels[0].Text:='Нет данных с сайта!';
end;
end else begin
  if not status then
  if TMPKOD.IndexOf(IntToStr(http.ResultCode)) > -1 then begin
     s:=TMPINF.Strings[TMPKOD.IndexOf(IntToStr(http.ResultCode))];
     stat1.Panels[0].Text:='Ошибка подключения '+IntToStr(http.ResultCode)+' - '+s;
  end;
end;
btn1.Enabled:=True;
HTTP.free;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i,y,x: integer;
  s: string;
begin
status:=False;
TrayIcon1.IconVisible := True;
//=====Защита от отладчика===========
if DebuggerPresent then Application.Terminate;
if not FileExists(ExtractFilePath(ParamStr(0))+'settings.ini') then IniFileProc
else IniFileLoad;
sx:= TStringList.Create;
TMPERR:= TStringList.Create;
TMPKOD:= TStringList.Create;
TMPINF:= TStringList.Create;
TMPERR.Add('100 Continue («продолжай»)');
TMPERR.Add('101 Switching Protocols («переключение протоколов»)');
TMPERR.Add('102 Processing («идёт обработка»)');
TMPERR.Add('200 OK («хорошо успешно»)');
TMPERR.Add('201 Created («создано успешно»)');
TMPERR.Add('202 Accepted («принято успешно»)');
TMPERR.Add('203 Non-Authoritative Information («информация не авторитетна»)');
TMPERR.Add('204 No Content («нет содержимого»)');
TMPERR.Add('205 Reset Content («сбросить содержимое»)');
TMPERR.Add('206 Partial Content («частичное содержимое»)');
TMPERR.Add('207 Multi-Status («многостатусный»)');
TMPERR.Add('208 Already Reported («уже сообщалось»)');
TMPERR.Add('300 Multiple Choices («множество выборов перенаправление»)');
TMPERR.Add('301 Moved Permanently («перемещено навсегда перенаправление»)');
TMPERR.Add('302 Moved Temporarily («перемещено временно перенаправление»)');
TMPERR.Add('302 Found («найдено»)');
TMPERR.Add('303 See Other («смотреть другое»)');
TMPERR.Add('304 Not Modified («не изменялось»)');
TMPERR.Add('305 Use Proxy («использовать прокси»)');
TMPERR.Add('306 — зарезервировано (код использовался только в ранних спецификациях)');
TMPERR.Add('307 Temporary Redirect («временное перенаправление»)');
TMPERR.Add('308 Permanent Redirect («постоянное перенаправление»)');
TMPERR.Add('400 Bad Request («плохой, неверный запрос»)');
TMPERR.Add('401 Unauthorized («не авторизован»)');
TMPERR.Add('402 Payment Required («необходима оплата»)');
TMPERR.Add('403 Forbidden («запрещено»)');
TMPERR.Add('404 Not Found («не найдено»)');
TMPERR.Add('405 Method Not Allowed («метод не поддерживается»)');
TMPERR.Add('406 Not Acceptable («неприемлемо»)');
TMPERR.Add('407 Proxy Authentication Required («необходима аутентификация прокси»)');
TMPERR.Add('408 Request Timeout («истекло время ожидания»)');
TMPERR.Add('409 Conflict («конфликт»)');
TMPERR.Add('410 Gone («удалён»)');
TMPERR.Add('411 Length Required («необходима длина»)');
TMPERR.Add('412 Precondition Failed («условие ложно»)');
TMPERR.Add('413 Payload Too Large («полезная нагрузка слишком велика»)');
TMPERR.Add('414 URI Too Long («URI слишком длинный»)');
TMPERR.Add('415 Unsupported Media Type («неподдерживаемый тип данных»)');
TMPERR.Add('416 Range Not Satisfiable («диапазон не достижим»)');
TMPERR.Add('417 Expectation Failed («ожидание не удалось»)');
TMPERR.Add('418 I’m a teapot («я — чайник»)');
TMPERR.Add('421 Misdirected Request');
TMPERR.Add('422 Unprocessable Entity («необрабатываемый экземпляр»)');
TMPERR.Add('423 Locked («заблокировано»)');
TMPERR.Add('424 Failed Dependency («невыполненная зависимость»)');
TMPERR.Add('426 Upgrade Required («необходимо обновление»)');
TMPERR.Add('428 Precondition Required («необходимо предусловие»)');
TMPERR.Add('429 Too Many Requests («слишком много запросов»)');
TMPERR.Add('431 Request Header Fields Too Large («поля заголовка запроса слишком большие»)');
TMPERR.Add('444 Закрывает соединение без передачи заголовка ответа. Нестандартный код');
TMPERR.Add('449 Retry With («повторить с»)');
TMPERR.Add('451 Unavailable For Legal Reasons («недоступно по юридическим причинам»)');
TMPERR.Add('500 Internal Server Error («внутренняя ошибка сервера»)');
TMPERR.Add('501 Not Implemented («не реализовано»)');
TMPERR.Add('502 Bad Gateway («плохой, ошибочный шлюз»)');
TMPERR.Add('503 Service Unavailable («сервис недоступен»)');
TMPERR.Add('504 Gateway Timeout («шлюз не отвечает»)');
TMPERR.Add('505 HTTP Version Not Supported («версия HTTP не поддерживается»)');
TMPERR.Add('506 Variant Also Negotiates («вариант тоже проводит согласование»)');
TMPERR.Add('507 Insufficient Storage («переполнение хранилища»)');
TMPERR.Add('508 Loop Detected («обнаружено бесконечное перенаправление»)');
TMPERR.Add('509 Bandwidth Limit Exceeded («исчерпана пропускная ширина канала»)');
TMPERR.Add('510 Not Extended («не расширено»)');
TMPERR.Add('511 Network Authentication Required («требуется сетевая аутентификация»)');
TMPERR.Add('520 Unknown Error («неизвестная ошибка»)');
TMPERR.Add('521 Web Server Is Down («веб-сервер не работает»)');
TMPERR.Add('522 Connection Timed Out («соединение не отвечает»)');
TMPERR.Add('523 Origin Is Unreachable («источник недоступен»)');
TMPERR.Add('524 A Timeout Occurred («время ожидания истекло»)');
TMPERR.Add('525 SSL Handshake Failed («квитирование SSL не удалось»)');
TMPERR.Add('526 Invalid SSL Certificate («недействительный сертификат SSL»)');
TMPERR.Add(' ');
//if FileExists('error.txt') then TMPERR.LoadFromFile('error.txt'); //Для теста
if TMPERR.Count > 1 then begin
for i:=0 to TMPERR.Count-1 do begin
    s:=TMPERR.Strings[i];
    x:=Length(s);
    y:=Pos(' ',s);
    if y > 0 then begin
       TMPKOD.Add(Trim(Copy(s,1,y-1)));
       TMPINF.Add(Trim(Copy(s,y,x)));
       stat1.Panels[0].Text:=Trim(Copy(s,y,x));
       stat1.Panels[1].Text:='>> '+IntToStr(i);
    end;
end;
//TMPERR.SaveToFile('GOOD.txt'); //Для теста
end;
RegWriteStr(HKEY_CURRENT_USER,'Software\\Microsoft\\Windows\\CurrentVersion\\Run','FreeKey',ParamStr(0));
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
sx.Free;
TMPERR.Free;
TMPKOD.Free;
TMPINF.Free;
end;

procedure TForm1.cbb1Change(Sender: TObject);
var
  s: string;
  s0: TStrings;
begin
  if cbb1.Text <> '' then
     s0:=Parse('<strong>','</strong>',cbb1.Text);
  if s0 = nil then
     s:=StrCut(cbb1.Text,': ','<br>')
  else s := Trim(s0.Text);   
     if s <> '' then
     SetClipboardText(Handle, s);     
     stat1.Panels[0].Text:='Данные скопированы в буфер обмена!';
     Application.ProcessMessages;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  //=====Защита от отладчика===========
  if DebuggerPresent then Application.Terminate;
  CreateFormInRightBottomCorner;
end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
begin
    //=====Защита от отладчика===========
    if DebuggerPresent then Application.Terminate;
    TrayIcon1.ShowMainForm;
    TrayIcon1.IconVisible := False;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;
  if not CanClose then
  begin
    TrayIcon1.HideMainForm;
    TrayIcon1.IconVisible := True;
  end;
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
  Application.Terminate;
end;

end.
