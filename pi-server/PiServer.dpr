program PiServer;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := False;
  Application.ShowMainForm := False;
  Application.CreateForm(TForm1, Form1);
  Application.Run;

end.
