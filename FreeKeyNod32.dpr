program FreeKeyNod32;

uses
  Forms,
  Windows,
  Unit1 in 'Unit1.pas' {Form1};

{$R UAC.RES}
{$R *.res}

var
  H: THandle;

begin
  H:= CreateMutex(nil, True, 'FREEKEYESETNOD32');
  if GetLastError = ERROR_ALREADY_EXISTS then
  begin
    H := FindWindow(nil, 'FREEKEYESETNOD32');
    SetForegroundWindow(H);
    Exit;
  end;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.ShowMainForm:=False;
  Application.Run;
  CloseHandle(H);
end.
