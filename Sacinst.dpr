program Sacinst;

uses
  Forms,
//  VirTualUI_AutoRun,
  SqlFun in '\Delphi\DelphiSeattle\sql\SqlFun.pas',
  SqlSis in '\Delphi\DelphiSeattle\sql\SqlSis.pas',
//  SqlEd in  '\Delphi\DelphiSeattle\sql\SqlEd.pas',
//  Geral in  '\DelphiSeattleProjetos\Sac\Programa\Geral.pas',
  UInstala in 'UInstala.pas' {FInstsac};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFInstsac, FInstsac);
  Application.Run;
end.
