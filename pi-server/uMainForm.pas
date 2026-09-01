unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, IdContext,
  IdCustomHTTPServer, IdBaseComponent, IdComponent, IdCustomTCPServer,
  IdHTTPServer,
  Winapi.MMSystem, Vcl.Menus, System.Notification;

type
  TForm1 = class(TForm)
    TrayIcon: TTrayIcon;
    HTTPServer: TIdHTTPServer;
    NotificationCenter: TNotificationCenter;
    PopupMenu: TPopupMenu;
    Exity1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure HTTPServerCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure Exity1Click(Sender: TObject);
    procedure NotificationCenterReceiveLocalNotification(Sender: TObject;
      ANotification: TNotification);
  private
    procedure ConfigureServerFromCommandLine;
    procedure ShowBeepNotification;
    procedure FocusWorkspaceWindow;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.ConfigureServerFromCommandLine;
var
  Host: string;
  ListenPort: Integer;
  I: Integer;
begin
  Host := '127.0.0.1';
  ListenPort := 9001;

  I := 1;
  while I <= ParamCount do
  begin
    if SameText(ParamStr(I), '--host') then
    begin
      Inc(I);
      if I <= ParamCount then
        Host := ParamStr(I);
    end
    else if SameText(ParamStr(I), '--port') then
    begin
      Inc(I);
      if I <= ParamCount then
        ListenPort := StrToIntDef(ParamStr(I), 9001);
    end;
    Inc(I);
  end;

  try
    HTTPServer.Active := False;
    HTTPServer.Bindings.Clear;
    with HTTPServer.Bindings.Add do
    begin
      IP := Host;
      Port := ListenPort;
    end;
    HTTPServer.Active := True;
  except
    on E: Exception do
    begin
      MessageDlg('Failed to start the HTTP server.' + sLineBreak + sLineBreak +
        E.Message, mtError, [mbOK], 0);
      Halt(1);
    end;
  end;
end;

const
  BEEP_NOTIFICATION_ID = 1;

type
  PFocusWindowSearch = ^TFocusWindowSearch;
  TFocusWindowSearch = record
    Substring: string;
    TargetHwnd: HWND;
  end;

function EnumWorkspaceWindowCallback(Wnd: HWND; LParam: LPARAM): BOOL; stdcall;
var
  Buf: array[0..511] of Char;
  Len: Integer;
  Title: string;
  Search: PFocusWindowSearch;
begin
  Search := PFocusWindowSearch(LParam);
  if Search^.TargetHwnd <> 0 then
  begin
    Result := False;
    Exit;
  end;

  if not IsWindowVisible(Wnd) then
  begin
    Result := True;
    Exit;
  end;

  Len := GetWindowText(Wnd, Buf, Length(Buf));
  if Len > 0 then
  begin
    Title := string(Buf);
    if Pos(Search^.Substring, Title) > 0 then
    begin
      Search^.TargetHwnd := Wnd;
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;

procedure TForm1.FocusWorkspaceWindow;
var
  Search: TFocusWindowSearch;
begin
  Search.Substring := '- workspace';
  Search.TargetHwnd := 0;
  EnumWindows(@EnumWorkspaceWindowCallback, LPARAM(@Search));
  if Search.TargetHwnd <> 0 then
  begin
    if IsIconic(Search.TargetHwnd) then
      ShowWindow(Search.TargetHwnd, SW_RESTORE);
    SetForegroundWindow(Search.TargetHwnd);
  end;
end;

procedure TForm1.NotificationCenterReceiveLocalNotification(Sender: TObject;
  ANotification: TNotification);
begin
  FocusWorkspaceWindow;
end;

procedure TForm1.ShowBeepNotification;
var
  Notification: TNotification;
  FileName: string;
begin
  FileName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'beep.wav';
  PlaySound(PChar(FileName), 0, SND_ASYNC or SND_FILENAME);

  Notification := NotificationCenter.CreateNotification;
  Notification.Name := 'BeepNotification';
  Notification.Number := BEEP_NOTIFICATION_ID;
  Notification.Title := 'Pi Server';
  Notification.AlertBody := 'Beep!';
  Notification.EnableSound := False;
  Notification.FireDate := Now;
  NotificationCenter.PresentNotification(Notification);
end;

procedure TForm1.Exity1Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Hide;
  TrayIcon.Visible := True;
  ConfigureServerFromCommandLine;
end;

procedure TForm1.HTTPServerCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  if ARequestInfo.Document = '/beep' then
  begin
    AResponseInfo.ContentType := 'application/json';
    TThread.Queue(nil,
      procedure
      begin
        ShowBeepNotification;
      end);
    AResponseInfo.ContentText := '{"success": true}';
  end;
end;

end.
