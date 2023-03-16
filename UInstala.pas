unit UInstala;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, SQLGrid, SqlSis, StdCtrls, Mask, SQLEd, Buttons,
  SQLBtn,SqlExpr, DbxDevartPostgreSQL, Data.DB, Data.DBXOracle;

type

  TFInstsac = class(TForm)
    Inst: TSQLInstall;
    OSistema: TSQLEnv;
    PMsgSistema: TSQLPanelGrid;
    rgServidor: TRadioGroup;
    GroupBox1: TGroupBox;
    EUsuario: TSQLEd;
    EConf_Usuario: TSQLEd;
    EServidor: TSQLEd;
    EDataBase: TSQLEd;
    ECaminho: TSQLEd;
    EPorta: TSQLEd;
    Painel: TPanel;
    bSair: TBitBtn;
    bInstVersao: TBitBtn;
    bTestarConexao: TBitBtn;
    BitBtn3: TBitBtn;
    Bevel1: TBevel;
    BitBtn2: TBitBtn;
    procedure InstCreateFields(Sender: TObject);
    procedure InstCreateConstraints(Sender: TObject);
    procedure InstCreateIndexes(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bSairClick(Sender: TObject);
    procedure bInstVersaoClick(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure bTestarConexaoClick(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure EPortaExitEdit(Sender: TObject);
    procedure rgServidorEnter(Sender: TObject);
    procedure PMsgSistemaDblClick(Sender: TObject);
  private
    procedure CriaTabelasSistema;
    function ConfiguraBancodeDados: boolean;
    procedure setaservidor;
    procedure inicializar;
    procedure CriaTabelasEstoque;
    procedure CriaTabelasdeCadastrodoSistema;
// 08.11.19
    procedure CriaTabelasPonto;

//    procedure ProcessosNovaVersao;

  public
    { Public declarations }
  end;

var
  FInstsac: TFInstsac;
  Ini: string;

implementation


uses SqlFun;

{$R *.dfm}

const f_cr = '#,###,###,##0.00';
      f_aliq = '###0.000';
      f_cr5 = '#,###,###,##0.00000';

const Versao='2.65';

// 2.65 - 14.03.23 - criado tabela MovReinf para digita��o dos eventos da ser�e R...
//                   inicialmente R4010 e r 4020
// 2.64 - 07.02.23 - campo esgr_unidade na tabela estgrades para gravar a unidade do item na grade
// 2.63 - 01.09.22 - campo movf_port_codigo na tabela movfin para gravar portador em vendas a vista
// 2.62 - 23.06.22 - campo de observacao no pedido de compra
// 2.61 - 15.07.21 - Gs Credito - criado mais campos na tabela de contratos
// 2.60 - 25.03.21 - Olstri - cria tabelas para armazena dados espec�ficos de medidores
// 2.59 - 16.09.20 - tabela contratos para emprestimos consignados
// 2.58 - 10.08.20 - campo para conta de reten��o de inss no cadastro de unidades
// 2.57 - 15.07.20 - 2 campos para exportar apropriacoes de notas de compra para contab.
// 2.56 - 08.07.20 - campo unid_contaservicos para exportar notas de prestacao de servicos para contab
// 2.55 - 05.06.20 - campo movd_cupim no movimento de abate para identificar carca�as q 'ficam' com o cupim
//                   campo movc_pesada no movimento de cargas pra prever mais de um pesada
//                   por dia de um mesmo caminhao
// 2.54 - 12.05.20 - campo pend_codbarras nas pendencias e tabela para guardar valores
//                   para uso em 'centros de custo' da fazenda
// 2.53 - 21.02.20 - campo para descri��o do produto no pedido de venda
// 2.52 - 19.02.20 - campo para codigo do beneficio fiscal junto ao cadastro de ncm
// 2.51 - 09.01.20 - 2 campos grupo de produtos para tolerancia peso e codigo acapar
//                   campo para tabela de desconto/acrescimo em clientes para usar no pedido de venda
// 2.50 - 28.10.19 - mais 2 campos de contas no fornecedor para compra remessa futura
// 2.49 - 30.09.19 - mais 3 campos de contas para extrato de IR do produtor
// 2.48 - 02.08.19 - campo sitt_cbenef no cadastro de CST
// 2.47 - 01.08.19 - campo equi_codigo no estoque,movesto e movestoque para gravar codigo equipamento
//        05.07.19 - campo Cfis_AliqST em codigosfiscais para % de icms pra ST
// 2.46 - 04.07.19 - campo move_aliii no movestoque ref. imposto de importacao
// 2.46 - 02.07.19 - campo cst para venda consumidor final na tabela de grupos do estoque
// 2.45 - 20.06.19 - campo insumos de produ��o no movesto
// 2.44 - 12.06.19 - campos nas tabela movabate para codigo do transportador ( caminhao ) e colaborador ( motorista )
// 2.43 - 30.05.19 - campos nas tabelas movcargas, transportares..para uso do mdfe
// 2.42 - 21.05.19 - campo de ganho de peso na tabela movabate
// 2.41 - 25.04.19 - tabelas para cadastro de baias na fazenda e para creditos sped pis/cofins
//                   e cst para pis/cofins no plano gerencial
// 2.40 - 16.04.19 - campo clie_tran_codigo para uso no leite da crian�a
// 2.39 - 11.04.19 - campos com os litros do leite da crian�a
// 2.38 - 08.03.19 - campo de validade e conservacao para produtos resfriados no estoque
// 2.37 - 26.02.19 - campo de acr�scimo nos clientes para usar nas vendas
// 2.36 - 06.02.19 - campo de comissao pedido de venda + campos estoque com descricao
// 2.35 - 25.09.18 - tabela movtelevendas para guardar as liga��es telefonicas
// 2.34 - 11.09.18 - campo tabela movcargas para guardar a quilometragem do caminhao
// 2.33 - 22.05.18 - campos no clientes e estoque para condicoes de pagamento e tabela pre�os para 002
// 2.32 - 05.04.18 - campos no cadmobra e custos para 'planilha de processo/composi��o'
// 2.31 - 13.03.18 - campo de conta para devedor duvidoso em clientes e ordem no movped
// 2.30 - 22.09.17 - campo de desconto automatico nos clientes para as vendas, grupo de produto
// 2.29 - 24.08.17 - campo esto_obs estoque para detalhes do produto ( armas )
// 2.28 - 22.06.17 - campos no movesto para controlar os manifestos de nf-e dos fornecedores
// 2.27 - 20.03.17 - tabela movagenda para agendar consultas dos pacientes
// 2.26 - 03.03.17 - campo de conta contabil para cota capital da unidade 002
// 2.25 - 16.01.17 - campos  forn_cidade e clie_contacompra02 e unid_contaissret
// 2.24 - 16.12.16 - campo forn_naocontab
// 2.23 - 05.12.16 - campo movf_unid_codigo nas contas gerenciais para usar em transferencias
// 2.22 - 27.10.16 - campo movd_pesovivoabate
// 2.21 - 25.10.16 - campo movd_oprastreamento
// 2.20 - 24.10.16 - campo movd_esto_codigoven
// 2.19 - 19.09.16 - campo movf_transacaocontax  + moes_pertransf + esto_taraperc + 4 campos movabatdet
// 2.18 - 13.09.16 - campo de contas para retencao de pis,cofins,ir e csll no cadastro de unidades
// 2.17 - 06.09.16 - campo de compra para nao socio no cadastro de unidades
// 2.16 - 19.08.16 - campo de cst e % de pis/cofins no cadastro de ncms
// 2.15 - 02.08.16 - campo de tara da camara fria no estoque por produto
// 2.14 - 27.06.16 - campo de tara e peso maxima do caminhao para montagem de carga e numero da carga no movabate
// 2.13 - 21.06.16 - campo de cst pis / confis no subgrupo do estoque + cliente email de 50 para 100
// 2.12 - 25.03.16 - campo cest no cadastrode ncms
// 2.11 - 14.01.16 - campos peso bruto para balanca de saida e conta pra baixa em vendas a vista ou cartao
// 2.10 - 15.09.15 - campo  de valor gta das notas de produtor e cadastro de unidades
// 2.09 - 30.07.15 - campo  de usuario q cadastrou o cheque recebido
// 2.08 - 30.07.15 - campo  para taxa 'gta' para descontar do total da nota de produtor e na entrada de abate por animal
// 2.07 - 25.05.15 - aumentando para 60 nome e razao social de cliente/fornecedore ; 50 para 100 prazos cond.pagamento
// 2.06 - 03.04.15 - tabela clientesdoc para guadar 4 documentos de clientes
// 2.05 - 10.03.15 - campos de codigo de CST e % icms para 'atos n�o cooperados'
// 2.04 - 26.02.15 - campos de agencia e conta corrente cadastro clientes
// 2.03 - 31.12.14 - campos de agencia e conta corrente cadastro clientes
// 2.02 - 04.09.14 - indice esgr_unid_codigo
// 2.01 - 23.06.14 - campos de unidades validas na tabela de desconto/acrescimo
// 2.00 - 07.12.13 - identifica se o cheque recebido � garantido pela assoc. comercial
// 1.99 - 24.09.13 - baia,codigo do setor no movabatedet pra usar como 'setor dentro da fazenda'
// 1.98 - 27.08.13 - codigo do setor no movesto,movestoque e pendencias para usar como 'centro de custo'
// 1.97 - 14.08.13 - criado indice para campo natf_codigo das tabelas movbase,movestoque e movesto
// 1.96 - 12.08.13 - campo de portadores no cadastro de clientes
// 1.95 - 18.07.13 - campos de cor, tamanho e peso no orcamdet ref. 'perfis do sac'
// 1.94 - 10.07.13 - campo clie_tiposremessas para definir tipos de remessas que o cliente est� autorizado
// 1.93 - 28.08.12 - campos ref. colaborador no transportador, impresso pedido no usuario,
//        campo embalagem e valor unitario da nota no movestoque, tabela de faixas para
//        pre�o arroba e campo com codigo da faixa no cadastro de grupos
// 1.92 - 12.01.12 - campos ref. dados da DI para nota de importacao-Asatec
// 1.91 - 31.10.11 - campo codigo forma de pagamento no cadastro de clientes
// 1.90 - campo tipo de venda pra orcamento de obras
// 1.90 - campos para uso de balan�as na 'saida de abate'...pedido -> faturamento saida
// 1.80 - tabela de informacoes nutricionais, ingredientes e de conserva��o
// 1.80 - campo de faturamento minimo de venda na tabela de cidades
// 1.80 - aumentado de 3 para 5 casas decimais moco_unitario
// 1.80 - codigo repr. e total em valor na  entrada de abate
// 1.79 - cst para simples nacional, cfop nos itens da nota, aliq. icms para diferimento
// 1.75 - campos de edits configuraveis na conf. movimento, se gera fiscal, tabela de similares e
//        vencimento original nas pendencias
// 1.74 - campo de ultimo valor e valor medio ref. servi�os (M.O) e campo pecas na tabela estgrades
//        campo industrializa na movcompras
// 1.73 - campo de icms e ipi no pedido de compra
// 1.72 - campo de d�bito e credito na config. de movimentos
// 1.71 - campo de fornecedores para orcamento no pedido de compra
// 1.70 - tabela movproducao e indices + tabela movobrasdet + orcamentos
// 1.69 - mais 4 campos de nota de produtor
//        campo de F ou C na config. de movimento


// 22.04.08 - pois de mensagem 'Use shorter procedures' na compila��o
procedure TFInstsac.CriaTabelasdeCadastrodoSistema;
///////////////////////////////////////////////////
begin
  Inst.AddTable('Codigosfis');
  Inst.AddField('Codigosfis','Cfis_Codigo'   ,'C',03,0,30,False,'C�digo','C�digo para tributa��o','',False,'1','','','2');
  Inst.AddField('Codigosfis','Cfis_Imposto'  ,'C',01,0,20,False,'Imp','Tipo do imposto','',False,'1','','','0');
  Inst.AddField('Codigosfis','Cfis_Aliquota' ,'N',07,3,70,True,'Al�quota','Percentual da al�quota do imposto','##0.000%',False,'3','','','0');
  Inst.AddField('Codigosfis','Cfis_CodFiscal','C',01,0,20,True,'CF','C�digo fiscal','',False,'1','','','0');
  Inst.AddField('Codigosfis','Cfis_PercBase' ,'N',07,3,70,True,'% Sub.trib.','Percentual para base icms subst. tribut�ria'   ,'',False,'3','','','0');
  Inst.AddField('Codigosfis','Cfis_ReduBase' ,'N',07,3,70,True,'% Red.Base' ,'Percentual para redu��o da base do imposto'    ,'',False,'3','','','0');
  Inst.AddField('Codigosfis','Cfis_PercTran' ,'N',07,3,70,True,'% Transf.'  ,'Percentual para c�lculo do custo em transfer�ncias'  ,'',False,'3','','','0');
// 08.10.08
  Inst.AddField('Codigosfis','Cfis_Pis'    ,'N',07,3,70,True,'% Pis'  ,'Percentual para c�lculo do pis'  ,'',False,'3','','','0');
  Inst.AddField('Codigosfis','Cfis_Cofins' ,'N',07,3,70,True,'% Cofins'  ,'Percentual para c�lculo do cofins'  ,'',False,'3','','','0');
// 10.09.10
  Inst.AddField('Codigosfis','Cfis_AliqDife' ,'N',07,3,70,True,'Al�q.Dif.','Percentual da al�quota para diferimento do imposto ','##0.000%',False,'3','','','0');
// 05.07.19
  Inst.AddField('Codigosfis','Cfis_AliqST'   ,'N',07,3,70,True,'Al�q.ST','Percentual da al�quota para c�lculo da substitui��o tribut�ria','##0.000%',False,'3','','','0');


  Inst.AddTable('Moedas');
  Inst.AddField('Moedas','Moed_Codigo','C',3,0,25,False,'C�digo','C�digo da moeda','000',False,'1','','','2');
  Inst.AddField('Moedas','Moed_Descricao','C',50,0,250,True,'Descri��o','Descri��o da moeda','',True,'1','','','2');
  Inst.AddField('Moedas','Moed_Simbolo','C',05,0,50,True,'Simbolo','Simbolo da moeda','',True,'1','','','1');
  Inst.AddField('Moedas','Moed_Singular','C',20,0,100,True,'Singular','Descri��o da moeda no singular','',True,'1','','','1');
  Inst.AddField('Moedas','Moed_Plural','C',20,0,100,True,'Plural','Descri��o da moeda no plural','',True,'1','','','1');
  Inst.AddField('Moedas','Moed_Cotacao','N',12,5,80,True,'Cota��o','Valor da cota��o atual da moeda','',True,'3','','','0');
  Inst.AddTable('FPgto');
  
  Inst.AddField('FPgto','Fpgt_Codigo','C',3,0,30,False,'C�digo','C�digo da forma de pagamento','000',False,'1','','','2');
  Inst.AddField('FPgto','Fpgt_Descricao','C',50,0,250,True,'Descri��o','Descri��o da forma de pagamento','',True,'1','','','1');
  Inst.AddField('FPgto','Fpgt_Reduzido','C',15,0,100,True,'Reduzido','Descri��o reduzida da forma de pagamento','',True,'1','','','2');
  Inst.AddField('FPgto','Fpgt_Aplicacao','C',20,0,100,True,'Aplica��o','Aplica��o da forma de pagamento','',True,'1','','','0');
  Inst.AddField('FPgto','Fpgt_Prazos','C',100,0,250,True,'Prazos','Prazos da forma de pagamento','',True,'1','','','0');
  Inst.AddField('FPgto','Fpgt_Acrescimos','N',10,5,70,True,'Acr�scimos','Percentual dos acr�scimos da forma de pagamento',f_aliq,True,'3','','','0');
  Inst.AddField('FPgto','Fpgt_Descontos','N',10,5,70,True,'Descontos','Percentual dos descontos da forma de pagamento',f_aliq,True,'3','','','0');
  Inst.AddField('FPgto','Fpgt_Entrada','N',10,5,70,True,'Entrada','Percentual da entrada da forma de pagamento',f_aliq,True,'3','','','0');
  Inst.AddField('FPgto','Fpgt_Comissao','N',10,5,70,True,'Comiss�o','Percentual da comiss�o da forma de pagamento',f_aliq,True,'3','','','0');
  Inst.AddField('FPgto','Fpgt_ICMSInt','N',10,5,70,True,'ICMS Int.','Percentual do ICMS interestadual da forma de pagamento',f_aliq,True,'3','','','0');

  Inst.AddTable('LPgto');
  Inst.AddField('LPgto','Lpgt_Codigo','C',3,0,50,False,'C�digo','C�digo do local de pagamento','000',False,'1','','','2');
  Inst.AddField('LPgto','Lpgt_Descricao','C',50,0,250,True,'Descri��o','Descri��o do local de pagamento','',True,'1','','','2');

  Inst.AddTable('CCustos');
  Inst.AddField('CCustos','CCst_Codigo','C',8,0,50     ,True,'C�digo','C�digo do centro de custos','99\.999\.999;0;_',False,'1','','','2');
  Inst.AddField('CCustos','CCst_Descricao','C',50,0,250,True,'Descri��o','Descri��o do centro de custos','',True,'1','','','0');
  Inst.AddField('CCustos','CCst_Reduzido','C',15,0,100 ,True,'Reduzido','Descri��o reduzida do centro de custos','',True,'1','','','0');

  Inst.AddTable('Portadores');
  Inst.AddField('Portadores','Port_Codigo','C',3,0,50,False,'C�digo','C�digo do portador','000',False,'1','','','2');
  Inst.AddField('Portadores','Port_Descricao','C',50,0,250,True,'Descri��o','Descri��o do portador','',True,'1','','','2');
// 20.01.16
  Inst.AddField('Portadores','Port_plan_Conta','N',08,0,60,True,'Conta','Conta para baixa de pend�ncia','0000',False,'3','','','0');

  Inst.AddTable('Departamentos');
  Inst.AddField('Departamentos','Dpto_Codigo','C',3,0,50,False,'C�digo','C�digo do departamento','000',False,'1','','','2');
  Inst.AddField('Departamentos','Dpto_Descricao','C',50,0,250,True,'Descri��o','Descri��o do departamento','',True,'1','','','2');

  Inst.AddTable('Bloqueados');
  Inst.AddField('Bloqueados','Bloq_Nome'              ,'C',50 ,0,270,True ,'Nome Do Impedido'       ,'Nome do impedido'                                               ,''       ,True ,'1','','','2');
  Inst.AddField('Bloqueados','Bloq_CNPJCPF'           ,'C',14 ,0,110,True ,'CNPJ/CPF'               ,'CNPJ do impedido'                                           ,''       ,True ,'1','','','1');
  Inst.AddField('Bloqueados','Bloq_CNPJCPFAv'         ,'C',14 ,0,110,True ,'CNPJ/CPF Avalista'      ,'CNPJ do avalista do impedido'                                           ,''       ,True ,'1','','','1');
  Inst.AddField('Bloqueados','Bloq_Motivo'            ,'C',3  ,0,34 ,True ,'Motivo'                 ,'C�digo do movimento de impedimento'                             ,''       ,True ,'1','','','1');
  Inst.AddField('Bloqueados','Bloq_Endereco'          ,'C',50 ,0,270,True ,'Endereco'               ,'Endere�o do impedido'                                         ,''       ,True ,'1','','','0');
  Inst.AddField('Bloqueados','Bloq_Bairro'            ,'C',40 ,0,250,True ,'Bairro'                 ,'Bairro do endere�o do impedido'                               ,''       ,True ,'1','','','0');
  Inst.AddField('Bloqueados','Bloq_CEP'               ,'C',8  ,0,65 ,True ,'CEP'                    ,'N�mero do CEP do endere�o do impedido'                        ,f_CEP    ,True ,'1','','','0');
  Inst.AddField('Bloqueados','Bloq_Cida_Codigo'       ,'N',5  ,0,80 ,False,'C�d. Cidade'            ,'C�digo da cidade do impedido'                                            ,''       ,False,'3','','','0');
  Inst.AddField('Bloqueados','Bloq_Fone'              ,'C',11 ,0,80 ,True ,'Fone'                   ,'N�mero do telefone do impedido'                               ,f_fone   ,True ,'1','','','0');
  Inst.AddField('Bloqueados','Bloq_Obs'               ,'C',100,0,300,True ,'Observa��o'             ,'Observa��o do impedimento'                                         ,''       ,True ,'1','','','0');
  Inst.AddField('Bloqueados','Bloq_DataInc'           ,'D',0  ,0,100,True ,'Dt Imc.'                ,'Data de inclus�o do impedimento'                            ,''       ,True ,'2','','','0');
  Inst.AddField('Bloqueados','Bloq_Usua_Inc'          ,'N',5  ,0,60 ,True ,'Usu Inc.'               ,'C�digo do usu�rio respons�vel pelo inclus�o do impedimento'               ,''       ,False,'3','','','0');
  Inst.AddField('Bloqueados','Bloq_DataPrev'          ,'D',0  ,0,100,True ,'Dt Prev.'               ,'Data prevista para a baixa do impedimento'                            ,''       ,True ,'2','','','0');
  Inst.AddField('Bloqueados','Bloq_DataBx'            ,'D',0  ,0,100,True ,'Dt Baixa'               ,'Data de baixa do impedimento'                            ,''       ,True ,'2','','','0');
  Inst.AddField('Bloqueados','Bloq_Usua_Bx'           ,'N',5  ,0,60 ,True ,'Usu Bx'                 ,'C�digo do usu�rio respons�vel pela baixa do impedimento'               ,''       ,False,'3','','','0');

  Inst.AddTable('Bloqueios');
  Inst.AddField('Bloqueios','Bloq_Codigo','N',3,0,30,False,'C�digo','C�digo do bloqueio','##0',False,'3','','','2');
  Inst.AddField('Bloqueios','Bloq_Nome','C',40,0,250,False,'Descri��o','Descri��o do bloqueio','',True,'','','','1');

  Inst.AddTable('Historicos');
  Inst.AddField('Historicos','Hist_Codigo','N',3,0,50,False,'C�digo','C�digo do hist�rico','0000',False,'1','','','2');
  Inst.AddField('Historicos','Hist_Descricao','C',50,0,250,True,'Descri��o','Descri��o do hist�rico','',True,'1','','','1');
  Inst.AddField('Historicos','Hist_Complemento','C',50,0,250,True,'Complemento','Complemento do hist�rico','',True,'1','','','0');

  Inst.AddTable('Cidades');
  Inst.AddField('Cidades','Cida_Codigo','N',5,0,50,False,'C�digo','C�digo da cidade'      ,'',False,'3','','','2');
  Inst.AddField('Cidades','Cida_Nome','C',40,0,250,False,'Nome Cidade','Nome da cidade','',True,'1','','','2');
  Inst.AddField('Cidades','Cida_UF','C',02,0,25,False,'UF','UF da cidade','',True,'1','','','0');
  Inst.AddField('Cidades','Cida_populacao'  ,'N',08,0,60,True ,'Popula��o','N�mero de habitantes da cidade','',True,'3','','','0');
  Inst.AddField('Cidades','Cida_Regi_Codigo','C',3 ,0,50,True ,'C�d. Regi�o','C�digo da regi�o da cidade','000',True,'3','','','0');
// 14.05.07 - para agilizar importacao do viasoft
  Inst.AddField('Cidades','Cida_CEP'        ,'C',8 ,0,70,True,'CEP','N�mero do CEP da cidade',f_CEP,True,'1','','','0');
// 18.09.08 - NFe
  Inst.AddField('Cidades','Cida_CodigoIBGE'      ,'C',7 ,0,70,True,'IBGE','Codigo da cidade segundo tabela do IBGE','',True,'1','','','0');
// 15.06.10 - NFe - codigo do pais para exportacao
  Inst.AddField('Cidades','Cida_CodigoPais'      ,'C',5 ,0,70,True,'Pais','Codigo do pais ( Bacen )','',True,'1','','','0');
  Inst.AddField('Cidades','Cida_NomePais'        ,'C',20,0,70,True,'Nome Pais','Nome do pais ( Bacen )','',True,'1','','','0');
// 12.05.11 - faturamento m�nimo por cidade na saida
  Inst.AddField('Cidades','Cida_fatminimo'       ,'N',12,3,70,True ,'Fat.M�nimo','Faturamento m�nimo para vendas nesta cidade','',True,'3','','','0');


  Inst.AddTable('Empresas');
  Inst.AddField('Empresas','Empr_Codigo','C',2,0,30,False,'C�digo','C�digo da empresa','',False,'1','','','2');
  Inst.AddField('Empresas','Empr_Nome','C',40,0,250,True,'Nome empresa','Nome da empresa','',True,'1','','','2');
  Inst.AddField('Empresas','Empr_Reduzido','C',15,0,100,True,'Nome Reduzido','Nome reduzido para a empresa','',True,'1','','','2');
  Inst.AddField('Empresas','Empr_RazaoSocial','C',50,0,250,True,'Raz�o Social','Raz�o Social da empresa','',True,'1','','','1');
  Inst.AddField('Empresas','Empr_CNPJ','C',14,0,110,True,'CNPJ Da empresa','CNPJ da empresa',f_Cgc,True,'1','','','1');
  Inst.AddField('Empresas','Empr_InscricaoEstadual','C',20,0,150,True,'Inscr. Estadual','Inscri��o Estadual da empresa','',True,'1','','','1');
  Inst.AddField('Empresas','Empr_InscricaoMunicipal','C',20,0,150,True,'Inscr. Municipal','Inscri��o Municipal da empresa','',True,'1','','','1');
  Inst.AddField('Empresas','Empr_RegJuntaComercial','C',20,0,150,True,'Reg. Junta Com.','N�mero do registro da empresa na Junta Comercial','',True,'1','','','1');
  Inst.AddField('Empresas','Empr_DtDespachoJunta','D',8,0,60,True,'Despacho Junta Com.','Data de despacho na Junta Comercial','',True,'2','','','0');
  Inst.AddField('Empresas','Empr_Atividade','C',40,0,250,True,'Ramo Atividade','Ramo de atividade da empresa','',True,'1','','','0');
  Inst.AddField('Empresas','Empr_IdentAtividade','C',2,0,30,True,'Ident. Atividade','Identifica��o do ramo de atividade da empresa','',True,'1','','','0');
  Inst.AddField('Empresas','Empr_Responsavel','C',40,0,250,True,'Respons�vel','Nome do respons�vel pela empresa','',True,'1','','','0');
  Inst.AddField('Empresas','Empr_CpfResponsavel','C',11,0,90,True,'CPF Respons�vel','CPF do respons�vel pela empresa',f_Cpf,True,'1','','','0');
  Inst.AddField('Empresas','Empr_Cargo','C',40,0,250,True,'Cargo','Cargo do respons�vel pela empresa','',True,'1','','','0');
  Inst.AddField('Empresas','Empr_Contador','C',40,0,250,True,'Contador','Nome do contador da empresa','',True,'1','','','0');
  Inst.AddField('Empresas','Empr_CpfContador','C',11,0,90,True,'CPF Contador','CPF do contador da empresa',f_Cpf,True,'1','','','0');
  Inst.AddField('Empresas','Empr_CrcContador','C',20,0,150,True,'CRC Contador','CRC do contador da empresa','',True,'1','','','0');
  Inst.AddField('Empresas','Empr_Endereco','C',40,0,250,True,'Endereco','Endereco da empresa','',True,'1','','','0');
  Inst.AddField('Empresas','Empr_Bairro','C',40,0,250,True,'Bairro','Bairro do endere�o da empresa','',True,'1','','','0');
  Inst.AddField('Empresas','Empr_CEP','C',8,0,70,True,'CEP','N�mero do CEP do endere�o da empresa',f_CEP,True,'1','','','0');
  Inst.AddField('Empresas','Empr_CxPostal','C',10,0,100,True,'Caixa Postal','N�mero da caixa postal da empresa','',True,'1','','','0');
  Inst.AddField('Empresas','Empr_Cida_Codigo','N',5,0,50,False,'C�d. Cidade','C�digo da cidade','',False,'3','','','0');
  Inst.AddField('Empresas','Empr_Municipio','C',40,0,250,True,'Cidade','Nome da cidade da empresa','',True,'1','','','0');
  Inst.AddField('Empresas','Empr_UF','C',2,0,30,True,'UF','UF da cidade da empresa','',True,'1','','','0');
  Inst.AddField('Empresas','Empr_Fone','C',11,0,100,True,'Fone','N�mero do telefone da empresa',f_fone,True,'1','','','0');
  Inst.AddField('Empresas','Empr_Fax','C',11,0,100,True,'Fax','N�mero do fax da empresa','',True,'1','','','0');
  Inst.AddField('Empresas','Empr_EMail','C',40,0,250,True,'E-Mail','E-Mail da empresa','',True,'1','','','0');

  Inst.AddTable('Unidades');
  Inst.AddField('Unidades','Unid_Codigo','C',3,0,30,False,'C�digo','C�digo da unidade','000',False,'1','','','2');
  Inst.AddField('Unidades','Unid_Empr_Codigo','C',2,0,30,False,'Emp','C�digo da empresa � que pertence a unidade','',False,'1','','','0');
  Inst.AddField('Unidades','Unid_Nome','C',40,0,250,True,'Nome Unidade','Nome da unidade','',True,'1','','','2');
  Inst.AddField('Unidades','Unid_Reduzido','C',15,0,100,True,'Nome Reduzido','Nome reduzido para a unidade','',True,'1','','','2');
  Inst.AddField('Unidades','Unid_RazaoSocial','C',50,0,250,True,'Raz�o Social','Raz�o Social da unidade','',True,'1','','','1');
  Inst.AddField('Unidades','Unid_CNPJ','C',14,0,110,True,'CNPJ Da Unidade','CNPJ da unidade',f_Cgc,True,'1','','','1');
  Inst.AddField('Unidades','Unid_InscricaoEstadual','C',20,0,150,True,'Inscr. Estadual','Inscri��o Estadual da unidade','',True,'1','','','1');
  Inst.AddField('Unidades','Unid_InscricaoMunicipal','C',20,0,150,True,'Inscr. Municipal','Inscri��o Municipal da unidade','',True,'1','','','1');
  Inst.AddField('Unidades','Unid_RegJuntaComercial','C',20,0,150,True,'Reg. Junta Com.','N�mero do registro da unidade na Junta Comercial','',True,'1','','','1');
  Inst.AddField('Unidades','Unid_DtDespachoJunta','D',8,0,60,True,'Despacho Junta Com.','Data de despacho na Junta Comercial','',True,'2','','','0');
  Inst.AddField('Unidades','Unid_Atividade','C',40,0,250,True,'Ramo Atividade','Ramo de atividade da unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_IdentAtividade','C',2,0,30,True,'Ident. Atividade','Identifica��o do ramo de atividade da unidade','',True,'1','','','');
  Inst.AddField('Unidades','Unid_Responsavel','C',40,0,250,True,'Respons�vel','Nome do respons�vel pela unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_CpfResponsavel','C',11,0,90,True,'CPF Respons�vel','CPF do respons�vel pela unidade',f_Cpf,True,'1','','','0');
  Inst.AddField('Unidades','Unid_Cargo','C',40,0,250,True,'Cargo','Cargo do respons�vel pela unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_Contador','C',40,0,250,True,'Contador','Nome do contador da unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_CpfContador','C',14,0,90,True,'CPF Contador','CPF do contador da unidade',f_Cpf,True,'1','','','0');
  Inst.AddField('Unidades','Unid_CrcContador','C',20,0,150,True,'CRC Contador','CRC do contador da unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_Endereco','C',40,0,250,True,'Endereco','Endereco da unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_Bairro','C',40,0,250,True,'Bairro','Bairro do endere�o da unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_CEP','C',8,0,70,True,'CEP','N�mero do CEP do endere�o da unidade',f_CEP,True,'1','','','0');
  Inst.AddField('Unidades','Unid_CxPostal','C',10,0,100,True,'Caixa Postal','N�mero da caixa postal da unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_Cida_Codigo','N',5,0,50,False,'C�d. Cidade','C�digo da cidade','',False,'3','','','0');
  Inst.AddField('Unidades','Unid_Municipio','C',40,0,250,True,'Cidade','Nome da cidade da unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_UF','C',2,0,30,True,'UF','UF da cidade da unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_Fone','C',11,0,100,True,'Fone','N�mero do telefone da unidade',f_fone,True,'1','','','0');
  Inst.AddField('Unidades','Unid_Fax','C',11,0,100,True,'Fax','N�mero do fax da unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_EMail','C',40,0,250,True,'E-Mail','E-Mail da unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_ContaContabil','N',08,0,70,True,'Conta Cont�bil','Conta cont�bil da unidade','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_empresa1'     ,'N',03,0,50,True,'Empresa 1'     ,'Empresa 1 da unidade','',True,'0','','','0');
  Inst.AddField('Unidades','Unid_filial1'      ,'N',03,0,50,True,'Filial 1'      ,'Filial 1 da unidade','',True,'0','','','0');
  Inst.AddField('Unidades','Unid_empresa2'     ,'N',03,0,50,True,'Empresa 2'     ,'Empresa 2 da unidade','',True,'0','','','0');
  Inst.AddField('Unidades','Unid_filial2'      ,'N',03,0,75,True,'Filial 2'      ,'Filial 2 da unidade','',True,'0','','','0');
  Inst.AddField('Unidades','Unid_VendaaVista'  ,'N',08,0,70,True,'Venda a Vista' ,'Conta exporta��o Venda a Vista','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_Caixa'        ,'N',08,0,70,True,'Caixa'         ,'Conta exporta��o Caixa','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_Clientes'     ,'N',08,0,70,True,'Clientes'      ,'Conta exporta��o Clientes','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_VendaaPrazo'  ,'N',08,0,70,True,'Venda a Prazo' ,'Conta exporta��o Venda a Prazo','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_TransEntrada' ,'N',08,0,70,True,'Transf. Entrada' ,'Transfer�ncia Entrada','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_TransSaida'   ,'N',08,0,70,True,'Transf. Saida' ,'Transfer�ncia Saida','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_Compras'      ,'N',08,0,70,True,'Compras prazo' ,'Conta exporta��o Compras a prazo' ,'',True,'1','','','0');
  Inst.AddField('Unidades','Unid_Comprasavista','N',08,0,70,True,'Compras vista' ,'Conta exporta��o Compras a vista' ,'',True,'1','','','0');
  Inst.AddField('Unidades','Unid_Simples'      ,'C',02,0,30,True,'Simples','Optante do Simples','',True,'1','','','0');
  Inst.AddField('Unidades','Unid_Serie'        ,'C',04,0,40,True,'S�rie'  ,'S�rie nota saida'  ,'',True,'1','','','0');
  Inst.AddField('Unidades','Unid_DevoVenda'    ,'N',08,0,70,True,'Devolu��o Venda' ,'Conta exporta��o Devolu��o Venda' ,'',True,'1','','','0');
// 01.08.05
  Inst.AddField('Unidades','Unid_cfis_codigoest'    ,'C',03,0,45 ,True ,'Codigo icms dentro estado' ,'Codigo icms dentro estado'                   ,f_aliq,True ,'1','','','0');
  Inst.AddField('Unidades','Unid_cfis_codigoforaest','C',03,0,45 ,True ,'Codigo icms fora estado'   ,'Codigo icms fora estado'                     ,f_aliq,True ,'1','','','0');
  Inst.AddField('Unidades','Unid_sitt_codestado'    ,'N',2 ,0,30 ,True ,'Sit.trib.dentro estado'    ,'Sit.trib.dentro estado'                      ,''    ,True ,'1','','','0');
  Inst.AddField('Unidades','Unid_sitt_forestado'    ,'N',2 ,0,30 ,True ,'Sit.trib.fora estado'      ,'Sit.trib.fora estado'                        ,''    ,True ,'1','','','0');
// 08.12.05
  Inst.AddField('Unidades','Unid_mensremessa'    ,'C',200,0,300 ,True ,'Remessa padr�o remessas' ,'Remessa padr�o remessas'                   ,f_aliq,True ,'1','','','0');
  Inst.AddField('Unidades','Unid_mensremessam'   ,'C',200,0,300 ,True ,'Remessa padr�o remessas magazine'   ,'Remessa padr�o remessas magazine'                     ,f_aliq,True ,'1','','','0');
// 20.06.07
  Inst.AddField('Unidades','Unid_ContaInss'      ,'N',008,0,070 ,True ,'Cta INSS','Conta INSS','#######0',True,'3','','','');
// 21.06.07
  Inst.AddField('Unidades','Unid_CtbTransNume'   ,'N',008,0,070 ,True ,'Cta Transf.Num','Conta Transfer�ncia de Numer�rio','#######0',True,'3','','','');
// 23.10.07
  Inst.AddField('Unidades','Unid_CtbFrete'       ,'N',008,0,070 ,True ,'Cta Frete','Conta Frete','#######0',True,'3','','','');
// 18.12.07
  Inst.AddField('Unidades','Unid_Especie'        ,'C',004,0,040 ,True ,'Esp�cie'  ,'Esp�cie'  ,'',True,'1','','','0');
// 14.08.08
  Inst.AddField('Unidades','Unid_Fornecedores'   ,'N',008,0,070,True,'Fornecedores'      ,'Conta exporta��o cont�bil Fornecedores','',True,'1','','','0');
// 02.10.08
  Inst.AddField('Unidades','Unid_Cnaefiscal'     ,'C',007,0,060,True ,'Cnae'  ,'Cnae Fiscal'  ,'',True,'1','','','0');
// 20.04.09
  Inst.AddField('Unidades','Unid_DevoCompra'    ,'N',08,0,70,True,'Devolu��o Compra' ,'Conta cont�bil exporta��o Devolu��o Compra' ,'',True,'1','','','0');
// 25.06.10 - Abra
  Inst.AddField('Unidades','Unid_NroSerieCertif','C',100,0,250,True,'Certificado Digital' ,'N�mero de s�rie do certificado digital da unidade' ,'',True,'1','','','0');
// 24.03.11
  Inst.AddField('Unidades','Unid_cfis_codestsemie'    ,'C',03,0,45 ,True ,'Codigo icms estado sem I.E.' ,'Codigo icms dentro estado para cliente sem Insc.Est.'                   ,f_aliq,True ,'1','','','0');
// 28.03.12
  Inst.AddField('Unidades','Unid_smtp'         ,'C',200,0,150,True ,'SMTP NFe' ,'Endere�o SMTP para envio de email da NFe','',True ,'1','','','0');
  Inst.AddField('Unidades','Unid_usuariosmtp'  ,'C',100,0,150,True ,'Usu�rio SMTP' ,'Endere�o de email do usu�rio do SMTP para envio de email da NFe','',True ,'1','','','0');
  Inst.AddField('Unidades','Unid_emailorigem'  ,'C',200,0,150,True ,'Email Origem' ,'Endere�o de email para o remetente para envio de email da NFe','',True ,'1','','','0');
  Inst.AddField('Unidades','Unid_senhasmtp'    ,'C',100,0,150,True ,'Senha'        ,'Senha do email para o usu�rio do SMTP para envio de email da NFe','',True ,'1','','','0');
  Inst.AddField('Unidades','Unid_portasmtp'    ,'N',004,0,040,True ,'Porta'        ,'Porta do SMTP para envio de email da NFe','',True ,'1','','','0');
  Inst.AddField('Unidades','Unid_imagemdanfe'  ,'C',200,0,150,True ,'Logo Danfe'   ,'Pasta e nome do arquivo BMP para impress�o do Danfe da NFe','',True ,'1','','','0');
// 15.09.15
  Inst.AddField('Unidades','Unid_ContaGta'     ,'N',008,0,070 ,True ,'Cta GTA','Conta GTA','#######0',True,'3','','','');
// 06.09.16
  Inst.AddField('Unidades','Unid_ComprasNS'    ,'N',008,0,070 ,True ,'N�o S�cio','N�o S�cio','#######0',True,'3','','','');
// 13.09.16
  Inst.AddField('Unidades','unid_contapisret'  ,'N',008,0,070 ,True ,'Cta PIS',   'Conta de reten��o PIS em nota de entrada','#######0',True,'3','','','');
  Inst.AddField('Unidades','unid_contacofret'  ,'N',008,0,070 ,True ,'Cta COFINS','Conta de reten��o COFINS em nota de entrada','#######0',True,'3','','','');
  Inst.AddField('Unidades','unid_contairret'   ,'N',008,0,070 ,True ,'Cta IR','Conta de reten��o IR em nota de entrada','#######0',True,'3','','','');
  Inst.AddField('Unidades','unid_contacsllret' ,'N',008,0,070 ,True ,'Cta CSLL','Conta de reten��o CSLL em nota de entrada','#######0',True,'3','','','');
// 05.12.16
// 21.06.07
  Inst.AddField('Unidades','Unid_CtbTransNumecre' ,'N',008,0,070 ,True ,'Cta Transf.Num.C','Conta Transfer�ncia de Numer�rio para Cr�dito','#######0',True,'3','','','');
// 16.01.17
  Inst.AddField('Unidades','unid_contaissret'     ,'N',008,0,070 ,True ,'Cta ISS','Conta de reten��o ISS em nota de entrada','#######0',True,'3','','','');
// 08.07.20
  Inst.AddField('Unidades','unid_contaservicos'   ,'N',008,0,070 ,True ,'Cta Servi�os','Conta de SERVI�OS para nota de saida de presta��o de servi�os','#######0',True,'3','','','');
// 10.08.20 - para diferenciar do inss ( funrural ) retido nas notas de entrada de produtor
  Inst.AddField('Unidades','unid_containssret'     ,'N',008,0,070 ,True ,'Ret INSS','Conta de reten��o INSS em nota de entrada de servi�s(tomados)','#######0',True,'3','','','');


  Inst.AddTable('Grupousu');
  Inst.AddField('Grupousu','Grus_Codigo','N',2,0,50,False,'C�digo','C�digo do grupo de usu�rios','000',False,'3','','','2');
  Inst.AddField('Grupousu','Grus_Descricao','C',40,0,250,False,'Descri��o Grupo Usu�rios','Descri��o do grupo de usu�rios','',True,'1','','','2');
  Inst.AddField('Grupousu','Grus_ObjetosAcessados','C',4000,0,0,True,'','','',False,'1','','','0');
  Inst.AddField('Grupousu','Grus_OutrosAcessos','C',4000,0,0,True,'','','',False,'1','','','0');
  Inst.AddField('Grupousu','Grus_LimiteMaximo','N',12,2,80,True,'Limite M�ximo','Valor m�ximo de limite a clientes',f_cr,True,'3','','','0');
  Inst.AddField('Grupousu','Grus_DescontoMaximo','N',10,5,70,True,'Desconto M�ximo','Percentual m�ximo de descontos concedidos',f_aliq,True,'3','','','0');
  Inst.AddField('Grupousu','Grus_TpDctosRelatorios','C',200,0,0,True,'Tipos Dcto Relat�rios','Tipos de documentos liberados para relat�rios','',True,'1','','','0');

  Inst.AddTable('Usuarios');
  Inst.AddField('Usuarios','Usua_Codigo','N',3,0,50,False,'C�digo','C�digo do usu�rio','',False,'3','','','2');
  Inst.AddField('Usuarios','Usua_Nome','C',40,0,250,False,'Nome Usu�rio','Nome do usu�rio','',True,'1','','','1');
  Inst.AddField('Usuarios','Usua_Grus_Codigo','N',2,0,50,False,'Grupo','C�digo do grupo de usu�rios','000',True,'3','','','0');
  Inst.AddField('Usuarios','Usua_Unid_Codigo','C',3,0,30,False,'Unid','C�digo da unidade do usu�rio','000',False,'1','','','0');
  Inst.AddField('Usuarios','Usua_Senha','N',08,0,80,True,'Senha','Senha do usu�rio','',True,'3','','','0');
  Inst.AddField('Usuarios','Usua_DataSenha','D',0,0,60,True,'Data Senha','Data do cadastramento da senha','',True,'1','','','0');
  Inst.AddField('Usuarios','Usua_ObjetosAcessados','C',4000,0,0,True,'','','',True,'1','','','0');
  Inst.AddField('Usuarios','Usua_OutrosAcessos','C',4000,0,0,True,'','','',True,'1','','','0');
  Inst.AddField('Usuarios','Usua_ContasCaixaValidas','C',300,0,0,True,'','','',True,'1','','','0');
  Inst.AddField('Usuarios','Usua_LimiteMaximo','N',12,2,80,True,'Limite M�ximo','Valor m�ximo de limite a clientes',f_cr,True,'3','','','0');
  Inst.AddField('Usuarios','Usua_DescontoMaximo','N',10,5,70,True,'Desconto M�ximo','Percentual m�ximo de descontos concedidos',f_aliq,True,'3','','','0');
  Inst.AddField('Usuarios','Usua_UnidadesMvto','C',300,0,0,True,'Unidades Mvto','Unidades liberadas para movimentos','',True,'1','','','0');
  Inst.AddField('Usuarios','Usua_UnidadesRelatorios','C',300,0,0,True,'Unidades Mvto','Unidades liberadas para gera��o de relat�rios','',True,'1','','','0');
  Inst.AddField('Usuarios','Usua_TpDctosRelatorios','C',200,0,0,True,'Tipos Dcto Relat�rios','Tipos de documentos liberados para relat�rios','',True,'1','','','0');
  Inst.AddField('Usuarios','Usua_Acessando','C',1,0,0,True,'Usu�rio Acessando Sistema','Usu�rio est� acessando o sistema','',True,'1','','','0');
// 18.07.05
  Inst.AddField('Usuarios','Usua_SenhaSuper','N',08,0,80,True,'Senha Supervisor','Senha de supervisor','',True,'3','','','0');
// 02.10.08
  Inst.AddField('Usuarios','Usua_email','C',80,0,150,True,'Email','Email usu�rio','',True,'3','','','0');
// 20.08.12
  Inst.AddField('Usuarios','Usua_imppedido','C',20,0,150,True,'Pedido','Codigo do impresso do Pedido de Venda','',True,'1','','','0');

  Inst.AddTable('CNAB');
  Inst.AddField('CNAB','Cnab_Codigo','C',3,0,40,False,'C�digo','C�digo do processo','',False,'1','','','2');
  Inst.AddField('CNAB','Cnab_Descricao','C',40,0,250,True,'Descri��o Do Processo','Descri��o do processo','',True,'1','','','2');
  Inst.AddField('CNAB','Cnab_Finalidade','C',1,0,20,True,'Fin.','Finalidade do processo','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_plan_Conta','N',8,0,70,True,'Conta Banc�ria','Conta banc�ria vinculada','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_Unidades','C',500,0,200,True,'Unidades','Unidades consideradas','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_ContasPendFin','C',500,0,200,True,'Contas','Contas consideradas','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_Especies','C',200,0,200,True,'Esp�cies','Esp�cies consideradas','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_LocaisPgto','C',200,0,200,True,'Locais Pgto','Locais de pagamento considerados','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_Portadores','C',200,0,200,True,'Portadores','Portadores considerados','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_TpPeriodo','C',1,0,20,True,'Tp.Per.','Tipo do per�odo considerado','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_SomenteNovas','C',1,0,20,True,'Novas','Considerar somente pend�ncias ainda n�o exportadas','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_Arquivo','C',200,0,200,True,'Arquivo Destino/Origem','Arquivo destino ou origem','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_CodBanco','C',03,0,30,True,'C�digo Banco','C�digo do banco','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_Agencia','C',20,0,80,True,'C�digo Ag�ncia','C�digo da ag�ncia do banco (com d�gito)','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_NumeroConta','C',20,0,80,True,'Conta','N�mero da conta (com d�gito)','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_DigitoAgConta','C',1,0,20,True,'D�gito Ag�ncia/Conta','D�gito verificador ag�ncia/conta','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_NomeEmpresa','C',50,0,250,True,'Nome Da Empresa','Nome da empresa','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_CNPJ','C',14,0,110,True,'CNPJ Da Empresa','CNPJ da empresa','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_MsgBloquetos1','C',40,0,200,True,'Mensagem 1','Mensagem 1 para bloquetos','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_MsgBloquetos2','C',40,0,200,True,'Mensagem 2','Mensagem 2 para bloquetos','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_DiasDtCre','N',5,0,50,True,'Dias Data Cr�dito','N�mero de dias para c�lculo da data do cr�dito','',True,'3','','','0');
  Inst.AddField('CNAB','Cnab_TipoOperacao','C',1,0,20,True,'Tipo Opera��o','Tipo da opera��o','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_TipoServico','C',2,0,30,True,'Tipo Servi�o','Tipo do servi�o','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_NumeroConvenio','C',9,0,100,True,'N�mero Conv�nio','N�mero do conv�nio','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_Convenio','C',2,0,60,True,'Conv�nio','Tipo do conv�nio','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_Variacao','C',3,0,60,True,'Varia��o','Varia��o da carteira de cobran�a','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_CodigoProduto','C',4,0,40,True,'C�digo Produto','C�digo do produto','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_CodigoMvto','C',2,0,30,True,'C�digo Movimento','C�digo do movimento','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_CodigoCarteira','C',1,0,20,True,'C�digo Carteira','C�digo da carteira','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_FormaCadastramento','C',1,0,20,True,'Forma Cadastr.','Forma do cadastramento','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_TipoDcto','C',1,0,20,True,'Tipo Dcto','Tipo do documento','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_Distribuicao','C',1,0,20,True,'Distribui��o','Respons�vel pela distribui��o','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_EspecieTitulo','C',2,0,30,True,'Esp�cie T�tulo','Esp�cie dos t�tulos','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_CodigoDesconto','C',1,0,20,True,'C�digo Desconto','C�digo do desconto','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_CodigoProtesto','C',1,0,20,True,'C�digo Protesto','C�digo do protesto','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_Aceito','C',1,0,20,True,'Ident. Aceite','Identifica��o de t�tulo aceito/n�o aceito','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_CodBxDev','C',1,0,20,True,'Baixa/Devolu��o','C�digo para baixa/devolu��o','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_PzDev','N',8,0,50,True,'Dias Baixa/Devolu��o','N�mero de dias para baixa/devolu��o','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_NomeBanco','C',30,0,150,True,'Nome Banco','Identifica��o do banco destino/origem do arquivo','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_Contador','C',10,0,50,True,'Contador','Nome do contador para sequ�ncial de arquivos','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_NossoNumero','C',02,0,30,True,'Nosso N�mero','Forma de c�lculo do "Nosso N�mero"','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_Usuarios','C',200,0,30,True,'Usu�rios','C�digo dos usu�rios autorizados','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_EmissaoBloqueto','C',1,0,20,True,'Emiss�o Bloq','Emiss�o de bloquetos','',True,'1','','','0');
  Inst.AddField('CNAB','Cnab_Moeda','C',2,0,25,True,'C�d Moeda','C�digo da moeda','',True,'1','','','0');

  Inst.AddTable('Impressos');
  Inst.AddField('Impressos','Impr_Codigo','C',3,0,30,False,'C�digo','C�digo do impresso','000',False,'1','','','2');
  Inst.AddField('Impressos','Impr_Descricao','C',50,0,250,True,'Descri��o','Descri��o do impresso','',True,'1','','','1');
  Inst.AddField('Impressos','Impr_Tipo','C',03,0,35,True,'Tipo','Tipo do impresso','',True,'1','','','0');
  Inst.AddField('Impressos','Impr_NomeContador','C',10,0,30,True,'Nome Contador','Nome do contador dos documentos impressos','',True,'1','','','0');
  Inst.AddField('Impressos','Impr_Geral','C',1,0,20,True,'Geral/Un','Contador geral ou por unidade','',True,'1','','','0');
  Inst.AddField('Impressos','Impr_FormaImpressao','C',1,0,20,True,'F.I.','Forma de impress�o do documento','',True,'1','','','0');

  Inst.AddTable('Feriados');
  Inst.AddField('Feriados','Feri_Data','D',0,0,60,False,'Data','Data do feriado','',False,'1','','','2');
  Inst.AddField('Feriados','Feri_Descricao','C',50,0,250,True,'Descri��o Do Feriado','Descri��o do feriado','',True,'1','','','0');
  Inst.AddField('Feriados','Feri_Abrangencia','C',1,0,20,True,'Abrang�ncia','Abrang�ncia do feriado','',True,'1','','','0');

  Inst.AddTable('Fornecedores');
  Inst.AddField('Fornecedores','Forn_Codigo'            ,'N', 7,0,80  ,False,'C�digo'                 ,'C�digo do fornececedor'                                         ,''       ,False,'3','','','2');
  Inst.AddField('Fornecedores','Forn_Codigo_ant'        ,'N',07,0,70  ,True,'C�digo anterior'         ,'C�digo anterior','#########0',False,'3','','','2');
  Inst.AddField('Fornecedores','Forn_Unid_ant'          ,'C',03,0,70  ,True,'Unidade anterior'        ,'Unidade anterior','#########0',False,'3','','','2');
  Inst.AddField('Fornecedores','Forn_Nome'              ,'C',60 ,0,270,True ,'Nome Do Fornecedor'     ,'Nome do fornececedor'                                           ,''       ,True ,'1','','','2');
  Inst.AddField('Fornecedores','Forn_RazaoSocial'       ,'C',60 ,0,270,True ,'Raz�o Social Fornecedor','Raz�o Social do fornececedor'                                   ,''       ,True ,'1','','','1');
  Inst.AddField('Fornecedores','Forn_CNPJCPF'           ,'C',14 ,0,110,True ,'CNPJ/CPF'               ,'CNPJ do fornececedor'                                           ,''       ,True ,'1','','','1');
  Inst.AddField('Fornecedores','Forn_Situacao'          ,'C',1  ,0,30 ,True ,'Sit'                    ,'Situa��o do fornececedor'                                       ,''       ,True ,'1','','','1');
  Inst.AddField('Fornecedores','Forn_CodVinc'           ,'N',5  ,0,60 ,True ,'C�d. Vinc.'             ,'C�digo de vincula��o de fornecedores'                           ,''       ,True ,'3','','','0');
  Inst.AddField('Fornecedores','Forn_InscricaoEstadual' ,'C',20 ,0,150,True ,'Inscr. Estadual'        ,'Inscri��o Estadual do fornececedor'                             ,''       ,True ,'1','','','1');
  Inst.AddField('Fornecedores','Forn_InscricaoMunicipal','C',20 ,0,150,True ,'Inscr. Municipal'       ,'Inscri��o Municipal do fornecedor'                              ,''       ,True ,'1','','','1');
  Inst.AddField('Fornecedores','Forn_RegJuntaComercial' ,'C',20 ,0,150,True ,'Reg. Junta Com.'        ,'N�mero do registro do fornecedor na Junta Comercial'            ,''       ,True ,'1','','','1');
  Inst.AddField('Fornecedores','Forn_Atividade'         ,'C',40 ,0,250,True ,'Ramo Atividade'         ,'Ramo de atividade do fornecedor'                                ,''       ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_Caracteristica'    ,'C',1  ,0,40 ,True ,'Car.'                   ,'Caracteristica do fornecedor'                                   ,''       ,True ,'1','','','0');  // Normal,Micro empresa,Produtor Rural,Cooperado
  Inst.AddField('Fornecedores','Forn_TipoFrete'         ,'C',1  ,0,40 ,True ,'Frete'                  ,'Tipo do frete do fornecedor'                                    ,''       ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_PzEntrega'         ,'N',5  ,0,70 ,True ,'Pz Entrega'             ,'Prazo (em dias) de entrega ap�s pedido de compra'               ,''       ,True ,'3','','','0');
  Inst.AddField('Fornecedores','Forn_PzReposicao'       ,'N',5  ,0,70 ,True ,'Pz Repos.'              ,'Prazo (em dias) de reposi��o das mercadorias do fornecedor'     ,''       ,True ,'3','','','0');
  Inst.AddField('Fornecedores','Forn_PzRecebimento'     ,'N',5  ,0,70 ,True ,'Pz Receb.'              ,'Prazo (em dias) para recebimento ap�s emiss�o das notas fiscais',''       ,True ,'3','','','0');
  Inst.AddField('Fornecedores','Forn_PzPgto'            ,'N',5  ,0,70 ,True ,'Pz Pgto'                ,'Prazo (em dias) m�dio para pagamentos'                          ,''       ,True ,'3','','','0');
  Inst.AddField('Fornecedores','Forn_Endereco'          ,'C',50 ,0,270,True ,'Endereco'               ,'Endere�o do fornecedor'                                         ,''       ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_Bairro'            ,'C',40 ,0,250,True ,'Bairro'                 ,'Bairro do endere�o do fornecedor'                               ,''       ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_CEP'               ,'C',8  ,0,65 ,True ,'CEP'                    ,'N�mero do CEP do endere�o do fornecedor'                        ,f_CEP    ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_CxPostal'          ,'C',8  ,0,65 ,True ,'Caixa Postal'           ,'N�mero da caixa postal do fornecedor'                           ,f_CEP    ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_Cida_Codigo'       ,'N',5  ,0,80 ,False,'C�d. Cidade'            ,'C�digo da cidade do fornecedor'                                 ,''       ,True ,'3','','','0');
  Inst.AddField('Fornecedores','Forn_UF'                ,'C',2  ,0,20 ,True ,'UF'                     ,'Unidade da federa��o do fornecedor'                             ,''       ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_Fone'              ,'C',11 ,0,80 ,True ,'Fone'                   ,'N�mero do telefone do fornecedor'                               ,f_fone   ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_Fax'               ,'C',11 ,0,80 ,True ,'Fax'                    ,'N�mero do fax do fornecedor'                                    ,f_fone   ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_EMail'             ,'C',40 ,0,250,True ,'E-Mail'                 ,'E-Mail do fornecedor'                                           ,''       ,True ,'1','','','0');
//  Inst.AddField('Fornecedores','Forn_Marcas'            ,'C',200,0,600,True ,'Marcas'                 ,'Marcas comercializadas pelo fornecedor'                         ,''       ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_Fpgt_Codigo'       ,'C',3  ,0,50 ,True ,'F.Pgto'                 ,'C�digo da forma de pagamento'                                   ,'000;0; ',False,'1','','','0');
//  Inst.AddField('Fornecedores','Forn_Lpgt_Codigo'       ,'C',3  ,0,50 ,True ,'L.Pgto'                 ,'C�digo do local de pagamento'                                   ,'000;0; ',False,'1','','','0');
  Inst.AddField('Fornecedores','Forn_Vendedor'          ,'C',50 ,0,250,True ,'Vendedor'               ,'Nome do vendedor'                                               ,''       ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_FoneVendedor'      ,'C',11 ,0,80 ,True ,'Fone Vend.'             ,'N�mero do telefone do vendedor'                                 ,f_fone   ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_CelularVendedor'   ,'C',11 ,0,80 ,True ,'Celular Vend.'          ,'N�mero do telefone celular do vendedor'                         ,f_fone   ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_FaxVendedor'       ,'C',11 ,0,80 ,True ,'Fax Vend.'              ,'N�mero do fax do vendedor'                                      ,f_fone   ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_Supervisor'        ,'C',50 ,0,250,True ,'Supervisor'             ,'Nome do supervisor'                                             ,''       ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_FoneSupervisor'    ,'C',11 ,0,80 ,True ,'Fone Supervisor'        ,'N�mero do telefone do supervisor'                               ,f_fone   ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_CelularSupervisor' ,'C',11 ,0,100,True ,'Celular Supervisor'     ,'N�mero do telefone celular do supervisor'                       ,f_fone   ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_Gerente'           ,'C',50 ,0,250,True ,'Gerente'                ,'Nome do gerente'                                                ,''       ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_FoneGerente'       ,'C',11 ,0,80 ,True ,'Fone Gerente'           ,'N�mero do telefone do gerente'                                  ,f_fone   ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_CelularGerente'    ,'C',11 ,0,80 ,True ,'Celular Gerente'        ,'N�mero do telefone celular do gerente'                          ,f_fone   ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_PercFunrural'      ,'N',10 ,3,80 ,True ,'Perc. Funrural'         ,'Percentual do funrural'                                         ,f_aliq   ,True ,'3','','','0');
  Inst.AddField('Fornecedores','Forn_DescPedidos'       ,'N',10 ,3,80 ,True ,'Desc. Pedidos'          ,'Percentual do desconto nos pedidos de compra'                   ,f_aliq   ,True ,'3','','','0');
  Inst.AddField('Fornecedores','Forn_DescPgtoDia'       ,'N',10 ,3,80 ,True ,'Desc. Pgtos'            ,'Percentual do desconto para pagamento em dia'                   ,f_aliq   ,True ,'3','','','0');
  Inst.AddField('Fornecedores','Forn_ObsPedidos'        ,'C',100,0,300,True ,'Observa��o Pedidos'     ,'Observa��o para pedidos de compra'                              ,''       ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_Contagerencial'    ,'N',8  ,0,70 ,True ,'Cta Gerencial'          ,'Conta gerencial do fornecedor'                                   ,''       ,True ,'3','','','0');
  Inst.AddField('Fornecedores','Forn_ContaContabil'     ,'N',8  ,0,70 ,True ,'Cta Cont�bil'           ,'Conta cont�bil do fornecedor'                                   ,''       ,True ,'3','','','0');
  Inst.AddField('Fornecedores','Forn_Comp_Codigo'       ,'C',3  ,0,70 ,True ,'Comprador'              ,'C�digo do comprador'                                            ,'000;0; ',True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_EnderecoInd'       ,'C',50 ,0,250,True ,'Endere�o Industria'     ,'Endere�o da industria'                                          ,''       ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_CidaInd_Codigo'    ,'N',5  ,0,80 ,True ,'C�d. Cidade'            ,'C�digo da cidade da industria'                               ,''       ,True ,'3','','','0');
  Inst.AddField('Fornecedores','Forn_FoneIndustria'     ,'C',11 ,0,80 ,True ,'Fone Industria'         ,'N�mero do telefone da industria'                                ,f_fone   ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_FaxIndustria'      ,'C',11 ,0,80 ,True ,'Fax Industria'          ,'N�mero do fax da industria'                                     ,f_fone   ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_ObsTrocas'         ,'C',100,0,300,True ,'Observa��o Trocas'      ,'Observa��o para trocas'                                         ,''       ,True ,'1','','','0');
  Inst.AddField('Fornecedores','Forn_DataCad'           ,'D',0  ,0,100,True ,'Data Cadastramento'     ,'Data do cadastramento do fornecedor'                            ,''       ,True ,'2','','','0');
  Inst.AddField('Fornecedores','Forn_DataAlt'           ,'D',0  ,0,100,True ,'Data Alt'               ,'Data de altera��o do cadastro do fornecedor'                    ,''       ,True ,'2','','','0');
  Inst.AddField('Fornecedores','Forn_Usua_Codigo'       ,'N',3  ,0,60 ,True ,'Usu�rio'                ,'C�digo do usu�rio respons�vel pelo cadastramento'               ,''       ,False,'3','','','0');
  Inst.AddField('Fornecedores','Forn_ContaExp'          ,'N',8  ,0,60 ,True ,'Conta p/ exporta��o'    ,'Conta para exporta��o para contabilidade externa'               ,''       ,False,'3','','','0');
  Inst.AddField('Fornecedores','Forn_Contribuinte'      ,'C',1  ,0,20 ,True ,'Ctb'                    ,'Fornecedor � contribuinte do ICMS'                              ,''       ,True ,'1','','','0');
// 28.11.06
 Inst.AddField('Fornecedores','Forn_EMail1'            ,'C',50 ,0,250,True ,'E-Mail 2'                ,'E-Mail 2 do fornecedor'                                         ,''       ,True ,'1','','','0');
// 06.03.07
  Inst.AddField('Fornecedores','Forn_ContaExp02'        ,'N',8  ,0,60 ,True ,'Conta p/ exporta��o 02'  ,'Conta para exporta��o para contabilidade externa'               ,''       ,False,'3','','','0');
  Inst.AddField('Fornecedores','Forn_ContaExp03'        ,'N',8  ,0,60 ,True ,'Conta p/ exporta��o 02'  ,'Conta para exporta��o para contabilidade externa'               ,''       ,False,'3','','','0');
  Inst.AddField('Fornecedores','Forn_ContaExp04'        ,'N',8  ,0,60 ,True ,'Conta p/ exporta��o 02'  ,'Conta para exporta��o para contabilidade externa'               ,''       ,False,'3','','','0');
  Inst.AddField('Fornecedores','Forn_unidexporta01','C',03,0,30,True,'Unidade exporta��o 01','C�digo da unidade para exporta��o','',True,'1','','','0');
  Inst.AddField('Fornecedores','Forn_unidexporta02','C',03,0,30,True,'Unidade exporta��o 02','C�digo da unidade para exporta��o','',True,'1','','','0');
  Inst.AddField('Fornecedores','Forn_unidexporta03','C',03,0,30,True,'Unidade exporta��o 03','C�digo da unidade para exporta��o','',True,'1','','','0');
  Inst.AddField('Fornecedores','Forn_unidexporta04','C',03,0,30,True,'Unidade exporta��o 04','C�digo da unidade para exporta��o','',True,'1','','','0');
// 30.12.08
  Inst.AddField('Fornecedores','Forn_certificado'  ,'C',01,0,30,True,'Certificado','Se o fornecedor � certificado','',True,'1','','','0');
// 20.04.09
  Inst.AddField('Fornecedores','Forn_devocompra'   ,'N',08,0,30,True,'Conta Devolu��o','Conta para exporta��o cont�bil de devol. de compra para contab. externa','',True,'1','','','0');
// 16.12.16
  Inst.AddField('Fornecedores','Forn_naocontab'    ,'C',01,0,30,True,'N�o Contab.','N�o contabiliza como um fornecedor da contabilidade','',True,'1','','','0');
// 16.01.17
  Inst.AddField('Fornecedores','Forn_Cidade'              ,'C',50,0,200,True,'Cidade','Cidade','',True,'1','','','0');
// 28.10.19
  Inst.AddField('Fornecedores','Forn_compraremFutura001'  ,'N',08,0,30,True,'Com.Rem.Fut.001','Conta para exporta��o cont�bil de compra remessa futura matriz','',True,'1','','','0');
  Inst.AddField('Fornecedores','Forn_compraremFutura002'  ,'N',08,0,30,True,'Com.Rem.Fut.002','Conta para exporta��o cont�bil de compra remessa futura filial','',True,'1','','','0');


  Inst.AddTable('Clientes');
  Inst.AddField('Clientes','Clie_Codigo'         ,'N',07 ,0,70 ,False,'C�digo'          ,'C�digo do cliente','#########0',False,'3','','','2');
  Inst.AddField('Clientes','Clie_Codigo_ant'     ,'N',07 ,0,70 ,True ,'C�digo anterior' ,'C�digo anterior','#########0',False,'3','','','2');
  Inst.AddField('Clientes','Clie_Unid_ant'       ,'C',03 ,0,70 ,True ,'Unidade anterior','Unidade anterior','#########0',False,'3','','','2');
  Inst.AddField('Clientes','Clie_Nome'           ,'C',60,0,250,True,'Nome Do Cliente','Nome do cliente','',True,'','','','1');
  Inst.AddField('Clientes','Clie_RazaoSocial'    ,'C',60,0,250,True,'Raz�o Social','Raz�o social do cliente','',True,'','','','');
//  Inst.AddField('Clientes','Clie_NomeCartao'     ,'C',30,0,150,True,'Nome Cart�o','Nome do cliente no cart�o','',True,'','','','');
  Inst.AddField('Clientes','Clie_Tipo','C'       ,1,0,20,False,'F/J','Pessoa F�sica ou Pessoa Jur�dica','',False,'','','','');
  Inst.AddField('Clientes','Clie_CNPJCPF'        ,'C',14,0,120,True,'CNPJ / CPF','CNPJ ou CPF do cliente','',True,'','','','2');
  Inst.AddField('Clientes','Clie_RgIe'           ,'C',20,0,140,True,'RG / Inscri��o Estadual','RG ou Inscri��o Estadual do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_DtExpRG'        ,'D',8,0,65,True,'Expedi��o','Data de expedi��o do RG','',True,'','','','');
  Inst.AddField('Clientes','Clie_OrgExpRG'       ,'C',10,0,70,True,'Org�o Expedidor','Org�o Expedidor do RG','',True,'','','','');
  Inst.AddField('Clientes','Clie_UFExpRG'        ,'C',2,0,30,True,'UF RG','UF de expedi��o do RG','',True,'','','','');
  Inst.AddField('Clientes','Clie_UF'             ,'C',2,0,30,True,'UF','UF do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_Sexo'           ,'C',1,0,20,True,'Sexo','Sexo do cliente','',true,'','','','');
  Inst.AddField('Clientes','Clie_EndRes'         ,'C',40,0,250,True,'Endere�o','Endere�o residencial do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_EndResCompl'    ,'C',20,0,140,True,'Complemento','Complemento do endere�o do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_BairroRes'      ,'C',30,0,200,True,'Bairro','Bairro do endere�o residencial do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_Cida_Codigo_Res','N',5,0,50,True,'Cod Cidade','C�digo da cidade do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_CepRes','C',8,0,70,True,'CEP','CEP do endere�o do cliente','##.###-###;0;_',True,'','','','');
  Inst.AddField('Clientes','Clie_FoneRes','C',12,0,90,True,'Fone Residencial','Telefone resid�ncial do cliente','(###) ####-####;0;_',True,'','','','');
  Inst.AddField('Clientes','Clie_FoneCel','C',12,0,90,True,'Fone Celular','Telefone celular do cliente','(###) ####-####;0;_',True,'','','','');
  Inst.AddField('Clientes','Clie_DtNasc','D',8,0,65,True,'Nascimento','Data de Nascimento do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_Naturalidade','C',30,0,200,True,'Naturalidade','Naturalidade do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_Classe','C',10,0,70,True,'Classe','Classe do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_EMail','C',100,0,250,True,'E-Mail','Endere�o de e-mail do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_EMailCorr','C',1,0,20,True,'Recebe E-Mail','Recebe Correspond�ncia no Endere�o de E-Mail','',True,'','','','');
  Inst.AddField('Clientes','Clie_EndCorr','C',1,0,20,True,'Endere�o Correspond�ncias','Endere�o para receber correspond�ncias','',True,'','','','');
  Inst.AddField('Clientes','Clie_Empresa','C',50,0,250,True,'Empresa','Empresa onde trabalha','',True,'','','','');
  Inst.AddField('Clientes','Clie_Funcao','C',30,0,200,True,'Fun��o','Fun��o do cliente na empresa onde trabalha','',True,'','','','');
  Inst.AddField('Clientes','Clie_EndCom','C',50,0,250,True,'Endere�o','Endere�o comercial do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_BairroCom','C',30,0,200,True,'Bairro','Bairro do endere�o comercial','',True,'','','','');
  Inst.AddField('Clientes','Clie_Cida_Codigo_Com','N',5,0,50,True,'Cod Cidade','C�digo da cidade do endere�o comercial','',True,'','','','');
  Inst.AddField('Clientes','Clie_CepCom','C',8,0,70,True,'CEP','CEP do endere�o comercial','',True,'##.###-###;0;_','','','');
  Inst.AddField('Clientes','Clie_FoneCom','C',12,0,90,True,'Fone Comercial','Telefone comercial do cliente','(###) ####-####;0;_',True,'','','','');
  Inst.AddField('Clientes','Clie_Ramal','N',5,0,50,True,'Ramal','Ramal do cliente na empresa','####0',True,'3','','','');
  Inst.AddField('Clientes','Clie_DtAdmissao','D',8,0,65,True,'Admiss�o','Data de admiss�o do cliente no emprego atual','',True,'','','','');
  Inst.AddField('Clientes','Clie_CodCliEmp','C',15,0,100,True,'C�digo Empresa','C�digo do cliente na empresa onde trabalha','',true,'','','','');
  Inst.AddField('Clientes','Clie_RendaComprovada','N',12,2,90,True,'Renda Comprovada','Valor da renda l�quida comprovada do cliente','###,###,##0.00',True,'3','+','','');
  Inst.AddField('Clientes','Clie_RendaNaoComprovada','N',12,2,90,True,'Renda N�o Comprovada','Valor da renda n�o comprovada do cliente','###,###,##0.00',True,'3','+','','');
  Inst.AddField('Clientes','Clie_DescrRendaNaoComp','C',50,0,300,True,'Descri��o Renda','Descritivo para a renda n�o comprovada do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_EstadoCivil','C',1,0,20,True,'Estado Civil','Estado civil do cliente','0',True,'','','','');
  Inst.AddField('Clientes','Clie_DescrEstadoCivil','C',20,0,140,True,'Nome Est.Civ.','Descri��o do estado civil do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_Escolaridade','C',1,0,20,True,'Escolaridade','Nivel de escolaridade do cliente','0',True,'','','','');
  Inst.AddField('Clientes','Clie_Emprego','C',1,0,20,True,'Emprego','Tipo de emprego do cliente','',True,'0','','','');
  Inst.AddField('Clientes','Clie_Moradia','C',1,0,20,True,'Moradia','Tipo de moradia do cliente','',True,'0','','','');
  Inst.AddField('Clientes','Clie_ValorAluguel','N',12,2,90,True,'Aluguel','Valor do aluguel do cliente','###,###,##0.00',True,'3','+','','');
  Inst.AddField('Clientes','Clie_DtMoradia','D',8,0,65,True,'Data Moradia','Data de entrada no im�vel de moradia atual','',True,'','','','');
  Inst.AddField('Clientes','Clie_ContaContabil','N',08,0,70,True,'Cta Cont�bil','Conta cont�bil do cliente','#########0',True,'3','','','');
  Inst.AddField('Clientes','Clie_ContaGerencial','N',08,0,70,True,'Cta Gerencial','Conta gerencial do cliente','#########0',True,'3','','','');
  Inst.AddField('Clientes','Clie_Obs','C',200,0,500,True,'Observa��o','Observa��es do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_DiaVenc','N',2,0,30,True,'Vencimento','Dia de vencimento do cart�o de cr�dito','#0',True,'3','','','');
  Inst.AddField('Clientes','Clie_Situacao','C',1,0,20,True,'Sit Cliente','Situa��o do cliente','0',True,'','','','');
  Inst.AddField('Clientes','Clie_Motivo','N',3,0,30,True,'Motivo Cliente','Motivo do bloqueio do cliente','##0',True,'3','','','');
  Inst.AddField('Clientes','Clie_UsuSituacao','N',5,0,50,True,'Usu�rio Bloqueio','Usu�rio respons�vel pela situa��o de bloqueio do cliente','####0',True,'3','','','');
  Inst.AddField('Clientes','Clie_DtLibCad','D',8,0,65,True,'Libera��o','Data de libera��o do cadastro do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_UsuLibCad','N',5,0,50,True,'Usu�rio Libera��o','Usu�rio respons�vel pela libera��o do cadastro do cliente','####0',True,'3','','','');
  Inst.AddField('Clientes','Clie_Dependentes','N',3,0,30,True,'Dependentes','N�mero de dependentes do cliente','##0',True,'3','','','');
  Inst.AddField('Clientes','Clie_NovoDiaVenc','N',2,0,30,True,'Novo Dia Venc','Novo dia de vencimento do cart�o','#0',True,'3','','','');
  Inst.AddField('Clientes','Clie_EncargosCob','C',1,0,20,True,'Encargos Cobran�a','Gerar encargos de cobran�a para o cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_DtCad','D',8,0,70,True,'Data Cadastro','Data de cadastramento do cliente','',False,'','','','');
  Inst.AddField('Clientes','Clie_DataAlt','D',8,0,70,True,'Data Alt','Data de altera��o do cadastro do cliente','',False,'','','','');
  Inst.AddField('Clientes','Clie_Unid_Codigo','C',3,0,30,True,'Unidade Cadastro','Unidade de cadastro do cliente','000',False,'','','','');
  Inst.AddField('Clientes','Clie_Usua_Codigo','N',3,0,50,True,'Usu�rio Cadastro','Usu�rio respons�vel pelo cadastro do cliente','####0',False,'','','','');
  Inst.AddField('Clientes','Clie_Contribuinte','C',1,0,20 ,True,'Ctb','Cliente � contribuinte do ICMS','',False,'1','','','0');
//  Inst.AddField('Clientes','Clie_RotaEntrega','C',15,0,100 ,True,'Rota Entrega','Rota ou sequ�ncia de entrega','',False,'1','','','0');
//  Inst.AddField('Clientes','Clie_Vend_Codigo','C',03,0,40 ,True,'Vendedor','C�digo do vendedor','',False,'1','','','0');
  Inst.AddField('Clientes','Clie_Filiacao','C',100,0,200 ,True,'Filia��o','Filia��o do cliente','',False,'1','','','0');
  Inst.AddField('Clientes','Clie_ContaBloqueio','N',8,0,60,True,'Conta Bloqueio','C�digo da conta a receber pela qual o cliente foi bloqueado','',True,'3','','','');
  Inst.AddField('Clientes','Clie_ConsFinal'    ,'C',1,0,30,True,'Cons.Final'    ,'Indica se � consumidor final'                               ,'',True,'3','','','');
  Inst.AddField('Clientes','Clie_Repr_Codigo'  ,'N',04,0,40 ,True,'Representante','C�digo do representante','',False,'','','','0');
  Inst.AddField('Clientes','Clie_Repr_Codigoant'  ,'N',04,0,40 ,True,'Representante','C�digo do representante','',False,'','','','0');
  Inst.AddField('Clientes','Clie_NomeCJE'         ,'C',40,0,250,True,'Conjuge','Nome do conjuge','',True,'','','','2');
  Inst.AddField('Clientes','Clie_CPFCJE'          ,'C',11,0,120,True,'CPF','CPF do conjuge','',True,'','','','2');
  Inst.AddField('Clientes','Clie_RgCJE'           ,'C',12,0,140,True,'RG ','RG do conjuge','',True,'','','','');
  Inst.AddField('Clientes','Clie_AgeCJE'          ,'C',08,0,060,True,'Ag�ncia','Ag�ncia banc�ria do conjuge','',True,'','','','');
  Inst.AddField('Clientes','Clie_BcoCJE'          ,'C',15,0,110,True,'Conta','Conta banc�ria do conjuge','',True,'','','','');
  Inst.AddField('Clientes','Clie_TrabalhoCJE'     ,'C',50,0,200,True,'Local Trabalho','Local de Trabalho do conjuge','',True,'','','','');
  Inst.AddField('Clientes','Clie_AnosTrabCJE'     ,'N',02,0,030,True,'Anos Trabalho','Anos de Trabalho do conjuge','',True,'','','','');
// 05.10.05
  Inst.AddField('Clientes','Clie_Pai'             ,'C',40,0,250,True,'Nome Do Pai'    ,'Nome do Pai'    ,'',True,'','','','1');
  Inst.AddField('Clientes','Clie_Mae'             ,'C',40,0,250,True,'Nome Do M�e'    ,'Nome do M�e'    ,'',True,'','','','1');
  Inst.AddField('Clientes','Clie_FonePai'         ,'C',12,0, 90,True,'Fone Pai','Fone Pai','(###) ####-####;0;_',True,'','','','');
// 28.11.06
  Inst.AddField('Clientes','Clie_EMail1'          ,'C',100,0,250,True,'E-Mail 2','Endere�o de e-mail 2 do cliente','',True,'','','','');
  Inst.AddField('Clientes','Clie_Fax'             ,'C',11,0,090,True,'Fax'     ,'Fax','(###) ####-####;0;_',True,'','','','');
// 07.03.07 - define se tem ou nao ipi quando vende para o cliente
  Inst.AddField('Clientes','Clie_Ipi'             ,'C',01,0,060,True,'IPI'     ,'IPI','',True,'','','','');
// 02.05.07
// ver se ser� preciso campo para matricula ou se poder� usar o proprio codigo
  Inst.AddField('Clientes','Clie_Ativo'           ,'C',01,0,060,True,'Ativo'     ,'Ativo','',True,'','','','');
  Inst.AddField('Clientes','Clie_Dtreccotas'      ,'D',08,0,065,True,'Rec.Cotas','Data de recebimento cotas','',True,'','','','');
  Inst.AddField('Clientes','Clie_Vlrreccotas'     ,'N',12,3,070,True,'Vlr.Rec.Cotas','Valor cotas recebidas','',True,'3','+','','');
  Inst.AddField('Clientes','Clie_Vlrcotas'        ,'N',12,3,070,True,'Valor Cotas','Valor cota capital',     '',True,'3','+','','');
// 21.05.07
  Inst.AddField('Clientes','Clie_Cidade'          ,'C',50,0,250,True,'Cidade','Nome Cidade',     '',True,'1','','','');
// 25.05.07
  Inst.AddField('Clientes','Clie_Limcredito'      ,'N',12,3,070,True,'Limite Cr�dito','Limite Cr�dito',     '',True,'3','','','');
// 20.06.07
  Inst.AddField('Clientes','Clie_ContaCotaCap'    ,'N',08,0,070,True,'Cta Cota Capital','Conta Cota Capital','#########0',True,'3','','','');
// 06.08.07
  Inst.AddField('Clientes','Clie_CodigoFinan'     ,'N',08,0,070,True,'Financeiro'      ,'Codigo Centralizador Financeiro','#######0',True,'3','','','');
// 07.01.08
  Inst.AddField('Clientes','Clie_ContaVendas01'   ,'N',08,0,070,True,'Cta Vendas 01'  ,'Conta cont�bil de vendas 01','#######0',True,'3','','','');
  Inst.AddField('Clientes','Clie_Unid_Codigo01'   ,'C',03,0,030,True,'Unidade 01'  ,'Unidade 01','000',False,'','','','');
  Inst.AddField('Clientes','Clie_ContaVendas02'   ,'N',08,0,070,True,'Cta Vendas 02'  ,'Conta cont�bil de vendas 02','#######0',True,'3','','','');
  Inst.AddField('Clientes','Clie_Unid_Codigo02'   ,'C',03,0,030,True,'Unidade 02'  ,'Unidade 02','000',False,'','','','');
// 14.02.08 - ctg
  Inst.AddField('Clientes','Clie_Matricula'       ,'N',07,0,070,True,'Matr�cula'      ,'Matr�cula','#######0',True,'3','','','');
// I - integrante  A - associado
  Inst.AddField('Clientes','Clie_Integrante'      ,'C',01,0,060,True,'Ass/Integrante'  ,'Associado/Integrante','',False,'','','','');
  Inst.AddField('Clientes','Clie_Tipomensa'       ,'C',02,0,060,True,'Mensalidade'     ,'Mensalidade'         ,'',False,'','','','');
  Inst.AddField('Clientes','Clie_Tipoinver'       ,'C',02,0,060,True,'Invernada'       ,'Invernada'           ,'',False,'','','','');
  Inst.AddField('Clientes','Clie_QIntegra'        ,'C',01,0,060,True,'Integrante'      ,'Integrante'          ,'',False,'','','','');
  Inst.AddField('Clientes','Clie_Grupoinv'        ,'C',20,0,150,True,'Grupo Invernada' ,'Grupo Invernada'     ,'',False,'1','','','');
// 15.08.08 - devolucao de vendas -novicarnes
  Inst.AddField('Clientes','Clie_ContaDevVen01'   ,'N',08,0,070,True,'Cta Dev Vendas 01'  ,'Conta cont�bil devolu��o vendas 01','#######0',True,'3','','','');
// 11.02.10 - novicarnes - produtor com acao na justica pra nao pagar funrural
//  Inst.AddField('Clientes','Clie_DescInssPro'     ,'C',01,0,050,True,'Desc.Inss'  ,'Desc.Inss NF Produtor','',True,'1','','','');
// 11.02.10 - novicarnes - produtor pessoa juridica mas com empregador recolhe 0,2
  Inst.AddField('Clientes','Clie_AliInssPro'     ,'N',07,3,050,True,'Aliq.Inss'  ,'Al�quota Inss NF Produtor','',True,'1','','','');
// 10.09.11 - novicarnes - produtor com deposito em conta judicial
  Inst.AddField('Clientes','Clie_Depojudi'       ,'C',01,0,050,True,'Dep.Judicial'  ,'Inss em dep�sito judicial','',True,'1','','','');
  Inst.AddField('Clientes','Clie_ContaDepojudi'  ,'C',20,0,080,True,'Conta Cor.'  ,'Conta corrente para dep�sito judicial','',True,'1','','','');
  Inst.AddField('Clientes','Clie_AliInssDepJud'  ,'N',07,3,050,True,'Al.Inss Dep.'  ,'Al�quota Inss para dep�sito judicial','',True,'1','','','');
// 31.10.11 - Novicarnes - isonel
  Inst.AddField('Clientes','Clie_Fpgt_Codigo'    ,'C',3  ,0,50 ,True ,'F.Pgto'                 ,'C�digo da forma de pagamento'                                   ,'000;0; ',False,'1','','','0');
// 15.07.13 - Vivan - Liane
  Inst.AddField('Clientes','Clie_tiposremessas'  ,'C',100,0,200,True,'Tipos de Remessas'      ,'Tipos de Remessa de Consigna��o permitidos'                                   ,'',False,'1','','','0');
// 12.08.13 - Vivan - Angela
  Inst.AddField('Clientes','Clie_Portadores'     ,'C',050,0,100,True,'Portadorores'           ,'C�digos do(s) portador(es)','',False,'1','','','0');
// 31.12.14 - Coorlaf
  Inst.AddField('Clientes','Clie_Agencia'        ,'C',010,0,100,True,'Ag�ncia'                ,'C�digo da ag�ncia do banco','',True,'1','','','0');
  Inst.AddField('Clientes','Clie_ContaCorrente'  ,'C',030,0,100,True,'Conta Corrente'         ,'N�mero da conta corrente no banco','',True,'1','','','0');
// 16.01.17
  Inst.AddField('Clientes','Clie_ContaDevVen02'  ,'N',08,0,070,True,'Cta Dev Vendas 02'  ,'Conta cont�bil devolu��o vendas 02','#######0',True,'3','','','');
  Inst.AddField('Clientes','Clie_ContaCompras02' ,'N',08,0,070,True,'Cta Compras 02   '  ,'Conta cont�bil de compras 02','#######0',True,'3','','','');
// 03.03.17
  Inst.AddField('Clientes','Clie_ContaCotaCap02'  ,'N',08,0,070,True,'Cta Cota Capital 02','Conta Cota Capital 02','#########0',True,'3','','','');
// 22.09.17
  Inst.AddField('Clientes','Clie_DescontoVenda'   ,'N',07,3,050,True,'Desc.Vendas'  ,'Percentual para desconto autom�tico nas vendas','',True,'1','','','');
// 13.03.18
  Inst.AddField('Clientes','Clie_ContaDevDuv'     ,'N',08,0,070,True,'Cta Dev Duv.'  ,'Conta cont�bil devedor duvidoso','#######0',True,'3','','','');
// 22.05.18 - Giacomoni - Barbara
  Inst.AddField('Clientes','Clie_CondicoesPag'    ,'C',100,0,170,True,'Condi��es Pag.'  ,'Condi��es de pagamento para uso nas vendas','',True,'3','','','');
// 25.10.18 - 2 contatos para uso nas televendas
  Inst.AddField('Clientes','Clie_Contato1'        ,'C',100,0,170,True,'Contato Tel.1'  ,'Contato Tel.1','',True,'1','','','');
  Inst.AddField('Clientes','Clie_Contato2'        ,'C',100,0,170,True,'Contato Tel.2'  ,'Contato Tel.2','',True,'1','','','');
// 26.02.19
  Inst.AddField('Clientes','Clie_AcrescimoVenda'  ,'N',07,3,050,True,'Acresc.Vendas'  ,'Percentual para acr�scimo autom�tico nas vendas','',True,'1','','','');
// 11.04.19 - Vida Nova - Leite da Crian�a
  Inst.AddField('Clientes','Clie_qtdediaria'      ,'N',07,0,050,True,'Qtde Di�ria'    ,'Quantidade di�ria a ser entregue por cliente','',True,'3','','','');
  Inst.AddField('Clientes','Clie_vezessegunda'    ,'N',07,0,050,True,'X Segunda'      ,'Multiplicador para quantidade na segunda-feira','',True,'3','','','');
  Inst.AddField('Clientes','Clie_vezesterca'      ,'N',07,0,050,True,'X Ter�a'        ,'Multiplicador para quantidade na ter�a-feira'   ,'',True,'3','','','');
  Inst.AddField('Clientes','Clie_vezesquarta'     ,'N',07,0,050,True,'X Quarta'       ,'Multiplicador para quantidade na quarta-feira'   ,'',True,'3','','','');
  Inst.AddField('Clientes','Clie_vezesquinta'     ,'N',07,0,050,True,'X Quinta'       ,'Multiplicador para quantidade na quinta-feira'   ,'',True,'3','','','');
  Inst.AddField('Clientes','Clie_vezessexta'      ,'N',07,0,050,True,'X Sexta'        ,'Multiplicador para quantidade na sexta-feira'   ,'',True,'3','','','');
// 16.04.19  - Leite da Crian�a
  Inst.AddField('Clientes','Clie_tran_codigo'     ,'C',3  ,0,30 ,True ,'Transp.'                    ,'C�digo do motorista/transportador'                   ,''    ,True,'1','','','0');
// 30.09.19 - Novicarnes - Ketlen
  Inst.AddField('Clientes','Clie_Ctaccassoc'    ,'N',008,0,070,True,'Cta CC Assoc'     ,'Conta cont�bil conta corrente associados','#######0',True,'3','','','');
  Inst.AddField('Clientes','Clie_CtaCotassoc'   ,'N',008,0,070,True,'Cta Cotas Assoc'  ,'Conta cont�bil cotas parte associados','#######0',True,'3','','','');
  Inst.AddField('Clientes','Clie_Ctaeapassoc'   ,'N',008,0,070,True,'Cta Emp.Ap. Assoc'  ,'Conta cont�bil empr�stimos a pagar associados','#######0',True,'3','','','');
// 09.01.20 - Mirvane
  Inst.AddField('Clientes' ,'Clie_Tabp_Codigo'  ,'N',003,0,30,   True ,'C�digo'                    ,'C�digo da tabela','',False,'1','','','2');
// 08.06.20  - Vida Nova
  Inst.AddField('Clientes' ,'Clie_Mens_codigo'  ,'N',004,0,30 , True ,'C�digo'                    ,'C�digo da mensagem'                           ,''    ,False,'1','','','2');


// 26.02.15 - vivan
  Inst.AddTable('Clientesdoc');
  Inst.AddField('Clientesdoc','Clid_Codigo'      ,'N',07 ,0,70 ,False,'C�digo'          ,'C�digo do cliente','#########0',True,'3','','','2');
  Inst.AddField('Clientesdoc','Clid_Doc1'        ,'M',000,0,100,True,'Documento 1'             ,'Digitaliza��o de documento 1','',True,'1','','','0');
  Inst.AddField('Clientesdoc','Clid_Doc2'        ,'M',000,0,100,True,'Documento 2'             ,'Digitaliza��o de documento 2','',True,'1','','','0');
  Inst.AddField('Clientesdoc','Clid_Doc3'        ,'M',000,0,100,True,'Documento 3'             ,'Digitaliza��o de documento 3','',True,'1','','','0');
  Inst.AddField('Clientesdoc','Clid_Doc4'        ,'M',000,0,100,True,'Documento 4'             ,'Digitaliza��o de documento 4','',True,'1','','','0');


// confirmar se ter� ou n�o vendedor
//  Inst.AddTable('Vendedores');
//  Inst.AddField('Vendedores','Vend_Codigo','C',3,0,30,False,'C�digo','C�digo do vendedor','000',False,'1','','','2');
//  Inst.AddField('Vendedores','Vend_Nome','C',50,0,250,True,'Nome Do Vendedor','Nome do vendedor','',True,'1','','','2');
//  Inst.AddField('Vendedores','Vend_Comissao','N',10,5,60,True,'Comiss�o','Percentual de comiss�o para o vendedor','##0.000',True,'3','','','0');

  Inst.AddTable('Representantes');
  Inst.AddField('Representantes','Repr_Codigo'            ,'N', 4,0, 30,False,'C�digo'                    ,'C�digo do representante','',False,'1','','','2');
  Inst.AddField('Representantes','Repr_Codigo_ant'        ,'N', 4,0, 30,True ,'C�digo anterior'           ,'C�digo anterior representante','',False,'1','','','2');
  Inst.AddField('Representantes','Repr_Unid_ant'          ,'C', 3,0, 30,True ,'Unidade anterior'          ,'Unidade anterior representante','',False,'1','','','2');
  Inst.AddField('Representantes','Repr_Nome'              ,'C',50,0,250,True ,'Nome Do Representante'     ,'Nome do representante','',True,'1','','','2');
  Inst.AddField('Representantes','Repr_RazaoSocial'       ,'C',50,0,280,True ,'Raz�o Social Representante','Raz�o Social do representante'                         ,''    ,True ,'1','','','1');
  Inst.AddField('Representantes','Repr_CNPJCPF'           ,'C',14,0,95 ,True ,'CNPJ/CPF'                  ,'C.N.P.J./C.P.F. do representante'                      ,''    ,True ,'1','','','1');
//  Inst.AddField('Representantes','Repr_Situacao'          ,'C',1 ,0,30 ,True ,'Sit'                       ,'Situa��o do representante'                             ,''    ,True ,'1','','','0');
  Inst.AddField('Representantes','Repr_InscricaoEstadual' ,'C',20,0,150,True ,'Inscr. Estadual'           ,'Inscri��o Estadual do representante'                   ,''    ,True ,'1','','','1');
  Inst.AddField('Representantes','Repr_InscricaoMunicipal','C',20,0,150,True ,'Inscr. Municipal'          ,'Inscri��o Municipal do representante'                  ,''    ,True ,'1','','','1');
  Inst.AddField('Representantes','Repr_RegJuntaComercial' ,'C',20,0,150,True ,'Reg. Junta Com.'           ,'N�mero do registro do representante na Junta Comercial',''    ,True ,'1','','','1');
  Inst.AddField('Representantes','Repr_Endereco'          ,'C',40,0,250,True ,'Endere�o'                  ,'Endere�o do representante'                             ,''    ,True ,'1','','','0');
  Inst.AddField('Representantes','Repr_Bairro'            ,'C',40,0,250,True ,'Bairro'                    ,'Bairro do representante'                               ,''    ,True ,'1','','','0');
  Inst.AddField('Representantes','Repr_CEP'               ,'C',8 ,0,65 ,True ,'CEP'                       ,'N�mero do CEP do representante'                        ,f_CEP ,True ,'1','','','0');
  Inst.AddField('Representantes','Repr_CxPostal'          ,'C',10,0,65 ,True ,'Caixa Postal'              ,'N�mero da caixa postal do representante'               ,f_CEP ,True ,'1','','','0');
  Inst.AddField('Representantes','Repr_Cida_Codigo'       ,'N',5 ,0,60 ,False,'C�d. Cidade'               ,'C�digo da cidade'                                      ,''    ,True ,'3','','','0');
  Inst.AddField('Representantes','Repr_Fone'              ,'C',11,0,80 ,True ,'Fone'                      ,'N�mero do telefone do representante'                   ,f_fone,True ,'1','','','0');
  Inst.AddField('Representantes','Repr_Fax'               ,'C',11,0,80 ,True ,'Fax'                       ,'N�mero do fax do representante'                        ,f_fone,True ,'1','','','0');
  Inst.AddField('Representantes','Repr_EMail'             ,'C',40,0,250,True ,'E-Mail'                    ,'E-Mail do representante'                               ,''    ,True ,'1','','','0');
  Inst.AddField('Representantes','Repr_Comissao'          ,'N',10,5,60 ,True,'Comiss�o','Percentual de comiss�o para o vendedor','##0.000',True,'3','','','0');
  Inst.AddField('Representantes','Repr_Contagerencial'    ,'N',8  ,0,70,True ,'Cta Gerencial'             ,'Conta gerencial do representante'                                   ,''       ,True ,'3','','','0');
// 13.07.06
  Inst.AddField('Representantes','Repr_Repr_Codigo'       ,'N',4  ,0,50  ,True ,'Codigo Supervisor'       ,'Codigo Supervisor'   ,'',False,'','','','2');
// 06.07.09
  Inst.AddField('Representantes','Repr_TipoRepr'          ,'C',1  ,0,50  ,True ,'Tipo'       ,'Tipo de Representante'   ,'',False,'','','','2');


  Inst.AddTable('Transportadores');
  Inst.AddField('Transportadores','Tran_codigo'            ,'C',3 ,0,30 ,False,'C�digo'                    ,'C�digo do transportador'                               ,''    ,False,'1','','','2');
  Inst.AddField('Transportadores','Tran_Nome'              ,'C',40,0,250,True ,'Nome Do Transportador'     ,'Nome do transportador'                                 ,''    ,True ,'1','','','2');
  Inst.AddField('Transportadores','Tran_RazaoSocial'       ,'C',50,0,280,True ,'Raz�o Social Transportador','Raz�o Social do transportador'                         ,''    ,True ,'1','','','1');
  Inst.AddField('Transportadores','Tran_CNPJCPF'           ,'C',14,0,95 ,True ,'CNPJ/CPF'                  ,'C.N.P.J./C.P.F. do transportador'                      ,''    ,True ,'1','','','1');
  Inst.AddField('Transportadores','Tran_Situacao'          ,'C',1 ,0,30 ,True ,'Sit'                       ,'Situa��o do transportador'                             ,''    ,True ,'1','','','0');
  Inst.AddField('Transportadores','Tran_InscricaoEstadual' ,'C',20,0,150,True ,'Inscr. Estadual'           ,'Inscri��o Estadual do transportador'                   ,''    ,True ,'1','','','1');
  Inst.AddField('Transportadores','Tran_InscricaoMunicipal','C',20,0,150,True ,'Inscr. Municipal'          ,'Inscri��o Municipal do transportador'                  ,''    ,True ,'1','','','1');
  Inst.AddField('Transportadores','Tran_RegJuntaComercial' ,'C',20,0,150,True ,'Reg. Junta Com.'           ,'N�mero do registro do transportador na Junta Comercial',''    ,True ,'1','','','1');
  Inst.AddField('Transportadores','Tran_Endereco'          ,'C',40,0,250,True ,'Endere�o'                  ,'Endere�o do transportador'                             ,''    ,True ,'1','','','0');
  Inst.AddField('Transportadores','Tran_Bairro'            ,'C',40,0,250,True ,'Bairro'                    ,'Bairro do endere�o do transportador'                   ,''    ,True ,'1','','','0');
  Inst.AddField('Transportadores','Tran_CEP'               ,'C',8 ,0,65 ,True ,'CEP'                       ,'N�mero do CEP do endere�o do transportador'            ,f_CEP ,True ,'1','','','0');
  Inst.AddField('Transportadores','Tran_CxPostal'          ,'C',10,0,65 ,True ,'Caixa Postal'              ,'N�mero da caixa postal do transportador'               ,f_CEP ,True ,'1','','','0');
  Inst.AddField('Transportadores','Tran_Cida_Codigo'       ,'N',5 ,0,60 ,False,'C�d. Cidade'               ,'C�digo da cidade'                                     ,''    ,True ,'3','','','0');
  Inst.AddField('Transportadores','Tran_Fone'              ,'C',11,0,80 ,True ,'Fone'                      ,'N�mero do telefone do transportador'                   ,f_fone,True ,'1','','','0');
  Inst.AddField('Transportadores','Tran_Fax'               ,'C',11,0,80 ,True ,'Fax'                       ,'N�mero do fax do transportador'                        ,f_fone,True ,'1','','','0');
  Inst.AddField('Transportadores','Tran_EMail'             ,'C',40,0,250,True ,'E-Mail'                    ,'E-Mail do transportador'                               ,''    ,True ,'1','','','0');
  Inst.AddField('Transportadores','Tran_Placa'             ,'C',20,0,100,True ,'Placa'                     ,'Placa do ve�culo transportador'                        ,''    ,True ,'1','','','0');
  Inst.AddField('Transportadores','Tran_UFPlaca'           ,'C',2 ,0,50 ,True ,'UF Placa'                  ,'UF da placa do ve�culo transportador'                  ,''    ,True ,'1','','','2');
  Inst.AddField('Transportadores','Tran_ContaGerencial'    ,'N',08,0,70 ,True ,'Cta Gerencial','Conta gerencial do transportador','#########0',True,'3','','','');
  Inst.AddField('Transportadores','Tran_Usua_Codigo'       ,'N',3 ,0,50 ,False,'Usu�rio'                   ,'C�digo do usu�rio respons�vel pelo cadastramento'      ,''    ,False,'3','','','0');
// 28.09.06
  Inst.AddField('Transportadores','Tran_Comissao'          ,'N',7 ,2,50 ,True ,'% Comiss�o'                ,'% Comiss�o'                                            ,''    ,False,'3','','','0');
// 03.09.08
  Inst.AddField('Transportadores','Tran_Proprio'           ,'C',1 ,0,50 ,True ,'Pr�prio'                   ,'Ve�culo pr�prio'                                       ,''    ,True ,'1','','','0');
// 20.08.12
  Inst.AddField('Transportadores','Tran_Cola_Codigo'       ,'C',4 ,0,50 ,True ,'Colaborador','C�digo do colaborador','0000',True,'1','','','2');
// 27.06.16
  Inst.AddField('Transportadores','Tran_Tara'              ,'N',12 ,2,50 ,True ,'Tara'                      ,'Tara'                                            ,''    ,False,'3','','','0');
  Inst.AddField('Transportadores','Tran_PesoMaximo'        ,'N',12 ,2,50 ,True ,'Peso M�ximo'               ,'Peso M�ximo'                                            ,''    ,False,'3','','','0');
// 30.05.19 - para uso no MDFe
  Inst.AddField('Transportadores','tran_rntrc'             ,'C',08 ,0,50 ,True ,'RNTRC'                      ,'Registro na ANTT'                                            ,''    ,False,'1','','','0');
  Inst.AddField('Transportadores','tran_renavan'           ,'C',11 ,0,50 ,True ,'Renavan'                    ,'Numero do renavan do ve�culo'                                            ,''    ,False,'1','','','0');
  Inst.AddField('Transportadores','tran_volume'            ,'N',03 ,0,50 ,True ,'Volume'                     ,'Capacidade em metros c�bicos'                                            ,''    ,False,'3','','','0');


  Inst.AddTable('Regioes');
  Inst.AddField('Regioes','Regi_Codigo','C',3,0,50,False,'C�digo','C�digo da regi�o','000',False,'3','','','2');
  Inst.AddField('Regioes','Regi_Descricao','C',40,0,250,False,'Descri��o Regi�o','Descri��o da regi�o','',True,'1','','','2');

  Inst.AddTable('Plano');
  Inst.AddField('Plano','plan_Classificacao','C',20,0,200,False,'Classifica��o','C�digo de classifica��o da conta','',False,'1','','','2');
  Inst.AddField('Plano','plan_Descricao','C',50,0,250,False,'Descri��o Da Conta','Descri��o da conta gerencial','',True,'1','','','1');
  Inst.AddField('Plano','plan_Conta','N',08,0,60,False,'Conta','C�digo reduzido da conta','',False,'3','','','2');
//  Inst.AddField('Plano','plan_Tipo','C',02,0,30,False,'Tipo','Tipo da conta gerencial','',False,'1','','','0');
  Inst.AddField('Plano','plan_Tipo','C',01,0,30,False,'Tipo','Tipo da conta gerencial','',False,'1','','','0');
  Inst.AddField('Plano','Plan_AutPgto','C',1,0,20,True,'Exige Aut. Pgto','Conta exige autoriza��o de pagamento para baixa','',True,'1','','','0');
  Inst.AddField('Plano','plan_CatEntidade','C',1,0,20,True,'Cat Entidade','Categoria da entidade','',True,'','','','0');
  Inst.AddField('Plano','plan_CodigoBanco','C',3,0,30,True,'C�digo Banco','C�digo do banco','000',True,'1','','','0');
  Inst.AddField('Plano','plan_Agencia','C',10,0,100,True,'Ag�ncia','C�digo da ag�ncia do banco','',True,'1','','','0');
  Inst.AddField('Plano','plan_ContaCorrente','C',30,0,100,True,'Conta Corrente','N�mero da conta corrente no banco','',True,'1','','','0');
  Inst.AddField('Plano','plan_FluxoCaixa','C',1,0,20,True,'Fluxo Caixa','Imprime cheques','',True,'1','','','0');
  Inst.AddField('Plano','plan_Moed_Codigo','C',3,0,25,True,'Moeda','C�digo da moeda','000',True,'1','','','0');
  Inst.AddField('Plano','plan_ContaJuros','N',08,0,60,True,'Conta Juros','C�digo reduzido da conta para juros','',True,'3','','','0');
  Inst.AddField('Plano','plan_CarenciaJuros','N',08,0,60,True,'Car�ncia Juros','N�mero de dias para car�ncia na cobran�a de juros','',True,'3','','','0');
  Inst.AddField('Plano','plan_TaxaJuros','N',10,5,70,True,'Taxa Juros','Taxa mensal de juros',f_aliq,True,'3','','','0');
  Inst.AddField('Plano','plan_TipoJuros','C',1,0,20,True,'Tipo Juros','Forma de aplica��o da taxa de juros','',True,'1','','','0');
  Inst.AddField('Plano','plan_ContaDescontos','N',08,0,60,True,'Conta Descontos','C�digo reduzido da conta para descontos','',True,'3','','','0');
  Inst.AddField('Plano','plan_PercDescontos','N',10,5,70,True,'Percentual Descontos','Percentual de descontos para pagamentos at� o vencimento',f_aliq,True,'3','','','0');
  Inst.AddField('Plano','plan_ContaMulta','N',08,0,60,True,'Conta Multa','C�digo reduzido da conta para multas','',True,'3','','','0');
  Inst.AddField('Plano','plan_CarenciaMulta','N',08,0,60,True,'Car�ncia Multa','N�mero de dias para car�ncia na cobran�a de multas','',True,'3','','','0');
  Inst.AddField('Plano','plan_PercMulta','N',10,5,70,True,'Percentual Multa','Percentual de multa para pagamento em atraso',f_aliq,True,'3','','','0');
  Inst.AddField('Plano','plan_ContaMora','N',08,0,60,True,'Conta Mora','C�digo reduzido da conta para moras','',True,'3','','','0');
  Inst.AddField('Plano','plan_CarenciaMora','N',08,0,60,True,'Car�ncia Mora','N�mero de dias para car�ncia na cobran�a de moras','',True,'3','','','0');
  Inst.AddField('Plano','plan_ValorMora','N',12,2,70,True,'Valor Di�rio Mora','Valor di�rio de mora para pagamento em atraso',f_aliq,True,'3','','','0');
  Inst.AddField('Plano','plan_ContaAcrescimos','N',08,0,60,True,'Conta Acr�scimos','C�digo reduzido da conta para outros acr�scimos','',True,'3','','','0');
  Inst.AddField('Plano','plan_ContaAbatimentos','N',08,0,60,True,'Conta Abatimentos','C�digo reduzido da conta para outros abatimentos','',True,'3','','','0');
  Inst.AddField('Plano','plan_Impr_Cheque','C',3,0,30,True,'Impresso Cheque','C�digo do impresso do cheque','',True,'','','','');
  Inst.AddField('Plano','plan_AtribAcess','C',01,0,20,True,'Atribuir Acess�rios','Forma de atribui��o dos valores acess�rios','',True,'','','','');
  Inst.AddField('Plano','plan_MvtoCaixa','C',01,0,20,True,'Movimento De Caixa','Movimento por lan�amento no caixa','',True,'','','','');
  Inst.AddField('Plano','plan_CodHist','N',03,0,40,True,'C�digo Hist�rico','C�digo do hist�rico padr�o para a conta','',True,'','','','');
  Inst.AddField('Plano','plan_CodHistBxPF','N',03,0,40,True,'C�digo Hist. Baixa','C�digo do hist�rico padr�o para as baixas de pend�ncias da conta','',True,'','','','');
  Inst.AddField('Plano','plan_MovFluxo','C',01,0,20,True,'Mvto Fluxo Caixa','Movimento para previs�o de fluxo de caixa','',True,'','','','');
  Inst.AddField('Plano','plan_BxParcial','C',01,0,20,True,'Permite Baixa Parcial','Permite baixas parciais nos documentos de pend�ncias financeiras','',True,'','','','');
  Inst.AddField('Plano','plan_CarenciaProtesto','N',08,0,60,True,'Car�ncia Protesto','N�mero de dias ap�s vcto para protesto','',True,'3','','','0');
  Inst.AddField('Plano','plan_PzBloqClientes','N',08,0,60,True,'Prazo Bloqueio Clientes','N�mero de dias ap�s vcto para bloqueio dos clientes','',True,'3','','','0');
  Inst.AddField('Plano','plan_MotivoBloqueio','N',08,0,60,True,'Motivo Bloqueio Clientes','C�digo do motivo para marcar bloqueio de clientes','',True,'3','','','0');
  Inst.AddField('Plano','plan_MotivoDesbloqueio','N',08,0,60,True,'Motivo Desbloqueio Clientes','C�digo do motivo para desmarcar bloqueios de clientes','',True,'3','','','0');
  Inst.AddField('Plano','plan_SitDesbloqClientes','C',01,0,20,True,'Situa��o Desbloqueio Clientes','Situa��o do cliente quendo desbloqueado','',True,'1','','','0');
// 05.02.05 na toke
  Inst.AddField('Plano','plan_ctaexporta01','N',08,0,60,True,'Conta exporta��o 01','C�digo reduzido da conta para exporta��o','',True,'3','','','0');
  Inst.AddField('Plano','plan_ctaexporta02','N',08,0,60,True,'Conta exporta��o 02','C�digo reduzido da conta para exporta��o','',True,'3','','','0');
  Inst.AddField('Plano','plan_ctaexporta03','N',08,0,60,True,'Conta exporta��o 03','C�digo reduzido da conta para exporta��o','',True,'3','','','0');
  Inst.AddField('Plano','plan_ctaexporta04','N',08,0,60,True,'Conta exporta��o 04','C�digo reduzido da conta para exporta��o','',True,'3','','','0');
  Inst.AddField('Plano','plan_ctaexporta05','N',08,0,60,True,'Conta exporta��o 05','C�digo reduzido da conta para exporta��o','',True,'3','','','0');
  Inst.AddField('Plano','plan_ctaexporta06','N',08,0,60,True,'Conta exporta��o 06','C�digo reduzido da conta para exporta��o','',True,'3','','','0');
// 01.12.06 - contas exporta��o para 'exporta��o'
  Inst.AddField('Plano','plan_unidexporta01','C',03,0,30,True,'Unidade exporta��o 01','C�digo da unidade para exporta��o','',True,'1','','','0');
  Inst.AddField('Plano','plan_unidexporta02','C',03,0,30,True,'Unidade exporta��o 02','C�digo da unidade para exporta��o','',True,'1','','','0');
  Inst.AddField('Plano','plan_unidexporta03','C',03,0,30,True,'Unidade exporta��o 03','C�digo da unidade para exporta��o','',True,'1','','','0');
  Inst.AddField('Plano','plan_unidexporta04','C',03,0,30,True,'Unidade exporta��o 04','C�digo da unidade para exporta��o','',True,'1','','','0');
  Inst.AddField('Plano','plan_unidexporta05','C',03,0,30,True,'Unidade exporta��o 05','C�digo da unidade para exporta��o','',True,'1','','','0');
  Inst.AddField('Plano','plan_unidexporta06','C',03,0,30,True,'Unidade exporta��o 06','C�digo da unidade para exporta��o','',True,'1','','','0');
// 28.02.08
  Inst.AddField('Plano','plan_CtaChequesComp','N',08,0,60,True,'Conta Ch.a Compensar','Conta Cheques a Compensar','',True,'3','','','0');
// 19.03.08 - carli
  Inst.AddField('Plano','plan_Imprimeextrato','C',01,0,40,True,'Imprime extrato'     ,'Imprime extrato','',True,'1','','','0');
//11.08.08
  Inst.AddField('Plano','plan_Tipocad'       ,'C',01,0,40,True,'Cadastro'     ,'Qual cadastro solicitiar digita��o','',True,'1','','','0');
//05.10.09 - Abra - Josemar
  Inst.AddField('Plano','plan_TipoAtiv'      ,'C',01,0,40,True,'Tipo Atividade'     ,'Tipo de Atividade','',True,'1','','','0');
//27.05.10 - Novicarnes - alem do itau agora BB
  Inst.AddField('Plano','plan_carteira'      ,'C',03,0,40,True,'Carteira'     ,'Carteira para emiss�o de boletos','',True,'1','','','0');
//  Inst.AddField('Plano','plan_convenio'      ,'C',07,0,40,True,'Conv�nio'     ,'Numero do conv�nio para emiss�o de boletos','',True,'1','','','0');
// 04.10.10 - Clessi - CEF 'maior'
  Inst.AddField('Plano','plan_convenio'       ,'C',20,0,40,True,'Conv�nio'     ,'Numero do conv�nio para emiss�o de boletos','',True,'1','','','0');
// 26.06.19 - Novicarnes - ketlen
  Inst.AddField('Plano','plan_cstpiscofins'   ,'C',02,0,40,True,'CST PIS/COF'     ,'CST para pis e cofins','',True,'1','','','0');
// 15.07.20
  Inst.AddField('Plano','plan_ctaapropriar01','N',08,0,60,True,'Conta material a apropriar 01','C�digo reduzido da conta de material a apropriar','',True,'3','','','0');
  Inst.AddField('Plano','plan_ctaapropriar02','N',08,0,60,True,'Conta material a apropriar 02','C�digo reduzido da conta de material a apropriar','',True,'3','','','0');
// 03.08.20
  Inst.AddField('Plano','Plan_Unid_codigo','C',   3,0, 35,True,'Unidade','Unidade da conta','',False,'','','','');


// 06.08.08 - Setores para uso nas RNC
  Inst.AddTable('Setores');
  Inst.AddField('Setores','Seto_Codigo','C',4,0,50,False,'C�digo','C�digo do setor','0000',False,'1','','','2');
  Inst.AddField('Setores','Seto_Descricao','C',50,0,250,True,'Descri��o','Descri��o do setor','',True,'1','','','2');
// 07.10.08
  Inst.AddField('Setores','Seto_Usua_Codigo'       ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio respons�vel'                        ,''    ,False,'3','','','0');
//  Inst.AddField('Setores','Seto_email','C',80,0,150,True,'Email','Email respons�vel setor','',True,'3','','','0');

// 06.07.09
  Inst.AddTable('TabComissao');
  Inst.AddField('TabComissao','Tabc_Status'                 ,'C',1  ,0,50  ,True ,'Status'       ,'Status'         ,'',False,'','','','0');
  Inst.AddField('TabComissao','Tabc_Seq'                    ,'C',4  ,0,50  ,True ,'Sequencial'   ,'Sequencial'     ,'',False,'','','','2');
  Inst.AddField('TabComissao','Tabc_Inicio'                 ,'N',11 ,3,60  ,True ,'Inicio Faixa' ,'Inicio Faixa'   ,'',False,'','','','0');
  Inst.AddField('TabComissao','Tabc_Fim'                    ,'N',11 ,3,60  ,True ,'T�rmino Faixa','T�rmino Faixa'   ,'',False,'','','','0');
  Inst.AddField('TabComissao','Tabc_Faixa'                  ,'N',11 ,3,50  ,True ,'Faixa'        ,'% da faixa'   ,'',False,'','','','0');
  Inst.AddField('TabComissao','Tabc_Usua_Codigo'            ,'N',3  ,0,50  ,True ,'Usu�rio'      ,'Usu�rio que informou'   ,'',False,'','','','0');
  Inst.AddField('TabComissao','Tabc_Dtlancto'               ,'D',8  ,0,50  ,True ,'Data'         ,'Data lan�amento'   ,'',False,'','','','0');
  Inst.AddField('TabComissao','Tabc_Repr_TipoRepr'          ,'C',1  ,0,50  ,True ,'Tipo'         ,'Tipo de Representante'   ,'',False,'','','','0');
  Inst.AddField('TabComissao','Tabc_Reflexo'                ,'N',11 ,3,50  ,True ,'Reflexo'        ,'% Reflexo sobre comiss�es'   ,'',False,'','','','0');

// 15.10.09 - colaboradores ( funcionarios ) - inicio para despesas dos ve�culos
  Inst.AddTable('Colaboradores');
  Inst.AddField('Colaboradores','Cola_Codigo','C',4,0,50,False,'C�digo','C�digo do colaborador','0000',False,'1','','','2');
  Inst.AddField('Colaboradores','Cola_Descricao','C',50,0,250,True,'Nome','Nome do colaborador','',True,'1','','','2');
  Inst.AddField('Colaboradores','Cola_Usua_Codigo'       ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio respons�vel'                        ,''    ,False,'3','','','0');
  Inst.AddField('Colaboradores','Cola_Seto_Codigo'  ,'C',4   ,0,50,True,'Setor','C�digo do setor','0000',False,'1','','','0');
// 30.05.19 - mdfe
  Inst.AddField('Colaboradores','Cola_cpf',          'C',11,0,090,True,'CPF','CPF do colaborador','',True,'1','','','0');


// 19.05.11 - ingredientes e tabela nutricional
  Inst.AddTable('Nutricionais');
  Inst.AddField('Nutricionais','Nutr_Codigo','N',8,0,80,False,'C�digo','C�digo da tabela nutricional','#######0',False,'3','','','');
  Inst.AddField('Nutricionais','Nutr_NomeBalanca','C',30,0,120,True,'Balan�a','Nome/modelo da balan�a para identificar a balan�a a ser usada','#######0',False,'3','','','');
  Inst.AddField('Nutricionais','Nutr_PorcaoCaseira','C',30,0,200,True,'Por��o Caseira','Descri��o da por��o caseira do produto','',True,'','','','');
  Inst.AddField('Nutricionais','Nutr_Qtde'      ,'N',10,3,80,True,'Unidades'  ,'Quantidade de unidades do produto','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_QtdePorcao','N',10,3,80,True,'Quantidade','Quantidade do produto na por��o caseira','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_UnPorcao','C',5,0,50,True,'Unid','Unidade da por��o caseira do produto','',True,'','','','');
  Inst.AddField('Nutricionais','Nutr_Balanca','C',1,0,25,True,'Bal','Indica se a informa��o nutricional ser� enviada para balan�a','',True,'','','','');
  Inst.AddField('Nutricionais','Nutr_Fator','N',10,3,80,True,'Fator','Fator de multiplica��o para industrializa��o','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_Calorias','N',10,3,80,True,'Calorias','Quantidade de calorias (Kcal) de uma por��o do produto','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_Carboidratos','N',10,3,80,True,'Carboidratos','Quantidade de carbohidratos (g) de uma por��o do produto','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_Proteinas','N',10,3,80,True,'Proteinas','Quantidade de prote�nas (g) de uma por��o do produto','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_GordTotais','N',10,3,80,True,'Gorduras Totais','Quantidade de gorduras totais (g) de uma por��o do produto','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_GordSaturadas','N',10,3,80,True,'Gord. Saturadas','Quantidade de gorduras saturadas (g) de uma por��o do produto','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_Fibras','N',10,3,80,True,'Fibras Aliment.','Quantidade de fibras alimentares (g) de uma por��o do produto','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_Colesterol','N',10,3,80,True,'Colesterol','Quantidade de colesterol (mg) de uma por��o do produto','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_Calcio','N',10,3,80,True,'C�lcio','Quantidade de c�lcio (mg) de uma por��o do produto','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_Ferro','N',10,3,80,True,'Ferro','Quantidade de ferro (mg) de uma por��o do produto','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_Sodio'   ,'N',10,3,80,True,'S�dio','Quantidade de s�dio (mg) de uma por��o do produto','####0.000',True,'3','','','');
  Inst.AddField('Nutricionais','Nutr_Validade','N',05,0,80,True,'Validade'  ,'Validade em dias do produto','####0',True,'3','','','');

  Inst.AddTable('Ingredientes');
  Inst.AddField('Ingredientes','Ingr_Codigo','N',8,0,80,False,'C�digo','C�digo da tabela de ingredientes','#######0',False,'3','','','');
  Inst.AddField('Ingredientes','Ingr_Linha1','C',100,0,500,True,'Linha1','Descri��o dos ingredientes do produto','',True,'1','','','');
  Inst.AddField('Ingredientes','Ingr_Linha2','C',100,0,500,True,'Linha2','Descri��o dos ingredientes do produto','',True,'1','','','');
  Inst.AddField('Ingredientes','Ingr_Linha3','C',100,0,500,True,'Linha3','Descri��o dos ingredientes do produto','',True,'1','','','');
  Inst.AddField('Ingredientes','Ingr_Linha4','C',100,0,500,True,'Linha4','Descri��o dos ingredientes do produto','',True,'1','','','');
  Inst.AddField('Ingredientes','Ingr_Linha5','C',100,0,500,True,'Linha5','Descri��o dos ingredientes do produto','',True,'1','','','');
  Inst.AddField('Ingredientes','Ingr_Linha6','C',100,0,500,True,'Linha6','Descri��o dos ingredientes do produto','',True,'1','','','');
  Inst.AddField('Ingredientes','Ingr_Linha7','C',100,0,500,True,'Linha7','Descri��o dos ingredientes do produto','',True,'1','','','');
  Inst.AddField('Ingredientes','Ingr_Linha8','C',100,0,500,True,'Linha8','Descri��o dos ingredientes do produto','',True,'1','','','');
  Inst.AddField('Ingredientes','Ingr_Linha9','C',100,0,500,True,'Linha9','Descri��o dos ingredientes do produto','',True,'1','','','');
  Inst.AddField('Ingredientes','Ingr_Linha10','C',100,0,500,True,'Linha10','Descri��o dos ingredientes do produto','',True,'1','','','');

  Inst.AddTable('Conservacao');
  Inst.AddField('Conservacao','Cons_Codigo','N',6,0,80,False,'C�digo','C�digo da tabela de conserva��o','#####0',False,'3','','','');
  Inst.AddField('Conservacao','Cons_Linha1','C',100,0,500,True,'Observa��o','Descri��o de informa��o de conserva��o do produto','',True,'1','','','');
  Inst.AddField('Conservacao','Cons_Linha2','C',100,0,500,True,'Linha2','Descri��o de informa��o de conserva��o do produto','',True,'1','','','');
  Inst.AddField('Conservacao','Cons_Linha3','C',100,0,500,True,'Linha3','Descri��o de informa��o de conserva��o do produto','',True,'1','','','');
  Inst.AddField('Conservacao','Cons_Linha4','C',100,0,500,True,'Linha4','Descri��o de informa��o de conserva��o do produto','',True,'1','','','');
  Inst.AddField('Conservacao','Cons_Linha5','C',100,0,500,True,'Linha4','Descri��o de informa��o de conserva��o do produto','',True,'1','','','');
  Inst.AddField('Conservacao','Cons_Linha6','C',100,0,500,True,'Linha4','Descri��o de informa��o de conserva��o do produto','',True,'1','','','');

// 06.09.11 - 'gerador de DRE' com contas de despesas e produtos (vendas)
  Inst.AddTable('RelGerencial');
  Inst.AddField('RelGerencial','Relg_Unid_codigo','C',   3,0, 35,True,'Unidade','Unidade','',False,'','','','');
  Inst.AddField('RelGerencial','Relg_Status'     ,'C',   1,0, 40,True,'Status','Status do lan�amento','',False,'','','','');
  Inst.AddField('RelGerencial','Relg_codigo'     ,'C',   5,0, 40,True,'Codigo','Codigo do item a ser impresso','',False,'','','','');
  Inst.AddField('RelGerencial','Relg_Ordem'      ,'C',   4,0, 40,True,'Ordem','Ordem do item a ser impresso','',False,'','','','');
  Inst.AddField('RelGerencial','Relg_Usua_codigo','N',   4,0, 40,True,'Usu�rio','Usu�rio','',False,'','','','');
  Inst.AddField('RelGerencial','Relg_NomeRel'    ,'C',  30,0,250,True,'Relat�rio','Nome do Relat�rio','',False,'','','','');
  Inst.AddField('RelGerencial','Relg_TituloRel'  ,'C', 100,0,300,True,'T�tulo','T�tulo do Relat�rio','',False,'','','','');
  Inst.AddField('RelGerencial','Relg_TituloLin'  ,'C', 100,0,300,True,'Tit.Linha','T�tulo da Linha do Relat�rio','',False,'','','','');
  Inst.AddField('RelGerencial','Relg_Sinal'      ,'C',   1,0, 40,True,'Sinal(+/-)','Sinal do item a ser impressso','',False,'','','','');
  Inst.AddField('RelGerencial','Relg_Tipo'       ,'C',   1,0, 40,True,'Tipo do Item','C - Conta de Despesa  P - Codigo de Produto  T - Tipo de Movimento','',False,'','','','');
  Inst.AddField('RelGerencial','Relg_Tipos'      ,'C',2000,0, 40,True,'Codigos do Item','Codigos de contas, produtos ou tipos de movimento a serem somados','',False,'','','','');
  Inst.AddField('RelGerencial','Relg_ES'         ,'C',   1,0, 40,True,'E/S','E - soma das entradas/compras   S - soma das saidas/vendas','',False,'','','','');


// 13.09.13 - M�quinas / Equipamentos / Ve�culos da Empresa
  Inst.AddTable('Equipamentos');
  Inst.AddField('Equipamentos','Equi_Codigo'          ,'C',004,  0, 50,False,'C�digo','C�digo do equipamento/ve�culo','0000',False,'1','','','2');
  Inst.AddField('Equipamentos','Equi_Descricao'       ,'C',100,  0,250,True ,'Descri��o','Descri��o do equipamento/ve�culo','',True,'1','','','2');
  Inst.AddField('Equipamentos','Equi_Numserie'        ,'C',050,  0,150,True ,'N�mero de S�rie','N�mero de S�rie do equipamento/ve�culo','',True,'1','','','2');
  Inst.AddField('Equipamentos','Equi_Oleomotor'       ,'N',012,  0,080,True ,'Troca de �leo Motor','Troca de �leo Motor','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_Oleohidra'       ,'N',012,  0,080,True ,'Troca de �leo Hidr�ulico','Troca de �leo Hidr�ulico','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_Oleodiesel'      ,'N',012,  0,080,True ,'Troca de �leo Diesel','Troca de �leo Diesel','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_Oleotransmissao' ,'N',012,  0,080,True ,'Troca de �leo Transmiss�o','Troca de �leo Transmiss�o','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_Filtromotor'     ,'N',012,  0,080,True ,'Troca de filtro Motor','Troca de filtro Motor','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_Filtrohidra'     ,'N',012,  0,080,True ,'Troca de filtro Hidr�ulico','Troca de filtro Hidr�ulico','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_Filtrodiesel'    ,'N',012,  0,080,True ,'Troca de filtro Diesel','Troca de filtro Diesel','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_Filtroar'        ,'N',012,  0,080,True ,'Troca de filtro Ar','Troca de filtro Ar','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_OleoGiro'        ,'N',012,  0,080,True ,'Troca de �leo motor giro','Troca de �leo motor de giro','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_Horimetro'       ,'N',012,  0,080,True ,'Hor�metro','Hor�metro','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_Odometro'        ,'N',012,  0,080,True ,'Hor�metro/Od�metro','Hor�metro/Od�metro','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_DataHorimetro'   ,'D',008,  0,080,True ,'Data Hor�metro','Data Hor�metro','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_Usua_Codigo'     ,'N',003,  0, 50,True ,'Usu�rio'                   ,'Usu�rio respons�vel'                        ,''    ,False,'3','','','0');
// 06.10.2021 - A2z
  Inst.AddField('Equipamentos','Equi_ProxTroca'       ,'N',010,  0,080,True ,'Horas Troca','Horas Troca','',True,'3','','','0');

// 25.03.2021 - Olstri
  Inst.AddField('Equipamentos','Equi_tipo_codigo'     ,'N',007,  0,30 ,True ,'Cliente'                   ,'C�digo do cliente'                            ,''    ,False,'2','','','2');
  Inst.AddField('Equipamentos','Equi_Numsensor'       ,'C',020,  0,150,True ,'N�mero do Sensor','N�mero de Sensor do equipamento','',True,'1','','','2');
  Inst.AddField('Equipamentos','Equi_Numdisplay'      ,'C',020,  0,150,True ,'N�mero do Display','N�mero de Display do equipamento','',True,'1','','','2');
  Inst.AddField('Equipamentos','Equi_Fator01'         ,'N',012,  5,080,True ,'Fact 01','Fact 01','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_Flow'            ,'N',012,  3,080,True ,'Flow Prob Prof','Flow Prob Prof','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_Tipo'            ,'C',001,  0,050,True ,'P/C','P - Plataforma   C - Caminh�o','',True,'1','','','2');
  Inst.AddField('Equipamentos','Equi_placa'           ,'C',008,  0,050,True ,'Placa','Placa do ve�culo','',True,'1','','','2');
  Inst.AddField('Equipamentos','Equi_Motorista'       ,'C',050,  0,050,True ,'MoPlaca','Placa do ve�culo','',True,'1','','','2');
  Inst.AddField('Equipamentos','Equi_VazaoMedia'      ,'N',012,  0,080,True ,'Vaz�o M�dia','Vaz�o M�dia de calibra��o','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_TempMedia'       ,'N',005,  0,080,True ,'Temp. M�dia','Temperatura M�dia de calibra��o','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_PressaoMax'      ,'N',005,  0,080,True ,'Press�o Max','Press�o m�xima de trabalho','',True,'3','','','0');
  Inst.AddField('Equipamentos','Equi_GrauProtSensor'  ,'C',010,  0,050,True ,'Grau Sensor','Grau de prote��o do sensor','',True,'1','','','2');
  Inst.AddField('Equipamentos','Equi_GrauProtConver'  ,'C',010,  0,050,True ,'Grau Conv.','Grau de prote��o do conversor','',True,'1','','','2');
  Inst.AddField('Equipamentos','Equi_Diamsensor'      ,'N',005,  0,080,True ,'Di�metro Sensor','Di�metro Sensor','',True,'3','','','0');


// 25.04.19 - Novicarnes - Isonel
  Inst.AddTable('Baias');
  Inst.AddField('Baias','Baia_codigo'           ,'C', 10,0,30   ,True,'Codigo'                     ,'Codigo Baia'                                 ,''    ,False,'1','','','1');
  Inst.AddField('Baias','Baia_descricao'        ,'C', 30,0,100  ,True,'Descri��o'                  ,'Descri��o Baia'                                 ,''    ,False,'1','','','2');
  Inst.AddField('Baias','Baia_cabecas'          ,'N', 05,0,070  ,True,'Cabe�as'                    ,'Cabe�as por Baia'                                 ,''    ,False,'3','','','0');
  Inst.AddField('Baias','Baia_sexo'             ,'C', 01,0,070  ,True,'Sexo'                       ,'Sexo por Baia'                                 ,''    ,False,'1','','','0');
  Inst.AddField('Baias','Baia_ganhopeso'        ,'N', 06,2,070  ,True,'Ganho Peso'                 ,'Percentual de ganho de peso ao dia'                                 ,''    ,False,'3','','','0');

// 25.04.19 - Novicarnes - Ketlen - valores mensais para sped contribuicoes
//            ref. aproveitamento de creditos
  Inst.AddTable('Sped');
  Inst.AddField('Sped','Sped_TipoSped'           ,'C', 30,0,50   ,True,'Tipo'                     ,'Qual Sped'                                 ,''    ,False,'1','','','1');
  Inst.AddField('Sped','Sped_Registro'           ,'C', 10,0,50   ,True,'Registro'                 ,'Codigo do registro no Sped'                                 ,''    ,False,'1','','','1');
  Inst.AddField('Sped','Sped_MesAno'             ,'C', 06,0,60   ,True,'Mes/Ano'            ,'Mes/ano envio sped'                                 ,''    ,False,'1','','','1');
  Inst.AddField('Sped','Sped_Per_Apu_Cred'       ,'C', 06,0,60   ,True,'Per.Ap.Cr�dito'           ,'Per.Ap.Cr�dito'                                 ,''    ,False,'1','','','1');
  Inst.AddField('Sped','Sped_Orig_Cred'          ,'N', 03,0,60   ,True,'Orig.Cr�dito'             ,'Orig.Cr�dito'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_Cnpj_Suc'           ,'C', 14,0,70   ,True,'CNPJ Suc.'             ,'CNPJ Suc.'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_Cod_Cre'            ,'N', 04,0,70   ,True,'Cod.Cr�dito'             ,'Cod.Cr�dito'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_VL_CRED_APU'         ,'N', 14,2,80   ,True,'Vlr.Cred.apu.'             ,'Vlr.Cred.apu.'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_VL_CRED_EXT_APU'     ,'N', 14,2,80   ,True,'Vlr.Cred.Ext.apu.'         ,'Vlr.Cred.Ext.Apu.'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_VL_TOT_CRED_APU'     ,'N', 14,2,80   ,True,'Vlr.Tot.Cred.Apu.'         ,'Vlr.Tot.Cred.Apu.'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_VL_CRED_DESC_PA_ANT' ,'N', 14,2,80   ,True,'Vlr.Cred.Desc.Pa.Ant.'         ,'Vlr.Cred.Desc.Pa.Ant.'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_VL_CRED_PER_PA_ANT'  ,'N', 14,2,80   ,True,'Vlr.Cred.Desc.Pa.Ant.'         ,'Vlr.Cred.Desc.Pa.Ant.'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_VL_CRED_DCOMP_PA_ANT','N', 14,2,80   ,True,'Vlr.Cred.DComp.Pa.Ant.'         ,'Vlr.Cred.DComp.Pa.Ant.'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_SD_CRED_DISP_EFD'    ,'N', 14,2,80   ,True,'Vlr.Cred.Disp.EFD'         ,'Vlr.Cred.Disp.EFD'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_VL_CRED_DESC_EFD'    ,'N', 14,2,80   ,True,'Vlr.Cred.Desc.EFD'         ,'Vlr.Cred.Desc.EFD'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_VL_CRED_PER_EFD'     ,'N', 14,2,80   ,True,'Vlr.Cred.Per.EFD'         ,'Vlr.Cred.Per.EFD'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_VL_CRED_DCOMP_EFD'   ,'N', 14,2,80   ,True,'Vlr.Cred.DComp.EFD'         ,'Vlr.Cred.DComp.EFD'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_VL_CRED_TRANS',       'N', 14,2,80   ,True,'Vlr.Cred.Cred.Trans'         ,'Vlr.Cred.Cred.Trans'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_VL_CRED_OUT'         ,'N', 14,2,80   ,True,'Vlr.Cred.Cred.Out'         ,'Vlr.Cred.Cred.Out'                                 ,''    ,False,'3','','','1');
  Inst.AddField('Sped','Sped_SLD_CRED_FIM'        ,'N', 14,2,80   ,True,'Vlr.Cred.Cred.Fim'         ,'Vlr.Cred.Cred.Fim'                                 ,''    ,False,'3','','','1');

// 16.06.19
  Inst.AddTable('replicacao');
  Inst.AddField('replicacao','Repl_tabela'       ,'C', 30,0,50   ,True,'Tabela'              ,''                                 ,''    ,False,'1','','','1');
  Inst.AddField('replicacao','Repl_sql'          ,'M', 10,0,50   ,True,'SQL'                 ,''                                 ,''    ,False,'1','','','1');
  Inst.AddField('replicacao','Repl_data'         ,'D', 10,0,50   ,True,'Data'                 ,''                                 ,''    ,False,'1','','','1');
  Inst.AddField('replicacao','Repl_hora'         ,'C', 30,0,50   ,True,'Hora'                 ,''                                 ,''    ,False,'1','','','1');


end;

procedure TFInstsac.CriaTabelasSistema;
/////////////////////////////////////////
begin

  Inst.AddTable('Movfin');   // caixa e bancos
  Inst.AddField('Movfin','Movf_Transacao'   ,'C',12,0,70,False,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('Movfin','Movf_Operacao'    ,'C',16,0,70,False,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('Movfin','Movf_Status'      ,'C',1,0,20,False,'Status','Status do lan�amento','',False,'1','','','0');
  Inst.AddField('Movfin','Movf_Unid_codigo' ,'C',3 ,0,30 ,False,'Unidade'                   ,'C�digo da unidade'                            ,''    ,False,'2','','','2');
  Inst.AddField('Movfin','Movf_DataLcto','D',0,0,60,False,'Data Lcto','Data de lan�amento','',True,'1','','','0');
  Inst.AddField('Movfin','Movf_DataMvto','D',0,0,60,False,'Data Mvto','Data de movimento','',True,'1','','','0');
  Inst.AddField('Movfin','Movf_DataCont','D',0,0,60,True ,'Data Cont','Data cont�bil'     ,'',True,'1','','','0');
  Inst.AddField('Movfin','Movf_DataPrevista','D',0,0,60,False,'Data Prevista','Data prevista para movimento no banco','',True,'1','','','0');
  Inst.AddField('Movfin','Movf_DataExtrato','D',0,0,60,True,'Data Extrato','Data de efetiva��o do movimento no banco','',True,'1','','','0');
  Inst.AddField('Movfin','Movf_plan_Conta','N',08,0,60,False,'Conta','C�digo reduzido da conta','0000',False,'3','','','0');
  Inst.AddField('Movfin','Movf_Hist_Codigo','N',3,0,50,True,'Hist�rico','C�digo do hist�rico','000',False,'1','','','0');
  Inst.AddField('Movfin','Movf_Complemento','C',100,0,250,True,'Complemento','Complemento do hist�rico','',False,'1','','','0');
  Inst.AddField('Movfin','Movf_NumeroDcto','C',20,0,100,True,'N�mero Dcto','N�mero do documento','',False,'1','','','0');
  Inst.AddField('Movfin','Movf_Codb_Codigo','C',3,0,30,True,'Dcto Bco','C�digo do documento banc�rio','000',False,'1','','','0');
  Inst.AddField('Movfin','Movf_ES','C',1,0,20,False,'E/S','Lan�amento de entrada ou sa�da','',False,'1','','','0');
  Inst.AddField('Movfin','Movf_Favorecido','C',100,0,250,True,'Favorecido','Favorecido do cheque','',False,'1','','','0');
  Inst.AddField('Movfin','Movf_NumeroCheque','N',08,0,70,True,'N�mero Cheque','N�mero do cheque emitido','',False,'1','','','0');
  Inst.AddField('Movfin','Movf_ValorGer','N',12,2,80,True,'Valor Ger','Valor gerencial do lan�amento',f_cr,True,'3','','','0');
  Inst.AddField('Movfin','Movf_ValorBco','N',12,2,80,True,'Valor Bco','Valor do banco do lan�amento',f_cr,True,'3','','','0');
  Inst.AddField('Movfin','Movf_TransConc','C',12,0,70,True,'Transa��o Concilia��o','N�mero de concilia��o','',False,'3','','','0');
  Inst.AddField('Movfin','Movf_SeqLcto','N',5,0,20,True,'Seq. Lcto','Sequencial no lan�amento do extrato','',False,'1','','','0');
  Inst.AddField('Movfin','Movf_plan_ContaRD','N',08,0,60,True ,'Conta','C�digo reduzido conta receita/despesas','0000',False,'3','','','0');
// 21.02.05
  Inst.AddField('Movfin','Movf_tipomov'     ,'C',2  ,0,30  ,True ,'Tipo'                      ,'Tipo do movimento'                           ,''    ,False,'2','','','2');
// 01.07.05 - 1.38
  Inst.AddField('Movfin','Movf_Usua_Codigo'       ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio respons�vel'                        ,''    ,False,'3','','','0');
// 08.05.06 - 1.44
  Inst.AddField('Movfin','Movf_Repr_Codigo'       ,'N',4 ,0,50   ,True ,'Cod.Repr.'                 ,'Nome representante'                         ,''    ,False,'3','','','0');
// 22.05.06
  Inst.AddField('Movfin','Movf_Tipo_Codigo'      ,'N',08 ,0,20   ,True ,'Cliente'       ,'C�digo cliente','',False,'1','','','0');
  Inst.AddField('Movfin','Movf_TipoCad'          ,'C',01 ,0,20   ,True ,'Tipo codigo'   ,'Tipo codigo','',False,'1','','','0');
// 19.09.16
  Inst.AddField('Movfin','Movf_TransacaoContax'  ,'C',16 ,0,120  ,True ,'Tr.Contax'   ,'Transa��o no Contax','',False,'1','','','0');
// 01.09.2022 - para poder identificar o meio de pagamento na venda a vista
// e futuramente caso usar TEF para pagamentos eletronicos...
  Inst.AddField('Movfin','Movf_Port_Codigo'      ,'C',3,0,50,True,'Portador','C�digo do portador','000',False,'1','','','0');


  Inst.AddTable('SaldosBco');
  Inst.AddField('SaldosBco','Sbco_plan_Conta','N',08,0,60,False,'Conta','C�digo reduzido da conta','',False,'3','','','0');
  Inst.AddField('SaldosBco','Sbco_Data','D',0,0,60,False,'Data Saldo','Data do saldo','',True,'1','','','0');
  Inst.AddField('SaldosBco','Sbco_Valor','N',12,2,80,True,'Valor Saldo','Valor do saldo',f_cr,True,'3','','','0');

  Inst.AddTable('Dotacoes');
  Inst.AddField('Dotacoes','Dota_Data','D',0,0,60,False,'Data Da Meta','Data da meta','',True,'1','','','0');
  Inst.AddField('Dotacoes','Dota_Unid_Codigo','C',3,0,30,False,'Unidade','C�digo da unidade','000',False,'1','','','0');
  Inst.AddField('Dotacoes','Dota_plan_Conta','N',08,0,60,False,'Conta','C�digo reduzido da conta','',False,'3','','','0');
  Inst.AddField('Dotacoes','Dota_Valor','N',12,2,80,True,'Valor Saldo','Valor do saldo',f_cr,True,'3','','','0');
// 18.03.10 - Abra
  Inst.AddField('Dotacoes','Dota_Seto_Codigo','C', 4,0,50,True ,'C�digo','C�digo do setor','0000',False,'1','','','0');
// 29.03.10 - Abra
  Inst.AddField('Dotacoes','Dota_VlrReal'    ,'N',12,3,50,True ,'Realizado','Valor realizado fixo no mes','',False,'3','','','0');


  Inst.AddTable('Cheques');
  Inst.AddField('Cheques','Cheq_Status'      ,'C', 1,0, 20,False,'Status do cheque','Status do cheque','',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_Emirec'      ,'C', 1,0, 20, true,'Cheque emitido/recebido','Cheque emitido/recebido','',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_bcoemitente' ,'C',20,0,200, true,'Nome do banco emitente' ,'Nome do banco emitente' ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_Cheque'      ,'C',12,0, 80, true,'Numero do cheque'       ,'Numero do cheque'       ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_Emitente'    ,'C',50,0,200, true,'Nome do emitente'       ,'Nome do emitente'       ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_Emissao'     ,'D',08,0, 60, true,'Emiss�o do cheque'      ,'Emiss�o do cheque'      ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_Predata'     ,'D',08,0, 60, true,'Cheque bom para'        ,'Cheque bom para'        ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_Valor'       ,'N',12,2, 80, true,'Valor do cheque'        ,'Valor do cheque'        ,'',True,'3','','','0');
  Inst.AddField('Cheques','Cheq_Datacont'    ,'D',0,0,60,True ,'Data Cont','Data cont�bil'     ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_Repr_codigo' ,'N',04,0, 40, true,'Codigo representante'   ,'Codigo representante'   ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_Repr_codigoant' ,'N',04,0, 40, true,'Codigo representante'   ,'Codigo representante'   ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_unid_codigo' ,'C',03,0, 40, true,'Codigo unidade'         ,'Codigo unidade'         ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_deposito'    ,'D',08,0, 60, true,'Dep�sito cheque'        ,'Dep�sito cheque'        ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_prorroga'    ,'D',08,0, 60, true,'Prorroga��o cheque'     ,'Prorroga��o cheque'     ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_Lancto'      ,'D',08,0, 60, true,'Data lan�amennto'       ,'Data lan�amento'        ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_Obs'         ,'C',60,0,220, true,'Observa��o'             ,'Observa��o'             ,'',True,'1','','','0');
// 01.02.06
  Inst.AddField('Cheques','Cheq_Devolvido'   ,'C',01,0, 30, true,'Devolvido'              ,'Devolvido'              ,'',True,'1','','','0');
// 10.03.06
  Inst.AddField('Cheques','Cheq_Tipo_codigo' ,'N',07,0, 40 , true,'Codigo emitente'   ,'Codigo emitente'   ,'',True,'1','','','0');
  Inst.AddField('Cheques','Cheq_tipocad'     ,'C',1  ,0,30  ,True,'Tipo emitente'             ,'Tipo do emitente'                            ,''    ,False,'2','','','0');
// 16.09.06
  Inst.AddField('Cheques','Cheq_Emit_Banco'  ,'C',003,0,060,True ,'Banco'  ,'C�digo do banco da conta','',False,'1','','','0');
  Inst.AddField('Cheques','Cheq_Emit_Agencia','N',010,0,080,True ,'Ag�ncia','Ag�ncia Banc�ria'       ,'',False,'3','','','1');
  Inst.AddField('Cheques','Cheq_Emit_Conta'  ,'N',015,0,100,True ,'Conta'  ,'Conta Corrente'         ,'',False,'3','','','1');
  Inst.AddField('Cheques','Cheq_Rc'          ,'C',001,0,030,True ,'Quem Pagou'         ,'Quem Pagou'                            ,''    ,False,'2','','','0');
// 01.02.07
  Inst.AddField('Cheques','Cheq_Cmc7'         ,'C',050,0,200,True ,'Leitura CMC7'    ,'Leitura CMC7'                            ,''    ,False,'1','','','0');
  Inst.AddField('Cheques','Cheq_plan_Contadep','N',008,0,060,True ,'Conta Dep�sito' ,'C�digo reduzido da conta','0000',False,'3','','','0');
  Inst.AddField('Cheques','Cheq_remessa'      ,'N',008,0,060,True ,'Remessa Cheques' ,'Remessa Cheques'         ,''    ,False,'3','','','0');
  Inst.AddField('Cheques','Cheq_dtremessa'    ,'D',008,0, 60,true ,'Data remessa'    ,'Data remessa'        ,'',True,'1','','','0');
// 20.02.08
  Inst.AddField('Cheques','Cheq_Valorrec'     ,'N',12,2, 80, true ,'Valor Recebido'      ,'Valor Recebido'        ,'',True,'3','','','0');
// 15.08.08
  Inst.AddField('Cheques','Cheq_BancoCustodia'  ,'C',003,0,060,True ,'Cust�dia'  ,'C�digo do banco de cust�dia do cheque','',False,'1','','','0');
// 03.10.08
  Inst.AddField('Cheques','Cheq_CNPJCPF'        ,'C',14 ,0,110,True ,'CNPJ/CPF'               ,'CNPJ/CPf do emitente'                                           ,''       ,True ,'1','','','1');
// 26.11.09 - para poder 'desdepositar' cheques baixados quando cancela transacao
  Inst.AddField('Cheques','Cheq_TransBaixa'     ,'C',12 ,0,70 ,True ,'Transa��o','N�mero da transa��o da baixa','',False,'3','','','0');
// 07.12.13 - vivan - cheque garantido
  Inst.AddField('Cheques','Cheq_Garantido'      ,'C',01 ,0,70 ,True ,'Garantido','Cheque garantido pela associa��o comercial','',False,'3','','','0');
  Inst.AddField('Cheques','Cheq_usua_Garantido' ,'N',3  ,0,50 ,False,'Usu�rio'  ,'Usu�rio respons�vel pela garantia do cheque'      ,''    ,False,'3','','','0');
// 11.08.15 - vivan - usuario q cadastrou o cheque
  Inst.AddField('Cheques','Cheq_Usua_Codigo'       ,'N',3  ,0,60 ,True ,'Usu�rio'                ,'C�digo do usu�rio respons�vel pelo cadastramento'               ,''       ,False,'3','','','0');


  Inst.AddTable('TabelaPreco');
  Inst.AddField('TabelaPreco','Tabp_Codigo'      ,'N',03,0,30,False,'C�digo'    ,'C�digo do percentual','',False,'3','','','2');
  Inst.AddField('TabelaPreco','Tabp_Aliquota'    ,'N',07,3,70,True ,'Percentual','Percentual para lista de pre�o','##0.000%',False,'3','','','0');
  Inst.AddField('TabelaPreco','Tabp_Tipo'        ,'C',01,0,30,True ,'Uso'       ,'D=Desconto   A=Acr�scimo','',False,'1','','','0');
  Inst.AddField('TabelaPreco','Tabp_Usua_Codigo' ,'N',3 ,0,50 ,False,'Usu�rio'  ,'Usu�rio respons�vel pelo cadastramento'      ,''    ,False,'3','','','0');
// 23.06.14 - Vivan
  Inst.AddField('TabelaPreco','Tabp_UnidadesMvto','C',100,0,0,True,'Unidades Mvto','Unidades liberadas para uso desta tabela','',True,'1','','','0');


  Inst.AddTable('Sittrib');
  Inst.AddField('Sittrib','Sitt_codigo'            ,'N',02,0,40 ,False,'C�digo da trib.'           ,'C�digo da trib.'                            ,''    ,False,'1','','','2');
  Inst.AddField('Sittrib','Sitt_cst'               ,'C',05,0,30 ,False,'C�digo da sit. trib.'      ,'C�digo da situa��o tribut�ria.'             ,''    ,False,'1','','','0');
  Inst.AddField('Sittrib','Sitt_Descricao'         ,'C',70,0,200,True ,'Descri��o da sit.trib.'    ,'Descri��o da sit.trib.'                     ,''    ,True ,'1','','','1');
  Inst.AddField('Sittrib','Sitt_cf       '         ,'C',1 ,0,25 ,True ,'Codigo fiscal da trib.'    ,'Codigo fiscal da trib.'                     ,''    ,True ,'1','','','1');
  Inst.AddField('Sittrib','Sitt_Usua_Codigo'       ,'N',3 ,0,50 ,False,'Usu�rio'                   ,'Usu�rio respons�vel pelo cadastramento'     ,''    ,False,'3','','','0');
// 07.09.10
  Inst.AddField('Sittrib','Sitt_Natf_Codigo'       ,'C',5  ,0,50  ,True ,'Cfop'                  ,'C�digo da natureza fiscal','#.####;0;_',False,'','','','');
// 10.09.10
  Inst.AddField('Sittrib','Sitt_cstme'             ,'C',05,0,30 ,True,'C�digo da sit. trib.'      ,'C�digo da situa��o tribut�ria para o Simples'             ,''    ,False,'1','','','0');
  Inst.AddField('Sittrib','Sitt_es'                ,'C',01,0,30 ,True,'Ent/Saida'                 ,'Uso nas entradas ou nas saidas'             ,''    ,False,'1','','','0');
  Inst.AddField('Sittrib','Sitt_Natf_CodigoFe'     ,'C',5  ,0,50,True ,'Cfop Fora'                ,'C�digo da natureza fiscal fora do estado','#.####;0;_',False,'','','','');
// 14.10.11
  Inst.AddField('Sittrib','Sitt_cstpis'             ,'C',05,0,30 ,True,'CST Pis'      ,'C�digo da situa��o tribut�ria para o PIS'             ,''    ,False,'1','','','0');
  Inst.AddField('Sittrib','Sitt_cstcofins'          ,'C',05,0,30 ,True,'CST Cofins'   ,'C�digo da situa��o tribut�ria para o COFINS'             ,''    ,False,'1','','','0');
// 02.08.19
  Inst.AddField('Sittrib','Sitt_cbenef'             ,'C',08,0,30 ,True,'CBenef'      ,'C�digo do benef�cio fiscal'             ,''    ,False,'1','','','0');


  Inst.AddTable('Referencias');
  Inst.AddField('Referencias','Refc_Chave','N',08,0,70,False,'Chave','C�digo da refer�ncia','#########0',False,'3','','','');
  Inst.AddField('Referencias','Refc_Clie_Codigo','N',08,0,70,False,'Cod Cliente','C�digo do cliente','#########0',False,'3','','','');
  Inst.AddField('Referencias','Refc_NomeRef','C',50,0,300,False,'Nome','Nome da refer�ncia do cliente','',True,'','','','');
  Inst.AddField('Referencias','Refc_FoneRef','C',11,0,90,True,'Fone','Telefone da refer�ncia do cliente','(###) ####-####;0;_',True,'','','','');
  Inst.AddField('Referencias','Refc_Obs','C',200,0,500,True,'Observa��o','Observa��o para a refer�ncia','',True,'','','','');
  Inst.AddField('Referencias','Refc_Unid_ant'          ,'C',03,0,70  ,True,'Unidade anterior'        ,'Unidade anterior','#########0',False,'3','','','2');

  Inst.AddTable('Motbloqueios');
  Inst.AddField('Motbloqueios','MoBl_Codigo','N',3 ,0,30 ,False,'C�digo','C�digo do bloqueio','##0',False,'3','','','2');
  Inst.AddField('Motbloqueios','MoBl_Nome'  ,'C',50,0,250,False,'Descri��o','Descri��o do bloqueio','',True,'','','','1');

  Inst.AddTable('Natureza');
  Inst.AddField('Natureza','Natf_Codigo','C',5,0,50,False,'C�digo','C�digo da natureza fiscal','#.####;0;_',False,'1','','','2');
  Inst.AddField('Natureza','Natf_Descricao','C',100,0,350,True,'Descri��o','Descri��o da natureza fiscal','',True,'1','','','1');
  Inst.AddField('Natureza','Natf_CodigoST','C',5,0,50,True,'C�d ST','C�digo da natureza fiscal para mvtos por substitui��o tribut�ria','#.####;0;_',False,'1','','','2');
  Inst.AddField('Natureza','Natf_ES','C',1,0,20,True,'E/S','Movimento de entrada/saida','',True,'1','','','0');
  Inst.AddField('Natureza','Natf_Movimento','C',1,0,20,True,'Mov','Tipo do movimento','',True,'1','','','0');
  Inst.AddField('Natureza','Natf_Produtos','C',1,0,20,True,'Prod','Produtos envolvidos','',True,'1','','','0');
  Inst.AddField('Natureza','Natf_Utilizacao','C',1,0,20,True,'Utiliz','Utiliza��o da natureza fiscal','',True,'1','','','0');
  Inst.AddField('Natureza','Natf_RegimeTrib','C',1,0,20,True,'Trib','Regime tribut�rio da natureza fiscal','',True,'1','','','0');


  Inst.AddTable('MovEsto');
  Inst.AddField('MovEsto','Moes_Transacao'         ,'C',12 ,0,70  ,False,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('MovEsto','Moes_Operacao'          ,'C',16 ,0,70  ,False,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('MovEsto','Moes_numerodoc'         ,'N',8  ,0,90  ,False,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('MovEsto','Moes_romaneio'          ,'N',8  ,0,90  ,True ,'Romaneio'                  ,'Numero do romaneio'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovEsto','Moes_status'            ,'C',1  ,0,30  ,False,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovEsto','Moes_tipomov'           ,'C',2  ,0,30  ,True ,'Tipo'                      ,'Tipo do movimento'                           ,''    ,False,'2','','','2');
// se e venda direta, venda "consignada", compra, devolu��o, etc
  Inst.AddField('MovEsto','Moes_Comv_codigo'       ,'N',3  ,0,40  ,true ,'Codigo'                    ,'Codigo da configura��o'                     ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_Tabp_Codigo'       ,'N',03,0,30,   True ,'C�digo'                    ,'C�digo da tabela','',False,'1','','','2');
  Inst.AddField('MovEsto','Moes_TabAliquota'       ,'N',07 ,2,40,  true ,'Percentual'                ,'Percentual da tabela','',False,'1','','','2');
  Inst.AddField('MovEsto','Moes_unid_codigo'       ,'C',3  ,0,30  ,True ,'Unidade'                   ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovEsto','Moes_tipo_codigo'       ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/fornecedor'                ,''    ,False,'2','','','0');
  Inst.AddField('MovEsto','Moes_Natf_Codigo'       ,'C',5  ,0,50  ,True ,'N.Fiscal'                  ,'C�digo da natureza fiscal','#.####;0;_',False,'','','','2');
  Inst.AddField('MovEsto','Moes_estado'            ,'C',2  ,0,30  ,True ,'Estado'                    ,'Unidade da Federa��o'                        ,''    ,False,'2','','','0');
  Inst.AddField('MovEsto','Moes_Cida_Codigo'       ,'N',5  ,0,80  ,True ,'C�d. Cidade'               ,'C�digo da cidade'                           ,''       ,False,'3','','','0');
// codigo de cliente, fornecedor, etc
  Inst.AddField('MovEsto','Moes_repr_codigo'       ,'N',4  ,0,90  ,True ,'C�digo'                    ,'C�digo do representante'                   ,''    ,False,'2','','','0');
  Inst.AddField('MovEsto','Moes_tipocad'           ,'C',1  ,0,30  ,True ,'Tipo cadastro'             ,'Tipo do cadastro'                            ,''    ,False,'2','','','0');
// se � cliente, fornecedor, etc
  Inst.AddField('MovEsto','Moes_repr_codigoant'       ,'N',4  ,0,90  ,True ,'C�digo'                    ,'C�digo do representante'                   ,''    ,False,'2','','','0');
  Inst.AddField('MovEsto','Moes_tipo_codigoant'       ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/fornecedor'                ,''    ,False,'2','','','0');
// para importa��o
  Inst.AddField('MovEsto','Moes_DataLcto'          ,'D',0  ,0,60  ,False,'Data Lcto','Data de lan�amento','',True,'1','','','0');
  Inst.AddField('MovEsto','Moes_DataMvto'          ,'D',0  ,0,60  ,False,'Data Mvto','Data de movimento','',True,'1','','','0');
  Inst.AddField('MovEsto','Moes_DataEmissao'       ,'D',0  ,0,60  ,False,'Emiss�o'  ,'Data de emiss�o'  ,'',True,'1','','','0');
  Inst.AddField('MovEsto','Moes_DataCont'          ,'D',0  ,0,60  ,True ,'Data Cont','Data cont�bil'     ,'',True,'1','','','0');
  Inst.AddField('MovEsto','Moes_Vlrtotal'          ,'N',12 ,3,70  ,True ,'Valor total'               ,'Valor total'                              ,''    ,True  ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Totprod'           ,'N',12 ,3,70  ,True ,'Valor total dos produtos'  ,'Valor total dos produtos'                 ,''    ,True  ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Baseicms'          ,'N',12 ,3,70  ,True ,'Base Icms'                 ,'Base Icms'                                ,''    ,True  ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Valoricms'         ,'N',12 ,3,70  ,True ,'Valor Icms'                ,'Valor Icms'                                ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_BaseSubstrib'      ,'N',12 ,3,70  ,True ,'Base Sub.Trib.'            ,'Base Substitui��o Tribut�ria'              ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Valoricmssutr'     ,'N',12 ,3,70  ,True ,'Valor Icms Sub.Trib.'      ,'Valor Icms Substitui��o Tribut�ria'        ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Frete'             ,'N',12 ,3,70  ,True ,'Frete'                     ,'Valor frete'                               ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_FreteCifFob'       ,'C',1  ,0,30  ,True ,'Cif/Fob'                   ,'Cif/Fob'                                   ,''    ,True ,'1','','','0');
  Inst.AddField('MovEsto','Moes_Valoripi'          ,'N',12 ,3,70  ,True ,'Valor Ipi'                 ,'Valor Ipi'                                 ,''    ,True ,'3','','','0');
//  Inst.AddField('MovEsto','Moes_remessas'          ,'C',500,0,200 ,True ,'Remessas devolvidas'       ,'N�meros da remessas devolvidas'            ,''    ,False,'1','','','0');
// 17.08.05
  Inst.AddField('MovEsto','Moes_remessas'          ,'C',1000,0,200 ,True ,'Remessas devolvidas'       ,'N�meros da remessas devolvidas'            ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_vispra'            ,'C',1  ,0,10  ,True ,'A vista/prazo'             ,'V - a vista  P - a prazo'                  ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_especie'           ,'C',4  ,0,40  ,True ,'Esp�cie'                   ,'Esp�cie do documento'                      ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_serie'             ,'C',4  ,0,40  ,True ,'S�rie'                     ,'S�rie do documento'                        ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_tran_codigo'       ,'C',3  ,0,30  ,True ,'C�digo'                    ,'C�digo do transportador'                   ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_qtdevolume'        ,'N',6  ,0,60  ,True ,'Qtde volumes'              ,'Quantidade de volumes'                     ,''    ,False,'3','','','0');
  Inst.AddField('MovEsto','Moes_especievolume'     ,'C',30 ,0,200 ,True ,'Esp�cie volumes'           ,'Tipo de volume utilizado'                  ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_nroconhec'         ,'C',10 ,0,60  ,True ,'Nro.conhec.'               ,'N�mero do conhecimento de transporte'      ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_Perdesco'          ,'N',8  ,4,70  ,True ,'% Desconto'                ,'% Desconto'                                ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Peracres'          ,'N',8  ,4,70  ,True ,'% Acr�scimo'               ,'% Acr�scimo'                               ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_ValorTotal'        ,'N',12 ,3,70  ,True ,'Valor total'               ,'Valor total'                              ,''    ,True  ,'3','','','0');
  Inst.AddField('MovEsto','Moes_ValoraVista'       ,'N',12 ,3,70  ,True ,'Valor a Vista'             ,'Valor a Vista'                            ,''    ,True  ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Usua_Codigo'       ,'N',3  ,0,50  ,False,'Usu�rio'                   ,'Usu�rio respons�vel'                       ,''    ,False,'3','','','0');
// 08.01.05
  Inst.AddField('MovEsto','Moes_rcmagazine'        ,'C',1   ,0, 50  ,True ,'Remessa de magazine'        ,'Remessa de magazine'                       ,''    ,True ,'0','','','0');
// 20.06.05
  Inst.AddField('MovEsto','Moes_mensagem'          ,'C',1000,0,150 ,True  ,'Mensagem'                   ,'Mensagem do documento'                     ,''    ,True ,'0','','','0');
// 01.07.05 - 1.38
  Inst.AddField('MovEsto','Moes_Fpgt_Codigo','C',3,0,30,True,'F.Pgto','C�digo da forma de pagamento','000',False,'1','','','0');
// 08.07.05 - guarda o codigo do 'cliente/representante' - especifico para o regime especial
  Inst.AddField('MovEsto','Moes_clie_codigo'       ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/representante'              ,''    ,False,'3','','','0');
// 20.09.05
  Inst.AddField('MovEsto','Moes_devolucoes'         ,'C',1000,0,200 ,True ,'Devolu��es usadas'       ,'N�meros das devolu��es usadas'             ,''    ,False,'1','','','0');
// 17.10.05
  Inst.AddField('MovEsto','Moes_pedido'            ,'N',10  ,0,90  ,True ,'Pedido'                    ,'Numero do pedido'                            ,''    ,False,'2','','','2');
// 14.11.05 - exporta��o
  Inst.AddField('MovEsto','Moes_pesobru'           ,'N',12 ,3,70  ,True ,'Peso Bruto'                ,'Peso Bruto'                               ,''    ,True  ,'3','','','0');
  Inst.AddField('MovEsto','Moes_pesoliq'           ,'N',12 ,3,70  ,True ,'Peso L�quido'              ,'Peso L�quido'                             ,''    ,True  ,'3','','','0');
// 08.12.05
  Inst.AddField('MovEsto','Moes_nota'              ,'N',8  ,0,90  ,True ,'Numero nota'               ,'Numero nota a que se refere'                 ,''    ,False,'2','','','2');
// 17.04.06
  Inst.AddField('MovEsto','Moes_vlrservicos'       ,'N',012,3,080 ,True ,'Valor Servi�os'            ,'Valor Servi�os'                              ,''    ,False,'2','','','2');
// 18.04.06
  Inst.AddField('MovEsto','Moes_dataacerto '       ,'D',008,0,080 ,True ,'Data Acerto'               ,'Data Acerto'                              ,''    ,False,'2','','','2');
  Inst.AddField('MovEsto','Moes_Transacerto'       ,'C',12 ,0,070 ,True ,'Transa��o acerto'         ,'Transa��o acerto','',False,'3','','','0');
// 21.06.06
  Inst.AddField('MovEsto','Moes_Seguro'            ,'N',12 ,3,70  ,True ,'Valor Seguro'              ,'Valor Seguro'                              ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_OutrasDesp'        ,'N',12 ,3,70  ,True ,'Valor Outras Despesas'     ,'Valor Outras Despesas'                              ,''    ,True ,'3','','','0');
// 26.06.06
  Inst.AddField('MovEsto','Moes_tipo_codigoind'    ,'N',7  ,0,90  ,True ,'Industria'                 ,'C�digo da ind�stria'                         ,''    ,False,'2','','','0');
// 19.09.06
  Inst.AddField('MovEsto','Moes_envio'             ,'C',1  ,0,30  ,True ,'Forma envio'               ,'Forma envio'                                 ,''    ,False,'2','','','2');
// 28.09.06
  Inst.AddField('MovEsto','Moes_Freteuni'          ,'N',12 ,3,70  ,True ,'Frete Unit�rio'            ,'Frete Unit�rio'                               ,''    ,True ,'3','','','0');
// 02.05.07
  Inst.AddField('MovEsto','Moes_Funrural'          ,'N',12 ,3,70  ,True ,'Valor Funrural'            ,'Valor Funrural'                                     ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Cotacapital'       ,'N',12 ,3,70  ,True ,'Valor Cota capital'        ,'Valor Cota Capital'                                 ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_notapro'           ,'N',8  ,0,90  ,True ,'Nota Produtor'             ,'Nota Produtor'                                      ,''    ,False,'2','','','0');
// 12.12.07
  Inst.AddField('MovEsto','Moes_notapro2'          ,'N',8  ,0,90  ,True ,'Nota Produtor 2'           ,'Nota Produtor 2'                                      ,''    ,False,'2','','','0');
  Inst.AddField('MovEsto','Moes_notapro3'          ,'N',8  ,0,90  ,True ,'Nota Produtor 3'           ,'Nota Produtor 3'                                      ,''    ,False,'2','','','0');
  Inst.AddField('MovEsto','Moes_notapro4'          ,'N',8  ,0,90  ,True ,'Nota Produtor 4'           ,'Nota Produtor 4'                                      ,''    ,False,'2','','','0');
  Inst.AddField('MovEsto','Moes_notapro5'          ,'N',8  ,0,90  ,True ,'Nota Produtor 5'           ,'Nota Produtor 5'                                      ,''    ,False,'2','','','0');
// 18.12.07
  Inst.AddField('MovEsto','Moes_nroobra'           ,'C',15 ,0,90  ,True ,'Numero Obra'               ,'Numero Obra'                                          ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_embarque'          ,'C',60 ,0,50  ,True ,'Porto Embarque'            ,'Porto Embarque'                              ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_destino'           ,'C',60 ,0,50  ,True ,'Porto Destino'             ,'Porto Destino'                               ,''    ,False,'1','','','0');
//  Inst.AddField('MovEsto','Moes_container'         ,'C',30 ,0,50  ,True ,'Nro Container'             ,'Numero Container'                            ,''    ,False,'1','','','0');
// 25.03.09
  Inst.AddField('MovEsto','Moes_container'         ,'C',100 ,0,90  ,True ,'Nro Container'             ,'Numero Container'                            ,''    ,False,'1','','','0');
// 24.09.08
  Inst.AddField('MovEsto','Moes_repr_codigo2'      ,'N',4  ,0,90  ,True ,'Vendedor'                   ,'Reserva T�cnica'                   ,''    ,False,'2','','','0');
  Inst.AddField('MovEsto','Moes_Percomissao'       ,'N',7  ,3,70  ,True ,'% Comiss�o'                 ,'% Comiss�o'                               ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Percomissao2'      ,'N',7  ,3,70  ,True ,'% Comiss�o'                 ,'% Reserva T�cnica'                               ,''    ,True ,'3','','','0');
// 11.11.08
  Inst.AddField('MovEsto','Moes_chavenfe'          ,'C',60 ,0,100 ,True ,'Chave Nfe'                 ,'Chave Nfe'                            ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_nfeexp'            ,'C',01 ,0,040 ,True ,'Nfe Exportada'                 ,'Nfe Exportada'                            ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_dtnfeexp'          ,'D',08 ,0,040 ,True ,'Data Exporta��o Nfe'         ,'Data Exporta��o Nfe'                            ,''    ,False,'1','','','0');
// 27.02.09 - notas de mao de obra - valores retidos
  Inst.AddField('MovEsto','Moes_Baseinss'          ,'N',12 ,3,70  ,True ,'Base Inss'                 ,'Base Inss'                                ,''    ,True  ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Baseiss'           ,'N',12 ,3,70  ,True ,'Base ISS'                  ,'Base ISS'                                ,''    ,True  ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Valorpis'          ,'N',12 ,3,70  ,True ,'Valor Pis'                 ,'Valor Pis'                                ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Valorcofins'       ,'N',12 ,3,70  ,True ,'Valor Cofins'              ,'Valor Cofins'                                ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Valorcsl'          ,'N',12 ,3,70  ,True ,'Valor CSL'                 ,'Valor CSL'                                ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Valorir'           ,'N',12 ,3,70  ,True ,'Valor IR'                  ,'Valor IR'                                ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Valorinss'         ,'N',12 ,3,70  ,True ,'Valor INSS'                ,'Valor INSS'                                ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Valoriss'          ,'N',12 ,3,70  ,True ,'Valor ISS'                 ,'Valor ISS'                                ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_Periss'            ,'N',7  ,3,70  ,True ,'% ISS'                     ,'% ISS'                               ,''    ,True ,'3','','','0');
// 08.07.09 - margem de lucro do 'fechamento de contrato da obra'
  Inst.AddField('MovEsto','Moes_Lucro'             ,'N',7  ,3,70  ,True ,'Lucro'                     ,'% Margem de Lucro l�quida'                               ,''    ,True ,'3','','','0');
// 15.10.09 - inicio 'controle de frota'
  Inst.AddField('MovEsto','Moes_km'                ,'N',9  ,3,70  ,True ,'KM'                     ,'Quilometragem do ve�culo'                               ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_cola_codigo'       ,'C',4  ,0,70  ,True ,'Colab.'                     ,'Colaborador que abasteceu o ve�culo'                               ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_plan_codigo'       ,'N',8  ,0,70  ,True ,'Conta'                     ,'Conta de despesa/receita'                               ,''    ,True ,'3','','','0');
// 11.11.09 - campos para nfe
  Inst.AddField('MovEsto','Moes_retornonfe'        ,'C',150 ,0,100 ,True ,'Retorno Sefa'                  ,'Retorno Sefa'                             ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_dtnfereto'         ,'D',08  ,0,040 ,True ,'Data Retorno Sefa'         ,'Data Retorno Sefa'                            ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_dtnfeauto'         ,'D',08  ,0,040 ,True ,'Data Autoriza��o Nfe'         ,'Data Autoriza��o Nfe'                            ,''    ,False,'1','','','0');
//  Inst.AddField('MovEsto','Moes_xmlnfe'            ,'C',20000,0,300 ,True ,'XML NFe'                  ,'XML NFe'                             ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_xmlnfe'            ,'B',0,0,300 ,True ,'XML NFe'                  ,'XML NFe'                             ,''    ,False,'1','','','0');
// 13.11.09 - campos para nfe
  Inst.AddField('MovEsto','Moes_Usua_CancNfe'       ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio que cancelou NFe na Sefa'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovEsto','Moes_dtnfecanc'         ,'D',08  ,0,040 ,True ,'Data Cancelamento Nfe'         ,'Data Cancelamento Nfe'                            ,''    ,False,'1','','','0');
//  Inst.AddField('MovEsto','Moes_xmlnfecanc'        ,'C',6000,0,300 ,True ,'XML Canc. NFe'                  ,'XML Canc. NFe'                             ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_xmlnfecanc'        ,'B',0,0,300 ,True ,'XML Canc. NFe'                  ,'XML Canc. NFe'                             ,''    ,False,'1','','','0');
// 26.11.09
  Inst.AddField('MovEsto','Moes_DataSaida'         ,'D',0  ,0,60  ,True ,'Saida'  ,'Data da saida'  ,'',True,'1','','','0');
// 30.11.09
  Inst.AddField('MovEsto','Moes_protodpec'         ,'C',150 ,0,150 ,True ,'Prot.Dpec'  ,'N�mero do protocolo do Dpec'  ,'',True,'1','','','0');
// 09.02.10 - km final para calcular m�dia por km
  Inst.AddField('MovEsto','Moes_kmfinal'           ,'N',9  ,3,70  ,True ,'KM Final'                     ,'Quilometragem final do ve�culo'                               ,''    ,True ,'3','','','0');
// 11.02.10
  Inst.AddField('MovEsto','Moes_obs'               ,'C',1000,0,150 ,True  ,'Observa��es'                   ,'Observa��es do documento'                     ,''    ,True ,'0','','','0');
// 15.07.10
  Inst.AddField('MovEsto','Moes_xmlnfeT'           ,'M',0,0,300 ,True ,'XML NFe'                  ,'XML NFe'                             ,''    ,False,'1','','','0');
// 23.08.10 - Abra - margem de lucro dos contratos
  Inst.AddField('MovEsto','Moes_PerMargem'         ,'N',7  ,3,70  ,True ,'% Margem Lucro'                     ,'% Margem Lucro'                               ,''    ,True ,'3','','','0');
// 21.10.10 - Novicarnes - Vava...movimentos 'CF'..usa outros 'debitos e creditos'
  Inst.AddField('MovEsto','Moes_plan_codigocre'    ,'N',8  ,0,70  ,True ,'Conta Cr�dito'                     ,'Conta de despesa/receita'                               ,''    ,True ,'3','','','0');
// 24.03.11
  Inst.AddField('MovEsto','Moes_estadoex'          ,'C',2  ,0,30  ,True ,'UF Exp.'        ,'UF de embarque para Exporta��o'                        ,''    ,False,'2','','','0');
// 24.06.11
// 11.11.08
  Inst.AddField('MovEsto','Moes_chavenferef'       ,'C',60 ,0,100 ,True ,'Chave Nfe Ref.'                 ,'Chave Nfe Referenciada(Complemento Icms...)'                            ,''    ,False,'1','','','0');
// 12.01.12 - campos para NFe de importacao - entrada - Asatec - dados da 'DI'-declaracao de importacao
  Inst.AddField('MovEsto','Moes_numerodi'         ,'C',010 ,0,90  ,True ,'Nro DI'               ,'Numero do documento de importa��o'                            ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_dtregistro'       ,'D',008 ,0,90  ,True ,'Registro'             ,'Data do registro do documento de importa��o'                            ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_localdesen'       ,'C',100 ,0,300 ,True ,'Local Desembara�o'             ,'Local Desembara�o'                            ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_ufdesen'          ,'C',002 ,0,30  ,True ,'UF'                   ,'UF do local do desembara�o aduaneiro'                            ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_dtdesen'          ,'D',008 ,0,90  ,True ,'Desembara�o'                   ,'Data do desembara�o aduaneiro'                            ,''    ,False,'1','','','0');
  Inst.AddField('MovEsto','Moes_codexp'           ,'C',060 ,0,90  ,True ,'Codigo Exp.'                   ,'Codigo do exportador usado no sistema que emite a NFe'                            ,''    ,False,'1','','','0');
// 20.08.12
  Inst.AddField('MovEsto','Moes_xmlCCe'           ,'M',0,0,300 ,True ,'XML CCe'                  ,'XML Carta de Corre��o'                             ,''    ,False,'1','','','0');
// 27.08.13
  Inst.AddField('MovEsto','Moes_Seto_Codigo'      ,'C',4,0,050,True,'Setor','C�digo do setor','0000',True ,'1','','','0');
// 30.07.15
  Inst.AddField('MovEsto','Moes_vlrgta'           ,'N',012,3, 90,True ,'Valor GTA'                  ,'Valor GTA'                                ,''    ,False,'3','','','0');
// 20.01.16 - cargas
  Inst.AddField('MovEsto','Moes_carga'            ,'N',8  ,0,90  ,True ,'Carga'                    ,'Numero da carga'                           ,''    ,False,'2','','','2');
// 21.09.16
  Inst.AddField('MovEsto','Moes_pertrans'         ,'N',7  ,3,70  ,True ,'% Transf.'                 ,'% para deduzir sobre a entrada de abate para gerar a entrada de produtor'          ,''    ,True ,'3','','','0');
// 22.06.17 - Manifesto da nota do fornecedor
  Inst.AddField('MovEsto','Moes_xmlmanifesto'      ,'M',0  ,0,70  ,True ,'Xml Manifesto NF-e'        ,'Xml de confirma��o da NF-e do fornecedor'          ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_datamanifesto'     ,'D',8  ,0,70  ,True ,'Data Manifesto NF-e'       ,'Data de confirma��o da NF-e do fornecedor'          ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_retornomanifesto'  ,'C',200,0,170 ,True ,'Retorno Manifesto NF-e'    ,'Retorno da confirma��o da NF-e do fornecedor'          ,''    ,True ,'3','','','0');
  Inst.AddField('MovEsto','Moes_nfecommanifesto'   ,'C',001,0,050 ,True ,''                          ,''          ,''    ,True ,'3','','','0');
// 20.06.19 - vida nova
  Inst.AddField('MovEsto','Moes_insumos'           ,'N',12  ,2,90  ,True ,'Insumos'                    ,'Insumos da produ��o'                           ,''    ,False,'2','','','2');
// 01.08.19 - A2z
  Inst.AddField('MovEsto','Moes_equi_codigo'       ,'C',04  ,2,60  ,True ,'Equipamento'                ,'Codigo do equipamento'                           ,''    ,False,'1','','','0');



  Inst.AddTable('MovEstoque');
  Inst.AddField('MovEstoque','Move_Transacao'         ,'C',12,0,70,False,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('MovEstoque','Move_Operacao'          ,'C',16,0,70,False,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('MovEstoque','Move_numerodoc'         ,'N',8 ,0,90,False,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('MovEstoque','Move_status'            ,'C',1 ,0,30,False,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovEstoque','Move_tipomov'           ,'C',2 ,0,30,False,'Tipo'                      ,'Tipo do movimento'                           ,''    ,False,'2','','','2');
  Inst.AddField('MovEstoque','Move_unid_codigo'       ,'C',3  ,0,30  ,False,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovEstoque','Move_esto_codigo'       ,'C',20 ,0,90  ,False,'C�digo'                    ,'C�digo do produto'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovEstoque','Move_tama_codigo'       ,'N',5  ,0,30  ,True ,'C�digo'                    ,'C�digo do tamanho'                           ,''    ,False,'2','','','0');
  Inst.AddField('MovEstoque','Move_core_codigo'       ,'N',3  ,0,30  ,True ,'C�digo'                    ,'C�digo da cor'                                ,''    ,False,'2','','','0');
  Inst.AddField('MovEstoque','Move_tipo_codigo'       ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/fornecedor'                ,''    ,False,'2','','','0');
  Inst.AddField('MovEstoque','Move_tipo_codigoant'    ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/fornecedor'                ,''    ,False,'2','','','0');
// codigo de cliente, fornecedor, etc
  Inst.AddField('MovEstoque','Move_tipocad'           ,'C',1  ,0,30  ,True ,'Tipo cadastro'             ,'Tipo do cadastro'                            ,''    ,False,'2','','','0');
// se � cliente, fornecedor, etc
  Inst.AddField('MovEstoque','Move_repr_codigo'       ,'N',4  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/representante'             ,''    ,False,'2','','','2');
  Inst.AddField('MovEstoque','Move_repr_codigoant'       ,'N',4  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/representante'             ,''    ,False,'2','','','2');
  Inst.AddField('MovEstoque','Move_Qtde'              ,'N',12 ,4,70  ,True ,'Qtde'                      ,'Qtde em movimento'                           ,''    ,True ,'1','','','0');
  Inst.AddField('MovEstoque','Move_Estoque'           ,'N',12 ,4,70  ,True ,'Qtde em estoque'           ,'Qtde em estoque'                             ,''    ,True ,'1','','','0');
  Inst.AddField('MovEstoque','Move_DataLcto'          ,'D',0  ,0,60  ,False,'Data Lcto','Data de lan�amento','',True,'1','','','0');
  Inst.AddField('MovEstoque','Move_DataMvto'          ,'D',0  ,0,60  ,True ,'Data Mvto','Data de movimento','',True,'1','','','0');
  Inst.AddField('MovEstoque','Move_DataCont'          ,'D',0  ,0,60  ,True ,'Data Cont','Data cont�bil'     ,'',True,'1','','','0');
  Inst.AddField('MovEstoque','Move_QtdeRetorno'       ,'N',12 ,4,70  ,True ,'Retorno'                   ,'Qtde de retorno'                             ,''    ,True ,'1','','','0');
  Inst.AddField('MovEstoque','Move_Custo'             ,'N',12 ,3,70  ,True ,'Custo atual   '            ,'Custo atual'                              ,''    ,True ,'1','','','0');
  Inst.AddField('MovEstoque','Move_Custoger'          ,'N',12 ,3,70  ,True ,'Custo gerencial'           ,'Custo gerencial'                          ,''    ,True ,'1','','','0');
  Inst.AddField('MovEstoque','Move_customedio'        ,'N',12, 3,80  ,True ,'Custo m�dio do produto'    ,'Custo m�dio do produto'                      ,''    ,True ,'1','','','0');
  Inst.AddField('MovEstoque','Move_customeger'        ,'N',12, 3,80  ,True ,'Custo m�dio gerencial'     ,'Custo m�dio gerencial'                       ,''    ,True ,'1','','','0');
//  Inst.AddField('MovEstoque','Move_Venda'             ,'N',12 ,3,70  ,True ,'Pre�o de venda'            ,'Pre�o de venda'                           ,''    ,True ,'1','','','0');
// 16.09.06 - devido aos 'esquemas' da coml. exterior
//  Inst.AddField('MovEstoque','Move_Venda'             ,'N',13 ,5,70  ,True ,'Pre�o venda'               ,'Pre�o de venda'                           ,''    ,True ,'1','','','0');
// 30.07.20 - devido aos 'esquemas' das compras de ra��o com 6 ou 7 casas no unitario pra 'fechar'
  Inst.AddField('MovEstoque','Move_Venda'             ,'N',14 ,6,70  ,True ,'Pre�o venda'               ,'Pre�o de venda'                           ,''    ,True ,'1','','','0');
  Inst.AddField('MovEstoque','Move_Grup_codigo'       ,'N',06 ,0,40  ,True ,'C�digo do grupo'           ,'C�digo do grupo'                             ,''    ,False,'1','','','0');
  Inst.AddField('MovEstoque','Move_Sugr_codigo'       ,'N',04 ,0,40  ,True ,'C�digo do subgrupo'        ,'C�digo do subgrupo'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovEstoque','Move_Fami_codigo'       ,'N',04 ,0,40  ,True ,'C�digo'                    ,'C�digo da familia'                        ,''    ,False,'2','','','2');
  Inst.AddField('MovEstoque','Move_cst'               ,'C',05 ,0,30  ,True ,'C�digo da sit. trib.'      ,'C�digo da situa��o tribut�ria.'             ,''    ,False,'1','','','0');
  Inst.AddField('MovEstoque','Move_aliicms'           ,'N',07 ,3,45  ,True ,'% icms'                    ,'% icms'                                      ,f_aliq,True ,'1','','','0');
  Inst.AddField('MovEstoque','Move_aliipi'            ,'N',07 ,3,45  ,True ,'% ipi'                     ,'% ipi'                                       ,f_aliq,True ,'1','','','0');
//  Inst.AddField('MovEstoque','Move_remessas'          ,'C',500,0,200 ,True ,'Remessas devolvidas'       ,'N�meros da remessas devolvidas'             ,''    ,False,'1','','','0');
// 17.08.05
  Inst.AddField('MovEstoque','Move_remessas'          ,'C',1000,0,200 ,True ,'Remessas devolvidas'       ,'N�meros da remessas devolvidas'             ,''    ,False,'1','','','0');
  Inst.AddField('MovEstoque','Move_Mate_codigo'       ,'N',04 ,0,40  ,True ,'Material'                  ,'C�digo do material predominante'             ,''    ,False,'','','','');
  Inst.AddField('MovEstoque','Move_Emlinha'           ,'C',01 ,0,40  ,True ,'Em linha'                  ,'Em linha'                                    ,''    ,False,'0','','','0');
  Inst.AddField('MovEstoque','Move_Usua_Codigo'       ,'N',3  ,0,50  ,False,'Usu�rio'                   ,'Usu�rio respons�vel'                        ,''    ,False,'3','','','0');
  Inst.AddField('MovEstoque','Move_Vendabru'          ,'N',12 ,3,70  ,True ,'Pre�o de venda bruto'      ,'Pre�o de venda bruto'                     ,''    ,True ,'3','','','0');
  Inst.AddField('MovEstoque','Move_Perdesco'          ,'N',07 ,3,70  ,True ,'% de desconto'             ,'% de desconto'                            ,''    ,True ,'3','','','0');
//  Inst.AddField('MovEstoque','Move_TransRetorno'      ,'C',12 ,0,70  , true,'Transa��o','Transa��o acerto consina��o','',False,'3','','','0');
// 08.07.05 - guarda o codigo do 'cliente/representante' - especifico para o regime especial
  Inst.AddField('MovEstoque','Move_clie_codigo'       ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/representante'              ,''    ,False,'3','','','0');
// 20.09.05
  Inst.AddField('MovEstoque','Move_devolucoes'          ,'C',1000,0,200 ,True ,'Devolu��es usadas'       ,'N�meros das devolu��es usadas'             ,''    ,False,'1','','','0');
// 05.05.06
  Inst.AddField('MovEstoque','Move_copa_codigo'          ,'N',3 ,0,30 ,True ,'Copa'                       ,'C�digo da copa'                            ,''    ,False,'2','','','0');
// 26.06.06
  Inst.AddField('MovEstoque','Move_tipo_codigoind'       ,'N',7  ,0,90  ,True ,'Industria'                 ,'C�digo da ind�stria'                         ,''    ,False,'2','','','0');
// 24.01.07
  Inst.AddField('MovEstoque','Move_qualidade'           ,'C',30,0,100  ,True ,'Qualidade'                 ,'Qualidade'                                    ,''    ,False,'2','','','0');
// 02.05.07
  Inst.AddField('MovEstoque','Move_Pecas'               ,'N',12 ,3,70  ,True ,'Pe�as'                     ,'Pe�as'                               ,''    ,True ,'3','','','0');
// 22.05.07
  Inst.AddField('MovEstoque','Move_Redubase'            ,'N',07 ,3,70  ,True ,'% red.base'               ,'% redu��o base de c�lculo'                            ,''    ,True ,'3','','','0');
// 27.05.07
  Inst.AddField('MovEstoque','Move_Vendamin'            ,'N',12 ,3,70  ,True ,'Pre�o de venda m�nimo'    ,'Pre�o de venda m�nimo'                     ,''    ,True ,'3','','','0');
// 03.11.07
  Inst.AddField('MovEstoque','Move_Estoquepc'           ,'N',12 ,3,70  ,True ,'Estoque Pe�as'           ,'Qtde de pe�as em estoque'                             ,''    ,True ,'1','','','0');
// 27.11.07
  Inst.AddField('MovEstoque','Move_locales'             ,'C',02,0,70   ,True ,'Local Estoque'             ,'Local Estoque'                                  ,'00'    ,True ,'1','','','0');
// 18.12.07
  Inst.AddField('MovEstoque','Move_nroobra'             ,'C',15 ,0,90  ,True ,'Numero Obra'               ,'Numero Obra'                                          ,''    ,False,'1','','','0');
// 21.01.08
  Inst.AddField('MovEstoque','Move_Peso'                ,'N',13 ,5,70  ,True ,'Peso'                       ,'Peso'                             ,''    ,True ,'3','','','0');
  Inst.AddField('MovEstoque','Move_Pesosobra'           ,'N',13 ,5,70  ,True ,'Peso Sobra'                 ,'Peso Sobra'                       ,''    ,True ,'3','','','0');
// 22.12.08
  Inst.AddField('MovEstoque','Move_certificado'         ,'C',01,0,100  ,True ,'Certificado'                 ,'Produto/Material certificado'                                    ,''    ,False,'3','','','0');
// 27.02.09   - criar apos o carnaval por 'seguran�a'
  Inst.AddField('MovEstoque','Move_descricao'           ,'C',100,0,100  ,True ,'Descri��o'                 ,'Descri��o do Produto/Material/Servi�o'                                 ,''    ,False,'3','','','0');
// 01.07.09
  Inst.AddField('MovEstoque','Move_core_codigoind'      ,'N',3  ,0,30  ,True ,'C�digo'                    ,'C�digo da cor que retorna da industrializa��o'                                ,''    ,False,'2','','','0');
// 08.09.10
  Inst.AddField('MovEstoque','Move_Natf_Codigo'         ,'C',5  ,0,50  ,True ,'N.Fiscal'                  ,'C�digo da natureza fiscal','#.####;0;_',False,'','','','');
// 20.08.12
  Inst.AddField('MovEstoque','Move_Embalagem'           ,'N',12 ,3,70  ,True ,'Qtde por embalagem'        ,'Qtde por embalagem'                           ,''    ,True ,'1','','','0');
  Inst.AddField('MovEstoque','Move_UnitarioNota'        ,'N',13 ,5,70  ,True ,'Pre�o Unit�rio Documento'  ,'Pre�o Unit�rio Documento'                           ,''    ,True ,'1','','','0');
// 27.08.13
  Inst.AddField('MovEstoque','Move_Seto_Codigo'         ,'C',4,0,050   ,True,'Setor','C�digo do setor','0000',True ,'1','','','0');
// 04.07.19 - Seip - aliquota imposto de importacao para somar na base do ipi
  Inst.AddField('MovEstoque','Move_aliii'            ,'N',07 ,3,45  ,True ,'% II'                     ,'% Imp.Importa��o'                                       ,f_aliq,True ,'1','','','0');
// 01.08.19 - A2z
  Inst.AddField('MovEstoque','Move_equi_codigo'       ,'C',04  ,2,60  ,True ,'Equipamento'                ,'Codigo do equipamento'                           ,''    ,False,'1','','','0');
// 23.02.23 - devolucoes com reducao de base de icms
  Inst.AddField('MovEstoque','Move_sitt_codigo'       ,'N',02  ,0,30  ,True ,'Sit.trib.'                ,'Codigo de situa��o tribut�ria'                           ,''    ,False,'1','','','0');


  Inst.AddTable('MovBase');
  Inst.AddField('MovBase','Movb_Transacao','C',12,0,70,False,'Transa��o','N�mero da transa��o','',False,'','','','');
  Inst.AddField('MovBase','Movb_Operacao','C',16,0,70,False,'Opera��o','N�mero da opera��o','',False,'','','','');
  Inst.AddField('MovBase','Movb_Status','C',1,0,20,False,'Status','Status do lan�amento','',False,'','','','');
  Inst.AddField('MovBase','Movb_numerodoc'    ,'N',8 ,0,90,True,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('MovBase','Movb_cst'       ,'C',05 ,0,30  ,True ,'C�digo da sit. trib.'      ,'C�digo da situa��o tribut�ria.'             ,''    ,False,'1','','','0');
  Inst.AddField('MovBase','Movb_Codigosfis','C',3,0,25,True,'Simb','Codigo para a tributa��o','',True,'','','','');
  Inst.AddField('MovBase','Movb_TpImposto','C',1,0,20,False,'Tp','Tipo do imposto','',False,'','','','');
// codigo de valores fiscais ( 1,,5 da impressao do livro fiscal )
  Inst.AddField('MovBase','Movb_CVF','C',1,0,20,True,'CVF','Codigo de valores fiscais','',False,'','','','');
  Inst.AddField('MovBase','Movb_tipomov','C',2,0,40,True,'Tipo Movimento','Tipo Movimento','',False,'','','','');
  Inst.AddField('MovBase','Movb_BaseCalculo','N',12,2,80,True,'Base C�lculo','Base de c�lculo do imposto','###,###,##0.00',True,'3','+','','');
  Inst.AddField('MovBase','Movb_Aliquota','N',7,3,50,True,'Aliquota','Aliquota do imposto','##0.000%',True,'3','','','');
  Inst.AddField('MovBase','Movb_ReducaoBc','N',7,3,50,True,'Redu��o','Redu��o da base de c�lculo do imposto','##0.000%',True,'3','','','');
  Inst.AddField('MovBase','Movb_Imposto','N',12,2,90,True,'Imposto','Valor do imposto','###,###,##0.00',True,'3','+','','');
  Inst.AddField('MovBase','Movb_Isentas','N',12,2,80,True,'Isentas','Valores de isentas','###,###,##0.00',True,'3','+','','');
  Inst.AddField('MovBase','Movb_Outras' ,'N',12,2,80,True,'Outras','Valores de outras','###,###,##0.00',True,'3','+','','');
  Inst.AddField('MovBase','Movb_Unid_Codigo','C',3,0,30,True ,'Unidade','C�digo da unidade','000',False,'1','','','0');
// 13.07.06
  Inst.AddField('MovBase','Movb_Natf_Codigo' ,'C',5  ,0,50  ,True ,'N.Fiscal'                  ,'C�digo da natureza fiscal','#.####;0;_',False,'','','','2');


  Inst.AddTable('Pendencias');
  Inst.AddField('Pendencias','Pend_Transacao','C',12,0,70,False,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('Pendencias','Pend_Operacao','C',16,0,70,False,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('Pendencias','Pend_Status','C',1,0,20,False,'Status','Status do lan�amento','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_DataLcto','D',0,0,60,False,'Data Lcto','Data de lan�amento','',True,'1','','','0');
  Inst.AddField('Pendencias','Pend_DataMvto','D',0,0,60,False,'Data Mvto','Data de movimento','',True,'1','','','0');
  Inst.AddField('Pendencias','Pend_DataVcto','D',0,0,60,False,'Data Vcto','Data do vencimento','',True,'1','','','0');
  Inst.AddField('Pendencias','Pend_DataCont','D',0,0,60,True ,'Data Cont','Data cont�bil'     ,'',True,'1','','','0');
  Inst.AddField('Pendencias','Pend_DataEmissao','D',0,0,60,False,'Data Emiss�o','Data de emiss�o do documento origem','',True,'1','','','0');
  Inst.AddField('Pendencias','Pend_DataAutPgto','D',0,0,60,True,'Data Aut. Pgto','Data autorizada para pagamento','',True,'1','','','0');
  Inst.AddField('Pendencias','Pend_Plan_Conta','N',08,0,60,False,'Conta','C�digo reduzido da conta','0000',False,'3','','','0');
  Inst.AddField('Pendencias','Pend_Unid_Codigo','C',3,0,30,False,'Unidade','C�digo da unidade','000',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_Fpgt_Codigo','C',3,0,30,True,'F.Pgto','C�digo da forma de pagamento','000',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_Port_Codigo','C',3,0,50,True,'Portador','C�digo do portador','000',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_Hist_Codigo','N',3,0,50,True,'C�digo','C�digo do hist�rico','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_Moed_Codigo','C',3,0,25,True,'Moeda','C�digo da moeda','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_Repr_Codigo','N',4,0,30,True,'Representante','C�digo do representante','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_Repr_Codigoant','N',4,0,30,True,'Representante','C�digo do representante','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_Tipo_Codigo','N',08,0,20,True,'Cod Cli/for','C�digo cliente/forn.','',False,'1','','','0');

  Inst.AddField('Pendencias','Pend_Tipo_Codigoant','N',08,0,20,True,'Cod Cli/for','C�digo cliente/forn.','',False,'1','','','0');

  Inst.AddField('Pendencias','Pend_TipoCad'    ,'C',01,0,20,True,'Tipo codigo','Tipo codigo','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_CNPJCPF','C',14,0,110,True,'CNPJ/CPF','CNPJ/CPF da entidade','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_Complemento','C',100,0,250,True,'Complemento','Complemento do hist�rico','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_NumeroDcto','C',20,0,100,True,'N�mero Dcto','N�mero do documento','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_Parcela','N',3,0,50,True,'Parcela','N�mero da parcela','000',False,'3','','','0');
  Inst.AddField('Pendencias','Pend_NParcelas','N',3,0,50,True,'Parcelas','N�mero de parcelas','000',False,'3','','','0');
  Inst.AddField('Pendencias','Pend_RP','C',1,0,20,False,'R/P','Recebimento ou pagamento','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_Valor'      ,'N',12,2,80,True,'Valor Dcto','Valor da pend�ncia',f_cr,True,'3','','','0');
  Inst.AddField('Pendencias','Pend_ValorTitulo','N',12,2,80,True,'Valor Total','Valor total da pend�ncia',f_cr,True,'3','','','0');
  Inst.AddField('Pendencias','Pend_Juros','N',12,2,80,True,'Valor Juros','Valor dos juros',f_cr,True,'3','','','0');
  Inst.AddField('Pendencias','Pend_Multa','N',12,2,80,True,'Valor Multa','Valor da multa',f_cr,True,'3','','','0');
  Inst.AddField('Pendencias','Pend_Mora','N',12,2,80,True,'Valor Mora','Valor da mora',f_cr,True,'3','','','0');
  Inst.AddField('Pendencias','Pend_Acrescimos','N',12,2,80,True,'Valor Acr�scimos','Valor dos acr�scimos',f_cr,True,'3','','','0');
  Inst.AddField('Pendencias','Pend_Descontos','N',12,2,80,True,'Valor Descontos','Valor dos descontos',f_cr,True,'3','','','0');
  Inst.AddField('Pendencias','Pend_ValorComissao','N',12,2,80,True,'Valor Comiss�o','Valor da comiss�o',f_cr,True,'3','','','0');
  Inst.AddField('Pendencias','Pend_TransBaixa','C',12,0,70,True,'Trans. Baixa','N�mero da transa��o da baixa','',False,'3','','','0');
  Inst.AddField('Pendencias','Pend_ContaBaixa','N',08,0,60,True,'Conta Baixa','C�digo reduzido da conta da baixa','0000',False,'3','','','0');
  Inst.AddField('Pendencias','Pend_DataBaixa','D',0,0,60,True,'Data Baixa','Data da baixa','',True,'1','','','0');
  Inst.AddField('Pendencias','Pend_Observacao','C',100,0,250,True,'Observa��o','Observa��o da pend�ncia','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_UsuBaixa','N',3,0,40,True,'Usu Baixa'    ,'Usu�rio respons�vel pela baixa da pend�ncia'      ,'',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_Impresso','N',08,0,70,True,'N�mero Impresso','N�mero do impresso da pend�ncia financeira','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_ImprDcto','C',1,0,20,True,'Dcto J� Impresso','Documento da pend�ncia j� foi impresso','',False,'1','','','0');
  Inst.AddField('Pendencias','Pend_LoteCNAB','N',8,0,20,True,'Lote Exp. CNAB','N�mero do lote da exporta��o para o CNAB','',False,'1','','','0');
// 20.06.05
  Inst.AddField('Pendencias','Pend_Usua_Codigo'     ,'N',3 ,0,50 ,True ,'Usu�rio'                 ,'Usu�rio respons�vel'         ,''    ,False,'3','','','0');
  Inst.AddField('Pendencias','Pend_tipomov'         ,'C',2  ,0,30  ,True ,'Tipo'                  ,'Tipo do movimento'                           ,''    ,False,'2','','','2');
// 01.07.05 - 1.38
  Inst.AddField('Pendencias','Pend_Opantecipa','C',16,0,70,True ,'Opera��o Ant.','N�mero da opera��o antecipa��o','',False,'3','','','0');
// 31.07.08
  Inst.AddField('Pendencias','Pend_DataVctoOri','D',0,0,60,True,'Data Vcto','Data do vencimento original','',True,'1','','','0');
// 27.08.13
  Inst.AddField('Pendencias','Pend_Seto_Codigo' ,'C',4,0,050   ,True,'Setor','C�digo do setor','0000',True ,'1','','','0');
// 12.05.20
  Inst.AddField('Pendencias','Pend_codbarra' ,'C',60,0,250   ,True,'Cod.Barra','C�digo de barra do boleto','',True ,'1','','','0');


  Inst.AddTable('ConfMov');
  Inst.AddField('ConfMov','Comv_codigo'            ,'N',3  ,0,40  ,false,'Codigo'                    ,'Codigo da configura��o'                     ,''    ,False,'1','','','2');
  Inst.AddField('ConfMov','Comv_descricao'         ,'C',50 ,0,200 ,false,'Descri��o'                 ,'Descri��o da configura��o'                  ,''    ,False,'1','','','1');
  Inst.AddField('ConfMov','Comv_especie'           ,'C',4  ,0,40  ,true ,'Esp�cie'                   ,'Esp�cie do documento'                       ,''    ,False,'1','','','0');
  Inst.AddField('ConfMov','Comv_serie'             ,'C',4  ,0,40  ,True ,'S�rie'                     ,'S�rie do documento'                         ,''    ,False,'1','','','0');
  Inst.AddField('ConfMov','Comv_Natf_EStado'       ,'C',5  ,0,50  ,True ,'Cfop Est.'                 ,'C�d. da natureza fiscal no estado'          ,'#.####;0;_',False,'','','','2');
  Inst.AddField('ConfMov','Comv_Natf_FoEStado'     ,'C',5  ,0,50  ,True ,'Cfop F.Est.'               ,'C�digo da natureza fiscal fora do estado'   ,'#.####;0;_',False,'','','','2');
  Inst.AddField('ConfMov','Comv_tipomovto'         ,'C',2  ,0,30  ,True ,'Tipo Movto'                ,'Tipo de movimento'                          ,''    ,False,'','','','2');
  Inst.AddField('ConfMov','Comv_Usua_Codigo'       ,'N',3  ,0,50  ,False,'Usu�rio'                   ,'Usu�rio respons�vel'                        ,''    ,False,'3','','','0');
// 01.07.05 - 1.38
  Inst.AddField('ConfMov','Comv_MensNF'            ,'C',1  ,0,30  ,True ,'Mensagem NF'               ,'Mensagem NF'                                ,''    ,False,'3','','','0');
// 08.12.05
  Inst.AddField('ConfMov','Comv_Icms'              ,'C',1  ,0,30  ,True ,'Calcula Icms'               ,'Calcula Icms'                                ,''    ,False,'3','','','0');
  Inst.AddField('ConfMov','Comv_SubsTrib'          ,'C',1  ,0,30  ,True ,'Calcula Subst.Tribut�ria'   ,'Calcula Subst.Tribut�ria'                   ,''    ,False,'3','','','0');
// 07.08.06
  Inst.AddField('ConfMov','Comv_Natf_Estadoipi'     ,'C',5  ,0,50  ,True ,'Cfop Est. IPI'             ,'C�d. da natureza fiscal no estado para IPI' ,'#.####;0;_',False,'','','','2');
  Inst.AddField('ConfMov','Comv_Natf_FoEstadoipi'   ,'C',5  ,0,50  ,True ,'Cfop F.Est. IPI'           ,'C�digo da natureza fiscal fora do estado para IPI'   ,'#.####;0;_',False,'','','','2');
// 23.10.07
  Inst.AddField('ConfMov','Comv_Natf_EstadoSer'     ,'C',5  ,0,50  ,True ,'Cfop Est. Ser'             ,'C�d. da natureza fiscal no estado para Servi�os' ,'#.####;0;_',False,'','','','2');
  Inst.AddField('ConfMov','Comv_Natf_FoEstadoSer'   ,'C',5  ,0,50  ,True ,'Cfop F.Est. Ser'           ,'C�digo da natureza fiscal fora do estado para Servi�os'   ,'#.####;0;_',False,'','','','2');
  Inst.AddField('ConfMov','Comv_sitt_codigo'        ,'N',2  ,0,30  ,True ,'Sit.trib. Ser'                 ,'Situa��o Tribut�ria para Servi�os'                      ,''    ,True ,'1','','','0');
// 12.12.07
  Inst.AddField('ConfMov','Comv_TipoCad'            ,'C',1  ,0,50  ,True ,'Cliente/Fornec.'           ,'Se � para Cliente ou Fornecedor'                            ,'',False,'','','','1');
// 24.03.08
  Inst.AddField('ConfMov','Comv_debito'             ,'N',008,0,070 ,True,'D�bito'         ,'Conta de d�bito para exporta��o cont�bil','',True,'3','','','0');
  Inst.AddField('ConfMov','Comv_credito'            ,'N',008,0,070 ,True,'Cr�dito'        ,'Conta de cr�dito para exporta��o cont�bil','',True,'3','','','0');
// 22.04.08 - conta de rec./despesa para levar automatico na nf de entrada por enquanto...
  Inst.AddField('ConfMov','Comv_plan_Conta'         ,'N',008,0,060 ,True,'Conta'          ,'C�digo reduzido da conta gerencial','0000',True,'3','','','0');
// 31.07.08
  Inst.AddField('ConfMov','Comv_EditsNota'          ,'C',300,0,250 ,True ,'Campos Nota'           ,'Campos a serem desabilitados na digita��o da nota'                            ,'',False,'','','','1');
  Inst.AddField('ConfMov','Comv_Esto_Codigo'        ,'C',020,0,100 ,True ,'Produto'               ,'Codigo de produto a ser gerado autom�tico na nota de entrada'                ,'',False,'','','','1');
  Inst.AddField('ConfMov','Comv_GeraFiscal'         ,'C',001,0,50  ,True ,'Gera Fiscal'           ,'Gera dados fiscais ou somente financeiro( notas de serv.,etc )'                ,'',False,'','','','1');


  Inst.AddTable('SalMovfin');
  Inst.AddField('SalMovfin','Samf_status'          ,'C',1 ,0,30 ,False,'Status'                  ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('SalMovfin','Samf_mesano'          ,'C',6 ,0,30 ,False,'Mes/ano'                 ,'Mes/ano'                                      ,''    ,False,'2','','','2');
  Inst.AddField('SalMovfin','Samf_unid_codigo'     ,'C',3 ,0,30 ,False,'C�digo'                  ,'C�digo da unidade'                            ,''    ,False,'2','','','2');
  Inst.AddField('SalMovfin','Samf_Plan_Conta'      ,'N',08,0,60 ,False,'Conta'                   ,'C�digo reduzido da conta','0000',False,'3','','','0');
  Inst.AddField('SalMovfin','Samf_saldomov'        ,'N',12,3,70 ,True ,'Saldo Movimento'         ,'Saldo Movimento'                              ,''    ,True ,'1','','','0');
  Inst.AddField('SalMovfin','Samf_saldocont'       ,'N',12,3,70 ,True ,'Saldo Cont�bil'          ,'Saldo Cont�bil'                               ,''    ,True ,'1','','','0');
  Inst.AddField('SalMovfin','Samf_saldoconf'       ,'N',12,3,70 ,True ,'Saldo Extrato'           ,'Saldo Extrato'                                ,''    ,True ,'1','','','0');
  Inst.AddField('SalMovfin','Samf_Usua_Codigo'     ,'N',3 ,0,50 ,False,'Usu�rio'                 ,'Usu�rio respons�vel pelo cadastramento'       ,''    ,False,'3','','','0');

  Inst.AddTable('CotasRepr');
  Inst.AddField('CotasRepr' ,'Core_mesano'          ,'C',6 ,0,30 ,True ,'Mes/ano'                 ,'Mes/ano'                                      ,''    ,False,'2','','','2');
  Inst.AddField('CotasRepr' ,'Core_Repr_Codigo'     ,'N',4 ,0,30 ,True ,'Representante','C�digo do representante','',False,'1','','','0');
  Inst.AddField('CotasRepr' ,'Core_cotames'         ,'N',12,3,70 ,True ,'Cota mensal em valores'  ,'Cota mensal em valores'                       ,''    ,True ,'3','','','0');
  Inst.AddField('CotasRepr' ,'Core_cotapecas'       ,'N',10,3,70 ,True ,'Cota em % de pe�as'    ,'Cota em % de pe�as'                         ,''    ,True ,'3','','','0');

  Inst.AddTable('MovComp');
  Inst.AddField('MovComp','Mocm_Transacao'         ,'C',12 ,0,70  ,True ,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('MovComp','Mocm_Operacao'          ,'C',16 ,0,70  ,True ,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('MovComp','Mocm_numerodoc'         ,'N',8  ,0,90  ,False,'Numero'                    ,'Numero do pedido'                            ,''    ,False,'2','','','2');
  Inst.AddField('MovComp','Mocm_status'            ,'C',1  ,0,30  ,False,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovComp','Mocm_tipomov'           ,'C',2  ,0,30  ,True ,'Tipo'                      ,'Tipo do movimento'                           ,''    ,False,'2','','','2');
  Inst.AddField('MovComp','Mocm_Tabp_Codigo'       ,'N',03,0,30,   True ,'C�digo'                    ,'C�digo da tabela','',False,'1','','','2');
  Inst.AddField('MovComp','Mocm_TabAliquota'       ,'N',07 ,2,40,  true ,'Percentual'                ,'Percentual da tabela','',False,'1','','','2');
  Inst.AddField('MovComp','Mocm_unid_codigo'       ,'C',3  ,0,30  ,True ,'Unidade'                   ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovComp','Mocm_tipo_codigo'       ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do fornecedor'                ,''    ,False,'2','','','0');
  Inst.AddField('MovComp','Mocm_tipocad'           ,'C',1  ,0,30  ,True ,'Tipo cadastro'             ,'Tipo do cadastro'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovComp','Mocm_DataLcto'          ,'D',0  ,0,60  ,True ,'Data Lcto','Data de lan�amento','',True,'1','','','0');
  Inst.AddField('MovComp','Mocm_DataMvto'          ,'D',0  ,0,60  ,True ,'Data Mvto','Data de movimento','',True,'1','','','0');
  Inst.AddField('MovComp','Mocm_DataCont'          ,'D',0  ,0,60  ,True ,'Data Cont','Data cont�bil'     ,'',True,'1','','','0');
  Inst.AddField('MovComp','Mocm_DataEntrega'       ,'D',0  ,0,60  ,True ,'Entrega'  ,'Data entrega'      ,'',True,'1','','','0');
  Inst.AddField('MovComp','Mocm_DataRecebido'      ,'D',0  ,0,60  ,True ,'Recebido' ,'Data recebimento'  ,'',True,'1','','','0');
  Inst.AddField('MovComp','Mocm_Vlrtotal'          ,'N',12 ,3,70  ,True ,'Valor total'               ,'Valor total'                              ,''    ,True  ,'3','','','0');
  Inst.AddField('MovComp','Mocm_Fpgt_Codigo'       ,'C',3  ,0,30  ,True ,'F.Pgto'                     ,'C�digo da forma de pagamento','000',False,'1','','','0');
  Inst.AddField('MovComp','Mocm_Totprod'           ,'N',12 ,3,70  ,True ,'Valor total dos produtos'  ,'Valor total dos produtos'                 ,''    ,True  ,'3','','','0');
  Inst.AddField('MovComp','Mocm_Frete'             ,'N',12 ,3,70  ,True ,'Frete'                     ,'Valor frete'                               ,''    ,True ,'3','','','0');
  Inst.AddField('MovComp','Mocm_FreteCifFob'       ,'C',1  ,0,30  ,True ,'Cif/Fob'                   ,'Cif/Fob'                                   ,''    ,True ,'1','','','0');
  Inst.AddField('MovComp','Mocm_Perdesco'          ,'N',7  ,3,70  ,True ,'% Desconto'                ,'% Desconto'                                ,''    ,True ,'3','','','0');
  Inst.AddField('MovComp','Mocm_Peracres'          ,'N',7  ,3,70  ,True ,'% Acr�scimo'               ,'% Acr�scimo'                               ,''    ,True ,'3','','','0');
  Inst.AddField('MovComp','Mocm_ValorTotal'        ,'N',12 ,3,70  ,True ,'Valor total'               ,'Valor total'                              ,''    ,True  ,'3','','','0');
  Inst.AddField('MovComp','Mocm_Usua_Codigo'       ,'N',3  ,0,50  ,False,'Usu�rio'                   ,'Usu�rio respons�vel'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovComp','Mocm_FormaEntrega'      ,'C',200,0,300 ,True ,'Forma de Entrega'          ,'Forma de entrega'                          ,''    ,False,'3','','','0');
// 10.03.08
  Inst.AddField('MovComp','Mocm_FornecOrcam'       ,'C',200,0,300 ,True ,'Fornecedores'              ,'Fornecedores para or�amento'               ,''    ,False,'3','','','0');
// 11.04.08
  Inst.AddField('MovComp','Mocm_Icms'              ,'N',10 ,5, 70 ,True, 'Icms' ,'Percentual do ICMS na compra',f_aliq,True,'3','','','0');
  Inst.AddField('MovComp','Mocm_Ipi'               ,'N',10 ,5, 70 ,True, 'Ipi' ,'Percentual do IPI na compra',f_aliq,True,'3','','','0');
// 04.08.08
  Inst.AddField('MovComp' ,'Mocm_Requisicoes'      ,'C',300,0,250 ,True ,'Requisi��es'          ,'Requisi��es do almoxarifado usadas','',False,'1','','','0');
  Inst.AddField('MovComp' ,'Mocm_TransReq'         ,'C',500,0,250 ,True ,'Transa��es Req.'      ,'Transa��es das Requisi��es do almoxarifado usadas','',False,'1','','','0');
// 23.06.2022
  Inst.AddField('MovComp' ,'Mocm_obspedido'         ,'C',300,0,200, True, 'Obs. Pedido','Observa��o Pedido'  ,'',False,'1','','','0');


  Inst.AddTable('MovCompras');
  Inst.AddField('MovCompras','Moco_Transacao'         ,'C',12,0,70,True ,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('MovCompras','Moco_Operacao'          ,'C',16,0,70,True ,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('MovCompras','Moco_numerodoc'         ,'N',8 ,0,90,True ,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('MovCompras','Moco_status'            ,'C',1 ,0,30,True ,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovCompras','Moco_tipomov'           ,'C',2 ,0,30,True ,'Tipo'                      ,'Tipo do movimento'                           ,''    ,False,'2','','','2');
  Inst.AddField('MovCompras','Moco_unid_codigo'       ,'C',3  ,0,30  ,True ,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovCompras','Moco_esto_codigo'       ,'C',20 ,0,90  ,True ,'C�digo'                    ,'C�digo do produto'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovCompras','Moco_tama_codigo'       ,'N',5  ,0,30  ,True ,'C�digo'                    ,'C�digo do tamanho'                           ,''    ,False,'2','','','0');
  Inst.AddField('MovCompras','Moco_core_codigo'       ,'N',3  ,0,30  ,True ,'C�digo'                    ,'C�digo da cor'                                ,''    ,False,'2','','','0');
  Inst.AddField('MovCompras','Moco_tipo_codigo'       ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do fornecedor'                ,''    ,False,'2','','','0');
  Inst.AddField('MovCompras','Moco_tipocad'           ,'C',1  ,0,30  ,True ,'Tipo cadastro'             ,'Tipo do cadastro'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovCompras','Moco_Qtde'              ,'N',12 ,3,70  ,True ,'Qtde'                      ,'Qtde pedida'                                 ,''    ,True ,'1','','','0');
  Inst.AddField('MovCompras','Moco_QtdeRecebida'      ,'N',12 ,3,70  ,True ,'Recebida'                  ,'Qtde recebida'                               ,''    ,True ,'1','','','0');
  Inst.AddField('MovCompras','Moco_DataLcto'          ,'D',0  ,0,60  ,True ,'Data Lcto','Data de lan�amento','',True,'1','','','0');
  Inst.AddField('MovCompras','Moco_DataMvto'          ,'D',0  ,0,60  ,True ,'Data Mvto','Data de movimento','',True,'1','','','0');
  Inst.AddField('MovCompras','Moco_DataCont'          ,'D',0  ,0,60  ,True ,'Data Cont','Data cont�bil'     ,'',True,'1','','','0');
//  Inst.AddField('MovCompras','Moco_Unitario'          ,'N',12 ,3,70  ,True ,'Valor unit�rio'            ,'Valor unit�rio'                           ,''    ,True ,'1','','','0');
// 17.02.11 - Abra - robson - para 'fechar os metros lineares'...
  Inst.AddField('MovCompras','Moco_Unitario'          ,'N',13 ,5,70  ,True ,'Valor unit�rio'            ,'Valor unit�rio'                           ,''    ,True ,'1','','','0');
  Inst.AddField('MovCompras','Moco_Grup_codigo'       ,'N',06 ,0,40  ,True ,'C�digo do grupo'           ,'C�digo do grupo'                             ,''    ,False,'1','','','0');
  Inst.AddField('MovCompras','Moco_Sugr_codigo'       ,'N',04 ,0,40  ,True ,'C�digo do subgrupo'        ,'C�digo do subgrupo'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovCompras','Moco_Fami_codigo'       ,'N',04 ,0,40  ,True ,'C�digo'                    ,'C�digo da familia'                        ,''    ,False,'2','','','2');
  Inst.AddField('MovCompras','Moco_Usua_Codigo'       ,'N',3  ,0,50  ,False,'Usu�rio'                   ,'Usu�rio respons�vel'                        ,''    ,False,'3','','','0');
  Inst.AddField('MovCompras','Moco_copa_codigo'       ,'N',3  ,0,30  ,True ,'C�digo'                    ,'C�digo da copa'                                ,''    ,False,'2','','','0');
// 29.08.06
  Inst.AddField('MovCompras' ,'Moco_Seq'               ,'N',04 ,0,70  ,True ,'Sequencial'                ,'Sequencial'                               ,''    ,True ,'1','','','0');
  Inst.AddField('MovCompras' ,'Moco_nfcompra'          ,'N',7  ,0,50  ,True ,'Nota Compra'               ,'Nota Compra'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovCompras' ,'Moco_datanfcompra'      ,'D',8  ,0,50  ,True ,'Data Nota Compra'          ,'Data Nota Compra'                         ,''    ,False,'3','','','0');
  Inst.AddField('MovCompras' ,'Moco_Transacaocompra'   ,'C',12 ,0,70  ,True ,'Transa��o Compra'          ,'N�mero da transa��o','',False,'1','','','0');
// 11.04.08
  Inst.AddField('MovCompras','Moco_cst'               ,'C',05 ,0,30  ,True ,'C�digo da sit. trib.'      ,'C�digo da situa��o tribut�ria.'             ,''    ,False,'1','','','0');
  Inst.AddField('MovCompras','Moco_aliicms'           ,'N',08 ,3,45  ,True ,'% icms'                    ,'% icms'                                      ,f_aliq,True ,'1','','','0');
  Inst.AddField('MovCompras','Moco_aliipi'            ,'N',08 ,3,45  ,True ,'% ipi'                     ,'% ipi'                                       ,f_aliq,True ,'1','','','0');
// 14.04.08
  Inst.AddField('MovCompras','Moco_pecas'             ,'N',12 ,3,45  ,True ,'Pe�as'                     ,'Pe�as'                                       ,'',True ,'3','','','0');
// 16.04.08 - se o produto ser� industrializado ( pintado, etc ) - se nao nao rateia a mao de obra na cobran�a da industrializacao
  Inst.AddField('MovCompras','Moco_industrializa'     ,'C',01 ,0,40  ,True ,'Indust.'               ,'Industrializa'                                     ,'',True ,'1','','','0');

///////////////////////////////////
// 20.06.05
  Inst.AddTable('MensagensNF');
  Inst.AddField('MensagensNF','Mens_codigo'            ,'N',004,0,30 ,False,'C�digo'                    ,'C�digo do produto'                           ,''    ,False,'1','','','2');
//  Inst.AddField('MensagensNF','Mens_Descricao'         ,'C',300,0,250,True ,'Descri��o da mensagem'     ,'Descri��o da mensagem'                             ,''    ,True ,'1','','','1');
// 18.12.07 - 'testes clessi'
  Inst.AddField('MensagensNF','Mens_Descricao'         ,'C',300,0,400,True ,'Descri��o da mensagem'     ,'Descri��o da mensagem'                             ,''    ,True ,'1','','','1');
////////////////////////////////////////
// 12.09.05
  Inst.AddTable('Cadocorrencias');
  Inst.AddField('CadOcorrencias','Caoc_codigo'            ,'N',003,0,30 ,False,'C�digo'                    ,'C�digo do produto'                           ,''    ,False,'1','','','2');
  Inst.AddField('CadOcorrencias','Caoc_Descricao'         ,'C',080,0,250,True ,'Descri��o da ocorr�ncia'   ,'Descri��o da ocorr�ncia'                             ,''    ,True ,'1','','','1');

  Inst.AddTable('Ocorrencias');
  Inst.AddField('Ocorrencias','Ocor_CatEntidade','C',1,0,20,True,'Cat. Entidade','Categoria da entidade','',False,'1','','','0');
  Inst.AddField('Ocorrencias','Ocor_CodEntidade','N',08,0,20,True,'Cod Entidade','C�digo da entidade','',False,'1','','','0');
  Inst.AddField('Ocorrencias','Ocor_Unid_Codigo','C',3,0,30,true,'Unidade','C�digo da unidade','000',false,'1','','','0');
  Inst.AddField('Ocorrencias','Ocor_Data','D',8,0,55,false,'Data','Data da ocorr�ncia','',false,'2','','','0');
  Inst.AddField('Ocorrencias','Ocor_Usuario','N',3,0,50,False,'Usu�rio','C�digo do usu�rio','',False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_Descricao','C',2000,0,40,true,'Ocorr�ncia','Descri��o da ocorr�ncia','', true,'','','','0');
  Inst.AddField('Ocorrencias','Ocor_numerodoc'         ,'N',8 ,0,90,True ,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('Ocorrencias','Ocor_Caoc_Codigo','N',03,0,20,True,'Cod Ocorrencia','C�digo da ocorr�ncia','',False,'1','','','0');
  Inst.AddField('Ocorrencias','Ocor_status'            ,'C',1 ,0,30,True ,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('Ocorrencias','Ocor_tipoocor'           ,'C',2  ,0,30  ,True ,'Tipo'                      ,'Tipo de ocorr�ncia'                           ,''    ,False,'2','','','2');
// 12.02.17  - oftalmo
  Inst.AddField('Ocorrencias','Ocor_odlongeesfe'      ,'N',7  ,2,50  ,True ,'OD Longe Esf.'              ,'Olho Direito Longe Esf�rico'                       ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_odlongecili'      ,'N',7  ,2,50  ,True ,'OD Longe Cil.'              ,'Olho Direito Longe Cilindrinco'                    ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_odlongeeixo'      ,'N',5  ,0,50  ,True ,'OD Longe Eixo'              ,'Olho Direito Longe Eixo'                           ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_oelongeesfe'      ,'N',7  ,2,50  ,True ,'OE Longe Esf.'              ,'Olho Esquerdo Longe Esf�rico'                      ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_oelongecili'      ,'N',7  ,2,50  ,True ,'OE Longe Cil.'              ,'Olho Esquerdo Longe Cilindrinco'                   ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_oelongeeixo'      ,'N',5  ,0,50  ,True ,'OE Longe Eixo'              ,'Olho Esquerdo Longe Eixo'                          ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_odpertoesfe'      ,'N',7  ,2,50  ,True ,'OD Perto Esf.'              ,'Olho Direito Perto Esf�rico'                       ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_odpertocili'      ,'N',7  ,2,50  ,True ,'OD Perto Cil.'              ,'Olho Direito Perto Cilindrinco'                    ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_odpertoeixo'      ,'N',5  ,0,50  ,True ,'OD Perto Eixo'              ,'Olho Direito Perto Eixo'                           ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_oepertoesfe'      ,'N',7  ,2,50  ,True ,'OE Perto Esf.'              ,'Olho Esquerdo Perto Esf�rico'                      ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_oepertocili'      ,'N',7  ,2,50  ,True ,'OE Perto Cil.'              ,'Olho Esquerdo Perto Cilindrinco'                   ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_oepertoeixo'      ,'N',5  ,0,50  ,True ,'OE Perto Eixo'              ,'Olho Esquerdo Perto Eixo'                          ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_dplonge'          ,'N',5  ,0,50  ,True ,'DP Longe'                   ,'D.P. Longe'                          ,''    ,False,'3','','','0');
  Inst.AddField('Ocorrencias','Ocor_dpperto'          ,'N',5  ,0,50  ,True ,'DP Perto'                   ,'D.P. Perto'                          ,''    ,False,'3','','','0');

  Inst.AddTable('Movped');
  Inst.AddField('Movped' ,'Mped_Transacao'         ,'C',12 ,0,70  ,False,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('Movped' ,'Mped_Operacao'          ,'C',16 ,0,70  ,False,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('Movped' ,'Mped_numerodoc'         ,'N',8  ,0,90  ,True ,'Pedido'                    ,'Numero do pedido'                            ,''    ,False,'2','','','2');
  Inst.AddField('Movped' ,'Mped_pedcliente'        ,'N',8  ,0,90  ,True ,'Pedido cliente'            ,'Numero do pedido cliente'                    ,''    ,False,'2','','','2');
  Inst.AddField('Movped' ,'Mped_status'            ,'C',1  ,0,30  ,False,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('Movped' ,'Mped_tipomov'           ,'C',2  ,0,30  ,True ,'Tipo'                      ,'Tipo do movimento'                           ,''    ,False,'2','','','2');
// se e venda direta, venda "consignada", compra, devolu��o, etc
  Inst.AddField('MovPed' ,'Mped_Tabp_Codigo'       ,'N',03,0,30,   True ,'C�digo'                    ,'C�digo da tabela','',False,'1','','','2');
  Inst.AddField('Movped' ,'Mped_TabAliquota'       ,'N',07 ,2,40,  true ,'Percentual'                ,'Percentual da tabela','',False,'1','','','2');
  Inst.AddField('MovPed' ,'Mped_unid_codigo'       ,'C',3  ,0,30  ,True ,'Unidade'                   ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('Movped' ,'Mped_tipo_codigo'       ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente'                ,''    ,False,'2','','','0');
  Inst.AddField('Movped' ,'Mped_estado'            ,'C',2  ,0,30  ,True ,'Estado'                    ,'Unidade da Federa��o'                        ,''    ,False,'2','','','0');
  Inst.AddField('Movped' ,'Mped_Cida_Codigo'       ,'N',5  ,0,80  ,True ,'C�d. Cidade'               ,'C�digo da cidade'                           ,''       ,False,'3','','','0');
// codigo de cliente, fornecedor, etc
  Inst.AddField('Movped' ,'Mped_repr_codigo'       ,'N',4  ,0,90  ,True ,'C�digo'                    ,'C�digo do representante'                   ,''    ,False,'2','','','0');
  Inst.AddField('Movped' ,'Mped_tipocad'           ,'C',1  ,0,30  ,True ,'Tipo cadastro'             ,'Tipo do cadastro'                            ,''    ,False,'2','','','0');
  Inst.AddField('Movped' ,'Mped_DataLcto'          ,'D',0  ,0,60  ,True ,'Data Lcto','Data de lan�amento','',True,'1','','','0');
  Inst.AddField('Movped' ,'Mped_DataMvto'          ,'D',0  ,0,60  ,True ,'Data Mvto','Data de movimento','',True,'1','','','0');
  Inst.AddField('Movped' ,'Mped_DataEmissao'       ,'D',0  ,0,60  ,True ,'Emiss�o'  ,'Data de emiss�o'  ,'',True,'1','','','0');
  Inst.AddField('Movped' ,'Mped_DataCont'          ,'D',0  ,0,60  ,True ,'Data Cont','Data cont�bil'     ,'',True,'1','','','0');
  Inst.AddField('Movped' ,'Mped_Vlrtotal'          ,'N',12 ,3,70  ,True ,'Valor total'               ,'Valor total'                              ,''    ,True  ,'3','','','0');
  Inst.AddField('Movped' ,'Mped_Totprod'           ,'N',12 ,3,70  ,True ,'Valor total dos produtos'  ,'Valor total dos produtos'                 ,''    ,True  ,'3','','','0');
  Inst.AddField('Movped' ,'Mped_vispra'            ,'C',1  ,0,10  ,True ,'A vista/prazo'             ,'V - a vista  P - a prazo'                  ,''    ,False,'1','','','0');
  Inst.AddField('Movped' ,'Mped_Perdesco'          ,'N',10 ,2,70  ,True ,'Desconto'                  ,'Desconto'                                ,''    ,True ,'3','','','0');
  Inst.AddField('Movped' ,'Mped_Peracres'          ,'N',10 ,2,70  ,True ,'Acr�scimo'                 ,'Acr�scimo'                               ,''    ,True ,'3','','','0');
  Inst.AddField('Movped' ,'Mped_ValoraVista'       ,'N',12 ,2,70  ,True ,'Valor a Vista'             ,'Valor a Vista'                            ,''    ,True  ,'3','','','0');
  Inst.AddField('Movped' ,'Mped_Usua_Codigo'       ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio respons�vel'                       ,''    ,False,'3','','','0');
//  Inst.AddField('Movped' ,'Mped_obs'               ,'C',200,0,150 ,True  ,'Mensagem'                 ,'Mensagem do documento'                     ,''    ,True ,'0','','','0');
// usar nas ocorrencias
  Inst.AddField('Movped' ,'Mped_situacao'          ,'C',1  ,0,30   ,True ,'Situa��o'                  ,'Situa��o do pedido'                          ,''    ,False,'2','','','2');
  Inst.AddField('Movped' ,'Mped_Fpgt_Codigo','C',3,0,30,True,'F.Pgto','C�digo da forma de pagamento','000',False,'1','','','0');
// pedido feito por telefone, fax, email.
  Inst.AddField('Movped' ,'Mped_formaped'          ,'C',1  ,0,30  ,True ,'Forma pedido'              ,'Forma pedido'                                ,''    ,False,'2','','','2');
  Inst.AddField('Movped' ,'Mped_envio'             ,'C',1  ,0,30  ,True ,'Forma envio'               ,'Forma envio'                                 ,''    ,False,'2','','','2');
  Inst.AddField('Movped' ,'Mped_Usua_autoriza'     ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio financeiro'                        ,''    ,False,'3','','','0');
  Inst.AddField('Movped' ,'Mped_DataAutoriza'      ,'D',0  ,0,60  ,True ,'Autoriza��o'  ,'Data autoriza��o'  ,'',True,'1','','','0');
  Inst.AddField('Movped' ,'Mped_fpgt_prazos'       ,'C',50 ,0,200 ,True ,'Descri��o Pagamentos'      ,'Descri��o Pagamentos'                                 ,''    ,False,'0','','','2');
  Inst.AddField('Movped' ,'Mped_contatopedido'     ,'C',50 ,0,150 ,True ,'Contato pedido'            ,'Quem fez o pedido'                                ,''    ,False,'2','','','2');
// 08.12.05
  Inst.AddField('Movped' ,'Mped_datapedcli'        ,'D',8  ,0,90  ,True ,'Data Pedido cliente'       ,'Data do pedido cliente'                    ,''    ,False,'2','','','2');
// 14.12.05
  Inst.AddField('Movped' ,'Mped_Usua_Cancela'      ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio Cancelamento'                        ,''    ,False,'3','','','0');
// 22.02.06
  Inst.AddField('Movped' ,'Mped_nftrans'           ,'N',7  ,0,50  ,True ,'Nota Transfer�ncia'        ,'Nota Transfer�ncia'                        ,''    ,False,'3','','','0');
  Inst.AddField('Movped' ,'Mped_datanftrans'       ,'D',8  ,0,50  ,True ,'Data Nota Transfer�ncia'   ,'Data Nota Transfer�ncia'                        ,''    ,False,'3','','','0');
  Inst.AddField('Movped' ,'Mped_nfvenda'           ,'N',7  ,0,50  ,True ,'Nota Venda'                ,'Nota Venda'                        ,''    ,False,'3','','','0');
  Inst.AddField('Movped' ,'Mped_datanfvenda'       ,'D',8  ,0,50  ,True ,'Data Nota Venda'           ,'Data Nota Venda'                          ,''    ,False,'3','','','0');
  Inst.AddField('Movped' ,'Mped_Transacaovenda'    ,'C',12 ,0,70  ,True ,'Transa��o Venda','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('Movped' ,'Mped_Transacaonftrans'  ,'C',12 ,0,70  ,True ,'Transa��o Transf.','N�mero da transa��o','',False,'3','','','0');
// 17.04.06
  Inst.AddField('movped' ,'Mped_obslibcredito'     ,'C',200,0,200, True, 'Obs. lib. cr�dito','Obs. lib. cr�dito'  ,'',False,'1','','','0');
  Inst.AddField('movped' ,'Mped_datalibcredito'    ,'D',008,0,030, True, 'Data lib. cr�dito','Data lib. cr�dito'  ,'',False,'1','','','0');
  Inst.AddField('movped' ,'Mped_usualibcred'       ,'N',003,0,030, True, 'Usu�rio lib. cr�dito','Usu�rio lib. cr�dito'  ,'',False,'1','','','0');
// 01.04.09
  Inst.AddField('movped' ,'Mped_obspedido'         ,'C',300,0,200, True, 'Obs. Pedido','Observa��o Pedido'  ,'',False,'1','','','0');
// 01.06.11- Novicarnes
  Inst.AddField('movped' ,'Mped_Port_Codigo'       ,'C',003,0,050, True,'Portador','C�digo do portador','000',False,'1','','','0');
// 13.03.18- Novicarnes
  Inst.AddField('movped' ,'Mped_ordem'             ,'N',004,0,050, True,'Ordem','Ordem de Carregamento','0000',False,'3','','','0');
// 06.02.19 - Seip
  Inst.AddField('Movped' ,'Mped_Vlrcomissao'       ,'N',12 ,2,70  ,True ,'Valor comiss�o'             ,'Valor comiss�o'                            ,''    ,True  ,'3','','','0');
  Inst.AddField('Movped' ,'Mped_Percomissao'       ,'N',08 ,3,70  ,True ,'% comiss�o'             ,'Percentual comiss�o'                            ,''    ,True  ,'3','','','0');


  Inst.AddTable('Movpeddet');
  Inst.AddField('Movpeddet','Mpdd_Transacao'         ,'C',12,0,70,False,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('Movpeddet','Mpdd_Operacao'          ,'C',16,0,70,False,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('Movpeddet','Mpdd_numerodoc'         ,'N',8 ,0,90,False,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('Movpeddet','Mpdd_status'            ,'C',1 ,0,30,False,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('Movpeddet','Mpdd_situacao'          ,'C',1  ,0,30   ,True ,'Situa��o'               ,'Situa��o do item'                            ,''    ,False,'2','','','2');
  Inst.AddField('Movpeddet','Mpdd_tipomov'           ,'C',2 ,0,30,False,'Tipo'                      ,'Tipo do movimento'                           ,''    ,False,'2','','','2');
  Inst.AddField('Movpeddet','Mpdd_unid_codigo'       ,'C',3  ,0,30  ,False,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('Movpeddet','Mpdd_esto_codigo'       ,'C',20 ,0,90  ,False,'C�digo'                    ,'C�digo do produto'                            ,''    ,False,'2','','','0');
  Inst.AddField('Movpeddet','Mpdd_tama_codigo'       ,'N',5  ,0,30  ,True ,'C�digo'                    ,'C�digo do tamanho'                           ,''    ,False,'2','','','0');
  Inst.AddField('Movpeddet','Mpdd_core_codigo'       ,'N',3  ,0,30  ,True ,'C�digo'                    ,'C�digo da cor'                                ,''    ,False,'2','','','0');
  Inst.AddField('Movpeddet','Mpdd_tipo_codigo'       ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/fornecedor'                ,''    ,False,'2','','','0');
  Inst.AddField('Movpeddet','Mpdd_tipocad'           ,'C',1  ,0,30  ,True ,'Tipo cadastro'             ,'Tipo do cadastro'                            ,''    ,False,'2','','','0');
  Inst.AddField('Movpeddet','Mpdd_repr_codigo'       ,'N',4  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/representante'             ,''    ,False,'2','','','2');
  Inst.AddField('Movpeddet','Mpdd_Qtde'              ,'N',12 ,3,70  ,True ,'Qtde'                      ,'Qtde em movimento'                           ,''    ,True ,'1','','','0');
  Inst.AddField('Movpeddet','Mpdd_DataLcto'          ,'D',0  ,0,60  ,False,'Data Lcto','Data de lan�amento','',True,'1','','','0');
  Inst.AddField('Movpeddet','Mpdd_DataMvto'          ,'D',0  ,0,60  ,True ,'Data Mvto','Data de movimento','',True,'1','','','0');
  Inst.AddField('Movpeddet','Mpdd_DataCont'          ,'D',0  ,0,60  ,True ,'Data Cont','Data cont�bil'     ,'',True,'1','','','0');
  Inst.AddField('Movpeddet','Mpdd_QtdeEnviada'       ,'N',12 ,3,70  ,True ,'Qtde enviada'              ,'Qtde enviada'                                ,''    ,True ,'1','','','0');
  Inst.AddField('Movpeddet','Mpdd_DataEnviada'       ,'D',0  ,0,60  ,True ,'Data Saida','Data Saida'     ,'',True,'1','','','0');
  Inst.AddField('Movpeddet','Mpdd_Venda'             ,'N',12 ,3,70  ,True ,'Pre�o de venda'            ,'Pre�o de venda'                           ,''    ,True ,'1','','','0');
  Inst.AddField('Movpeddet','Mpdd_Grup_codigo'       ,'N',06 ,0,40  ,True ,'C�digo do grupo'           ,'C�digo do grupo'                             ,''    ,False,'1','','','0');
  Inst.AddField('Movpeddet','Mpdd_Sugr_codigo'       ,'N',04 ,0,40  ,True ,'C�digo do subgrupo'        ,'C�digo do subgrupo'                          ,''    ,False,'1','','','0');
  Inst.AddField('Movpeddet','Mpdd_Fami_codigo'       ,'N',04 ,0,40  ,True ,'C�digo'                    ,'C�digo da familia'                        ,''    ,False,'2','','','2');
  Inst.AddField('Movpeddet','Mpdd_Mate_codigo'       ,'N',04 ,0,40  ,True ,'Material'                  ,'C�digo do material predominante'             ,''    ,False,'','','','');
  Inst.AddField('Movpeddet','Mpdd_Emlinha'           ,'C',01 ,0,40  ,True ,'Em linha'                  ,'Em linha'                                    ,''    ,False,'0','','','0');
  Inst.AddField('Movpeddet','Mpdd_Usua_Codigo'       ,'N',3  ,0,50  ,False,'Usu�rio'                   ,'Usu�rio respons�vel'                        ,''    ,False,'3','','','0');
  Inst.AddField('Movpeddet','Mpdd_Vendabru'          ,'N',12 ,3,70  ,True ,'Pre�o de venda bruto'      ,'Pre�o de venda bruto'                     ,''    ,True ,'1','','','0');
  Inst.AddField('Movpeddet','Mpdd_Perdesco'          ,'N',07 ,3,70  ,True ,'% de desconto'             ,'% de desconto'                            ,''    ,True ,'1','','','0');
// confirma aqui ou por pedido - motivo do 'n�o atendimento' do pedido
  Inst.AddField('Movpeddet','Mpdd_Caoc_Codigo','N',03,0,20,True,'Cod Ocorrencia','C�digo da ocorr�ncia','',False,'1','','','0');
// 09.11.05
  Inst.AddField('Movpeddet','Mpdd_Seq'               ,'N',04 ,0,70  ,True ,'Sequencial'                ,'Sequencial'                               ,''    ,True ,'1','','','0');
// 09.12.05
  Inst.AddField('Movpeddet','Mpdd_DataMontagem'      ,'D',0  ,0,60  ,True ,'Data Montagem','Data Montagem','',True,'1','','','0');
  Inst.AddField('Movpeddet','Mpdd_DataPrevista'      ,'D',0  ,0,60  ,True ,'Data Prevista','Data Prevista','',True,'1','','','0');
// 14.12.05
  Inst.AddField('Movpeddet','Mpdd_Usua_Cancela'       ,'N',3  ,0,50 ,True ,'Usu�rio'                   ,'Usu�rio Cancelamento'                        ,''    ,False,'3','','','0');
// 22.02.06
  Inst.AddField('Movpeddet' ,'Mpdd_nftrans'           ,'N',7  ,0,50  ,True ,'Nota Transfer�ncia'        ,'Nota Transfer�ncia'                        ,''    ,False,'3','','','0');
  Inst.AddField('Movpeddet' ,'Mpdd_datanftrans'       ,'D',8  ,0,50  ,True ,'Data Nota Transfer�ncia'   ,'Data Nota Transfer�ncia'                        ,''    ,False,'3','','','0');
  Inst.AddField('Movpeddet' ,'Mpdd_nfvenda'           ,'N',7  ,0,50  ,True ,'Nota Venda'                ,'Nota Venda'                        ,''    ,False,'3','','','0');
  Inst.AddField('Movpeddet' ,'Mpdd_datanfvenda'       ,'D',8  ,0,50  ,True ,'Data Nota Venda'           ,'Data Nota Venda'                          ,''    ,False,'3','','','0');
  Inst.AddField('Movpeddet' ,'Mpdd_Transacaovenda'    ,'C',12 ,0,70  ,True ,'Transa��o Venda','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('Movpeddet' ,'Mpdd_Transacaonftrans'  ,'C',12 ,0,70  ,True ,'Transa��o Transf.','N�mero da transa��o','',False,'3','','','0');
// 05.05.06
  Inst.AddField('Movpeddet' ,'Mpdd_copa_codigo'       ,'N',3  ,0,30   ,True ,'Copa'                      ,'C�digo da copa'                               ,''    ,False,'2','','','0');
// 24.01.07
  Inst.AddField('Movpeddet' ,'Mpdd_pacotes'           ,'N',5  ,0,40   ,True ,'Pacotes'                   ,'N�mero de Pacotes'                            ,''    ,False,'2','','','0');
  Inst.AddField('Movpeddet' ,'Mpdd_fardos'            ,'N',5  ,0,40   ,True ,'Fardos'                    ,'N�mero de Fardos'                             ,''    ,False,'2','','','0');
  Inst.AddField('Movpeddet' ,'Mpdd_cubagem'           ,'N',12 ,3,60   ,True ,'Cubagem'                   ,'Metros c�bicos'                               ,''    ,False,'2','','','0');
  Inst.AddField('Movpeddet' ,'Mpdd_qualidade'         ,'C',30 ,0,100  ,True ,'Qualidade'                 ,'Qualidade'                                    ,''    ,False,'2','','','0');
  Inst.AddField('Movpeddet' ,'Mpdd_perdescre'         ,'N',06 ,2,40   ,True ,'Desc.Cubagem'              ,'Desc.Cubagem'                                 ,''    ,False,'2','','','0');
// 01.06.11
  Inst.AddField('Movpeddet' ,'Mpdd_Pecas'             ,'N',12 ,3,70   ,True ,'Pe�as'                     ,'Pe�as'                                        ,''    ,True ,'3','','','0');
// 21.02.20  - Guiben
  Inst.AddField('Movpeddet' ,'Mpdd_esto_descricao'    ,'C',100 ,0,270   ,True ,'Descri��o do item'                     ,'Pe�as'                                        ,''    ,True ,'1','','','0');

// 06.12.05
  Inst.AddTable('Movpesquisas');
  Inst.AddField('Movpesquisas' ,'Mpes_status'       ,'C',1  ,0,30  ,True ,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('Movpesquisas' ,'Mpes_Seq'          ,'C',12 ,0,70  ,True,'Sequencial','Sequencial','',False,'3','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_tipo_codigo'  ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/fornecedor'                ,''    ,False,'2','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_tipocad'      ,'C',1  ,0,30  ,True ,'Tipo cadastro'             ,'Tipo do cadastro'                            ,''    ,False,'2','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_DataLcto'     ,'D',0  ,0,60  ,True ,'Data Lcto','Data de lan�amento','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_DataMvto'     ,'D',0  ,0,60  ,True ,'Data Movto','Data de movimento','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_pergunta1'    ,'C',200,0,60  ,True ,''               ,'','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_resposta1'    ,'C',1  ,0,60  ,True  ,''             ,'','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_obs1'         ,'C',200,0,60  ,True  ,''             ,'','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_pergunta2'    ,'C',200,0,60  ,True  ,''             ,'','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_resposta2'    ,'C',1  ,0,60  ,True  ,''            ,'','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_obs2'         ,'C',200,0,60  ,True  ,''             ,'','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_pergunta3'    ,'C',200,0,60  ,True  ,''             ,'','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_resposta3'    ,'C',1  ,0,60  ,True  ,''            ,'','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_obs3'         ,'C',200,0,60  ,True  ,''             ,'','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_pergunta4'    ,'C',200,0,60  ,True  ,''             ,'','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_resposta4'    ,'C',1  ,0,60  ,True  ,''            ,'','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_obs4'         ,'C',200,0,60  ,True  ,''             ,'','',True,'1','','','0');
  Inst.AddField('Movpesquisas' ,'Mpes_Usua_Codigo'  ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio respons�vel'                       ,''    ,False,'3','','','0');

////////////////////////////////////////////////////////////////
// 11.04.06
  Inst.AddTable('Conpedidos');
  Inst.AddField('Conpedidos'	 ,'conp_sequencial'    ,'C',012,0, 80,True ,'Sequencial'             ,'Sequencial'                       ,''    ,False,'1','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_status'        ,'C',001,0, 30,True ,'Status'                 ,'Status'                          ,''    ,False,'1','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_repr_codigo'   ,'N',004,0, 50,True ,'Codigo Repr.'           ,'Codigo representante'             ,''    ,False,'3','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_tipo_codigo'   ,'N',007,0, 60,True ,'Cliente'                ,'Cliente'                       ,''    ,False,'3','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_datalcto'      ,'D',008,0, 70,True ,'Lan�amento'             ,'Data lan�amento'                  ,''    ,False,'1','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_datamvto'      ,'D',008,0, 70,True ,'Data Mvto'              ,'Data do movimento'                ,''    ,False,'1','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_dataentrega'   ,'D',008,0, 70,True ,'Data Entrega'           ,'Data de entrega'                ,''    ,False,'1','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_dataatend'     ,'D',008,0, 70,True ,'Atendimento'            ,'Data de atendimento'               ,''    ,False,'1','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_qtdesolic'     ,'N',011,3, 70,True ,'Solicitada'             ,'Quantidade solicitada'             ,''    ,False,'3','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_qtdeliber'     ,'N',011,3, 70,True ,'Liberada'               ,'Quantidade liberada'               ,''    ,False,'3','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_mediamesant'   ,'N',011,3, 70,True ,'Media mes'              ,'Media mes anterior'                ,''    ,False,'3','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_mediatrimestre','N',011,3, 70,True ,'Media trimestre'        ,'Media trimestre anterior'                ,''    ,False,'3','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_tiposmedia'    ,'C',100,0,200,True ,'Tipos M�dia'            ,'Tipos M�dia'                        ,''    ,False,'1','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_obs'           ,'C',200,0,200,True ,'Observa��es'            ,'Observa��es'                        ,''    ,False,'1','','','0');
  Inst.AddField('Conpedidos'	 ,'conp_complemento'   ,'C',001,0,030,True ,'Complemento'            ,'Complemento'                        ,''    ,False,'1','','','0');
// 26.04.06
  Inst.AddField('Conpedidos'   ,'conp_obslibcredito'  ,'C',200,0,200, True, 'Obs. lib. cr�dito','Obs. lib. cr�dito'  ,'',False,'1','','','0');
  Inst.AddField('Conpedidos'   ,'conp_datalibcredito' ,'D',008,0,030, True, 'Data lib. cr�dito','Data lib. cr�dito'  ,'',False,'1','','','0');
  Inst.AddField('Conpedidos'   ,'conp_usualibcred'    ,'N',003,0,030, True, 'Usu�rio lib. cr�dito','Usu�rio lib. cr�dito'  ,'',False,'1','','','0');

////////////////////
// 05.05.06
  Inst.AddTable('Copas');
  Inst.AddField('Copas','Copa_codigo'            ,'N',03,0,40 ,False,'C�digo da copa'      ,'C�digo da copa'                        ,''    ,False,'2','','','2');
  Inst.AddField('Copas','Copa_reduzido'          ,'C',02,0,60 ,True ,'Forma reduzida'      ,'Forma reduzida'                       ,''    ,False,'1','','','');
  Inst.AddField('Copas','Copa_descricao'         ,'C',50,0,250,True ,'Descri��o da copa'   ,'Descri��o da copa'                     ,''    ,False,'1','','','2');

// 02.06.06
///////////////////////////////////
  Inst.AddTable('Custos');
  Inst.AddField('Custos'     ,'Cust_status'            ,'C', 1 ,0, 30 ,True ,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('Custos'     ,'Cust_esto_codigo'       ,'C',20 ,0, 90 ,True ,'C�digo'                    ,'C�digo do produto'                            ,''    ,False,'2','','','0');
  Inst.AddField('Custos'     ,'Cust_tama_codigo'       ,'N',5  ,0, 30 ,True ,'C�digo'                    ,'C�digo do tamanho'                           ,''    ,False,'2','','','0');
  Inst.AddField('Custos'     ,'Cust_core_codigo'       ,'N',3  ,0, 30 ,True ,'C�digo'                    ,'C�digo da cor'                                ,''    ,False,'2','','','0');
  Inst.AddField('Custos'     ,'Cust_Copa_codigo'       ,'N',03 ,0 ,40 ,True ,'C�digo da copa'            ,'C�digo da copa'                        ,''    ,False,'2','','','2');
  Inst.AddField('Custos'     ,'Cust_esto_codigomat'    ,'C',20 ,0, 90 ,True ,'C�digo'                    ,'C�digo do material'                            ,''    ,False,'2','','','0');
  Inst.AddField('Custos'     ,'Cust_tama_codigomat'    ,'N',5  ,0, 30 ,True ,'C�digo'                    ,'C�digo do tamanho do material'               ,''    ,False,'2','','','0');
  Inst.AddField('Custos'     ,'Cust_core_codigomat'    ,'N',3  ,0, 30 ,True ,'C�digo'                    ,'C�digo da cor do material'                   ,''    ,False,'2','','','0');
  Inst.AddField('Custos'     ,'Cust_Qtde'              ,'N',12 ,5 ,70 ,True ,'Qtde'                      ,'Qtde da composi��o'                          ,''    ,True ,'1','','','0');
  Inst.AddField('Custos'     ,'Cust_Usua_Codigo'       ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio respons�vel'                       ,''    ,False,'3','','','0');
// 29.08.07
  Inst.AddField('Custos'     ,'Cust_PerQtde'           ,'N',12 ,5 ,70 ,True ,'% Qtde'                    ,'% da Qtde na composi��o'                          ,''    ,True ,'3','','','0');
  Inst.AddField('Custos'     ,'Cust_PerCusto'          ,'N',12 ,5 ,70 ,True ,'% Custo'                   ,'% do Custo na composi��o'                          ,''    ,True ,'3','','','0');
// 17.08.09
  Inst.AddField('Custos'     ,'Cust_Tipo'              ,'C',1  ,0 ,70 ,True ,'Tipo'                      ,'Tipo de composi��o(onde ser� usada)'                          ,''    ,True ,'3','','','0');
// 05.04.18
  Inst.AddField('Custos'     ,'Cust_ordem'             ,'N',3  ,0 ,70 ,True ,'Ordem'                     ,'Ordem para efetuar os processos na produ��o'                          ,''    ,True ,'3','','','0');
  Inst.AddField('Custos'     ,'Cust_cadm_codigo'       ,'N',5  ,0 ,70 ,True ,'Processo'                  ,'Codigo do processo de produ��o'                          ,''    ,True ,'3','','','0');
  Inst.AddField('Custos'     ,'Cust_temperatura'       ,'N',5  ,0 ,70 ,True ,'Temperatura'               ,'Temperatura ideal para efetuar o processo na produ��o'                          ,''    ,True ,'3','','','0');
  Inst.AddField('Custos'     ,'Cust_tempo'             ,'N',5  ,0 ,70 ,True ,'Tempo'                     ,'Tempo ideal de dura��o do processo de produ��o'                          ,''    ,True ,'3','','','0');

// 13.07.06
  Inst.AddTable('Codigosipi');
  Inst.AddField('Codigosipi','Cipi_Codigo'   ,'N',004,0,040,False ,'C�digo','C�digo para ipi','',False,'1','','','2');
  Inst.AddField('Codigosipi','Cipi_Descricao','C',050,0,200,True ,'Descri��o','Descri��o','',False,'1','','','0');
  Inst.AddField('Codigosipi','Cipi_CodFiscal','C',030,0,100,True ,'NCM(Classif. Fiscal)','Classif. Fiscal','',False,'1','','','0');
  Inst.AddField('Codigosipi','Cipi_Aliquota' ,'N',007,3,070,True ,'Al�quota','Percentual da al�quota do ipi','##0.000%',False,'3','','','0');
// 18.03.10
  Inst.AddField('Codigosipi','Cipi_Fabricap' ,'C',001,0,070,True ,'Pr�prio','Se � de fabrica��o pr�pria','',False,'3','','','0');
// 25.01.11
  Inst.AddField('Codigosipi','cipi_cst'      ,'C',003,0,070,True ,'CST Ipi','Situa��o Tribut�ria ref. IPI para saidas','',False,'1','','','0');
// 23.04.12
  Inst.AddField('Codigosipi','cipi_cstent'   ,'C',003,0,070,True ,'CST Ipi','Situa��o Tribut�ria ref. IPI para entradas','',False,'1','','','0');
// 25.03.16
  Inst.AddField('Codigosipi','Cipi_Cest'     ,'C',030,0,100,True ,'CEST','CEST','',False,'1','','','0');
// 19.08.16
  Inst.AddField('Codigosipi','Cipi_cstpis'    ,'C',05,0,30 ,True,'CST Pis'    ,'C�digo da situa��o tribut�ria para o PIS nas entradas'             ,''    ,False,'1','','','0');
  Inst.AddField('Codigosipi','Cipi_cstcofins' ,'C',05,0,30 ,True,'CST Cofins' ,'C�digo da situa��o tribut�ria para o COFINS nas entradas'             ,''    ,False,'1','','','0');
  Inst.AddField('Codigosipi','Cipi_PisE'      ,'N',07,3,70,True,'% Pis'       ,'Percentual para c�lculo do pis nas entradas'  ,'',False,'3','','','0');
  Inst.AddField('Codigosipi','Cipi_CofinsE'   ,'N',07,3,70,True,'% Cofins'    ,'Percentual para c�lculo do cofins nas entradas'  ,'',False,'3','','','0');
// 13.05.19 - ja devia ter criado este campo para uso na importacao porem 'esqueci'...
  Inst.AddField('Codigosipi','Cipi_AliII'     ,'N',007,3,070,True ,'% II','Percentual do Imposto de IMporta��o','##0.000%',False,'3','','','0');
// 19.02.20
  Inst.AddField('Codigosipi','Cipi_Cbenef'    ,'C',010,0,070,True ,'Ben.Fiscal','Codigo benef�cio fiscal','',False,'1','','','0');
// 24.03.2021
  Inst.AddField('Codigosipi','Cipi_mva'      ,'N',007,03,070,True ,'MVA','% de Margem de Valor Agregado','',False,'1','','','0');
  Inst.AddField('Codigosipi','Cipi_mvas'     ,'N',007,03,070,True ,'MVA Simples','% de MVA para empresas do SIMPLES','',False,'1','','','0');

 /////////////

// 16.09.06
  Inst.AddTable('Emitentes');
  Inst.AddField('Emitentes','Emit_Banco'     ,'C',003,0,060,True ,'Banco'  ,'C�digo do banco da conta','',False,'1','','','0');
  Inst.AddField('Emitentes','Emit_Agencia'   ,'N',010,0,080,True ,'Ag�ncia','Ag�ncia Banc�ria'       ,'',False,'3','','','1');
  Inst.AddField('Emitentes','Emit_Conta'     ,'N',015,0,100,True ,'Conta'  ,'Conta Corrente'         ,'',False,'3','','','1');
  Inst.AddField('Emitentes','Emit_Descricao' ,'C',100,0,300,True ,'Descri��o Da Conta','Descri��o da conta corrente','',True,'1','','','1');
// 03.10.08
  Inst.AddField('Emitentes','Emit_Cheq_CNPJCPF'        ,'C',14 ,0,110,True ,'CNPJ/CPF'               ,'CNPJ/CPf do emitente'                                           ,''       ,True ,'1','','','1');

// 02.05.07
///////////////////////////////////
  Inst.AddTable('Baixaesto');
  Inst.AddField('Baixaesto'     ,'Bxes_status'            ,'C', 1 ,0, 30 ,True ,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('Baixaesto'     ,'Bxes_esto_codigo'       ,'C',20 ,0, 90 ,True ,'C�digo'                    ,'C�digo do produto'                            ,''    ,False,'2','','','0');
  Inst.AddField('Baixaesto'     ,'Bxes_esto_codigobai'    ,'C',20 ,0, 90 ,True ,'C�digo'                    ,'C�digo a ser baixado'                                ,''    ,False,'2','','','0');
  Inst.AddField('Baixaesto'     ,'Bxes_Perc'              ,'N',12 ,5 ,70 ,True ,'Perc'                      ,'Perc da composi��o'                          ,''    ,True ,'1','','','0');
  Inst.AddField('Baixaesto'     ,'Bxes_Usua_Codigo'       ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio respons�vel'                       ,''    ,False,'3','','','0');

// 05.09.07
  Inst.AddTable('MovAbate');
  Inst.AddField('MovAbate','Mova_Transacao'         ,'C',12,0,70,False,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('MovAbate','Mova_Operacao'          ,'C',16,0,70,False,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('MovAbate','Mova_numerodoc'         ,'N',8 ,0,90,True,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('MovAbate','Mova_status'            ,'C',1 ,0,30,True,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovAbate','Mova_tipomov'           ,'C',2 ,0,30,True,'Tipo'                      ,'Tipo do movimento'                           ,''    ,False,'2','','','2');
  Inst.AddField('MovAbate','Mova_unid_codigo'       ,'C',3 ,0,30  ,False,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovAbate','Mova_datalcto'          ,'D',008,0, 70,True ,'Lan�amento'               ,'Data lan�amento'                  ,''    ,False,'1','','','0');
  Inst.AddField('MovAbate','Mova_dtcarrega'         ,'D',008,0, 70,True ,'Carregamento'             ,'Data Carregamento'                  ,''    ,False,'1','','','0');
  Inst.AddField('MovAbate','Mova_dtabate'           ,'D',008,0, 70,True ,'Abate'                    ,'Data do Abate'                  ,''    ,False,'1','','','0');
  Inst.AddField('MovAbate','Mova_dtvenci'           ,'D',008,0, 70,True ,'Vencimento'               ,'Data do Vencimento'                  ,''    ,False,'1','','','0');
  Inst.AddField('MovAbate','Mova_Usua_Codigo'       ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio respons�vel'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovAbate','Mova_NotaGerada'        ,'N',8 ,0,90,True,'Numero'                    ,'Numero Nota gerada'                         ,''    ,False,'3','','','2');
  Inst.AddField('MovAbate','Mova_TransacaoGerada'   ,'C',12 ,0,90,True,'Transa��o'                    ,'Numero Transa��o gerada'                         ,''    ,False,'1','','','2');
  Inst.AddField('MovAbate','Mova_tipo_codigo'       ,'N',007,0, 60,True ,'Associado'                ,'Associado'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovAbate','Mova_pesovivo'          ,'N',012,3, 90,True ,'Peso Vivo'                ,'Peso Vivo'                             ,''    ,False,'3','','','0');
  Inst.AddField('MovAbate','Mova_pesocarcaca'       ,'N',012,3, 90,True ,'Peso Carca�a'             ,'Peso Carca�a'                             ,''    ,False,'3','','','0');
  Inst.AddField('MovAbate','Mova_datacont'          ,'D',008,0, 70,True ,'Movimento'                ,'Data movimento'                  ,''    ,False,'1','','','0');
  Inst.AddField('MovAbate','Mova_Perc'              ,'N',12 ,5 ,70,True ,'Perc'                    ,'Perc de rateio'                          ,''    ,True ,'1','','','0');
  Inst.AddField('MovAbate','Mova_situacao'          ,'C',1  ,0 ,30,True ,'Situa��o'                  ,'Situa��o'                                    ,''    ,False,'2','','','2');
// 10.02.10
  Inst.AddField('MovAbate','Mova_tran_codigo'       ,'C',3  ,0,30  ,True ,'C�digo'                    ,'C�digo do transportador'                   ,''    ,False,'1','','','0');
  Inst.AddField('MovAbate','Mova_Fpgt_Codigo'       ,'C',3 ,0,30   ,True ,'F.Pgto','C�digo da forma de pagamento','000',False,'1','','','0');
// 21.01.11
  Inst.AddField('MovAbate','Mova_repr_codigo'       ,'N',4  ,0 ,90,True ,'C�digo'                    ,'C�digo do representante'                   ,''    ,False,'2','','','0');
  Inst.AddField('MovAbate','Mova_vlrtotal'          ,'N',012,3, 90,True ,'Valor Total'               ,'Valor Total'                               ,''    ,False,'3','','','0');
  Inst.AddField('MovAbate','Mova_PercComissao'      ,'N',008,3 ,70,True ,'% Comiss�o'                ,'Percentual de comiss�o do comprador'       ,''    ,True ,'3','','','0');
// 30.07.15
  Inst.AddField('MovAbate','Mova_vlrgta'            ,'N',012,3, 90,True ,'Valor GTA'                  ,'Valor GTA'                                ,''    ,False,'3','','','0');
// 27.06.16                                  '
// 20.01.16 - cargas
  Inst.AddField('MovAbate','Mova_carga'             ,'N',8  ,0,90  ,True ,'Carga'                    ,'Numero da carga'                           ,''    ,False,'2','','','2');
// 21.05.19
  Inst.AddField('MovAbate','Mova_ganhopeso'        ,'N', 06,2,070  ,True,'Ganho Peso'                 ,'Percentual de ganho de peso ao dia'                                 ,''    ,False,'3','','','0');
// 12.06.19 - comissao motoristas q trazem os bois para o abate
  Inst.AddField('MovAbate','Mova_cola_codigo'       ,'C',4  ,0,70  ,True ,'Colab.'                     ,'Colaborador que conduz o ve�culo'                               ,''    ,True ,'3','','','0');
  Inst.AddField('MovAbate','Mova_Kmi'               ,'N',10  ,2,090,True ,'KM Inicial'  ,'KM inicial do caminh�o','',False,'3','','','0');
  Inst.AddField('MovAbate','Mova_Kmf'               ,'N',10  ,2,090,True ,'KM Final'    ,'KM final do caminh�o','',False,'3','','','0');


  Inst.AddTable('MovAbatedet');
  Inst.AddField('MovAbatedet','Movd_Transacao'         ,'C',12 ,0, 70,False,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('MovAbatedet','Movd_Operacao'          ,'C',16 ,0, 70,False,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('MovAbatedet','Movd_numerodoc'         ,'N',8  ,0, 90,True,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('MovAbatedet','Movd_status'            ,'C',1  ,0, 30,True,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovAbatedet','Movd_tipomov'           ,'C',2  ,0, 30,True,'Tipo'                      ,'Tipo do movimento'                           ,''    ,False,'2','','','2');
  Inst.AddField('MovAbatedet','Movd_unid_codigo'       ,'C',3  ,0, 30  ,False,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovAbatedet','Movd_esto_codigo'       ,'C',20 ,0, 90  ,False,'C�digo'                    ,'C�digo do produto'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovAbatedet','Movd_ordem'             ,'N', 3 ,0, 90,True,'Sequencial'                ,'Numero de ordem'                             ,''    ,False,'3','','','0');
  Inst.AddField('MovAbatedet','Movd_brinco'            ,'C',10 ,0, 90,True,'Brinco'                    ,'Brinco'                                       ,''    ,False,'1','','','0');
  Inst.AddField('MovAbatedet','Movd_idade'             ,'C', 3 ,0, 90,True,'Idade'                     ,'Idade'                             ,''    ,False,'2','','','0');
  Inst.AddField('MovAbatedet','Movd_tipo_codigo'       ,'N',007,0, 60,True ,'Associado'                ,'Associado'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovAbatedet','Movd_pesovivo'          ,'N',011,3, 90,True ,'Peso Vivo'                ,'Peso Vivo'                             ,''    ,False,'3','','','0');
  Inst.AddField('MovAbatedet','Movd_pesocarcaca'       ,'N',011,3, 90,True ,'Peso Carca�a'             ,'Peso Carca�a'                             ,''    ,False,'3','','','0');
  Inst.AddField('MovAbatedet','Movd_vlrarroba'         ,'N',008,3, 90,True ,'Valor Arroba'             ,'Valor Arroba'                             ,''    ,False,'3','','','0');
  Inst.AddField('MovAbatedet','Movd_obs'               ,'C',200,0,200,True ,'Observa��o'               ,'Observa��o'                             ,''    ,False,'1','','','0');
// 14.10.08 - Isonel
  Inst.AddField('MovAbatedet','Movd_Pecas'             ,'N',12 ,3,70  ,True ,'Pe�as'                     ,'Pe�as'                               ,''    ,True ,'3','','','0');
// 24.09.13 - Isonel
  Inst.AddField('MovAbatedet','Movd_Seto_codigo'       ,'C', 4 ,0,30   ,True,'Setor'                    ,'Codigo do Setor'                          ,''    ,False,'2','','','0');
  Inst.AddField('MovAbatedet','Movd_Baia'              ,'C', 10,0,30   ,True,'Baia'                     ,'Baia'                                 ,''    ,False,'2','','','0');
// 20.01.16 - Isonel  - balancao na saida
  Inst.AddField('MovAbatedet','Movd_pesobalanca'       ,'N',011,3, 90,True ,'Peso Balan�a'              ,'Peso Balan�a'                             ,''    ,False,'3','','','0');
// 22.09.16
  Inst.AddField('MovAbatedet','Movd_vlrabate'          ,'N',008,3, 90,True ,'Valor Abate'               ,'Valor no Abate'                             ,''    ,False,'3','','','0');
  Inst.AddField('MovAbatedet','Movd_abatido'           ,'C',1  ,0, 30,True,'Abatido'                    ,'Se j� foi abatido'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovAbatedet','Movd_Datamvto'          ,'D',8  ,0, 30,True,'Data'                       ,'Data do movimento'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovAbatedet','Movd_Dataabate'         ,'D',8  ,0, 30,True,'Abate'                      ,'Data do abate'                              ,''    ,False,'2','','','2');
// 24.10.16
  Inst.AddField('MovAbatedet','Movd_esto_codigoven'    ,'C',20 ,0, 90  ,True,'C�digo'                    ,'C�digo do produto'                            ,''    ,False,'2','','','0');
// 25.10.16
  Inst.AddField('MovAbatedet','Movd_oprastreamento'    ,'C',20 ,0, 90  ,True,'Opera��o Rast.'           ,'Opera��o Reastreamento'                            ,''    ,False,'1','','','0');
// 27.10.16
  Inst.AddField('MovAbatedet','Movd_pesovivoabate'     ,'N',11 ,3, 90  ,True,'Peso Vivo Abate'           ,'Peso Vivo Abate'                            ,''    ,False,'3','','','0');
// 05.06.20
  Inst.AddField('MovAbatedet','Movd_Cupim'             ,'C',01 ,0,090,True ,'Cupim'    ,'N - N�o tem cupim  S - Tem cupim','',False,'3','','','0');


// 14.01.08 - ordem/controle de produ��o
  Inst.AddTable('MovProducao');
  Inst.AddField('MovProducao','Movp_Transacao'         ,'C',12,0,70,False,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('MovProducao','Movp_Operacao'          ,'C',16,0,70,False,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('MovProducao','Movp_numerodoc'         ,'N',8 ,0,90,True,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('MovProducao','Movp_status'            ,'C',1 ,0,30,False,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovProducao','Movp_tipomov'           ,'C',2 ,0,30,True ,'Tipo'                      ,'Tipo do movimento'                           ,''    ,False,'2','','','2');
  Inst.AddField('MovProducao','Movp_unid_codigo'       ,'C',3  ,0,30  ,False,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovProducao','Movp_esto_codigo'       ,'C',20 ,0,90  ,False,'C�digo'                    ,'C�digo do produto'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovProducao','Movp_tama_codigo'       ,'N',5  ,0,30  ,True ,'C�digo'                    ,'C�digo do tamanho'                           ,''    ,False,'2','','','0');
  Inst.AddField('MovProducao','Movp_core_codigo'       ,'N',3  ,0,30  ,True ,'C�digo'                    ,'C�digo da cor'                                ,''    ,False,'2','','','0');
  Inst.AddField('MovProducao','Movp_tipo_codigo'       ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/fornecedor'                ,''    ,False,'2','','','0');
  Inst.AddField('MovProducao','Movp_tipocad'           ,'C',1  ,0,30  ,True ,'Tipo cadastro'             ,'Tipo do cadastro'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovProducao','Movp_repr_codigo'       ,'N',4  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/representante'             ,''    ,False,'2','','','2');
  Inst.AddField('MovProducao','Movp_QtdeGeral'         ,'N',12 ,3,70  ,True ,'Qtde Geral'                ,'Qtde Geral a produzir'                           ,''    ,True ,'1','','','0');
  Inst.AddField('MovProducao','Movp_tamag_codigo'       ,'N',5  ,0,30  ,True ,'Tamanho Geral'                    ,'C�digo do tamanho'                           ,''    ,False,'2','','','0');
  Inst.AddField('MovProducao','Movp_coreg_codigo'       ,'N',3  ,0,30  ,True ,'Cor Geral'                    ,'C�digo da cor'                                ,''    ,False,'2','','','0');
  Inst.AddField('MovProducao','Movp_Estoque'           ,'N',12 ,3,70  ,True ,'Qtde em estoque'           ,'Qtde em estoque'                             ,''    ,True ,'1','','','0');
  Inst.AddField('MovProducao','Movp_DataLcto'          ,'D',0  ,0,60  ,False,'Data Lcto','Data de lan�amento','',True,'1','','','0');
  Inst.AddField('MovProducao','Movp_DataMvto'          ,'D',0  ,0,60  ,True ,'Data Mvto','Data de movimento','',True,'1','','','0');
  Inst.AddField('MovProducao','Movp_QtdeOp'            ,'N',12 ,3,70  ,True ,'Qtde OP'                   ,'Qtde a produzir'                            ,''    ,True ,'1','','','0');
  Inst.AddField('MovProducao','Movp_QtdeProd'          ,'N',12 ,3,70  ,True ,'Produ��o'                  ,'Qtde produzida'                             ,''    ,True ,'1','','','0');
  Inst.AddField('MovProducao','Movp_Venda'             ,'N',13 ,5,70  ,True ,'Pre�o venda'               ,'Pre�o de venda'                           ,''    ,True ,'1','','','0');
  Inst.AddField('MovProducao','Movp_Grup_codigo'       ,'N',06 ,0,40  ,True ,'C�digo do grupo'           ,'C�digo do grupo'                             ,''    ,False,'1','','','0');
  Inst.AddField('MovProducao','Movp_Sugr_codigo'       ,'N',04 ,0,40  ,True ,'C�digo do subgrupo'        ,'C�digo do subgrupo'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovProducao','Movp_Fami_codigo'       ,'N',04 ,0,40  ,True ,'C�digo'                    ,'C�digo da familia'                        ,''    ,False,'2','','','2');
  Inst.AddField('MovProducao','Movp_Usua_Codigo'       ,'N',3  ,0,50  ,False,'Usu�rio'                   ,'Usu�rio respons�vel'                        ,''    ,False,'3','','','0');
  Inst.AddField('MovProducao','Movp_Pecas'               ,'N',12 ,3,70  ,True ,'Pe�as'                     ,'Pe�as'                               ,''    ,True ,'3','','','0');
  Inst.AddField('MovProducao','Movp_locales'             ,'C',02,0,70   ,True ,'Local Estoque'             ,'Local Estoque'                                  ,'00'    ,True ,'1','','','0');
  Inst.AddField('MovProducao','Movp_nroobra'             ,'C',15 ,0,90  ,True ,'Numero Obra'               ,'Numero Obra'                                          ,''    ,False,'1','','','0');
  Inst.AddField('MovProducao','Movp_HoraMvto'           ,'C',10  ,0,60  ,True ,'Hora Mvto','Hora do movimento','',True,'1','','','0');
  Inst.AddField('MovProducao','Movp_Localobra'          ,'C',20 ,0,120  ,True ,'Local'                      ,'Local na obra','',True,'1','','','0');
  Inst.AddField('MovProducao','Movp_Operacaoop'         ,'C',50 ,0,250  ,True ,'Opera��o OP'                 ,'Opera��o da OP','',True,'1','','','0');
  Inst.AddField('MovProducao','Movp_Maqu_Codigo'        ,'N',04 ,0,50  ,True  ,'Posto Operativo'              ,'Posto OPerativo','',True,'1','','','0');

// 24.01.08 - itens de cada 'produto' da obra onde � instalado na obra
  Inst.AddTable('MovObrasDet');
  Inst.AddField('MovObrasDet','Movo_Transacao'         ,'C',12,0,70,False,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('MovObrasDet','Movo_Operacao'          ,'C',16,0,70,False,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('MovObrasDet','Movo_numerodoc'         ,'N',8 ,0,90,True,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('MovObrasDet','Movo_status'            ,'C',1 ,0,30,False,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovObrasDet','Movo_tipomov'           ,'C',2 ,0,30,True ,'Tipo'                      ,'Tipo do movimento'                           ,''    ,False,'2','','','2');
  Inst.AddField('MovObrasDet','Movo_unid_codigo'       ,'C',3  ,0,30  ,False,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovObrasDet','Movo_esto_codigo'       ,'C',20 ,0,90  ,False,'C�digo'                    ,'C�digo do produto'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovObrasDet','Movo_tama_codigo'       ,'N',5  ,0,30  ,True ,'C�digo'                    ,'C�digo do tamanho'                           ,''    ,False,'2','','','0');
  Inst.AddField('MovObrasDet','Movo_core_codigo'       ,'N',3  ,0,30  ,True ,'C�digo'                    ,'C�digo da cor'                                ,''    ,False,'2','','','0');
  Inst.AddField('MovObrasDet','Movo_tipo_codigo'       ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/fornecedor'                ,''    ,False,'2','','','0');
  Inst.AddField('MovObrasDet','Movo_tipocad'           ,'C',1  ,0,30  ,True ,'Tipo cadastro'             ,'Tipo do cadastro'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovObrasDet','Movo_repr_codigo'       ,'N',4  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/representante'             ,''    ,False,'2','','','2');
  Inst.AddField('MovObrasDet','Movo_QtdeGeral'         ,'N',12 ,3,70  ,True ,'Qtde Geral'                ,'Qtde Geral a produzir'                           ,''    ,True ,'1','','','0');
  Inst.AddField('MovObrasDet','Movo_Estoque'           ,'N',12 ,3,70  ,True ,'Qtde em estoque'           ,'Qtde em estoque'                             ,''    ,True ,'1','','','0');
  Inst.AddField('MovObrasDet','Movo_DataLcto'          ,'D',0  ,0,60  ,False,'Data Lcto','Data de lan�amento','',True,'1','','','0');
  Inst.AddField('MovObrasDet','Movo_DataMvto'          ,'D',0  ,0,60  ,True ,'Data Mvto','Data de movimento','',True,'1','','','0');
  Inst.AddField('MovObrasDet','Movo_QtdeOp'            ,'N',12 ,3,70  ,True ,'Qtde OP'                   ,'Qtde a produzir'                            ,''    ,True ,'1','','','0');
  Inst.AddField('MovObrasDet','Movo_QtdeProd'          ,'N',12 ,3,70  ,True ,'Produ��o'                  ,'Qtde produzida'                             ,''    ,True ,'1','','','0');
  Inst.AddField('MovObrasDet','Movo_Venda'             ,'N',13 ,5,70  ,True ,'Pre�o venda'               ,'Pre�o de venda'                           ,''    ,True ,'1','','','0');
  Inst.AddField('MovObrasDet','Movo_Usua_Codigo'       ,'N',3  ,0,50  ,False,'Usu�rio'                   ,'Usu�rio respons�vel'                        ,''    ,False,'3','','','0');
  Inst.AddField('MovObrasDet','Movo_Area'              ,'N',12 ,3,70  ,True ,'Area'                      ,'Area'                                ,''    ,True ,'3','','','0');
  Inst.AddField('MovObrasDet','Movo_Peso'              ,'N',12 ,3,70  ,True ,'Peso'                      ,'Peso'                                ,''    ,True ,'3','','','0');
  Inst.AddField('MovObrasDet','Movo_Largura'           ,'N',08 ,0,70  ,True ,'Largura'                   ,'Largura'                             ,''    ,True ,'3','','','0');
  Inst.AddField('MovObrasDet','Movo_Altura'            ,'N',08 ,0,70  ,True ,'Altura'                    ,'Altura'                              ,''    ,True ,'3','','','0');
  Inst.AddField('MovObrasDet','Movo_nroobra'           ,'C',15 ,0,90  ,True ,'Numero Obra'               ,'Numero Obra'                                          ,''    ,False,'1','','','0');
  Inst.AddField('MovObrasDet','Movo_HoraMvto'          ,'C',10  ,0,60  ,True ,'Hora Mvto','Hora do movimento','',True,'1','','','0');
  Inst.AddField('MovObrasDet','Movo_Localobra'         ,'C',20 ,0,120  ,True ,'Local'                      ,'Local na obra','',True,'1','','','0');
  Inst.AddField('MovObrasDet','Movo_Descricaoobra'     ,'C',80 ,0,120  ,True ,'Localiza��o'                ,'Descri��o local','',True,'1','','','0');

// 29.01.08 - or�amentos feitos/fechados/perdidos
  Inst.AddTable('Orcamentos');
  Inst.AddField('Orcamentos','Orca_numerodoc'         ,'N',8 ,0,70,True,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('Orcamentos','Orca_status'            ,'C',1 ,0,30,False,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','0');
  Inst.AddField('Orcamentos','Orca_situacao'          ,'C',1  ,0,45  ,True,'Situa��o'                  ,'Situa��o'                                    ,''    ,False,'2','','','0');
  Inst.AddField('Orcamentos','Orca_unid_codigo'       ,'C',3  ,0,40  ,False,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('Orcamentos','Orca_tipo_codigo'       ,'N',7  ,0,90  ,True ,'C�digo'                    ,'C�digo do cliente/fornecedor'                ,''    ,False,'2','','','0');
  Inst.AddField('Orcamentos','Orca_tipocad'           ,'C',1  ,0,30  ,True ,'Tipo cadastro'             ,'Tipo do cadastro'                            ,''    ,False,'2','','','0');
  Inst.AddField('Orcamentos','Orca_repr_codigo'       ,'N',4  ,0,90  ,True ,'C�digo'                    ,'C�digo do representante'             ,''    ,False,'2','','','2');
  Inst.AddField('Orcamentos','Orca_DataLcto'          ,'D',0  ,0,60  ,True,'Data Lcto','Data de lan�amento','',True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_DataMvto'          ,'D',0  ,0,60  ,True ,'Data Mvto','Data de movimento','',True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_DataRetorno'       ,'D',0  ,0,60  ,True ,'Data Retorno','Data de retorno','',True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_cliente1'          ,'C',050,0,250 ,True ,'Cliente'                   ,'Nome cliente'                                ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_cliente2'          ,'C',050,0,250 ,True ,'Contato'                   ,'Nome contato'                                ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_obra'              ,'C',050,0,250 ,True ,'Obra'                      ,'Nome da Obra'                                ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_linha'             ,'C',050,0,250 ,True ,'Linha'                     ,'Nome da Linha'                               ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_area'              ,'N',012,3,090 ,True ,'�rea'                      ,'Metros quadrados de �rea'            ,''    ,False,'3','','','0');
  Inst.AddField('Orcamentos','Orca_peso'              ,'N',012,3,090 ,True ,'Peso'                      ,'Peso em kilos'                       ,''    ,False,'3','','','0');
  Inst.AddField('Orcamentos','Orca_valor'             ,'N',012,3,090 ,True ,'Valor'                     ,'Valor Total'                         ,''    ,False,'3','+','','0');
  Inst.AddField('Orcamentos','Orca_DataFecha'         ,'D',0  ,0,60  ,True ,'Data Fech.'  ,'Data Fechamento','',True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_obs'               ,'C',200,0,350 ,True ,'Observa��es'                ,'Observa��es'                                ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_Usua_Codigo'       ,'N',3  ,0,50  ,False,'Usu�rio'                   ,'Usu�rio respons�vel'                        ,''    ,False,'3','','','0');
  Inst.AddField('Orcamentos','Orca_Fone'              ,'C',11 ,0,100 ,True ,'Fone','N�mero do telefone fixo',f_fone,True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_Celular'           ,'C',11 ,0,80  ,True ,'Celular'          ,'N�mero do telefone celular'                         ,f_fone   ,True ,'1','','','0');
// 23.10.08
  Inst.AddField('Orcamentos','Orca_nroobra'         ,'C',15 ,0,90,True,'Obra'                    ,'Numero da Obra/Or�amento'                         ,''    ,False,'2','','','2');
// 14.01.09
  Inst.AddField('Orcamentos','Orca_DtPrevisaoEnt'         ,'D',0  ,0,60  ,True ,'Previs�o Entrega'  ,'Data Previs�o Entrega','',True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_DtEntrega'             ,'D',0  ,0,60  ,True ,'Entrega'  ,'Data Entrega','',True,'1','','','0');
// 07.04.09
  Inst.AddField('Orcamentos','Orca_enderecocli'        ,'C',060,0,250 ,True ,'Endere�o Cliente'                   ,'Endere�o Cliente'                                ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_FoneCom'            ,'C',11 ,0,100 ,True ,'Fone Com.','N�mero do telefone comercial',f_fone,True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_nomeesp'            ,'C',050,0,250 ,True ,'Nome Especificador'                   ,'Nome Especificador'                                ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_empresaesp'         ,'C',050,0,250 ,True ,'Empresa Especificador'                ,'Empresa Especificador'                                ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_enderecoesp'        ,'C',060,0,250 ,True ,'Endere�o Especificador'                ,'Endere�o Especificador'                                ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_Foneesp'            ,'C',11 ,0,100 ,True ,'Fone','N�mero do telefone fixo',f_fone,True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_FoneComesp'         ,'C',11 ,0,100 ,True ,'Fone Com.','N�mero do telefone comercial',f_fone,True,'1','','','0');
//--------
  Inst.AddField('Orcamentos','Orca_nomerespcon'        ,'C',050,0,250 ,True ,'Nome Respons�vel Executor'                   ,'Nome Respons�vel Executor'                                ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_empresacon'         ,'C',050,0,250 ,True ,'Empresa Construtora'                ,'Empresa Construtora'                                ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_enderecocon'        ,'C',060,0,250 ,True ,'Endere�o Construtora'                ,'Endere�o Construtora'                                ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_Fonecon'            ,'C',11 ,0,100 ,True ,'Fone','N�mero do telefone fixo',f_fone,True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_FoneComcon'         ,'C',11 ,0,100 ,True ,'Fone Com.','N�mero do telefone comercial',f_fone,True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_TipoObra'           ,'C',30 ,0,100 ,True ,'Tipo Obra','Tipo Obra','',True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_Pavimentos'         ,'N',03 ,0,060 ,True ,'Pavimentos','N�mero de Pavimentos','',True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_DtIdenti'           ,'D',0  ,0,60  ,True ,'Identif.'  ,'Data de Identifica��o','',True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_vidrotemp'          ,'N',012,3,090 ,True ,'M2 Temperado'                 ,'M2 Vidro Temperado'                               ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_vidrolami'          ,'N',012,3,090 ,True ,'M2 Laminado'                  ,'M2 Vidro Laminado'                               ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_vidromono'          ,'N',012,3,090 ,True ,'M2 Monol�tico'                ,'M2 Vidro Monol�tico'                               ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_vidroinsu'          ,'N',012,3,090 ,True ,'M2 Insulado'                  ,'M2 Vidro Insulado'                               ,''    ,False,'1','','','0');
  Inst.AddField('Orcamentos','Orca_potpeso'            ,'N',012,3,090 ,True ,'Pot. Kg'                      ,'Potencial em kilos'                       ,''    ,False,'3','','','0');
  Inst.AddField('Orcamentos','Orca_potarea'            ,'N',012,3,090 ,True ,'Pot. M2'                      ,'Potencial em metros quadrados'                       ,''    ,False,'3','','','0');
  Inst.AddField('Orcamentos','Orca_potmoeda'           ,'N',012,3,090 ,True ,'Pot. R$'                      ,'Potencial em reais'                       ,''    ,False,'3','','','0');
  Inst.AddField('Orcamentos','Orca_Motivorej'          ,'C',500,0,200 ,True ,'Motivo','Motivo da rejei��o','',True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_tipovenda'          ,'C',020,0,090 ,True ,'Tipo Venda','Tipo Venda','',True,'1','','','0');
  Inst.AddField('Orcamentos','Orca_Cida_Codigo'        ,'N',5  ,0, 80 ,True ,'C�d. Cidade'            ,'C�digo da cidade da obra'                                 ,''       ,True ,'3','','','0');
// 12.08.09
  Inst.AddField('Orcamentos','Orca_Usua_Desaprova'       ,'N',3  ,0,50  ,False,'Usu�rio'                   ,'Usu�rio que autorizou alterar obra fechada'                        ,''    ,False,'3','','','0');
  Inst.AddField('Orcamentos','Orca_DtDesaprova'          ,'D',0  ,0,60  ,True ,'Desaprova��o'  ,'Data em que foi autorizado a altera��o de obra fechada','',True,'1','','','0');
// 13.12.10
  Inst.AddField('Orcamentos','Orca_DtPrevFecha'          ,'D',0  ,0,60  ,True ,'Prev.Fechamento'  ,'Data de previs�o de fechamento do or�amento','',True,'1','','','0');
// 10.06.11
  Inst.AddField('Orcamentos','Orca_ProdSer'              ,'C',2  ,0,080 ,True ,'Tipo Venda' ,'Tipo Venda - Produtos ou Servi�os','',True,'1','','','0');



// 04.10.8
// 23.10.08 - or�amentos valores para forma��o do pre�o de venda da obra
  Inst.AddTable('Orcamencal');
  Inst.AddField('Orcamencal','Orcc_numerodoc'         ,'N',8 ,0,70,True,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('Orcamencal','Orcc_Nome'              ,'C',50 ,0,30,False,'Nome'                    ,'Nome do c�lculo do or�amento'                          ,''    ,False,'2','','','0');
  Inst.AddField('Orcamencal','Orcc_status'            ,'C',1 ,0,30,False,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','0');
  Inst.AddField('Orcamencal','Orcc_unid_codigo'       ,'C',3  ,0,40  ,False,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('Orcamencal','Orcc_venda'             ,'N',012,3,090 ,True ,'Valor Venda'                     ,'Valor Venda'                         ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_custoobra'         ,'N',012,3,090 ,True ,'Custo Obra'         ,'Custo Obra'                         ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_ofertacliente'     ,'N',012,3,090 ,True ,'Oferta Cliente'         ,'Oferta Cliente'                         ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_simples'           ,'N',007,3,090 ,True ,'% Simples'         ,'% Simples'                         ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_pis'               ,'N',007,3,090 ,True ,'% Pis'             ,'% Pis'                             ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_cofins'            ,'N',007,3,090 ,True ,'% Cofins'          ,'% Cofins'                          ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_ir'                ,'N',007,3,090 ,True ,'% IR'              ,'% Imposto Renda'                   ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_cs'                ,'N',007,3,090 ,True ,'% CS'              ,'% Contribui��o Social'            ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_comissoes'         ,'N',007,3,090 ,True ,'% Comiss�es'       ,'% Comiss�es'            ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_icms'              ,'N',007,3,090 ,True ,'% Icms'            ,'% Icms'                 ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_reserva'           ,'N',007,3,090 ,True ,'% Reserva'         ,'% Reserva T�cnica'      ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_fretes'            ,'N',007,3,090 ,True ,'% Fretes'          ,'% Fretes'               ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_custofixo'         ,'N',007,3,090 ,True ,'% Custo Fixo'      ,'% Custo Fixo'           ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_margem'            ,'N',007,3,090 ,True ,'% Margem'          ,'% Margem'               ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_desconto01'        ,'N',007,3,090 ,True ,'% Desc.01'         ,'% Desconto 01'          ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_desconto02'        ,'N',007,3,090 ,True ,'% Desc.02'         ,'% Desconto 02'          ,''    ,False,'3','','','0');
// 17.12.08
  Inst.AddField('Orcamencal','Orcc_acessorios'        ,'N',012,3,090 ,True ,'Valor Acess�rios'  ,'Valor Acess�rios'       ,''    ,False,'3','','','0');
// 11.02.09
  Inst.AddField('Orcamencal','Orcc_motorizacao'       ,'N',012,3,090 ,True ,'Motoriza��o '  ,'Valor Motoriza��o'       ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_persianas'         ,'N',012,3,090 ,True ,'Persianas '  ,'Valor Persianas'         ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_cremonas'          ,'N',012,3,090 ,True ,'Cremonas '  ,'Valor Cremonas'         ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_desloca'           ,'N',012,3,090 ,True ,'Deslocamento'  ,'Valor Deslocamento'         ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_alimentacao'       ,'N',012,3,090 ,True ,'Alimenta��o'  ,'Valor Alimenta��o'         ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_estadia'           ,'N',012,3,090 ,True ,'Estadia'  ,'Valor Estadia'         ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_km'                ,'N',010,0,090 ,True ,'KM'       ,'Distancia em Kilometros at� a obra(ida e volta)'         ,''    ,False,'3','','','0');
// 16.02.09
  Inst.AddField('Orcamencal','Orcc_geralprod'         ,'N',010,3,090 ,True ,'% Produ��o'       ,'Gastos Gerais de Produ��o em percentual'         ,''    ,False,'3','','','0');
// 20.02.09
  Inst.AddField('Orcamencal','Orcc_pesoliquido'       ,'N',012,3,090 ,True ,'Peso L�quido'     ,'Peso L�quido'         ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_margemcli'         ,'N',007,3,090 ,True ,'% Margem'          ,'% Margem do cliente'               ,''    ,False,'3','','','0');
// 01.07.09
  Inst.AddField('Orcamencal','Orcc_carga'             ,'N',010,3,090 ,True ,'Carga(m2)'        ,'Capacidade do ve�culo'      ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_combustivel'       ,'N',009,3,090 ,True ,'Combust�vel'      ,'Valor por litro'      ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_diaria'            ,'N',010,3,090 ,True ,'Di�ria'        ,'Valor da di�ria da hospedagem'      ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_refeicao'          ,'N',010,3,090 ,True ,'Refei��o'      ,'Valor da refei��o di�ria ( almo�o e janta)'      ,''    ,False,'3','','','0');
// 08.07.09
  Inst.AddField('Orcamencal','Orcc_ReflexoCom'        ,'N',007,3,090 ,True ,'Reflexo'        ,'% Reflexo sobre comiss�es'   ,'',False,'','','','0');
// 12.08.09 - se este foi o 'Fechado' - aprovado pelo cliente - 'F'
  Inst.AddField('Orcamencal','Orcc_situacao'          ,'C',1  ,0,45  ,True,'Situa��o'                  ,'Situa��o'                                    ,''    ,False,'2','','','0');
/////  Inst.AddField('Orcamencal','Orcc_vendaobra'         ,'N',012,3,090 ,True ,'Venda'  ,'Valor de Venda da Obra'       ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_vendaobrafinal'    ,'N',012,3,090 ,True ,'Venda Final'  ,'Valor de Venda da Obra com juros financeiros'       ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_vlrentrada'        ,'N',012,3,090 ,True ,'Valor Entrada'  ,'Valor Entrada'       ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_nparcelas'         ,'N',003,0,090 ,True ,'Num.Parcelas'  ,'Num.Parcelas'       ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_percjurosfin'      ,'N',007,3,090 ,True ,'% Juros Fin.'  ,'% Juros Fin.'       ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_mesescare'         ,'N',002,0,090 ,True ,'Car�ncia'      ,'Meses de Car�ncia'  ,''    ,False,'3','','','0');
  Inst.AddField('Orcamencal','Orcc_Fpgt_Codigo'       ,'C',3  ,0,50  ,True ,'F.Pgto'                 ,'C�digo da forma de pagamento'                                   ,'000;0; ',False,'1','','','0');
// 10.09.10
  Inst.AddField('Orcamencal','Orcc_construcard'       ,'N',007,3,090 ,True ,'% Construcard'   ,'% Construcard'                         ,''    ,False,'3','','','0');

// 22.01.09 - or�amentos valores para forma��o do pre�o de venda da obra - detalhamentos de
//
  Inst.AddTable('Orcamendet');
  Inst.AddField('Orcamendet','Orcd_numerodoc'         ,'N',8  ,0,70,True,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('Orcamendet','Orcd_Nome'              ,'C',50 ,0,30,True,'Nome'                    ,'Nome do c�lculo do or�amento'                          ,''    ,False,'2','','','0');
  Inst.AddField('Orcamendet','Orcd_status'            ,'C',1  ,0,30,True,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','0');
  Inst.AddField('Orcamendet','Orcd_unid_codigo'       ,'C',3  ,0,40  ,True ,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
//  Inst.AddField('Orcamendet','Orcd_codigo'        ,'C',5  ,0,40  ,True ,'C�digo'                    ,'C�digo item'                            ,''    ,False,'2','','','0');
// 04.05.09 - Abra - Adriano em primeiro treinamento planilha calculo
  Inst.AddField('Orcamendet','Orcd_codigo'        ,'C',20 ,0,40  ,True ,'C�digo'                    ,'C�digo item'                            ,''    ,False,'2','','','0');
  Inst.AddField('Orcamendet','Orcd_descricao'     ,'C',50 ,0,200 ,True ,'Descri��o'                    ,'Descri��o item'                            ,''    ,False,'2','','','0');
  Inst.AddField('Orcamendet','Orcd_unidade'       ,'C',5  ,0,50  ,True ,'Unidade'                    ,'Unidade do item'                            ,''    ,False,'2','','','0');
  Inst.AddField('Orcamendet','Orcd_qtde'          ,'N',12 ,4,70  ,True ,'Quantidade'                    ,'Quantidade do item'                            ,''    ,False,'3','','','0');
  Inst.AddField('Orcamendet','Orcd_unitario'      ,'N',12 ,4,70  ,True ,'Unit�rio'                    ,'Valor unit�rio do item'                            ,''    ,False,'3','','','0');
  Inst.AddField('Orcamendet','Orcd_tipoitem'      ,'C',1  ,0,40  ,True ,'Tipo'                    ,'Tipo de item'                            ,''    ,False,'2','','','0');
// 17.07.13 - Metalforte
  Inst.AddField('Orcamendet','Orcd_tama_codigo'   ,'N',5  ,0,30  ,True ,'C�digo'                    ,'C�digo do tamanho'                        ,''    ,False,'2','','','0');
  Inst.AddField('Orcamendet','Orcd_core_codigo'   ,'N',3  ,0,30  ,True ,'C�digo'                    ,'C�digo da cor'                            ,''    ,False,'2','','','0');
  Inst.AddField('Orcamendet','Orcd_peso'          ,'N',12 ,4,70  ,True ,'Peso'                      ,'Peso item'                            ,''    ,False,'3','','','0');
////
// 22.01.09 - cadastro de servicos para uso inicial na planilha de forma��o de pre�o
//            dos or�amentos
//
  Inst.AddTable('CadMObra');
  Inst.AddField('CadMObra','Cadm_Codigo'       ,'N',5  ,0,50  ,False ,'Codigo'                   ,'Codigo do m�o de obra'                       ,''    ,False,'3','','','0');
  Inst.AddField('CadMObra','Cadm_descricao'    ,'C',50,0,250  ,True ,'Descri��o'   ,'Descri��o da M�o de Obra'                     ,''    ,False,'1','','','2');
  Inst.AddField('CadMObra','Cadm_unitario'     ,'N',12 ,4,70  ,True ,'Unit�rio'                    ,'Valor unit�rio da M�o de Obra'                            ,''    ,False,'3','','','0');
  Inst.AddField('CadMObra','Cadm_unidade'      ,'C',5  ,0,50  ,True ,'Unidade'                    ,'Unidade da M�o de Obra'                            ,''    ,False,'2','','','0');
  Inst.AddField('CadMObra','Cadm_Somatotal'    ,'C',1  ,0,50  ,True ,'Soma'                    ,'Se soma no total da nota de M�o de Obra'                            ,''    ,False,'2','','','0');
  Inst.AddField('CadMObra','Cadm_IncideInss'   ,'C',1  ,0,50  ,True ,'INSS'                    ,'Se � base de c�lculo para reten��o de INSS'                            ,''    ,False,'2','','','0');
// 13.03.09 - para 'pular linha' na impressao da nota de servicos 'da copel'
  Inst.AddField('CadMObra','Cadm_Pulalinha'    ,'N',2  ,0,50  ,True ,'Pula Linha'              ,'Numero de linhas a pular na impress�o da nota de m�o de obra'                            ,''    ,False,'2','','','0');
// 05.04.18
  Inst.AddField('CadMObra','Cadm_temperatura'  ,'N',6 ,0 ,70  ,True ,'Temperatura'        ,'Temperatura para executar o processo'                            ,''    ,False,'3','','','0');
  Inst.AddField('CadMObra','Cadm_tempo'        ,'N',6 ,0 ,70  ,True ,'Tempo'              ,'Tempo estimado de dura��o do processo'                            ,''    ,False,'3','','','0');
  Inst.AddField('CadMObra','Cadm_nivel'        ,'C',1  ,0,60  ,True ,'N�vel'              ,'N�vel indicado para o processo'                            ,''    ,False,'2','','','0');


// 06.08.08 - RNC -relat�rio de n�o conformidade
  Inst.AddTable('MovRnc');
  Inst.AddField('MovRnc','Mrnc_numerornc'         ,'N',8 ,0,70,True,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('MovRnc','Mrnc_unid_codigo'       ,'C',3  ,0,40  ,True,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovRnc','Mrnc_status'            ,'C',1 ,0,30   ,true,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','0');
  Inst.AddField('MovRnc','Mrnc_situacao'          ,'C',1  ,0,45  ,True,'Situa��o'                  ,'Aprovada/Reprovada'                                    ,''    ,False,'2','','','0');
  Inst.AddField('MovRnc','Mrnc_Usua_Codigo'       ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio que digitou'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovRnc','Mrnc_Usua_Resp'         ,'N',3  ,0,50  ,True ,'Respons�vel'                   ,'Usu�rio respons�vel'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovRnc','Mrnc_Usua_Exclusao'     ,'N',3  ,0,50  ,True ,'Exclus�o'                   ,'Usu�rio que excluiu'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovRnc','Mrnc_Data'              ,'D',0  ,0,60  ,True ,'Data'  ,'Data Relat�rio','',True,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Seto_codigo'       ,'C',4 ,0,30   ,True,'Setor'                    ,'Codigo do Setor'                          ,''    ,False,'2','','','0');
//  Inst.AddField('MovRnc','Mrnc_FornLocal'         ,'C',100,0,300 ,True,'Fornecedor/Local'         ,'Fornecedor/Local'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Seto_Ocorre'       ,'C',4 ,0,30   ,True,'Setor'                   ,'Codigo do Setor onde ocorre a n�o conformidade'                          ,''    ,False,'2','','','0');
  Inst.AddField('MovRnc','Mrnc_IntExt'            ,'C',1   ,0,30 ,True,'Interno/Externo'         ,'Interno/Externo'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_numerodoc'         ,'N',8   ,0,70 ,True,'Documento'               ,'Numero da Nota/Pedido'                         ,''    ,False,'2','','','2');
  Inst.AddField('MovRnc','Mrnc_ProdProcDoc'       ,'C',100 ,0,200,True,'Prod/Proc/Doc'           ,'Produto/Processo/Documento'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Tipo'              ,'C',1   ,0,50 ,True,'Tipo'                    ,'Real/Potencial'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Especie'           ,'C',1   ,0,50 ,True,'Esp�cie'                    ,'Esp�cie'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Origem'            ,'C',1   ,0,50 ,True,'Origem'                    ,'Origem'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Descricao'         ,'C',1000,0,400,True,'Descri��o'         ,'Descri��o da N�o conformidade'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Resultado'         ,'C',1000,0,400,True,'Resultado'         ,'Resultado Esperado'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Aprovada'          ,'C',1   ,0,50 ,True,'Descri��o'         ,'Descri��o da N�o conformidade'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_DtApuCausa'        ,'D',8   ,0,60 ,True,'Apur.Causa'         ,'Data Apura��o da Causa'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Metodo'            ,'C',1000,0,150,True,'M�todo'         ,'M�todo'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Maquina'           ,'C',1000,0,150,True,'M�quina'         ,'M�quina'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_MatPrima'          ,'C',1000,0,150,True,'Mat�ria Prima'         ,'Mat�ria Prima'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_MeioAmbiente'      ,'C',1000,0,150,True,'Meio Ambiente'         ,'Meio Ambiente'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_MaoObra'           ,'C',1000,0,150,True,'Mao de Obra'         ,'Mao de Obra'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Medida'            ,'C',1000,0,150,True,'Medida'         ,'Medida'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Efeito'            ,'C',100 ,0,150,True,'Efeito'         ,'Efeito'                          ,''    ,False,'1','','','0');
//  Inst.AddField('MovRnc','Mrnc_AcaoBloqueio'      ,'C',100 ,0,150,True,'A��o de Bloqueio'         ,'A��o de Bloqueio Proposta'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_DtVerifAcao'       ,'D',8   ,0,60 ,True,'Verif.A��es'         ,'Data para Verifica��o das A��es'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_ResAlcancado'      ,'C',1000,0,400,True,'Res.Alcan�ado'         ,'Resultado Alcan�ado'                          ,''    ,False,'1','','','0');
// parte de produtos
  Inst.AddField('MovRnc','Mrnc_Inspetor'          ,'C',100 ,0,150,True,'Inspetor'         ,'Inspetor'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_OP'                ,'C',20  ,0,090,True,'OP'         ,'OP'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_AnalCritica'       ,'C',1   ,0,090,True,'An�lise Cr�tica'         ,'An�lise Cr�tica'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Reinsplotes'       ,'C',1   ,0,090,True,'Reins.Lotes Ant.'         ,'Reinspecionar Lotes Anteriores'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_ReAnalCritica'     ,'C',100 ,0,090,True,'Res.Anal.Cr�tica'         ,'Respons�vel pela An�lise Cr�tica'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_LaudoReinsp'       ,'C',1   ,0,090,True,'Laudo Reins.'         ,'Laudo da Reinspe��o '                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_DtReinsp'          ,'D',8   ,0,60 ,True,'Data Reins.'         ,'Data Reinspe��o'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Usua_dispfinal'    ,'N',3   ,0,50 ,True,'Resp.Disp.Final'        ,'Resp. pela Disposi��o Final'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovRnc','Mrnc_Comunicara'        ,'C',100 ,0,090,True,'Comunicar a'         ,'Comunicar a'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_PrevEncerra'       ,'D',8   ,0,60 ,True,'Prev.Enc.'         ,'Previs�o Encerramento'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Eficacia'          ,'C',1   ,0,090,True,'Efic�cia'         ,'Efic�cia'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Usua_ConsEmit'     ,'N',3   ,0,50 ,True,'Consenso Emit.'        ,'Consenso Setor Emitente'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovRnc','Mrnc_DtConsenso'        ,'D',8   ,0,60 ,True,'Consenso'         ,'Data do Consenso'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_DtEncerra'         ,'D',8   ,0,60 ,True,'Encerram.'         ,'Data do Encerramento'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Custoaprox'        ,'N',12  ,2,70 ,True,'Custo Aprox.'        ,'Custo Aproximado'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovRnc','Mrnc_Obs'               ,'C',100 ,0,200,True,'Obs.'             ,'Observa��o'                          ,''    ,False,'1','','','0');
  Inst.AddField('MovRnc','Mrnc_Usua_Reinsp'       ,'N',3   ,0,50 ,True,'Reinspe��o'         ,'Respons�vel Reinspe��o'                        ,''    ,False,'3','','','0');
  Inst.AddField('MovRnc','Mrnc_Usua_Eficacia'     ,'N',3   ,0,50 ,True,'Efic�cia'           ,'Respons�vel pela Efic�cia'                     ,''    ,False,'3','','','0');
  Inst.AddField('MovRnc','Mrnc_DispFinal'         ,'C',100 ,0,200,True,'Disp.Final'       ,'Disposi��o Final'                    ,''    ,False,'1','','','0');
// 21.11.08
  Inst.AddField('MovRnc','Mrnc_Usua_Produto'      ,'N',3  ,0,50  ,True ,'Resp.Produto'                   ,'Usu�rio resp. pela destina��o do produto'                       ,''    ,False,'3','','','0');


  Inst.AddTable('PlanoAcao');
  Inst.AddField('PlanoAcao','Paca_status'            ,'C',1 ,0,30,True,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','0');
  Inst.AddField('PlanoAcao','Paca_seq'               ,'C',3 ,0,30,True,'Sequencial'                ,'Sequencial'                          ,''    ,False,'2','','','0');
  Inst.AddField('PlanoAcao','Paca_Numeroata'         ,'C',12 ,0,70,True,'Numero'                    ,'Numero da ata de plano do a��o'                         ,''    ,False,'2','','','2');
  Inst.AddField('PlanoAcao','Paca_Mrnc_numerornc'    ,'N',8 ,0,70,True,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('PlanoAcao','Paca_unid_codigo'       ,'C',3  ,0,40  ,True,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('PlanoAcao','Paca_situacao'          ,'C',1  ,0,45  ,True,'Situa��o'                  ,'Situa��o'                                    ,''    ,False,'2','','','0');
// define se � plano de a��o de uma RNC ( 'R' ) ou ata de plano de a��o ( 'A' )   
  Inst.AddField('PlanoAcao','Paca_Tipoplano'         ,'C',1  ,0,45  ,True,'Tipo'                    ,'Tipo'                                    ,''    ,False,'2','','','0');
  Inst.AddField('PlanoAcao','Paca_Usua_Codigo'       ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio que digitou'                       ,''    ,False,'3','','','0');
  Inst.AddField('PlanoAcao','Paca_Usua_Resp'         ,'N',3  ,0,50  ,True ,'Respons�vel'               ,'Usu�rio respons�vel'                       ,''    ,False,'3','','','0');
  Inst.AddField('PlanoAcao','Paca_Usua_Exclusao'     ,'N',3  ,0,50  ,True ,'Exclus�o'                 ,'Usu�rio que excluiu'                       ,''    ,False,'3','','','0');
  Inst.AddField('PlanoAcao','Paca_Data'              ,'D',0  ,0,60  ,True ,'Data'  ,'Data Plano de A��o','',True,'1','','','0');
  Inst.AddField('PlanoAcao','Paca_Dtlcto'            ,'D',0  ,0,60  ,True ,'Data'  ,'Data Lcto Plano de A��o','',True,'1','','','0');
  Inst.AddField('PlanoAcao','Paca_Seto_codigo'       ,'C',4  ,0,30  ,True,'Setor'                    ,'Codigo do Setor'                          ,''    ,False,'2','','','0');
  Inst.AddField('PlanoAcao','Paca_Objetivo'          ,'C',1000,0,300 ,True,'Objetivo'                 ,'Objetivo'                          ,''    ,False,'1','','','0');
  Inst.AddField('PlanoAcao','Paca_Oque'              ,'C',1000,0,300 ,True,'O que ?'                  ,'O que ?'                          ,''    ,False,'1','','','0');
  Inst.AddField('PlanoAcao','Paca_Como'              ,'C',1000,0,300 ,True,'Como ?'                  ,'Como ?'                          ,''    ,False,'1','','','0');
  Inst.AddField('PlanoAcao','Paca_Quem'              ,'C',1000,0,300 ,True,'Quem ?'                  ,'Quem ?'                          ,''    ,False,'1','','','0');
  Inst.AddField('PlanoAcao','Paca_Usua_Quem'         ,'N',3   ,0,50  ,True,'Usu.Quem ?'                  ,'Usu�rio que executar� a tarefa'                          ,''    ,False,'3','','','0');
//  Inst.AddField('PlanoAcao','Paca_Quando'            ,'C',1000,0,300 ,True,'Quando ?'                  ,'Quando ?'                          ,''    ,False,'1','','','0');
  Inst.AddField('PlanoAcao','Paca_Quando'            ,'D',8   ,0,070 ,True,'Quando ?'                  ,'Quando ?'                          ,''    ,False,'1','','','0');
  Inst.AddField('PlanoAcao','Paca_Porque'            ,'C',1000,0,300 ,True,'Por que ?'                  ,'Por que ?'                          ,''    ,False,'1','','','0');
  Inst.AddField('PlanoAcao','Paca_DtEncerra'         ,'D',0  ,0,60   ,True ,'Encerramento'  ,'Data de Encerramento','',True,'1','','','0');
  Inst.AddField('PlanoAcao','Paca_Valor'             ,'N',12 ,3,70   ,True ,'Valor'                  ,'Valor estimado'                       ,''    ,False,'3','','','0');
// 17.11.08
  Inst.AddField('PlanoAcao','Paca_Usua_Ence'         ,'N',3   ,0,50  ,True,'Encerramento'                ,'Usu�rio que encerrou a tarefa'                          ,''    ,False,'3','','','0');


// 15.12.08 - insumos da planilha de custo vinculada ao or�amento ( mostrado no grid )
  Inst.AddTable('Orcainsumos');
  Inst.AddField('Orcainsumos','Orin_numerodoc'         ,'N',8  ,0,70,True,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('Orcainsumos','Orin_Nome'              ,'C',50 ,0,30,False,'Nome'                    ,'Nome do c�lculo do or�amento'                          ,''    ,False,'2','','','0');
  Inst.AddField('Orcainsumos','Orin_status'            ,'C',1  ,0,30,False,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','0');
  Inst.AddField('Orcainsumos','Orin_unid_codigo'       ,'C',3  ,0,40  ,False,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('Orcainsumos','Orin_esto_codigo'       ,'C',20 ,0,40  ,False,'C�digo'                    ,'C�digo do insumo'                            ,''    ,False,'1','','','0');
  Inst.AddField('Orcainsumos','orin_pesobruto'         ,'N',12 ,3,70,True,'Peso Bruto'                    ,'Peso Bruto'                         ,''    ,False,'3','','','0');
  Inst.AddField('Orcainsumos','orin_pesosobra'         ,'N',12 ,3,70,True,'Peso Sobra'                    ,'Peso Bruto'                         ,''    ,False,'3','','','0');
  Inst.AddField('Orcainsumos','orin_percsobrabruta'    ,'N',07 ,2,70,True,'% Sobra Bruta'                 ,'% Sobra Bruta'                         ,''    ,False,'3','','','0');
  Inst.AddField('Orcainsumos','orin_percperda'         ,'N',07 ,2,70,True,'% Perda'                    ,'% Perda'                         ,''    ,False,'3','','','0');
  Inst.AddField('Orcainsumos','orin_pesoreal'          ,'N',12 ,3,70,True,'Peso Real'                    ,'Peso Real'                         ,''    ,False,'3','','','0');
  Inst.AddField('Orcainsumos','orin_precouni'          ,'N',12 ,3,70,True,'Unit�rio'                      ,'Unit�rio'                           ,''    ,False,'3','','','0');
  Inst.AddField('Orcainsumos','orin_custopeca'         ,'N',12 ,3,70,True,'Custo/Pe�a'                    ,'Custo/Pe�a'                         ,''    ,False,'3','','','0');

// 20.02.09 - tabela de tipos notas fiscais DE MAO DE OBRA para identificar quando tem reten��o
//            de pis,cofins, csl, etc
//
  Inst.AddTable('TiposNota');
  Inst.AddField('TiposNota','Tipn_Codigo'       ,'N',5  ,0,50  ,False ,'Codigo'                   ,'Codigo do tipo de nota'                       ,''    ,False,'3','','','0');
  Inst.AddField('TiposNota','Tipn_descricao'    ,'C',50, 0,250  ,True ,'Descri��o'   ,'Descri��o do tipo de nota'                    ,''    ,False,'1','','','2');
  Inst.AddField('TiposNota','Tipn_Incidencias'  ,'C',100,0,150  ,True ,'Incid�ncias'                    ,'Define as incid�ncias dos impostos retidos na nota'                            ,''    ,False,'2','','','0');
//
// 04.05.09 - Abra - tabelas de indicadores
///////////////////////////////////////////
  Inst.AddTable('Indicadores');
  Inst.AddField('Indicadores','Indi_Codigo'       ,'N',5  ,0,50  ,True ,'Codigo'                   ,'Codigo do indicador'                          ,''    ,False,'3','','','0');
  Inst.AddField('Indicadores','Indi_descricao'    ,'C',50, 0,250 ,True ,'Descri��o'   ,'Descri��o do indicador'                       ,''    ,False,'1','','','2');
  Inst.AddField('Indicadores','Indi_Usua_Codigo'  ,'N',3   ,0,50 ,True ,'Usu�rio'     ,'Usu�rio que incluiu/alterou o cadastro do indicador'                       ,''    ,False,'3','','','0');
  Inst.AddField('Indicadores','Indi_Usua_Resp'    ,'N',3   ,0,50 ,True ,'Resp.'       ,'Usu�rio respons�vel pelo indicador'                       ,''    ,False,'3','','','0');
  Inst.AddField('Indicadores','Indi_DiaInfo'      ,'N',2   ,0,70 ,True ,'Dia Inf.'               ,'Dia para informar indicador'  ,''    ,False,'3','','','0');
  Inst.AddField('Indicadores','Indi_Unidade'      ,'C',10  ,0,70 ,True ,'Unidade'               ,'V-Valor ou P-Percentual'  ,''    ,False,'3','','','0');
// 15.10.09 - Paulo paulek
  Inst.AddField('Indicadores','Indi_Seto_Codigo'  ,'C',4   ,0,50,True,'Setor','C�digo do setor','0000',False,'1','','','0');

  Inst.AddTable('MovIndicadores');
  Inst.AddField('MovIndicadores','MInd_Indi_Codigo' ,'N',5  ,0,50  ,True ,'Codigo'                   ,'Codigo do indicador'                          ,''    ,False,'3','','','0');
  Inst.AddField('MovIndicadores','MInd_Status'      ,'C',50, 0,250 ,True ,'Status'   ,'Status do lan�amento'                       ,''    ,False,'1','','','2');
  Inst.AddField('MovIndicadores','MInd_Usua_Codigo' ,'N',3   ,0,50 ,True ,'Usu�rio'     ,'Usu�rio que informou o indicador'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovIndicadores','MInd_IndiPrevi'   ,'N',12  ,3,70 ,True ,'Previsto'          ,'Valor OU percentual do indicador Previsto'  ,''    ,False,'3','','','0');
  Inst.AddField('MovIndicadores','MInd_IndiReal'    ,'N',12  ,3,70 ,True ,'Realizado'         ,'Valor OU percentual do indicador Realizado'  ,''    ,False,'3','','','0');
  Inst.AddField('MovIndicadores','MInd_DataLcto'    ,'D',8   ,0,70 ,True ,'Data'               ,'Data que foi informado'  ,''    ,False,'3','','','0');
  Inst.AddField('MovIndicadores','MInd_DataInd'     ,'D',8   ,0,70 ,True ,'Data Ind.'          ,'Data do indicador'  ,''    ,False,'3','','','0');
///////////////////////////////////////////
// 08.09.10
  Inst.AddTable('MovNFeEstoque');
  Inst.AddField('MovNFeEstoque','Mnfe_status'            ,'C',1 ,0,30  ,True,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovNFeEstoque','Mnfe_esto_codigo'       ,'C',20 ,0,90 ,True,'Produto'                    ,'C�digo do produto'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovNFeEstoque','Mnfe_tipo_codigo'       ,'N',7  ,0,90 ,True,'Fornec.'                    ,'Codigo do fornecedor'                ,''    ,False,'2','','','0');
  Inst.AddField('MovNFeEstoque','Mnfe_forn_codigo'       ,'C',20 ,0,90 ,True,'Codigo'                    ,'C�digo do fornecedor'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovNFeEstoque','Mnfe_Data'              ,'D',8  ,0,70 ,True,'Data'                     ,'Data da entrada'  ,''    ,False,'3','','','0');
///////////////////////////////////////////
// 13.07.11
  Inst.AddTable('MovLeituraEcf');
  Inst.AddField('MovLeituraEcf','Mecf_status'            ,'C',1   ,0,30 ,True,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovLeituraEcf','Mecf_Tipo'              ,'C',1   ,0,30 ,True,'Tipo'                    ,'Tipo da Leitura'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovLeituraEcf','Mecf_Usua_Codigo'       ,'N',3   ,0,50 ,True,'Usu�rio'     ,'Usu�rio que executou a leitura no ECF'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_Data'              ,'D',8   ,0,70 ,True,'Data'                     ,'Data da leitura'  ,''    ,False,'3','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_unid_codigo'       ,'C',3   ,0,40 ,True,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_Hora'              ,'C',8   ,0,50 ,True,'Hora','Hora da leitura','',False,'1','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_leitura'           ,'C',200 ,0,150,True,'Leitura'                    ,'Informa��o da Leitura'                            ,''    ,False,'1','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_NumeroSerie'       ,'C',20  ,0,140,True,'Num.S�rie','Numero de S�rie do equipamento','',False,'1','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_NumeroOrdem'       ,'N',05  ,0,040,True,'Num.Ordem','Numero de Ordem sequencial do equipamento','',False,'1','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_Modelo'            ,'C',02  ,0,040,True,'Modelo','Codigo do modelo do documento fiscal','',False,'1','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_NumeroCOOi'        ,'N',08  ,0,060,True,'COO Inicial','Contador de Ordem de OPera��o no in�cio do dia','',False,'3','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_NumeroCOOf'        ,'N',08  ,0,060,True,'COO Final'  ,'Contador de Ordem de OPera��o no fim do dia','',False,'3','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_NumeroCRZ'         ,'N',08  ,0,060,True,'CRZ '  ,'Contador da Redu��o Z','',False,'3','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_NumeroCRO'         ,'N',05  ,0,060,True,'CRO '  ,'Valor acumulado do Contador de rein�cio de opera��o','',False,'3','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_VendaBruta'        ,'N',16  ,3,090,True,'Venda Bruta'  ,'Valor acumulado da venda bruta','',False,'3','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_TotalGeral'        ,'N',16  ,3,090,True,'Total Geral'  ,'Valor acumulado do totalizador geral','',False,'3','','','0');
  Inst.AddField('MovLeituraEcf','Mecf_AliqsIcms'         ,'C',300 ,0,200,True,'% Icms'      ,'Valores para cada al�quota de Icms'                            ,''    ,False,'1','','','0');

///////////////////////////////////////////
// 20.01.16
  Inst.AddTable('MovCargas');
  Inst.AddField('MovCargas','Movc_status'            ,'C',1   ,0,30 ,True,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovCargas','Movc_Numero'            ,'N',08  ,0,040,True,'Carga','Numero da Carga','',False,'1','','','0');
  Inst.AddField('MovCargas','Movc_Data'              ,'D',8   ,0,70 ,True,'Data'                     ,'Data da carga'  ,''    ,False,'3','','','0');
  Inst.AddField('MovCargas','Movc_DataMvto'          ,'D',8   ,0,70 ,True,'Data Movto.'                     ,'Data de lan�amento'  ,''    ,False,'3','','','0');
  Inst.AddField('MovCargas','Movc_unid_codigo'       ,'C',3   ,0,40 ,True,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovCargas','Movc_Usua_Codigo'       ,'N',3   ,0,50 ,True,'Usu�rio'     ,'Usu�rio que digitou a carga'                       ,''    ,False,'3','','','0');
  Inst.AddField('MovCargas','Movc_PesoI'             ,'N',16  ,3,090,True,'Peso Inicial'  ,'Peso Inicial da balan�a da carga','',False,'3','','','0');
  Inst.AddField('MovCargas','Movc_PesoF'             ,'N',16  ,3,090,True,'Peso Final'  ,'Peso Final da balan�a da carga','',False,'3','','','0');
  Inst.AddField('MovCargas','Movc_DifPeso'           ,'N',16  ,3,090,True,'Dif. Peso'  ,'Diferen�a de Peso da carga','',False,'3','','','0');
  Inst.AddField('MovCargas','Movc_tran_codigo'       ,'C',3   ,0,30 ,True ,'C�digo'     ,'C�digo do ve�culo/transportador'                   ,''    ,False,'1','','','0');
  Inst.AddField('MovCargas','Movc_cola_codigo01'     ,'C',4  ,0,70  ,True ,'Motorista 01' ,'Colaborador que dirigiu o ve�culo'                               ,''    ,True ,'3','','','0');
  Inst.AddField('MovCargas','Movc_cola_codigo02'     ,'C',4  ,0,70  ,True ,'Motorista 02' ,'Colaborador que auxiliou/dirigiu o ve�culo'                               ,''    ,True ,'3','','','0');
  Inst.AddField('MovCargas','Movc_PesoNotas'         ,'N',16  ,3,090,True ,'Peso Notas'  ,'Peso Total das notas da carga','',False,'3','','','0');
// 11.09.18 - Novicarnes - Km do caminh�o
  Inst.AddField('MovCargas','Movc_Km'                ,'N',10  ,2,090,True ,'KM Ve�culo'  ,'KM Ve�culo quando carregou a carga','',False,'3','','','0');
// 30.05.19 - mdfe
  Inst.AddField('MovCargas','Movc_xmlmdfe'           ,'M', 0,  0,300,True ,'XML MDFe'                  ,'XML MDFe'                             ,''    ,False,'1','','','0');
  Inst.AddField('MovCargas','Movc_dtauto'            ,'D', 0,  0,300,True ,'Data'                  ,'Data autoriza��o'                             ,''    ,False,'1','','','0');
  Inst.AddField('MovCargas','Movc_protocolo'         ,'C',30,  0,70  ,True,'Protocolo' ,'Numero do protocolo de envio'                               ,''    ,True ,'1','','','0');
  Inst.AddField('MovCargas','Movc_recibo'            ,'C',30,  0,70  ,True,'Recibo'    ,'Numero do recibo de envio'                               ,''    ,True ,'1','','','0');
  Inst.AddField('MovCargas','Movc_xmlmdfeenc'        ,'M', 0,  0,300,True ,'XML Enc.MDFe'                  ,'XML de encerramento do MDFe'                             ,''    ,False,'1','','','0');
  Inst.AddField('MovCargas','Movc_dtenc '            ,'D', 0,  0,008,True ,'Data Enc.'                  ,'Data do encerramento do MDFe'                             ,''    ,False,'1','','','0');
  Inst.AddField('MovCargas','Movc_xmlcancmdfe'       ,'M', 0,  0,300,True ,'XML Canc.MDFe'                  ,'XML de cancelamento do MDFe'                             ,''    ,False,'1','','','0');
  Inst.AddField('MovCargas','Movc_dtcanc'            ,'D', 0,  0,008,True ,'Data Canc.'                  ,'Data do cancelamento do MDFe'                             ,''    ,False,'1','','','0');
// 11.07.19
  Inst.AddField('MovCargas','Movc_NumeroMdfe'       ,'N',08  ,0,040,True, 'Mdfe','Numero do Mdfe','',False,'1','','','0');
  Inst.AddField('MovCargas','Movc_ChaveMdfe'        ,'C',44  ,0,140,True, 'Chave Mdfe','Chave do Mdfe','',False,'1','','','0');
// 12.05.20
  Inst.AddField('MovCargas','Movc_PesoPedidos'      ,'N',16  ,3,090,True ,'Peso Pedidos'  ,'Peso Total dos pedidos da carga','',False,'3','','','0');
// 05.06.20
  Inst.AddField('MovCargas','Movc_Pesada'           ,'N',2   ,0,090,True ,'Pesada'  ,'Vez que o caminh�o pesou no dia','',False,'3','','','0');


// 17.03.17 - tabela de 'agendamento'
  Inst.AddTable('Movagenda');
  Inst.AddField('Movagenda','Moag_status'            ,'C',1  ,0,30 ,True,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('Movagenda','Moag_Numero'            ,'N',08 ,0,040,True,'Agendamento','Numero do Agendamento','',False,'1','','','0');
  Inst.AddField('Movagenda','Moag_DataLcto'          ,'D',8  ,0,70 ,True,'Data'                     ,'Data da Agendamento'  ,''    ,False,'3','','','0');
  Inst.AddField('Movagenda','Moag_DataMvto'          ,'D',8  ,0,70 ,True,'Data Movto.'                     ,'Data de lan�amento'  ,''    ,False,'3','','','0');
  Inst.AddField('Movagenda','Moag_unid_codigo'       ,'C',3  ,0,40 ,True,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('Movagenda','Moag_Usua_Codigo'       ,'N',3  ,0,50 ,True,'Usu�rio'     ,'Usu�rio que digitou a informa��o'                       ,''    ,False,'3','','','0');
  Inst.AddField('Movagenda','Moag_tipocad'           ,'C',1  ,0,30 ,True,'TipoCad'                ,'Tipo de Cadastro'                          ,''    ,True,'2','','','2');
  Inst.AddField('Movagenda','Moag_tipo_codigo'       ,'N',7  ,0,90 ,True,'C�digo'                    ,'C�digo do cliente/fornecedor'                ,''    ,True,'2','','','0');
  Inst.AddField('Movagenda','Moag_tipoage'           ,'C',1  ,0,30 ,True,'Tipo'                ,'Tipo de Agendamento'                          ,''    ,True,'2','','','2');
  Inst.AddField('Movagenda','Moag_valor'             ,'N',12 ,3,090,True,'Valor'  ,'Valor do agendamento','',False,'3','','','0');
  Inst.AddField('Movagenda','Moag_hora'              ,'C',5  ,0,50 ,True,'Hor�rio'                ,'Hor�rio do agendamento'                          ,''    ,True,'2','','','2');

// 25.10.18
// tabela das ligacoes do televendas
  Inst.AddTable('Movtelevendas');
  Inst.AddField('Movtelevendas','Movt_status'            ,'C',1 ,0,30,True,'Status'                      ,'Status do registro'                          ,''    ,False,'2','','','0');
  Inst.AddField('Movtelevendas','Movt_DataMvto'          ,'D',0  ,0,60  ,True ,'Data'  ,'Data da liga��o','',True,'1','','','0');
  Inst.AddField('Movtelevendas','Movt_DataRepro'         ,'D',0  ,0,60  ,True ,'Data Repr.'  ,'Data para futura liga��o','',True,'1','','','0');
  Inst.AddField('Movtelevendas','Movt_Dtlcto'            ,'D',0  ,0,60  ,True ,'Data'  ,'Data Lcto da liga��o','',True,'1','','','0');
  Inst.AddField('Movtelevendas','Movt_unid_codigo'       ,'C',3  ,0,40  ,True,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','0');
  Inst.AddField('Movtelevendas','Movt_situacao'          ,'C',1  ,0,45  ,True,'Situa��o'                  ,'Situa��o'                                    ,''    ,False,'2','','','0');
  Inst.AddField('Movtelevendas','Movt_Usua_Codigo'       ,'N',3  ,0,50  ,True ,'Usu�rio'                   ,'Usu�rio que digitou'                       ,''    ,False,'3','','','0');
  Inst.AddField('Movtelevendas','Movt_Obs'               ,'C',1000,0,300 ,True,'Observa��es'                 ,'Objetivo'                          ,''    ,False,'1','','','0');
  Inst.AddField('Movtelevendas','Movt_Tipo_Codigo'       ,'N',7  ,0,50  ,True ,'Codigo'                   ,'Cliente da liga��o'                       ,''    ,False,'3','','','0');
  Inst.AddField('Movtelevendas','Movt_tipocad'           ,'C',1  ,0,30 ,True  ,'TipoCad'                ,'Tipo de Cadastro'                          ,''    ,True,'2','','','2');
  Inst.AddField('Movtelevendas','Movt_Caoc_codigo'       ,'N',3  ,0,45  ,True, 'Resultado'                  ,'Resultado da liga��o'                                    ,''    ,False,'2','','','0');
  Inst.AddField('Movtelevendas','Movt_operacao'          ,'C',16 ,0,140 ,True, 'Opera��o',  'Opera��o','',False,'1','','','0');
  Inst.AddField('Movtelevendas','Movt_Contato'           ,'C',100 ,0,140 ,True,'Contato',  'Contato','',False,'1','','','0');
// 16.09.20
  Inst.AddField('Movtelevendas','Movt_transcontrato'     ,'C',16 ,0,140 ,True, 'Transa�ao',  'Transa��o do contrato','',False,'1','','','0');
// 10.09.2021
  Inst.AddField('Movtelevendas','Movt_ValorLiberado'  ,'N',12,2,80,True,'Valor Liberado','Valor Liberado',f_cr,True,'3','','','0');
  Inst.AddField('Movtelevendas','Movt_ValorSolicitado','N',12,2,80,True,'Valor Solicitado','Valor Solicitado',f_cr,True,'3','','','0');
  Inst.AddField('Movtelevendas','Movt_Parcela',        'N',12,2,80,True,'Valor Parcela','Valor parcela',f_cr,True,'3','','','0');
  Inst.AddField('Movtelevendas','Movt_banco'      ,    'C',3 ,0,30,True,'Banco'         ,'Codigo do banco'                          ,''    ,False,'2','','','0');
  Inst.AddField('Movtelevendas','Movt_Parcelas',       'N',04 ,0,80,True,'No.Parcelas','N�mero de parcelas',f_cr,True,'3','','','0');
  Inst.AddField('Movtelevendas','Movt_Tipoconta'       ,'C',20,0,130,True,'Tipo Conta'    ,'Tipo Conta'                          ,''    ,False,'2','','','0');
  Inst.AddField('Movtelevendas','Movt_Agencia'         ,'C',10,0,130,True,'Ag�ncia'    ,'Ag�ncia'                          ,''    ,False,'2','','','0');
  Inst.AddField('Movtelevendas','Movt_Conta'           ,'C',20,0,130,True,'Conta'    ,'Conta'                          ,''    ,False,'2','','','0');
  Inst.AddField('Movtelevendas','Movt_Beneficio'       ,'C',20,0,130,True,'Benef�cio'    ,'Benef�cio'                          ,''    ,False,'2','','','0');

// 20.03.19
// tabela com contas contabeis de debito/credito usadas na exporta��o contabil
  Inst.AddTable('movcontab');
  Inst.AddField('movcontab','Moct_tipo'              ,'C',10 ,0,30 ,True ,'Tipo'                      ,'Tipo da exporta��o'                          ,''    ,False,'2','','','0');
  Inst.AddField('movcontab','Moct_DataMvto'          ,'D',0  ,0,60 ,True ,'Data'  ,'Data de movimento da nota','',True,'1','','','0');
  Inst.AddField('movcontab','Moct_unid_codigo'       ,'C',03 ,0,60 ,True ,'Unidade'  ,'Codigo da unidade','',True,'1','','','0');
  Inst.AddField('movcontab','Moct_transacao'         ,'C',12 ,0,60 ,True ,'Transa��o'  ,'Data da transa��o','',True,'1','','','0');
  Inst.AddField('movcontab','Moct_debito'            ,'N',08 ,0,60 ,True ,'D�bito'  ,'Conta a d�bito','',True,'3','','','0');
  Inst.AddField('movcontab','Moct_credito'           ,'N',08 ,0,60 ,True ,'Cr�dito'  ,'Conta a cr�ito','',True,'3','','','0');

// 12.05.20
// tabela 'inicial' para gravar valores de centro de custo
  Inst.AddTable('CentrosdeCusto');
  Inst.AddField('CentrosdeCusto','Ccus_Data',       'D',0,0,60,True,'Mes/ano CC','Mes/ano do centro de custo','',True,'1','','','0');
  Inst.AddField('CentrosdeCusto','Ccus_Unid_Codigo','C',3,0,30,True,'Unidade','C�digo da unidade','000',False,'1','','','0');
  Inst.AddField('CentrosdeCusto','Ccus_Codigo',     'C',08,0,70,True ,'C�digo','C�digo do centro de custo','',False,'1','','','0');
  Inst.AddField('CentrosdeCusto','Ccus_plan_Contas','C',100,0,200,True,'Contas','Contas que somam neste centro de custo','',False,'3','','','0');
  Inst.AddField('CentrosdeCusto','Ccus_VlrReal'    ,'N',12,2,80,True,'Valor CC','Valor do centro de custo',f_cr,True,'3','','','0');
  Inst.AddField('CentrosdeCusto','Ccus_VlrMeta'    ,'N',12,3,50,True ,'Meta em Valor','Valor desej�vel para este centro de custo','',False,'3','','','0');

// tabela 'inicial' para gravar valores ref. apropriacao de valores de custos para contab.
  Inst.AddTable('Apropriacoes');
  Inst.AddField('Apropriacoes','Apro_status'     ,'C',1 ,0,30,True,'Status'                      ,'Status do registro'                          ,''    ,False,'2','','','0');
  Inst.AddField('Apropriacoes','Apro_Unid_Codigo','C',3,0,30,True,'Unidade','C�digo da unidade','000',False,'1','','','0');
  Inst.AddField('Apropriacoes','Apro_transacao'  ,'C',12 ,0,60 ,True ,'Transa��o'  ,'Data da transa��o','',True,'1','','','0');
  Inst.AddField('Apropriacoes','Apro_Data',       'D',0,0, 60,True,'Data','Data da apropria��o do valor','',True,'1','','','0');
  Inst.AddField('Apropriacoes','Apro_Valor',      'N',12,2,80,True,'Valor','Valor da apropria��o',f_cr,True,'3','','','0');
  Inst.AddField('Apropriacoes','Apro_NVezes',     'N',03,0,80,True,'Vezes','Numero de vezes a apropriar',f_cr,True,'3','','','0');
  Inst.AddField('Apropriacoes','Apro_Vez',        'N',03,0,80,True,'Vez'  ,'Numero da vez sendo apropriar',f_cr,True,'3','','','0');
  Inst.AddField('Apropriacoes','Apro_Comv_codigo','N',3  ,0,40  ,true ,'Codigo'                    ,'Codigo da configura��o'                     ,''    ,False,'1','','','0');
  Inst.AddField('Apropriacoes','Apro_tipomov'    ,'C',2  ,0,30  ,True ,'Tipo'                      ,'Tipo do movimento'                           ,''    ,False,'1','','','0');
  Inst.AddField('Apropriacoes','Apro_numerodoc'  ,'N',8  ,0,90  ,False,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('Apropriacoes','Apro_plan_codigo','N',8  ,0,70  ,True ,'Conta'                     ,'Conta de despesa/receita'                               ,''    ,True ,'3','','','0');

// 16.09.20
// tabela de movimentos dos contratos de emprestimo
  Inst.AddTable('Contratos');
  Inst.AddField('Contratos','Cont_status'     ,    'C',1 ,0,30,True,'Status'                      ,'Status do registro'                          ,''    ,False,'2','','','0');
  Inst.AddField('Contratos','Cont_Unid_Codigo',    'C',3,0,30,True,'Unidade','C�digo da unidade','000',False,'1','','','0');
  Inst.AddField('Contratos','Cont_transacao'  ,    'C',12 ,0,60 ,True ,'Transa��o'  ,'Data da transa��o','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_DataEnt',        'D',0,0, 60,True,'Data Entrada','Data da entrada do contrato','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_DataCon',        'D',0,0, 60,True,'Data Contrato','Data do contrato','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_Dtlcto'         ,'D',0  ,0,60  ,True ,'Data'  ,'Data Lcto Contrato','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_ValorOferecido', 'N',12,2,80,True,'Valor Oferecido','Valor oferecido',f_cr,True,'3','','','0');
  Inst.AddField('Contratos','Cont_ValorBruto',     'N',12,2,80,True,'Valor Bruto','Valor bruto',f_cr,True,'3','','','0');
  Inst.AddField('Contratos','Cont_Parcela',        'N',12,2,80,True,'Valor Parcela','Valor parcela',f_cr,True,'3','','','0');
  Inst.AddField('Contratos','Cont_fisico'     ,    'C',1 ,0,30,True,'F�sico'         ,'F�sico'                          ,''    ,False,'2','','','0');
  Inst.AddField('Contratos','Cont_tipo_codigo'    ,'N',7  ,0,90  ,True ,'C�digo Cliente'   ,'C�digo do cliente'                ,''    ,False,'2','','','0');
  Inst.AddField('Contratos','Cont_numerodoc'      ,'N',8  ,0,90  ,True,'Numero Contrato' ,'Numero do contrato'                         ,''    ,False,'2','','','2');
  Inst.AddField('Contratos','Cont_banco'          ,'C',3 ,0,30,True,'Banco'         ,'Codigo do banco'                          ,''    ,False,'2','','','0');
  Inst.AddField('Contratos','Cont_Usua_Codigo'    ,'N',3  ,0,50 ,True,'Usu�rio'     ,'Usu�rio que digitou a informa��o'                       ,''    ,False,'3','','','0');
  Inst.AddField('Contratos','Cont_Parcelas',       'N',04 ,0,80,True,'No.Parcelas','N�mero de parcelas',f_cr,True,'3','','','0');
// 15.07.2021 - 'a continua��o'
  Inst.AddField('Contratos','Cont_Tipo',          'C', 30, 0,100,True,'Tipo','Tipo de contrato','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_corretora',     'C', 30, 0,100,True,'Corretora','Nome da corretora','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_ValorLiquido',  'N', 12, 2,080,True,'Valor L�quido','Valor L�quido',f_cr,True,'3','','','0');
  Inst.AddField('Contratos','Cont_reducao',       'C',  1, 0,040,True ,'Redu��o'   ,'Se reduzo valor da parcela original','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_margem',        'N', 10, 2,080,True,'Valor Margem','Valor Margem',f_cr,True,'3','','','0');
  Inst.AddField('Contratos','Cont_Usua_Codigolig','N',  3, 0,050,True,'Ligou'     ,'Usu�rio que ligou'       ,''    ,False,'3','','','0');
  Inst.AddField('Contratos','Cont_Usua_Codigoate','N',  3, 0,050,True,'Atendeu'     ,'Usu�rio que atendeu'  ,''    ,False,'3','','','0');
  Inst.AddField('Contratos','Cont_DataPedSaldo',  'D',  0, 0,060,True,'Pedido Saldo','Data pedido do saldo','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_DataRecSaldo',  'D',  0, 0,060,True,'Receb. Saldo','Data recebimento do saldo','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_situacao',      'C', 30, 0,030,True,'Situa��o'    ,'Situa��o do contrato','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_DataAtual',     'D',  0, 0,060,True,'Data Atual.','Data atualiza��o','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_comsaldo',      'N', 12, 2,080,True,'Com Saldo','Com Saldo',f_cr,True,'3','','','0');
  Inst.AddField('Contratos','Cont_Tabp_Codigo'   ,'N', 03, 0,030,True,'C�digo'                    ,'C�digo da tabela','',False,'1','','','2');
  Inst.AddField('Contratos','Cont_TabAliquota'   ,'N', 07, 2,040,True,'Percentual'                ,'Percentual da tabela','',False,'1','','','2');
  Inst.AddField('Contratos','Cont_refiport',      'C', 01, 0,040,True,'Refi Port','Refi Port','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_bancoport'     ,'C',  3, 0,030,True,'Banco Port'         ,'Banco Portado'                          ,''    ,False,'2','','','0');
  Inst.AddField('Contratos','Cont_inf12pagas'    ,'C',  1, 0,030,True,'Inf.12 Pagas'  ,'Inferior 12 Pagas'                          ,''    ,False,'2','','','0');
  Inst.AddField('Contratos','Cont_situacaoprop',  'C', 30, 0,030,True,'Situa��o Prop.'    ,'Descri��o da situa��o proposta','',True,'1','','','0');
  Inst.AddField('Contratos','Cont_ComLiquido',    'N', 12, 2,080,True,'Com L�quido','Valor comiss�o l�quido',f_cr,True,'3','','','0');
  Inst.AddField('Contratos','Cont_ComBruto',      'N', 12, 2,080,True,'Com Bruto','Valor comiss�o bruto',f_cr,True,'3','','','0');


// 25.03.2021
//Olstri - Gelyane e Rodrigo
// tabela de movimentos dos atendimentos feitos nas maquinas dos clientes
  Inst.AddTable('MovCalibracoes');
  Inst.AddField('MovCalibracoes','Moca_status'     ,    'C',1 ,0,30,True,'Status'                      ,'Status do registro'                          ,''    ,False,'2','','','0');
  Inst.AddField('MovCalibracoes','Moca_Unid_Codigo',    'C',3,0,30,True,'Unidade','C�digo da unidade','000',False,'1','','','0');
  Inst.AddField('MovCalibracoes','Moca_transacao'  ,    'C',12 ,0,60 ,True ,'Transa��o'  ,'Numero da transa��o','',True,'1','','','0');
  Inst.AddField('MovCalibracoes','Moca_mped_numerodoc' ,'N',08  ,0,90  ,True ,'Pedido'                    ,'Numero do pedido'       ,''    ,False,'1','','','0');
  Inst.AddField('MovCalibracoes','Moca_vazaomedia'     ,'N',10  ,0,90  ,True ,'Vaz�o M�dia'   ,'Vaz�o M�dia de calibra��o'          ,''    ,False,'3','','','0');
  Inst.AddField('MovCalibracoes','Moca_Equi_Codigo'    ,'C',004,  0, 50,False,'Equip.','C�digo do equipamento/ve�culo','0000',False,'1','','','2');
  Inst.AddField('MovCalibracoes','Moca_tipo_codigo'    ,'N',007,  0,30 ,True ,'Cliente'                   ,'C�digo do cliente'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovCalibracoes','Moca_Data'           ,'D',0,   0, 60,True,'Data','Data da calibra��o','',True,'1','','','0');
  Inst.AddField('MovCalibracoes','Moca_Trabalho'       ,'M',000, 0,100,True,'Trabalho Realizado'  ,'Trabalho Realizado','',True,'1','','','0');

  Inst.AddTable('MovCalibracoesDet');
  Inst.AddField('MovCalibracoesDet','Mocd_status'     ,    'C',1 ,0,30,True,'Status'                      ,'Status do registro'                          ,''    ,False,'2','','','0');
  Inst.AddField('MovCalibracoesDet','Mocd_Unid_Codigo',    'C',3,0,30,True,'Unidade','C�digo da unidade','000',False,'1','','','0');
  Inst.AddField('MovCalibracoesDet','Mocd_transacao'  ,    'C',12 ,0,60 ,True ,'Transa��o'  ,'Sequencial do arquivo','',True,'1','','','0');
  Inst.AddField('MovCalibracoesDet','Mocd_mped_numerodoc' ,'N',08  ,0,90  ,True ,'Pedido'                    ,'Numero do pedido'       ,''    ,False,'1','','','0');
  Inst.AddField('MovCalibracoesDet','Mocd_fatorcalib'     ,'N',012, 4,080 ,True ,'Fator Calib.' ,'Fator de calibra��o'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovCalibracoesDet','Mocd_tanque'         ,'N',005, 0,080 ,True ,'Tanque' ,'Litros colocados no tanque'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovCalibracoesDet','Mocd_medido'         ,'N',005, 0,080 ,True ,'Medi��o' ,'Litros efetivamente medidos'                            ,''    ,False,'2','','','0');
  Inst.AddField('MovCalibracoesDet','Mocd_tipo_codigo'    ,'N',007,  0,30 ,True ,'Cliente'                   ,'C�digo do cliente'                            ,''    ,False,'2','','','0');


// 31.08.2021
// tabela de movimentos das atualiza��es e cada contrato de emprestimo
  Inst.AddTable('ContratosAtu');
  Inst.AddField('ContratosAtu','Cona_status'     ,    'C',1 ,0,30,True,'Status'                      ,'Status do registro'                          ,''    ,False,'2','','','0');
  Inst.AddField('ContratosAtu','Cona_Unid_Codigo',    'C',3,0,30,True,'Unidade','C�digo da unidade','000',False,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_transacao'  ,    'C',12 ,0,60 ,True ,'Transa��o'  ,'transa��o','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_operacao'   ,    'C',16 ,0,70 ,True ,'Opera��o'  ,'opera��o','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_DataEnt',        'D',0,0, 60,True,'Data Entrada','Data da entrada do contrato','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_DataCon',        'D',0,0, 60,True,'Data Contrato','Data do contrato','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_Dtlcto'         ,'D',0  ,0,60  ,True ,'Data'  ,'Data Lcto Contrato','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_ValorOferecido', 'N',12,2,80,True,'Valor Oferecido','Valor oferecido',f_cr,True,'3','','','0');
  Inst.AddField('ContratosAtu','Cona_ValorBruto',     'N',12,2,80,True,'Valor Bruto','Valor bruto',f_cr,True,'3','','','0');
  Inst.AddField('ContratosAtu','Cona_Parcela',        'N',12,2,80,True,'Valor Parcela','Valor parcela',f_cr,True,'3','','','0');
  Inst.AddField('ContratosAtu','Cona_fisico'     ,    'C',1 ,0,30,True,'F�sico'         ,'F�sico'                          ,''    ,False,'2','','','0');
  Inst.AddField('ContratosAtu','Cona_tipo_codigo'    ,'N',7  ,0,90  ,True ,'C�digo Cliente'   ,'C�digo do cliente'                ,''    ,False,'2','','','0');
  Inst.AddField('ContratosAtu','Cona_numerodoc'      ,'N',8  ,0,90  ,True,'Numero Contrato' ,'Numero do contrato'                         ,''    ,False,'2','','','2');
  Inst.AddField('ContratosAtu','Cona_banco'          ,'C',3 ,0,30,True,'Banco'         ,'Codigo do banco'                          ,''    ,False,'2','','','0');
  Inst.AddField('ContratosAtu','Cona_Usua_Codigo'    ,'N',3  ,0,50 ,True,'Usu�rio'     ,'Usu�rio que digitou a informa��o'                       ,''    ,False,'3','','','0');
  Inst.AddField('ContratosAtu','Cona_Parcelas',       'N',04 ,0,80,True,'No.Parcelas','N�mero de parcelas',f_cr,True,'3','','','0');
  Inst.AddField('ContratosAtu','Cona_Tipo',          'C', 30, 0,100,True,'Tipo','Tipo de contrato','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_corretora',     'C', 30, 0,100,True,'Corretora','Nome da corretora','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_ValorLiquido',  'N', 12, 2,080,True,'Valor L�quido','Valor L�quido',f_cr,True,'3','','','0');
  Inst.AddField('ContratosAtu','Cona_reducao',       'C',  1, 0,040,True ,'Redu��o'   ,'Se reduzo valor da parcela original','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_margem',        'N', 10, 2,080,True,'Valor Margem','Valor Margem',f_cr,True,'3','','','0');
  Inst.AddField('ContratosAtu','Cona_DataPedSaldo',  'D',  0, 0,060,True,'Pedido Saldo','Data pedido do saldo','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_DataRecSaldo',  'D',  0, 0,060,True,'Receb. Saldo','Data recebimento do saldo','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_situacao',      'C', 30, 0,030,True,'Situa��o'    ,'Situa��o do contrato','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_DataAtual',     'D',  0, 0,060,True,'Data Atual.','Data atualiza��o','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_comsaldo',      'N', 12, 2,080,True,'Com Saldo','Com Saldo',f_cr,True,'3','','','0');
  Inst.AddField('ContratosAtu','Cona_Tabp_Codigo'   ,'N', 03, 0,030,True,'C�digo'                    ,'C�digo da tabela','',False,'1','','','2');
  Inst.AddField('ContratosAtu','Cona_TabAliquota'   ,'N', 07, 2,040,True,'Percentual'                ,'Percentual da tabela','',False,'1','','','2');
  Inst.AddField('ContratosAtu','Cona_refiport',      'C', 01, 0,040,True,'Refi Port','Refi Port','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_bancoport'     ,'C',  3, 0,030,True,'Banco Port'         ,'Banco Portado'                          ,''    ,False,'2','','','0');
  Inst.AddField('ContratosAtu','Cona_inf12pagas'    ,'C',  1, 0,030,True,'Inf.12 Pagas'  ,'Inferior 12 Pagas'                          ,''    ,False,'2','','','0');
  Inst.AddField('ContratosAtu','Cona_situacaoprop',  'C', 30, 0,030,True,'Situa��o Prop.'    ,'Descri��o da situa��o proposta','',True,'1','','','0');
  Inst.AddField('ContratosAtu','Cona_ComLiquido',    'N', 12, 2,080,True,'Com L�quido','Valor comiss�o l�quido',f_cr,True,'3','','','0');
  Inst.AddField('ContratosAtu','Cona_ComBruto',      'N', 12, 2,080,True,'Com Bruto','Valor comiss�o bruto',f_cr,True,'3','','','0');


// 01.03.2023
// tabela de movimentos de notas e 'outros' a serem lan�ados para envio no reinf
// ref. aos registros da s�rie r4000 ref. a dirf...
  Inst.AddTable('MovReinf');
  Inst.AddField('MovReinf','Morf_Transacao'         ,'C',12 ,0,70  ,True,'Transa��o','N�mero da transa��o','',False,'3','','','0');
  Inst.AddField('MovReinf','Morf_Operacao'          ,'C',16 ,0,70  ,True,'Opera��o','N�mero da opera��o','',False,'3','','','0');
  Inst.AddField('MovReinf','Morf_numerodoc'         ,'N',8  ,0,90  ,True,'Numero'                    ,'Numero do documento'                         ,''    ,False,'2','','','2');
  Inst.AddField('MovReinf','Morf_status'            ,'C',1  ,0,30  ,True,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('MovReinf','Morf_evento'            ,'C',10 ,0,50  ,True,'Evento'           ,'Codigo do evento do reinf'                           ,''    ,False,'2','','','2');
// mais pra pagamentos a PF
  Inst.AddField('MovReinf','Morf_cpfcnpj'           ,'C',14 ,0,70  ,True,'CPF/CNPJ','CPF/CNPJdo benefici�rio','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_cpfdep01'          ,'C',11 ,0,70  ,True,'CPF 01','CPF do dependente 01','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_reldep01'          ,'C',02 ,0,70  ,True,'Rela�ao 01','Rela��o de dependencia 01','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_cpfdep02'          ,'C',11 ,0,70  ,True,'CPF 02','CPF do dependente 02','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_reldep02'          ,'C',02 ,0,70  ,True,'Rela�ao 02','Rela��o de dependencia 02','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_cpfdep03'          ,'C',11 ,0,70  ,True,'CPF 03','CPF do dependente 03','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_reldep03'          ,'C',02 ,0,70  ,True,'Rela�ao 03','Rela��o de dependencia 03','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_natrend'           ,'N',05 ,0,70  ,True,'Nat.Rend.','Natureza do rendimento(Tabela 01)','',True,'3','','','0');
  Inst.AddField('MovReinf','Morf_obs'               ,'C',200,0,170 ,True,'Observa��es','Observa��es','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_dtfg'              ,'D',  0, 0,060,True,'Data Pg.','Data do pagamento(do fator gerador)','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_compfp'            ,'D',  0, 0,060,True,'Compet�ncia','Compet�ncia no formato mes/ano','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_indDecTerc'        ,'C',01 ,0,170 ,True,'Ind.Dec.Ter.','Ind.Dec.Ter. S ou nao preenche','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_vlrRendBruto'      ,'N', 12, 2,080,True,'Rend. Bruto','Valor do rendimento bruto',f_cr,True,'3','','','0');
  Inst.AddField('MovReinf','Morf_vlrRendTrib'       ,'N', 12, 2,080,True,'Rend. Trib.','Valor do rendimento tributado',f_cr,True,'3','','','0');
  Inst.AddField('MovReinf','Morf_vlrIR'             ,'N', 12, 2,080,True,'Valor IR','Valor do IR',f_cr,True,'3','','','0');
  Inst.AddField('MovReinf','Morf_indRRA'            ,'C',01 ,0,170 ,True,'indRRA','Indicativo de Rendimento Recebido Acumuladamente','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_tpIsencao'         ,'C',02 ,0,170 ,True,'Tipo Isen.','Tipo de Isen��o','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_vlrisento'         ,'N', 12, 2,080,True,'Valor Isento','Valor da parcela isenta',f_cr,True,'3','','','0');
  Inst.AddField('MovReinf','Morf_descRendimento'    ,'C',100 ,0,170,True,'Descri��o','Descri��o do rendimento isento/n�o tribut�vel.','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_dtLaudo'           ,'D',  0, 0,060,True,'Laudo','Data da mol�stia grave atribu�da pelo laudo','',True,'1','','','0');
  Inst.AddField('MovReinf','Morf_isenImun'          ,'C',01 ,0,070 ,True,'Isen/Imun.','Informa��es sobre isen��o e imunidade','',True,'1','','','0');
// mais pra pagamentos a PJ ( R4020 )
  Inst.AddField('MovReinf','Morf_vlrBaseIR'         ,'N', 12, 2,080,True,'Base Ret. IR','Valor da base de reten��o do IR, efetivamente realizada',f_cr,True,'3','','','0');
  Inst.AddField('MovReinf','Morf_vlrBaseCSLL'       ,'N', 12, 2,080,True,'Base CSLL','Valor da base de c�lculo da Contribui��o Social sobre Lucro L�quido',f_cr,True,'3','','','0');
  Inst.AddField('MovReinf','Morf_vlrCSLL'           ,'N', 12, 2,080,True,'Valor CSLL','Valor da reten��o da Contribui��o Social sobre Lucro L�quido',f_cr,True,'3','','','0');
  Inst.AddField('MovReinf','Morf_vlrBaseCofins'     ,'N', 12, 2,080,True,'Base Cofins','Valor da base de c�lculo da Cofins',f_cr,True,'3','','','0');
  Inst.AddField('MovReinf','Morf_vlrCofins'         ,'N', 12, 2,080,True,'Valor Cofins','Valor da reten��o da Cofins',f_cr,True,'3','','','0');
  Inst.AddField('MovReinf','Morf_vlrBasePP'         ,'N', 12, 2,080,True,'Base Pis','Valor da base de c�lculo do Pis/Pasep',f_cr,True,'3','','','0');
  Inst.AddField('MovReinf','Morf_vlrPP'             ,'N', 12, 2,080,True,'Valor Cofins','Valor da reten��o do Pis/Pasep',f_cr,True,'3','','','0');


end;



procedure TFInstsac.InstCreateFields(Sender: TObject);
///////////////////////////////////////////////////////////////////
begin

  Inst.AddTable('Config1');
  Inst.AddField('Config1','Cfg1_Nome','C',20,0,50,True,'Nome','Nome do campo','',False,'1','','','0');
  Inst.AddField('Config1','Cfg1_Tipo','C',1,0,20,True,'Tipo','Tipo do campo','',False,'1','','','0');
  Inst.AddField('Config1','Cfg1_Conteudo','C',200,0,20,True,'Conteudo','Conteudo do campo','',False,'1','','','0');

  Inst.AddTable('Config2');
  Inst.AddField('Config2','Cfg2_Topicos','C',4000,0,50,True,'T�picos','T�picos de configura��o','',False,'1','','','0');

  Inst.AddTable('Controle');
  Inst.AddField('Controle','Ctrl_Registro','N',8,0,50,True,'Registro','N�mero registro','',False,'0','','','0');
  Inst.AddField('Controle','Ctrl_UsuExclusivo','N',8,0,50,True,'Usu�rio Exclusivo','Usu�rio exclusivo do sistema','',False,'0','','','0');
  Inst.AddField('Controle','Ctrl_DataManual','D',8,0,50,True,'Data Do Manual','Data da �ltima atualiza��o do manual','',False,'0','','','0');
  Inst.AddField('Controle','Ctrl_VersaoManual','C',8,0,50,True,'Vers�o Do Manual','Vers�o do manual do sistema','',False,'0','','','0');
  Inst.AddField('Controle','Ctrl_NovaVersao','C',1000,0,50,True,'Controle Nova Versao','Controle de execu��o de processos troca de vers�o','',False,'0','','','0');

  Inst.AddTable('Log');
  Inst.AddField('Log','Log_Codigo','N',8,0,50,True,'C�digo Evento','C�digo do evento','',False,'1','','','0');
  Inst.AddField('Log','Log_Data','D',8,0,50,True,'Data','Data do evento','',False,'1','','','0');
  Inst.AddField('Log','Log_Hora','C',8,0,50,True,'Hora','Hora do evento','',False,'1','','','0');
  Inst.AddField('Log','Log_Usua_Codigo','N',3,0,50,True,'Usu�rio','C�digo do usu�rio gerando do evento','',False,'1','','','0');
  Inst.AddField('Log','Log_Complemento','C',100,0,50,True,'Complemento','Complemento do evento','',False,'1','','','0');
// 11.04.06
  Inst.AddField('Log','Log_Usua_Canc'     ,'N',  3,0, 50,True,'Usu�rio','C�digo do usu�rio que solicitou o cancelamento','',False,'1','','','0');
  Inst.AddField('Log','Log_Motivo'        ,'C',200,0,120,True,'Motivo ','Descri��o do motivo','',False,'1','','','0');
  Inst.AddField('Log','log_transacaocanc' ,'C', 12,0,080,True,'Tran.Cancelada','Transa��o Cancelada','',False,'1','','','0');


  Inst.AddTable('Refresh');
  Inst.AddField('Refresh','Refr_Nome','C',15,0,50,True,'Nome','Nome do contador de refresh','',False,'3','','','2');
  Inst.AddField('Refresh','Refr_Posicao','N',08,0,70,True,'Posicao','Posi��o do contador','',False,'3','','','0');

(*
  Inst.AddTable('GerRel');
  Inst.AddField('GerRel','Grel_Descricao'  ,'C', 30,0, 60,True,'Descri��o'             ,'Descri��o do relat�rio','',false,'3','','','2');
  Inst.AddField('GerRel','Grel_Usuarios'  ,'C', 200,0, 60,True,'Usu�rios'             ,'Usu�rios para acesso ao relat�rio','',false,'3','','','2');
  Inst.AddField('GerRel','Grel_Comandos'   ,'M',100,0, 40, true,'Comandos'    ,'Comandos','', true,'','','','0');
  Inst.AddField('GerRel','Grel_Texto'   ,'M',100,0, 40, true,'Texto'    ,'Texto','', true,'','','','0');

  Inst.AddTable('Mensagens');
  Inst.AddField('Mensagens','Mens_Numero','N',08,0,50,False,'N�mero','N�mero da mensagem','',False,'3','','','2');
  Inst.AddField('Mensagens','Mens_UsuEnv','N',08,0,55,True,'Usu�rio Env�o','Usu�rio origem da mensagem','',False,'2','','','0');
  Inst.AddField('Mensagens','Mens_NomeEnv','C',50,0,55,True,'Nome Usu�rio Env�o','Nome Do usu�rio origem da mensagem','',False,'2','','','0');
  Inst.AddField('Mensagens','Mens_DataEnv','D',08,0,55,True,'Data Do Env�o','Data de env�o da mensagem','',False,'2','','','0');
  Inst.AddField('Mensagens','Mens_HoraEnv','C',05,0,55,True,'Hora Do Env�o','Hora do env�o da mensagem','',False,'2','','','0');
  Inst.AddField('Mensagens','Mens_Assunto','C',50,0,250,True,'Assunto','Assundo da mensagem','',False,'1','','','0');
  Inst.AddField('Mensagens','Mens_Texto','C',4000,0,250,True,'Texto','Texto da mensagem','',False,'1','','','0');
  Inst.AddField('Mensagens','Mens_DataRec','D',08,0,55,True,'Data Do Recebimento','Data de recebimento da mensagem','',False,'2','','','0');
  Inst.AddField('Mensagens','Mens_HoraRec','C',05,0,55,True,'Hora Do Recebimento','Hora do recebimento da mensagem','',False,'2','','','0');
  Inst.AddField('Mensagens','Mens_UsuDest','N',08,0,55,True,'Usu�rio Destino','Usu�rio destino da mensagem','',False,'2','','','0');
  Inst.AddField('Mensagens','Mens_Status','C',01,0,20,True,'Status','Status da mensagem','',False,'2','','','0');

  Inst.AddTable('Textos');
  Inst.AddField('Textos','Text_Identificador','C',30,0,50,False,'Identificador','Identificador do texto','',False,'3','','','2');
  Inst.AddField('Textos','Text_Texto','C',4000,0,250,True,'Texto','Texto','',False,'1','','','0');
*)

  CriaTabelasSistema;
  CriaTabelasdeCadastrodoSistema;
  CriaTabelasEstoque;
// 11.11.19
  CriaTabelasPonto;

end;


procedure TFInstsac.InstCreateConstraints(Sender: TObject);
begin

  Inst.AddConstraint('Regioes','Regi_PK','PK','Regi_Codigo','','');
  Inst.AddConstraint('Cidades','Cida_PK','PK','Cida_Codigo','','');
  Inst.AddConstraint('Usuarios','Usua_PK','PK','Usua_Codigo','','');
  Inst.AddConstraint('Grupousu','Grus_PK','PK','Grus_Codigo','','');
  Inst.AddConstraint('Unidades','Unid_PK','PK','Unid_Codigo','','');
  Inst.AddConstraint('Historicos','Hist_PK','PK','Hist_Codigo','','');
  Inst.AddConstraint('Natureza','Natf_PK','PK','Natf_Codigo','','');
  Inst.AddConstraint('Portadores','Port_PK','PK','Port_Codigo','','');
  Inst.AddConstraint('Moedas','Moed_PK','PK','Moed_Codigo','','');
  Inst.AddConstraint('FPgto','Fpgt_PK','PK','Fpgt_Codigo','','');
//  Inst.AddConstraint('LPgto','Lpgt_PK','PK','Lpgt_Codigo','','');
  Inst.AddConstraint('Dotacoes'    ,'Dota_PK','PK','Dota_Data,Dota_Unid_Codigo,Dota_plan_Conta','','');
  Inst.AddConstraint('Impressos'   ,'Impr_PK','PK','Impr_Codigo','','');
  Inst.AddConstraint('Fornecedores','Forn_PK','PK','Forn_Codigo','','');
  Inst.AddConstraint('Representantes','Repr_PK','PK','Repr_Codigo','','');
  Inst.AddConstraint('Transportadores','Tran_PK','PK','Tran_Codigo','','');
  Inst.AddConstraint('Clientes'    ,'Clie_PK','PK','Clie_Codigo','','');
  Inst.AddConstraint('Sittrib'     ,'Sitt_PK','PK','Sitt_Codigo','','');
  Inst.AddConstraint('Estoque'     ,'Esto_PK','PK','Esto_Codigo','','');
//  Inst.AddConstraint('EstoqueQtde' ,'Esqt_PK','PK','Esqt_status,Esqt_Esto_Codigo,Esqt_unid_codigo','','');
//  Inst.AddConstraint('SalEstoque'  ,'Saes_PK','PK','Saes_status,Saes_mesano,Saes_Esto_Codigo,Saes_unid_codigo','','');
  Inst.AddConstraint('Plano'       ,'Plan_PK','PK','Plan_Conta','','');
  Inst.AddConstraint('Motbloqueios','Mobl_PK','PK','Mobl_Codigo','','');
  Inst.AddConstraint('Cores'       ,'Core_PK','PK','Core_Codigo','','');
  Inst.AddConstraint('Tamanhos'    ,'Tama_PK','PK','Tama_Codigo','','');
  Inst.AddConstraint('Grupos'      ,'Grup_PK','PK','Grup_Codigo','','');
  Inst.AddConstraint('SubGrupos'   ,'Sugr_PK','PK','Sugr_Codigo','','');
  Inst.AddConstraint('Grades'      ,'Grad_PK','PK','Grad_Codigo','','');
  Inst.AddConstraint('TabelaPreco' ,'Tabp_PK','PK','Tabp_Codigo','','');
//  Inst.AddConstraint('CotasRepr'   ,'Core_PK','PK','Core_mesano,Core_Repr_Codigo','','');
// 13.03.09 - dava problema no instalador
  Inst.AddConstraint('MensagensNF'   ,'Mens_PK','PK','Mens_codigo','','');
  Inst.AddConstraint('CadOcorrencias','Caoc_PK','PK','Caoc_codigo','','');
// 13.07.06
  Inst.AddConstraint('Codigosipi'    ,'Cipi_PK','PK','Cipi_Codigo','','');
// 31.07.06
  Inst.AddConstraint('Similares'     ,'Simi_PK','PK','Simi_Esto_Codigo,Simi_Esto_Similar','','');
// 23.01.09
  Inst.AddConstraint('CadMObra'      ,'Cadm_PK','PK','Cadm_Codigo','','');
// 20.02.09
  Inst.AddConstraint('TiposNota'      ,'Tipn_PK','PK','Tipn_Codigo','','');
// 13.09.13
  Inst.AddConstraint('Equipamentos'      ,'Equi_PK','PK','Equi_Codigo','','');

end;

procedure TFInstsac.InstCreateIndexes(Sender: TObject);
/////////////////////////////////////////////////////////
begin

  Inst.AddIndex('Fornecedores','Forn_Nome_IDX','Forn_Nome');
  Inst.AddIndex('Fornecedores','Forn_Razao_IDX','Forn_RazaoSocial');
  Inst.AddIndex('Fornecedores','Forn_CNPJCPF_IDX','Forn_CNPJCPF');
  Inst.AddIndex('Fornecedores','Forn_CodVinc_IDX','Forn_CodVinc');

  Inst.AddIndex('Clientes','Clie_Nome_IDX','Clie_Nome');
  Inst.AddIndex('Clientes','Clie_CNPJCPF_IDX','Clie_CNPJCPF');
  Inst.AddIndex('Clientes','Clie_DataAlt_IDX','Clie_DataAlt');
// 26.02.15
  Inst.AddIndex('Clientesdoc','Clid_codigo_IDX','Clid_codigo');

  Inst.AddIndex('Estoque','Esto_codigo_IDX','Esto_Codigo');
  Inst.AddIndex('Estoque','Esto_Descricao_IDX','Esto_Descricao');
  Inst.AddIndex('Estoque','Esto_Grup_Codigo_IDX','Esto_Grup_Codigo');
  Inst.AddIndex('Estoque','Esto_SuGr_Codigo_IDX','Esto_SuGr_Codigo');
  Inst.AddIndex('Estoque','Esto_Codbarra_IDX'   ,'Esto_Codbarra');
// 08.03.06
  Inst.AddIndex('Estoque','Esto_Sisvendas_IDX'   ,'Esto_Sisvendas');
  Inst.AddIndex('Estoque','Esto_Categoria_IDX'   ,'Esto_Categoria');

  Inst.AddIndex('Estoqueqtde' ,'Esqt_status_IDX' ,'Esqt_status');
  Inst.AddIndex('Estoqueqtde' ,'Esqt_Esto_Codigo_IDX','Esqt_Esto_Codigo');
  Inst.AddIndex('Estoqueqtde' ,'Esqt_unid_codigo_IDX','Esqt_unid_codigo');
  Inst.AddIndex('Estoqueqtde' ,'Esqt_codbarra_IDX','Esqt_codbarra');
  Inst.AddIndex('Estoqueqtde' ,'Esqt_tama_codigo_IDX','Esqt_tama_codigo');
  Inst.AddIndex('Estoqueqtde' ,'Esqt_core_codigo_IDX','Esqt_core_codigo');
  Inst.AddIndex('Estoqueqtde' ,'Esqt_copa_codigo_IDX','Esqt_copa_codigo');

  Inst.AddIndex('EstGrades','Esgr_status_IDX'      ,'Esgr_status');
  Inst.AddIndex('EstGrades','Esgr_esto_codigo_IDX' ,'Esgr_esto_codigo');
  Inst.AddIndex('EstGrades','Esgr_grad_codigo_IDX' ,'Esgr_grad_codigo');
  Inst.AddIndex('EstGrades','Esgr_codigolinha_IDX' ,'Esgr_codigolinha');
  Inst.AddIndex('EstGrades','Esgr_codigocoluna_IDX','Esgr_codigocoluna');
  Inst.AddIndex('EstGrades','Esgr_core_codigo_IDX' ,'Esgr_core_codigo');
  Inst.AddIndex('EstGrades','Esgr_tama_codigo_IDX' ,'Esgr_tama_codigo');
  Inst.AddIndex('EstGrades','Esgr_codbarra_IDX','Esgr_codbarra');
  Inst.AddIndex('EstGrades','Esgr_copa_codigo_IDX' ,'Esgr_copa_codigo');
// 04.09.14 - transf. mensal estoque 20 minutos
  Inst.AddIndex('EstGrades' ,'Esgr_unid_codigo_IDX','Esgr_unid_codigo');

  Inst.AddIndex('MovEsto','Moes_Transacao_IDX'   ,'Moes_Transacao');
  Inst.AddIndex('MovEsto','Moes_Operacao_IDX'    ,'Moes_Operacao');
  Inst.AddIndex('MovEsto','Moes_status_IDX'      ,'Moes_status');
  Inst.AddIndex('MovEsto','Moes_numerodoc_IDX'   ,'Moes_numerodoc');
  Inst.AddIndex('MovEsto','Moes_tipomov_IDX'     ,'Moes_tipomov' );
  Inst.AddIndex('MovEsto','Moes_unid_codigo_IDX' ,'Moes_unid_codigo' );
  Inst.AddIndex('MovEsto','Moes_tipo_codigo_IDX' ,'Moes_tipo_codigo');
  Inst.AddIndex('MovEsto','Moes_repr_codigo_IDX' ,'Moes_repr_codigo');
  Inst.AddIndex('MovEsto','Moes_DataMvto_IDX'    ,'Moes_DataMvto');
  Inst.AddIndex('MovEsto','Moes_remessas_IDX'    ,'Moes_remessas');
//  Inst.AddIndex('MovEsto','Moes_Transretorno_IDX','Moes_Transretorno');
  Inst.AddIndex('MovEsto','Moes_tipo_codigoant_IDX' ,'Moes_tipo_codigoant');   // 09.01.05
  Inst.AddIndex('MovEsto','Moes_clie_codigo_IDX' ,'Moes_clie_codigo');   // 08.07.05
// 26.06.06
  Inst.AddIndex('MovEsto','Moes_tipo_codigoind_IDX','Moes_tipo_codigoind');
// 18.12.07
  Inst.AddIndex('MovEsto','Moes_nroobra_IDX','Moes_nroobra');
// 14.08.13
  Inst.AddIndex('MovEsto','Moes_natf_codigo_IDX'  ,'Moes_natf_codigo');
// 20.01.16
  Inst.AddIndex('MovEsto','Moes_DataEmissao_IDX'    ,'Moes_DataEmissao');
  Inst.AddIndex('MovEsto','Moes_Carga_IDX'          ,'Moes_Carga');


  Inst.AddIndex('MovEstoque','Move_Transacao_IDX'   ,'Move_Transacao');
  Inst.AddIndex('MovEstoque','Move_Operacao_IDX'    ,'Move_Operacao');
  Inst.AddIndex('MovEstoque','Move_status_IDX'      ,'Move_status');
  Inst.AddIndex('MovEstoque','Move_numerodoc_IDX'   ,'Move_numerodoc');
  Inst.AddIndex('MovEstoque','Move_tipomov_IDX'     ,'Move_tipomov' );
  Inst.AddIndex('MovEstoque','Move_unid_codigo_IDX' ,'Move_unid_codigo' );
  Inst.AddIndex('MovEstoque','Move_esto_codigo_IDX' ,'Move_esto_codigo');
  Inst.AddIndex('MovEstoque','Move_grup_codigo_IDX' ,'Move_grup_codigo');
  Inst.AddIndex('MovEstoque','Move_sugr_codigo_IDX' ,'Move_sugr_codigo');
  Inst.AddIndex('MovEstoque','Move_fami_codigo_IDX' ,'Move_sugr_codigo');
  Inst.AddIndex('MovEstoque','Move_tama_codigo_IDX' ,'Move_tama_codigo');
  Inst.AddIndex('MovEstoque','Move_core_codigo_IDX' ,'Move_core_codigo');
  Inst.AddIndex('MovEstoque','Move_remessas_IDX'    ,'Move_remessas');
  Inst.AddIndex('MovEstoque','Move_tipo_codigo_IDX' ,'Move_tipo_codigo');  // 16.08.04
//  Inst.AddIndex('MovEstoque','Move_Transretorno_IDX','Move_Transretorno');
  Inst.AddIndex('MovEstoque','Move_tipo_codigoant_IDX' ,'Move_tipo_codigoant');  // 09.01.05
  Inst.AddIndex('MovEstoque','Move_clie_codigo_IDX' ,'Move_clie_codigo');  // 08.07.05
// 13.09.05
  Inst.AddIndex('MovEstoque','Move_DataMvto_IDX'    ,'Move_DataMvto');
// 23.02.06
  Inst.AddIndex('MovEstoque','Move_repr_codigo_IDX' ,'Move_repr_codigo');
//05.05.06
  Inst.AddIndex('MovEstoque','Move_copa_codigo_IDX' ,'Move_copa_codigo');
// 26.06.06
  Inst.AddIndex('MovEstoque','Move_tipo_codigoind_IDX'  ,'Move_tipo_codigoind');
// 18.12.07
  Inst.AddIndex('MovEstoque','Move_nroobra_IDX','Move_nroobra');
// 14.08.13
  Inst.AddIndex('MovEstoque','Move_natf_codigo_IDX'  ,'Move_natf_codigo');

//////////////////////////////////////////////////////////////////////////////////

  Inst.AddIndex('Plano','Plan_Descricao_IDX','Plan_Descricao');
  Inst.AddIndex('Plano','Plan_Classificacao_IDX','Plan_Classificacao');

  Inst.AddIndex('Dotacoes','Dota_Data_IDX','Dota_Data');
  Inst.AddIndex('Dotacoes','Dota_Unid_Codigo_IDX','Dota_Unid_Codigo');
  Inst.AddIndex('Dotacoes','Dota_plan_Conta_IDX','Dota_plan_Conta');

  Inst.AddIndex('SaldosBco','Sbco_plan_Conta_IDX','Sbco_plan_Conta');
  Inst.AddIndex('SaldosBco','Sbco_Data_IDX','Sbco_Data');

  Inst.AddIndex('MovBase'  ,'Movb_transacao_IDX'     ,'Movb_transacao');
  Inst.AddIndex('MovBase'  ,'Movb_numerodoc_IDX'    ,'Movb_numerodoc');
  Inst.AddIndex('MovBase'  ,'Movb_status_IDX'       ,'Movb_status');
  Inst.AddIndex('MovBase'  ,'Movb_cst_IDX'          ,'Movb_cst');
// 14.08.13
  Inst.AddIndex('MovBase'  ,'Movb_natf_codigo_IDX'  ,'Movb_natf_codigo');

  Inst.AddIndex('Pendencias','Pend_Transacao_IDX','Pend_Transacao');
  Inst.AddIndex('Pendencias','Pend_OPeracao_IDX' ,'Pend_Operacao');
  Inst.AddIndex('Pendencias','Pend_DataLcto_IDX' ,'Pend_DataLcto');
  Inst.AddIndex('Pendencias','Pend_DataMvto_IDX' ,'Pend_DataMvto');
  Inst.AddIndex('Pendencias','Pend_DataVcto_IDX','Pend_DataVcto');
  Inst.AddIndex('Pendencias','Pend_DataBaixa_IDX','Pend_DataBaixa');
//  Inst.AddIndex('Pendencias','Pend_DataAutPgto_IDX','Pend_DataAutPgto');
  Inst.AddIndex('Pendencias','Pend_Plan_Conta_IDX','Pend_Plan_Conta');
  Inst.AddIndex('Pendencias','Pend_Tipo_Codigo_IDX','Pend_Tipo_Codigo');
  Inst.AddIndex('Pendencias','Pend_RP_IDX','Pend_RP');
  Inst.AddIndex('Pendencias','Pend_Status_IDX','Pend_Status');
  Inst.AddIndex('Pendencias','Pend_Transbaixa_IDX','Pend_Transbaixa');

  Inst.AddIndex('Movfin'  ,'Movf_Transacao_IDX','Movf_Transacao');
  Inst.AddIndex('Movfin'  ,'Movf_OPeracao_IDX','Movf_Operacao');
  Inst.AddIndex('Movfin'  ,'Movf_Status_IDX','Movf_Status');
  Inst.AddIndex('Movfin'  ,'Movf_Unid_Codigo_IDX','Movf_Unid_codigo');
  Inst.AddIndex('Movfin'  ,'Movf_DataLcto_IDX','Movf_DataLcto');
  Inst.AddIndex('Movfin'  ,'Movf_DataMvto_IDX','Movf_DataMvto');
  Inst.AddIndex('Movfin'  ,'Movf_DataPrevista_IDX','Movf_DataPrevista');
  Inst.AddIndex('Movfin'  ,'Movf_DataExtrato_IDX','Movf_DataExtrato');
  Inst.AddIndex('Movfin'  ,'Movf_plan_Conta_IDX','Movf_plan_Conta');
  Inst.AddIndex('Movfin'  ,'Movf_plan_ContaRD_IDX','Movf_plan_ContaRD');
// 08.05.06
  Inst.AddIndex('Movfin'  ,'Movf_Repr_Codigo_IDX' ,'Movf_Repr_Codigo');
// 22.05.06
  Inst.AddIndex('Movfin'  ,'Movf_Tipo_Codigo_IDX' ,'Movf_Tipo_Codigo');

  Inst.AddIndex('Cheques','Cheq_Status_IDX'      ,'Cheq_Status');
  Inst.AddIndex('Cheques','Cheq_Emirec_IDX'      ,'Cheq_Emirec');
  Inst.AddIndex('Cheques','Cheq_bcoemitente_IDX' ,'Cheq_bcoemitente');
  Inst.AddIndex('Cheques','Cheq_Cheque_IDX'      ,'Cheq_Cheque');
  Inst.AddIndex('Cheques','Cheq_Emissao_IDX'     ,'Cheq_Emissao');
  Inst.AddIndex('Cheques','Cheq_Predata_IDX'     ,'Cheq_Predata');
  Inst.AddIndex('Cheques','Cheq_Lancto_IDX'      ,'Cheq_Lancto');
  Inst.AddIndex('Cheques','Cheq_Repr_codigo_IDX' ,'Cheq_Repr_codigo');
  Inst.AddIndex('Cheques','Cheq_Unid_codigo_IDX' ,'Cheq_UNid_codigo');
// 23.08.05 - ver se agiliza pesquisa de cheques
  Inst.AddIndex('Cheques','Cheq_emitente_IDX'    ,'Cheq_emitente');
// 13.03.06
  Inst.AddIndex('Cheques','Cheq_Tipo_codigo_IDX' ,'Cheq_Tipo_codigo');
  Inst.AddIndex('Cheques','Cheq_tipocad_IDX'     ,'Cheq_tipocad');
// 16.09.06
  Inst.AddIndex('Cheques'    ,'Cheq_Emit_Banco_IDX'     ,'Cheq_Emit_Banco');
  Inst.AddIndex('Cheques'    ,'Cheq_Emit_Agencia_IDX'   ,'Cheq_Emit_Agencia');
  Inst.AddIndex('Cheques'    ,'Cheq_Emit_Conta_IDX'     ,'Cheq_Emit_Conta');


  Inst.AddIndex('CotasRepr','Core_mesano_IDX'      ,'Core_mesano');
  Inst.AddIndex('CotasRepr','Core_Repr_Codigo_IDX' ,'Core_Repr_Codigo');

  Inst.AddIndex('MovComp','Mocm_Transacao_IDX'   ,'Mocm_Transacao');
  Inst.AddIndex('MovComp','Mocm_Operacao_IDX'    ,'Mocm_Operacao');
  Inst.AddIndex('MovComp','Mocm_status_IDX'      ,'Mocm_status');
  Inst.AddIndex('MovComp','Mocm_numerodoc_IDX'   ,'Mocm_numerodoc');
  Inst.AddIndex('MovComp','Mocm_tipomov_IDX'     ,'Mocm_tipomov' );
  Inst.AddIndex('MovComp','Mocm_unid_codigo_IDX' ,'Mocm_unid_codigo' );
  Inst.AddIndex('MovComp','Mocm_tipo_codigo_IDX' ,'Mocm_tipo_codigo');
  Inst.AddIndex('MovComp','Mocm_DataMvto_IDX'    ,'Mocm_DataMvto');
  Inst.AddIndex('MovComp','Mocm_DataEntrega_IDX' ,'Mocm_DataEntrega');

  Inst.AddIndex('MovCompras','Moco_Transacao_IDX'   ,'Moco_Transacao');
  Inst.AddIndex('MovCompras','Moco_Operacao_IDX'    ,'Moco_Operacao');
  Inst.AddIndex('MovCompras','Moco_status_IDX'      ,'Moco_status');
  Inst.AddIndex('MovCompras','Moco_numerodoc_IDX'   ,'Moco_numerodoc');
  Inst.AddIndex('MovCompras','Moco_tipomov_IDX'     ,'Moco_tipomov' );
  Inst.AddIndex('MovCompras','Moco_unid_codigo_IDX' ,'Moco_unid_codigo' );
  Inst.AddIndex('MovCompras','Moco_esto_codigo_IDX' ,'Moco_esto_codigo');
  Inst.AddIndex('MovCompras','Moco_tama_codigo_IDX' ,'Moco_tama_codigo');
  Inst.AddIndex('MovCompras','Moco_core_codigo_IDX' ,'Moco_core_codigo');
  Inst.AddIndex('MovCompras','Moco_copa_codigo_IDX' ,'Moco_copa_codigo');
// 29.08.06
  Inst.AddIndex('MovCompras','Moco_Seq_IDX'         ,'Moco_Seq');
  Inst.AddIndex('MovCompras','Moco_Transacaocompra_IDX','Moco_Transacaocompra');


  Inst.AddIndex('SalEstoque','Saes_status_IDX'      ,'Saes_status');
  Inst.AddIndex('SalEstoque','Saes_mesano_IDX'      ,'Saes_mesano');
  Inst.AddIndex('SalEstoque','Saes_unid_codigo_IDX' ,'Saes_unid_codigo');
  Inst.AddIndex('SalEstoque','Saes_Esto_codigo_IDX' ,'Saes_Esto_codigo');
  Inst.AddIndex('SalEstoque','Saes_tama_codigo_IDX' ,'Saes_tama_codigo');
  Inst.AddIndex('SalEstoque','Saes_core_codigo_IDX' ,'Saes_core_codigo');
  Inst.AddIndex('SalEstoque','Saes_copa_codigo_IDX' ,'Saes_copa_codigo');

  Inst.AddIndex('MensagensNF','Mens_codigo_IDX','Mens_Codigo');
  Inst.AddIndex('MensagensNF','Mens_Descricao_IDX','Mens_Descricao');
// 12.09.05
  Inst.AddIndex('CadOcorrencias','Caoc_codigo_IDX','Caoc_Codigo');
  Inst.AddIndex('CadOcorrencias','Caoc_Descricao_IDX','Caoc_Descricao');

  Inst.AddIndex('Ocorrencias'   ,'Ocor_Entidade_IDX'     ,'Ocor_CatEntidade,Ocor_CodEntidade');
  Inst.AddIndex('Ocorrencias'   ,'Ocor_Numerodoc_IDX'    ,'Ocor_Numerodoc');

  Inst.AddIndex('MovPed','Mped_Transacao_IDX'   ,'Mped_Transacao');
  Inst.AddIndex('MovPed','Mped_Operacao_IDX'    ,'Mped_Operacao');
  Inst.AddIndex('MovPed','Mped_status_IDX'      ,'Mped_status');
  Inst.AddIndex('MovPed','Mped_numerodoc_IDX'   ,'Mped_numerodoc');
  Inst.AddIndex('MovPed','Mped_tipomov_IDX'     ,'Mped_tipomov' );
  Inst.AddIndex('MovPed','Mped_unid_codigo_IDX' ,'Mped_unid_codigo' );
  Inst.AddIndex('MovPed','Mped_tipo_codigo_IDX' ,'Mped_tipo_codigo');
  Inst.AddIndex('MovPed','Mped_repr_codigo_IDX' ,'Mped_repr_codigo');
  Inst.AddIndex('MovPed','Mped_DataMvto_IDX'    ,'Mped_DataMvto');
// 22.02.06
  Inst.AddIndex('Movped','Mped_Transacaovenda_IDX','Mped_Transacaovenda');
  Inst.AddIndex('Movped','Mped_Transacaonftrans_IDX','Mped_Transacaonftrans');

  Inst.AddIndex('MovPedDet','Mpdd_Transacao_IDX'   ,'Mpdd_Transacao');
  Inst.AddIndex('MovPedDet','Mpdd_Operacao_IDX'    ,'Mpdd_Operacao');
  Inst.AddIndex('MovPedDet','Mpdd_status_IDX'      ,'Mpdd_status');
  Inst.AddIndex('MovPedDet','Mpdd_numerodoc_IDX'   ,'Mpdd_numerodoc');
  Inst.AddIndex('MovPedDet','Mpdd_tipomov_IDX'     ,'Mpdd_tipomov' );
  Inst.AddIndex('MovPedDet','Mpdd_unid_codigo_IDX' ,'Mpdd_unid_codigo' );
  Inst.AddIndex('MovPedDet','Mpdd_esto_codigo_IDX' ,'Mpdd_esto_codigo');
  Inst.AddIndex('MovPedDet','Mpdd_grup_codigo_IDX' ,'Mpdd_grup_codigo');
  Inst.AddIndex('MovPedDet','Mpdd_sugr_codigo_IDX' ,'Mpdd_sugr_codigo');
  Inst.AddIndex('MovPedDet','Mpdd_fami_codigo_IDX' ,'Mpdd_sugr_codigo');
  Inst.AddIndex('MovPedDet','Mpdd_tama_codigo_IDX' ,'Mpdd_tama_codigo');
  Inst.AddIndex('MovPedDet','Mpdd_core_codigo_IDX' ,'Mpdd_core_codigo');
  Inst.AddIndex('MovPedDet','Mpdd_tipo_codigo_IDX' ,'Mpdd_tipo_codigo');  // 16.08.04
// 13.09.05
  Inst.AddIndex('MovPedDet','Mpdd_DataMvto_IDX'    ,'Mpdd_DataMvto');
// 09.11.05
  Inst.AddIndex('MovPedDet','Mpdd_Seq_IDX'         ,'Mpdd_Seq');
// 22.02.06
  Inst.AddIndex('MovpedDet','Mpdd_Transacaovenda_IDX','Mpdd_Transacaovenda');
  Inst.AddIndex('MovpedDet','Mpdd_Transacaonftrans_IDX','Mpdd_Transacaonftrans');
// 05.05.06
  Inst.AddIndex('MovPedDet','Mpdd_copa_codigo_IDX' ,'Mpdd_copa_codigo');

// 08.12.05
  Inst.AddIndex('Movpesquisas' ,'Mpes_Status_IDX'       ,'Mpes_Status');
  Inst.AddIndex('Movpesquisas' ,'Mpes_Seq_IDX'          ,'Mpes_Seq');
  Inst.AddIndex('Movpesquisas' ,'Mpes_tipo_codigo_IDX'  ,'Mpes_tipo_codigo');
  Inst.AddIndex('Movpesquisas' ,'Mpes_tipocad_IDX'      ,'Mpes_tipocad');
  Inst.AddIndex('Movpesquisas' ,'Mpes_DataLcto_IDX'     ,'Mpes_DataLcto');
  Inst.AddIndex('Movpesquisas' ,'Mpes_DataMvto_IDX'     ,'Mpes_DataMvto');

// 11.04.06
  Inst.AddIndex('Log'          ,'log_transacaocanc_IDX' ,'log_transacaocanc');
// 23.06.06
  Inst.AddIndex('Log'          ,'log_usua_codigo_IDX'   ,'log_usua_codigo');
  Inst.AddIndex('Log'          ,'log_data_IDX'          ,'log_data');

// 26.04.06
  Inst.AddIndex('Conpedidos'   ,'conp_status_IDX'       ,'conp_status');
  Inst.AddIndex('Conpedidos'   ,'conp_sequencial_IDX'   ,'conp_sequencial');
  Inst.AddIndex('Conpedidos'   ,'conp_repr_codigo_IDX'  ,'conp_repr_codigo');
  Inst.AddIndex('Conpedidos'   ,'conp_datamvto_IDX'     ,'conp_datamvto');
  Inst.AddIndex('Conpedidos'   ,'conp_dataentrega_IDX'  ,'conp_dataentrega');
// 06.06.06
  Inst.AddIndex('Custos'       ,'Cust_status_IDX'         ,'Cust_status');
  Inst.AddIndex('Custos'       ,'Cust_esto_codigo_IDX'    ,'Cust_esto_codigo');
  Inst.AddIndex('Custos'       ,'Cust_tama_codigo_IDX'    ,'Cust_tama_codigo');
  Inst.AddIndex('Custos'       ,'Cust_core_codigo_IDX'    ,'Cust_core_codigo');
  Inst.AddIndex('Custos'       ,'Cust_Copa_codigo_IDX'    ,'Cust_Copa_codigo');
  Inst.AddIndex('Custos'       ,'Cust_esto_codigomat_IDX' ,'Cust_esto_codigomat');
  Inst.AddIndex('Custos'       ,'Cust_tama_codigomat_IDX' ,'Cust_tama_codigomat');
  Inst.AddIndex('Custos'       ,'Cust_core_codigomat_IDX' ,'Cust_core_codigomat');
// 16.09.06
  Inst.AddIndex('Emitentes'    ,'Emit_Banco_IDX'     ,'Emit_Banco');
  Inst.AddIndex('Emitentes'    ,'Emit_Agencia_IDX'   ,'Emit_Agencia');
  Inst.AddIndex('Emitentes'    ,'Emit_Conta_IDX'     ,'Emit_Conta');
  Inst.AddIndex('Emitentes'    ,'Emit_Descricao_IDX' ,'Emit_Descricao');
// 02.05.07
  Inst.AddIndex('Baixaesto'    ,'Bxes_status_IDX'         ,'Bxes_status');
  Inst.AddIndex('Baixaesto'    ,'Bxes_esto_codigo_IDX'    ,'Bxes_esto_codigo');
  Inst.AddIndex('Baixaesto'    ,'Bxes_esto_codigobai_IDX' ,'Bxes_esto_codigobai');
// 05.09.07
  Inst.AddIndex('MovAbate'     ,'Mova_Transacao_IDX'       ,'Mova_Transacao');
  Inst.AddIndex('MovAbate'     ,'Mova_Operacao_IDX'        ,'Mova_Operacao');
  Inst.AddIndex('MovAbate'     ,'Mova_numerodoc_IDX'       ,'Mova_numerodoc');
  Inst.AddIndex('MovAbate'     ,'Mova_status_IDX'          ,'Mova_status');
  Inst.AddIndex('MovAbate'     ,'Mova_tipomov_IDX'         ,'Mova_tipomov');
  Inst.AddIndex('MovAbate'     ,'Mova_unid_codigo_IDX'     ,'Mova_unid_codigo');
  Inst.AddIndex('MovAbate'     ,'Mova_dtabate_IDX'         ,'Mova_dtabate');
  Inst.AddIndex('MovAbate'     ,'Mova_tipo_codigo_IDX'     ,'Mova_tipo_codigo');
// 22.09.17
  Inst.AddIndex('MovAbate'     ,'Mova_datalcto_IDX'         ,'Mova_datalcto');
  Inst.AddIndex('MovAbate'     ,'Mova_Transacaogerada_IDX'  ,'Mova_Transacaogerada');

  Inst.AddIndex('MovAbatedet'  ,'Movd_Transacao_IDX'       ,'Movd_Transacao');
  Inst.AddIndex('MovAbatedet'  ,'Movd_Operacao_IDX'        ,'Movd_Operacao');
  Inst.AddIndex('MovAbatedet'  ,'Movd_numerodoc_IDX'       ,'Movd_numerodoc');
  Inst.AddIndex('MovAbatedet'  ,'Movd_status_IDX'          ,'Movd_status');
  Inst.AddIndex('MovAbatedet'  ,'Movd_tipomov_IDX'         ,'Movd_tipomov');
  Inst.AddIndex('MovAbatedet'  ,'Movd_unid_codigo_IDX'     ,'Movd_unid_codigo');
  Inst.AddIndex('MovAbatedet'  ,'Movd_esto_codigo_IDX'     ,'Movd_esto_codigo');
  Inst.AddIndex('MovAbatedet'  ,'Movd_ordem_IDX'           ,'Movd_ordem');
  Inst.AddIndex('MovAbatedet'  ,'Movd_tipo_codigo_IDX'     ,'Movd_tipo_codigo');
// 22.09.17
  Inst.AddIndex('MovAbatedet'  ,'Movd_Oprastreamento_IDX'  ,'Movd_Oprastreamento');
// 18.06.19
  Inst.AddIndex('MovAbatedet'  ,'Movd_Datamvto_IDX'        ,'Movd_Datamvto');
  Inst.AddIndex('MovAbatedet'  ,'Movd_Brinco_IDX'          ,'Movd_Brinco');
  Inst.AddIndex('MovAbatedet'  ,'Movd_Baia_IDX'            ,'Movd_Baia');
  Inst.AddIndex('MovAbatedet'  ,'Movd_Seto_Codigo_IDX'     ,'Movd_Seto_Codigo');
// 20.11.07
//////////// - retirado em 15.10.09
{
  Inst.AddIndex('SalEstoLoc','Salo_status_IDX'      ,'Salo_status');
  Inst.AddIndex('SalEstoLoc','Salo_mesano_IDX'      ,'Salo_mesano');
  Inst.AddIndex('SalEstoLoc','Salo_unid_codigo_IDX' ,'Salo_unid_codigo');
  Inst.AddIndex('SalEstoLoc','Salo_Esto_codigo_IDX' ,'Salo_Esto_codigo');
  Inst.AddIndex('SalEstoLoc','Salo_tama_codigo_IDX' ,'Salo_tama_codigo');
  Inst.AddIndex('SalEstoLoc','Salo_core_codigo_IDX' ,'Salo_core_codigo');
  Inst.AddIndex('SalEstoLoc','Salo_copa_codigo_IDX' ,'Salo_copa_codigo');
  }
////////////

// 14.01.08
  Inst.AddIndex('MovProducao','Movp_Transacao_IDX'   ,'Movp_Transacao');
  Inst.AddIndex('MovProducao','Movp_Operacao_IDX'    ,'Movp_Operacao');
  Inst.AddIndex('MovProducao','Movp_status_IDX'      ,'Movp_status');
  Inst.AddIndex('MovProducao','Movp_numerodoc_IDX'   ,'Movp_numerodoc');
  Inst.AddIndex('MovProducao','Movp_tipomov_IDX'     ,'Movp_tipomov' );
  Inst.AddIndex('MovProducao','Movp_unid_codigo_IDX' ,'Movp_unid_codigo' );
  Inst.AddIndex('MovProducao','Movp_esto_codigo_IDX' ,'Movp_esto_codigo');
  Inst.AddIndex('MovProducao','Movp_grup_codigo_IDX' ,'Movp_grup_codigo');
  Inst.AddIndex('MovProducao','Movp_tama_codigo_IDX' ,'Movp_tama_codigo');
  Inst.AddIndex('MovProducao','Movp_core_codigo_IDX' ,'Movp_core_codigo');
  Inst.AddIndex('MovProducao','Movp_tipo_codigo_IDX' ,'Movp_tipo_codigo');  
  Inst.AddIndex('MovProducao','Movp_DataMvto_IDX'    ,'Movp_DataMvto');
  Inst.AddIndex('MovProducao','Movp_nroobra_IDX'     ,'Movp_nroobra');

// 24.01.08
  Inst.AddIndex('MovObrasDet','Movo_Transacao_IDX'   ,'Movo_Transacao');
  Inst.AddIndex('MovObrasDet','Movo_Operacao_IDX'    ,'Movo_Operacao');
  Inst.AddIndex('MovObrasDet','Movo_status_IDX'      ,'Movo_status');
  Inst.AddIndex('MovObrasDet','Movo_numerodoc_IDX'   ,'Movo_numerodoc');
  Inst.AddIndex('MovObrasDet','Movo_tipomov_IDX'     ,'Movo_tipomov' );
  Inst.AddIndex('MovObrasDet','Movo_unid_codigo_IDX' ,'Movo_unid_codigo' );
  Inst.AddIndex('MovObrasDet','Movo_esto_codigo_IDX' ,'Movo_esto_codigo');
  Inst.AddIndex('MovObrasDet','Movo_tama_codigo_IDX' ,'Movo_tama_codigo');
  Inst.AddIndex('MovObrasDet','Movo_core_codigo_IDX' ,'Movo_core_codigo');
  Inst.AddIndex('MovObrasDet','Movo_tipo_codigo_IDX' ,'Movo_tipo_codigo');
  Inst.AddIndex('MovObrasDet','Movo_DataMvto_IDX'    ,'Movo_DataMvto');
  Inst.AddIndex('MovObrasDet','Movo_nroobra_IDX'     ,'Movo_nroobra');

// 29.01.08
  Inst.AddIndex('Orcamentos','Orca_numerodoc_IDX'    ,'Orca_numerodoc');
  Inst.AddIndex('Orcamentos','Orca_status_IDX'       ,'Orca_status');
  Inst.AddIndex('Orcamentos','Orca_situacao_IDX'     ,'Orca_situacao');
  Inst.AddIndex('Orcamentos','Orca_unid_codigo_IDX'  ,'Orca_unid_codigo');
  Inst.AddIndex('Orcamentos','Orca_tipo_codigo_IDX'  ,'Orca_tipo_codigo');
  Inst.AddIndex('Orcamentos','Orca_DataMvto_IDX'     ,'Orca_DataMvto');
  Inst.AddIndex('Orcamentos','Orca_DataRetorno_IDX'  ,'Orca_DataRetorno');
// 23.10.08
  Inst.AddIndex('Orcamencal','Orcc_numerodoc_IDX'    ,'Orcc_numerodoc');
  Inst.AddIndex('Orcamencal','Orcc_status_IDX'       ,'Orcc_status');
  Inst.AddIndex('Orcamencal','Orcc_unid_codigo_IDX'  ,'Orcc_unid_codigo');
// 16.12.08
  Inst.AddIndex('Orcainsumos','Orin_numerodoc_IDX'    ,'Orin_numerodoc');
  Inst.AddIndex('Orcainsumos','Orin_status_IDX'       ,'Orin_status');
  Inst.AddIndex('Orcainsumos','Orin_unid_codigo_IDX'  ,'Orin_unid_codigo');
  Inst.AddIndex('Orcainsumos','Orin_esto_codigo_IDX'  ,'Orin_esto_codigo');
// 22.01.09
  Inst.AddIndex('Orcamendet','Orcd_numerodoc_IDX'    ,'Orcd_numerodoc');
  Inst.AddIndex('Orcamendet','Orcd_status_IDX'       ,'Orcd_status');
  Inst.AddIndex('Orcamendet','Orcd_unid_codigo_IDX'  ,'Orcd_unid_codigo');

// 19.09.08
  Inst.AddIndex('PlanoAcao','Paca_status_IDX'            ,'Paca_status');
  Inst.AddIndex('PlanoAcao','Paca_seq_IDX'               ,'Paca_seq');
  Inst.AddIndex('PlanoAcao','Paca_Numeroata_IDX'         ,'Paca_Numeroata');
  Inst.AddIndex('PlanoAcao','Paca_Mrnc_numerornc_IDX'    ,'Paca_Mrnc_numerornc');
  Inst.AddIndex('PlanoAcao','Paca_unid_codigo_IDX'       ,'Paca_unid_codigo');
  Inst.AddIndex('PlanoAcao','Paca_situacao_IDX'          ,'Paca_situacao');
  Inst.AddIndex('PlanoAcao','Paca_Tipoplano_IDX'         ,'Paca_Tipoplano');

// 04.05.09
  Inst.AddIndex('MovIndicadores','MInd_Indi_Codigo_IDX'      ,'MInd_Indi_Codigo');
  Inst.AddIndex('MovIndicadores','MInd_Status_IDX'      ,'MInd_Status');
  Inst.AddIndex('MovIndicadores','MInd_DataInd_IDX'     ,'MInd_DataInd');
// 08.09.10
  Inst.AddIndex('MovNFeEstoque','Mnfe_status_IDX'     ,'Mnfe_status' );
  Inst.AddIndex('MovNFeEstoque','Mnfe_esto_codigo_IDX','Mnfe_esto_codigo' );
  Inst.AddIndex('MovNFeEstoque','Mnfe_tipo_codigo_IDX','Mnfe_tipo_codigo' );
  Inst.AddIndex('MovNFeEstoque','Mnfe_forn_codigo_IDX','Mnfe_forn_codigo' );
// 19.05.11
  Inst.AddIndex('Nutricionais' ,'Nutr_Codigo_IDX','Nutr_Codigo');
  Inst.AddIndex('Ingredientes' ,'Ingr_Codigo_IDX','Ingr_Codigo');
  Inst.AddIndex('Conservacao'  ,'Cons_Codigo_IDX','Cons_Codigo');
// 13.07.11
  Inst.AddIndex('MovLeituraEcf','Mecf_status_IDX'     ,'Mecf_status');
  Inst.AddIndex('MovLeituraEcf','Mecf_Data_IDX'       ,'Mecf_Data');
  Inst.AddIndex('MovLeituraEcf','Mecf_unid_codigo_IDX','Mecf_unid_codigo');
// 20.01.16
  Inst.AddIndex('MovCargas','Movc_status_IDX'          ,'Movc_status');
  Inst.AddIndex('MovCargas','Movc_Numero_IDX'          ,'Movc_Numero');
  Inst.AddIndex('MovCargas','Movc_DataMvto_IDX'        ,'Movc_DataMvto');
  Inst.AddIndex('MovCargas','Movc_unid_codigo_IDX'     ,'Movc_unid_codigo');
  Inst.AddIndex('MovCargas','Movc_tran_codigo_IDX'     ,'Movc_tran_codigo');
// 20.03.17
  Inst.AddIndex('MovAgenda','MoAG_status_IDX'          ,'Moag_status');
  Inst.AddIndex('MovAgenda','Moag_Numero_IDX'          ,'Moag_Numero');
  Inst.AddIndex('MovAgenda','Moag_DataMvto_IDX'        ,'Moag_DataMvto');
  Inst.AddIndex('MovAgenda','Moag_unid_codigo_IDX'     ,'Moag_unid_codigo');
  Inst.AddIndex('MovAgenda','Moag_tipo_codigo_IDX'     ,'Moag_tipo_codigo');
// 25.10.18
  Inst.AddIndex('MovTelevendas','Movt_status_IDX'     ,'Movt_status');
  Inst.AddIndex('MovTelevendas','Movt_unid_codigo_IDX','Movt_unid_codigo');
  Inst.AddIndex('MovTelevendas','Movt_tipo_codigo_IDX','Movt_tipo_codigo');
  Inst.AddIndex('MovTelevendas','Movt_datamvto_IDX'   ,'Movt_datamvto');
  Inst.AddIndex('MovTelevendas','Movt_situacao_IDX'   ,'Movt_situacao');
  Inst.AddIndex('MovTelevendas','Movt_operacao_IDX'   ,'Movt_operacao');
// 20.03.19
  Inst.AddIndex('movcontab','Moct_tipo_IDX'           ,'Moct_tipo');
  Inst.AddIndex('movcontab','Moct_DataMvto_IDX'       ,'Moct_DataMvto');
  Inst.AddIndex('movcontab','Moct_transacao_IDX'      ,'Moct_transacao');
// 16.06.19
  Inst.AddIndex('replicacao','Repl_Data_IDX'           ,'Repl_Data');
  Inst.AddIndex('replicacao','Repl_Hora_IDX'           ,'Repl_Hora');
// 12.05.20
  Inst.AddIndex('CentrosdeCusto','Ccus_Data_IDX'       ,'Ccus_Data');
  Inst.AddIndex('CentrosdeCusto','Ccus_Unid_Codigo_IDX','Ccus_Unid_Codigo');
  Inst.AddIndex('CentrosdeCusto','Ccus_Codigo_IDX'     ,'Ccus_Codigo');

  Inst.AddIndex('Apropriacoes','Apro_transacao_IDX'    ,'Apro_transacao');
  Inst.AddIndex('Apropriacoes','Apro_Data_IDX'         ,'Apro_Data');
// 16.09.20
  Inst.AddIndex('Contratos','Cont_transacao_IDX'       ,'Cont_transacao');
  Inst.AddIndex('Contratos','Cont_DataEnt_IDX'         ,'Cont_DataEnt');
  Inst.AddIndex('Contratos','Cont_DataCon_IDX'         ,'Cont_DataCon');
  Inst.AddIndex('Contratos','Cont_tipo_codigo_IDX'     ,'Cont_tipo_codigo');
  Inst.AddIndex('Contratos','Cont_numerodoc_IDX'       ,'Cont_numerodoc');
  Inst.AddIndex('Contratos','Cont_tipo_codigo_IDX'     ,'Cont_tipo_codigo');
  Inst.AddIndex('Contratos','Cont_unid_codigo_IDX'     ,'Cont_unid_codigo');

// 25.03.2021
  Inst.AddIndex('MovCalibracoes','Moca_status_IDX'     ,'Moca_status');
  Inst.AddIndex('MovCalibracoes','Moca_Unid_Codigo_IDX','Moca_Unid_Codigo');
  Inst.AddIndex('MovCalibracoes','Moca_transacao_IDX'      ,'Moca_transacao');
  Inst.AddIndex('MovCalibracoes','Moca_mped_numerodoc_IDX' ,'Moca_mped_numerodoc');
  Inst.AddIndex('MovCalibracoes','Moca_Equi_Codigo_IDX'    ,'Moca_Equi_Codigo');
  Inst.AddIndex('MovCalibracoes','Moca_tipo_codigo_IDX'    ,'Moca_tipo_codigo');
  Inst.AddIndex('MovCalibracoes','Moca_Data_IDX'           ,'Moca_Data');

  Inst.AddIndex('MovCalibracoesDet','Mocd_status_IDX'         ,'Mocd_status');
  Inst.AddIndex('MovCalibracoesDet','Mocd_Unid_Codigo_IDX'    ,'Mocd_Unid_Codigo');
  Inst.AddIndex('MovCalibracoesDet','Mocd_transacao_IDX'      ,'Mocd_transacao');
  Inst.AddIndex('MovCalibracoesDet','Mocd_mped_numerodoc_IDX' ,'Mocd_mped_numerodoc');

// 31.08.2021
  Inst.AddIndex('ContratosAtu','Cona_transacao_IDX'       ,'Cona_transacao');
  Inst.AddIndex('ContratosAtu','Cona_status_IDX'          ,'Cona_status');
  Inst.AddIndex('ContratosAtu','Cona_DataEnt_IDX'         ,'Cona_DataEnt');
  Inst.AddIndex('ContratosAtu','Cona_Operacao_IDX'        ,'Cona_Operacao');
  Inst.AddIndex('ContratosAtu','Cona_tipo_codigo_IDX'     ,'Cona_tipo_codigo');
  Inst.AddIndex('ContratosAtu','Cona_unid_codigo_IDX'     ,'Cona_unid_codigo');


end;


function TFInstsac.ConfiguraBancodeDados: boolean;

  function getsenha: string;
  var senha: TStringList;
      dir: string;
  begin
    case rgServidor.ItemIndex of
       0: dir:= 'SACINST\ORACLE';
       1: dir:= 'SACINST\SQLSERVER';
       2: dir:= 'SACINST\POSTGRESQL';
       3: dir:= 'SACINST\FIREBIRD';
       4: dir:= 'SACINST\INTERBASE';
    end;
    senha:= TStringList.Create;
    senha.Add(GetIni('SACD', dir, 'EConf_Usuario'));
    DecriptList(senha);
    result:= senha.Strings[0];
    senha.Free;
  end;

begin
  result:= false;
  if not EUsuario.ValidEdiAll(self, 1) then exit;
  if EConf_Usuario.IsEmpty then EConf_Usuario.Text:= getsenha;
  if rgServidor.ItemIndex=0 then begin // oracle
     Inst.ServerName:=EServidor.Text;
     Inst.DataBaseName:=EDataBase.Text;
     Inst.SQLUserName:=EUsuario.Text;
     Inst.SQLPassword:=EConf_Usuario.Text;
     Inst.RPUserName:='SAC';
     Inst.RPPassword:='sac'+IntToStr(35269147);
     Inst.TypeServer:=tsOracle;
  end else if rgServidor.ItemIndex=1 then begin // sql server
     Inst.ServerName:=EServidor.Text;
     Inst.DataBaseName:=EDataBase.Text;
     Inst.SQLUserName:=EUsuario.Text;
     Inst.SQLPassword:=EConf_Usuario.Text;
     Inst.RPUserName:='sac';
     Inst.RPPassword:='sac'+IntToStr(35269147);
     Inst.TypeServer:=tsSQLServer;
  end else if rgServidor.ItemIndex=2 then begin // postgre sql
     Inst.ServerName:=EServidor.Text+':'+EPorta.Text;
     Inst.DataBaseName:=EDataBase.Text;
     Inst.SQLUserName:=EUsuario.Text;
     Inst.SQLPassword:=EConf_Usuario.Text;
     Inst.RPUserName:='sac';
// 04.10.16
     if pos('cloud',Eservidor.text)>0 then
       Inst.RPPassword:=EConf_usuario.Text
     else
       Inst.RPPassword:='sacd'+IntToStr(35269147);
     Inst.TypeServer:=tsPostGreSQL;
  end else if rgServidor.ItemIndex=3 then begin // firebird
     Inst.ServerName:=EServidor.Text;
     Inst.DataBaseName:=ECaminho.Text;
     Inst.SQLUserName:=EUsuario.Text;
     Inst.SQLPassword:=EConf_Usuario.Text;
     Inst.RPUserName:='SAC';
     Inst.RPPassword:='sac'+IntToStr(35269147);
     Inst.TypeServer:=tsInterBase;
  end else if rgServidor.ItemIndex=4 then begin // interbase
     Inst.ServerName:=EServidor.Text;
     Inst.DataBaseName:=ECaminho.Text;
     Inst.SQLUserName:=EUsuario.Text;
     Inst.SQLPassword:=EConf_Usuario.Text;
     Inst.RPUserName:='SAC';
     Inst.RPPassword:='sac'+IntToStr(35269147);
     Inst.TypeServer:=tsInterBase;
  end;
  result:= true;
end;

procedure TFInstsac.FormActivate(Sender: TObject);
begin
  if Ini <> 'S' then inicializar;
end;

procedure TFInstsac.FormCreate(Sender: TObject);
begin
  position := poScreenCenter;
  Caption:=Caption+' / '+Versao;
  OSistema.Version:=Versao;
  Inst.Version:=Versao;
  OSistema.Version:=Versao;
// 06.09.19
///  wxoPrepare(Handle,Application.Handle);

end;

procedure TFInstsac.setaservidor;
begin
  if rgServidor.ItemIndex=0 then begin // oracle
     EServidor.Text:= 'SERVIDOR';
     EDataBase.Text:= 'SAC';
     EUsuario.Text:= 'SYSTEM';
     EConf_Usuario.Text:= 'MANAGER';
  end else if rgServidor.ItemIndex=1 then begin // sql server
     EServidor.Text:= 'SERVIDOR';
     EDataBase.Text:= 'SAC';
     EUsuario.Text:= 'SA';
     EConf_Usuario.Clear;
  end else if rgServidor.ItemIndex=2 then begin // postgre sql
     EServidor.Text:= '127.0.0.1';
     EPorta.Text:= '5432';
     EDataBase.Text:= 'sac';
     EUsuario.Text:= 'postgres';
     EConf_Usuario.Clear;
  end else if rgServidor.ItemIndex=3 then begin // firebird
     EServidor.Text:= '127.0.0.1';
     ECaminho.Text:= 'C:/SAC/SAC.GDB';
     EUsuario.Text:= 'SYSDBA';
     EConf_Usuario.Text:= 'masterkey';
  end else if rgServidor.ItemIndex=4 then begin // interbase
     EServidor.Text:= '127.0.0.1';
     ECaminho.Text:= 'C:/SAC/SAC.GDB';
     EUsuario.Text:= 'SYSDBA';
     EConf_Usuario.Text:= 'masterkey';
  end;
end;

procedure TFInstsac.inicializar;
var dir, banco: string;
begin
  Ini:= 'S';
  EPorta.Visible:= rgServidor.ItemIndex = 2;
  ECaminho.Visible:= (rgServidor.ItemIndex = 3) or (rgServidor.ItemIndex = 4);
  banco:= GetIni('SACD', 'SACINST', 'Banco');
  if banco = '' then begin
     setaservidor;
     exit;
  end;
  case StrToInt(banco) of
     0: dir:= 'SACINST\ORACLE';
     1: dir:= 'SACINST\SQLSERVER';
     2: dir:= 'SACINST\POSTGRESQL';
     3: dir:= 'SACINST\FIREBIRD';
     4: dir:= 'SACINST\INTERBASE';
  end;
  EUsuario.Text:= GetIni('SACD', dir, 'EUsuario');
  EDataBase.Text:= GetIni('SACD', dir, 'EDataBase');
  EServidor.Text:= GetIni('SACD', dir, 'EServidor');
  ECaminho.Text:= GetIni('SACD', dir, 'ECaminho');
  EPorta.Text:= GetIni('SACD', dir, 'EPorta');
  if not EConf_Usuario.IsEmpty then EConf_Usuario.Clear;
  rgServidor.ItemIndex := StrToInt(banco);
  EPorta.Visible:= rgServidor.ItemIndex = 2;
  ECaminho.Visible:= (rgServidor.ItemIndex = 3) or (rgServidor.ItemIndex = 4);
// ver parametros do 'dos'
//  bInstVersaoClick(FInsttoke);


end;

procedure TFInstsac.bSairClick(Sender: TObject);
begin
  Close;
end;

procedure TFInstsac.bInstVersaoClick(Sender: TObject);
var dir: string;

  procedure armazenasenha;
  /////////////////////////
  var senha: TStringList;
  begin
    if not EConf_Usuario.IsEmpty then begin
       senha:= TStringList.Create;
       senha.Add(EConf_Usuario.Text);
       CriptList(senha);
       SetIni('SACD', dir, 'EConf_Usuario', senha.Text);
       senha.Free;
    end;
  end;

begin

  if not Confirma('Confirma a instala��o da vers�o') then Exit;
  bSair.SetFocus;
  PMsgSistema.Caption:='Aguarde...';
  Application.ProcessMessages;
  if not ConfiguraBancodeDados then exit;
  bInstVersao.Enabled:=False;
  if Inst.InstallSystem then begin
     case rgServidor.ItemIndex of
        0: dir:= 'SACINST\ORACLE';
        1: dir:= 'SACINST\SQLSERVER';
        2: dir:= 'SACINST\POSTGRESQL';
        3: dir:= 'SACINST\FIREBIRD';
        4: dir:= 'SACINST\INTERBASE';
     end;
     SetIni('SACD', dir, 'EUsuario', EUsuario.Text);
     armazenasenha;
     SetIni('SACD', dir, 'EDataBase', EDataBase.Text);
     SetIni('SACD', dir, 'EServidor', EServidor.Text);
     SetIni('SACD', dir, 'ECaminho',  ECaminho.Text);
     SetIni('SACD', dir, 'EPorta',    EPorta.Text);
     SetIni('SACD', 'SACINST', 'Banco', inttostr(rgServidor.ItemIndex));
//     ProcessosNovaVersao;

  end;
  bInstVersao.Enabled:=True;
  bSair.SetFocus;
end;

procedure TFInstsac.BitBtn2Click(Sender: TObject);
var dir, s, servidor: string;
begin
// s:= InputBox('Banco de Dados', 'Escolha do Banco de Dados', '');
   s:=rgServidor.Items[rgServidor.ItemIndex];
   if uppercase(s) = 'ORACLE' then rgServidor.ItemIndex := 0
   else if uppercase(s) = 'SQL SERVER' then rgServidor.ItemIndex := 1
   else if uppercase(s) = 'POSTGRESQL SERVER' then rgServidor.ItemIndex := 2
   else if uppercase(s) = 'FIREBIRD' then rgServidor.ItemIndex := 3
   else if uppercase(s) = 'INTERBASE' then rgServidor.ItemIndex := 4
   else begin
          AvisoErro('N�o foi encontrado o banco de dados especificado');
          exit;
        end;
   case rgServidor.ItemIndex of
      0: dir:= 'SACINST\ORACLE';
      1: dir:= 'SACINST\SQLSERVER';
      2: dir:= 'SACINST\POSTGRESQL';
      3: dir:= 'SACINST\FIREBIRD';
      4: dir:= 'SACINST\INTERBASE';
   end;
   servidor:= GetIni('SACD', dir, 'EServidor');
   if servidor = '' then setaservidor
   else begin
          SetIni('SACD', 'SACINST', 'Banco', inttostr(rgServidor.ItemIndex));
          inicializar;
        end;

end;

procedure TFInstsac.bTestarConexaoClick(Sender: TObject);
begin
  if not ConfiguraBancodeDados then exit;
  if Sistema.Init then Aviso('Conex�o realizado com sucesso!!!') else AvisoErro('N�o foi poss�vel se conectar ao servidor');
  if Sistema.Inicializado then begin
     Sistema.Conexao.Close;
     Sistema.Inicializado := false;
  end;
end;

procedure TFInstsac.BitBtn3Click(Sender: TObject);
begin
  EUsuario.Enabled:=True;
  EConf_Usuario.Enabled:=True;
  EDataBase.Enabled:=True;
  EServidor.Enabled:=True;
  EPorta.Enabled:=True;
  ECaminho.Enabled:=True;
  EUsuario.SetFocus;
end;

procedure TFInstsac.EPortaExitEdit(Sender: TObject);
begin
  bSair.SetFocus;
  EUsuario.Enabled:=False;
  EConf_Usuario.Enabled:=False;
  EDataBase.Enabled:=False;
  EServidor.Enabled:=False;
  ECaminho.Enabled:=False;
  EPorta.Enabled:=False;
end;

procedure TFInstsac.rgServidorEnter(Sender: TObject);
begin
  bSair.SetFocus;
end;


(*
procedure TFInsttoke.ProcessosNovaVersao;
var Q:TSqlQuery; s:String;

    procedure GeraContadores;
    var Q:TSqlQuery; NomCont:String; PosCont:Integer;
    begin
      Q:=SqlToQuery('Select * From Contadores');
      while not Q.Eof do begin
         NomCont:=Q.FieldByName('Cont_Nome').AsString;
         PosCont:=Q.FieldByName('Cont_Posicao').AsInteger;
         SetSequencia(NomCont,PosCont);
         Q.Next;
      end;
      Q.Close; FreeAndNil(Q);
      s[134]:='S';
      Sistema.Edit('Controle');
      Sistema.SetField('Ctrl_NovaVersao',s);
      Sistema.Post('Ctrl_Registro=1');
      Sistema.Commit;
    end;

begin

  Q:=SqlToQuery('SELECT Ctrl_NovaVersao FROM Controle WHERE Ctrl_Registro=1');
  s:=StrSpace(Q.FieldByName('Ctrl_NovaVersao').AsString,1000);
  Q.Close;Q.Free;

end;

*)

procedure TFInstsac.PMsgSistemaDblClick(Sender: TObject);
var  L:TStringList;
     q,i:integer;
     n:string;
begin
  if Confirma('Confirma a Elimina��o das Tabelas Tempor�rias') then begin
     if Sistema.Conexao.Connected then Sistema.Conexao.Close;
     if not ConfiguraBancodeDados then exit;
     Sistema.Init;

     L:=TStringList.Create;
     q:=0;
     Sistema.BeginProcess('Eliminando Tabelas Old');
     Sistema.GetTableNames(L);
     for i:=0 to L.Count-1 do begin
         n:=L.Strings[i];
         if UpperCase(LeftStr(n,3))='OLD' then begin
            Sistema.Conexao.ExecuteDirect('DROP TABLE '+n);
            Inc(q);
         end;
     end;
     Sistema.EndProcess(IntToStr(q)+' Tabelas Eliminadas');
     L.Free;
  end;

end;

// 22.11.07 - pois dA mensagem 'Use shorter procedures' na compila��o
procedure TFInstsac.CriaTabelasEstoque;
//////////////////////////////////////////////////
begin
  Inst.AddTable('Estoque');
  Inst.AddField('Estoque','Esto_codigo'            ,'C',20,0,30 ,False,'C�digo'                    ,'C�digo do produto'                           ,''    ,False,'1','','','2');
  Inst.AddField('Estoque','Esto_Descricao'         ,'C',100,0,250,True ,'Nome do Produto'           ,'Nome do produto'                             ,''    ,True ,'1','','','1');
  Inst.AddField('Estoque','Esto_Unidade'           ,'C',10,0,70 ,True ,'Unidade do Produto'        ,'Unidade do produto'                          ,''    ,True ,'1','','','0');
  Inst.AddField('Estoque','Esto_Embalagem'         ,'N',08,0,70 ,True ,'Qtde por embalagem'        ,'Qtde por embalagem'                          ,''    ,True ,'1','','','0');
  Inst.AddField('Estoque','Esto_Peso'              ,'N',10,3,70 ,True ,'Peso do Produto'           ,'Peso do produto'                             ,''    ,True ,'1','','','0');
  Inst.AddField('Estoque','Esto_Codbarra'          ,'C',20,0,100,True ,'Codigo de barras'          ,'Codigo de barras'                            ,''    ,True ,'1','','','0');
  Inst.AddField('Estoque','Esto_Grup_codigo'       ,'N',06,0,40 ,True ,'C�digo do grupo'           ,'C�digo do grupo'                             ,''    ,False,'1','','','0');
  Inst.AddField('Estoque','Esto_Sugr_codigo'       ,'N',04,0,40 ,True ,'C�digo do subgrupo'        ,'C�digo do subgrupo'                          ,''    ,False,'1','','','0');
  Inst.AddField('Estoque','Esto_Fami_codigo'       ,'N',04,0,40 ,False,'C�digo'                    ,'C�digo da familia'                        ,''    ,False,'2','','','2');
  Inst.AddField('Estoque','Esto_Grad_codigo'       ,'N',02,0,40 ,True ,'C�digo da grade'           ,'C�digo da grade'                             ,''    ,False,'0','','','0');
  Inst.AddField('Estoque','Esto_Emlinha'           ,'C',01,0,40 ,True ,'Em linha'                  ,'Em linha'                                    ,''    ,False,'0','','','0');
  Inst.AddField('Estoque','Esto_Mate_codigo'       ,'N',04,0,40 ,True ,'Material'                  ,'C�digo do material predominante'             ,''    ,False,'2','','','2');
  Inst.AddField('Estoque','Esto_qtdeminimo'        ,'N',12,3,70 ,True ,'Minimo'                    ,'Quantidade m�nima para compra'               ,''    ,False,'' ,'','','');
  Inst.AddField('Estoque','Esto_qtdemaximo'        ,'N',12,3,70 ,True ,'M�ximo'                    ,'Quantidade m�xima para compra'               ,''    ,False,'' ,'','','');
  Inst.AddField('Estoque','Esto_Usua_Codigo'       ,'N',003,0,50 ,False,'Usu�rio'                   ,'Usu�rio respons�vel pelo cadastramento'      ,''    ,False,'3','','','0');
// 14.06.05
  Inst.AddField('Estoque','Esto_custozeroc'        ,'N',012,2,80 ,True ,'Custo do produto'          ,'Custo do produto'                            ,''    ,True ,'1','','','0');
  Inst.AddField('Estoque','Esto_custozerog'        ,'N',012,2,80 ,True ,'Custo gerencial do produto','Custo gerencial do produto'                  ,''    ,True ,'1','','','0');
// 01.02.06
  Inst.AddField('Estoque','Esto_sisvendas'         ,'C',010,0,080,True ,'Sistema de vendas'          ,'Sistema de vendas'                  ,''    ,True ,'1','','','0');
// 08.03.06 - Cleuziane+Janina
  Inst.AddField('Estoque','Esto_categoria'         ,'C',004,0,080,True ,'Categoria'                  ,'Categoria'                          ,''    ,True ,'1','','','0');
// 08.06.06 -
  Inst.AddField('Estoque','Esto_referencia'        ,'C',020,0,030,True ,'Refer�ncia'                ,'C�digo do fabricante'                        ,''    ,False,'1','','','0');
// 23.06.06
  Inst.AddField('Estoque','Esto_precocompra'       ,'N',013,4,080,True ,'Pre�o de Compra do produto','Pre�o de Compra do produto'                  ,''    ,True ,'1','','','0');
// 13.07.06
  Inst.AddField('Estoque','Esto_cipi_codigo'       ,'N',004,0,45  ,True ,'Codigo ipi' ,'Codigo ipi'                   ,f_aliq,True ,'1','','','0');
// 27.05.07
  Inst.AddField('Estoque','Esto_desconto'          ,'N',07 ,3,45  ,True ,'% Desconto'                ,'% Desconto'                                       ,f_aliq,True ,'3','','','0');
// 28.05.07
  Inst.AddField('Estoque','Esto_pervenda'          ,'N',08 ,3,45  ,True ,'% Venda'                   ,'% Venda'                                       ,f_aliq,True ,'3','','','0');
  Inst.AddField('Estoque','Esto_codigovenda'       ,'C',20 ,0,30  ,True ,'Cod.Venda'                 ,'Cod. Venda'                           ,''    ,False,'1','','','2');
// 28.02.08 - novicarnes
  Inst.AddField('Estoque','Esto_baixavenda'        ,'C',001,0,080,True ,'Baixa na Venda'             ,'Baixa composi��o cfe a venda'       ,''    ,True ,'1','','','0');
// 24.09.08 - carli
  Inst.AddField('Estoque','Esto_compminimo'        ,'N',008,4,080,True ,'Com.M�nimo'                 ,'Comprimento m�nimo para aproveitamento'       ,''    ,True ,'1','','','0');
// 09.08.10 - Dist. Bavi
  Inst.AddField('Estoque','Esto_imagem'            ,'M',000,0,120,True ,'Imagem Produto'                 ,'Imagem do produto'       ,''    ,True ,'1','','','0');
// 19.05.11 - Damama
  Inst.AddField('Estoque','Esto_Nutr_Codigo'       ,'N',008,0,120,True ,'Inf.Nutricional'            ,'Codigo da tabela de informa��o nutricional'       ,''    ,True ,'1','','','0');
  Inst.AddField('Estoque','Esto_Ingr_Codigo'       ,'N',008,0,120,True ,'Codigo Ingredientes'        ,'Codigo da tabela de ingredientes'       ,''    ,True ,'1','','','0');
// 30.05.11 - Damama
  Inst.AddField('Estoque','Esto_Cons_Codigo'       ,'N',006,0,100,True ,'Codigo Conserva��o'        ,'Codigo da tabela de conserva��o de produtos'       ,''    ,True ,'1','','','0');
  Inst.AddField('Estoque','Esto_Cons_Codigo1'      ,'N',006,0,100,True ,'Codigo Registro'           ,'Codigo da tabela de conserva��o usado para registro'       ,''    ,True ,'1','','','0');
// 01.06.11 - Novicarnes
  Inst.AddField('Estoque','Esto_tara'              ,'N',013,5,080,True ,'Tara Balan�a'              ,'Tara Balan�a de abate'           ,''    ,True ,'3','','','0');
  Inst.AddField('Estoque','Esto_qbalanca'          ,'C',020,0,080,True ,'Qual(is) Balan�a'              ,'Qual(is) balan�a(s) o produto usa por padr�o para pesagem na venda '       ,''    ,True ,'1','','','0');
// 17.06.11 - Novicarnes
  Inst.AddField('Estoque','Esto_validade'          ,'N',005,0,080,True ,'Validade'                  ,'Validade produto em dias'                  ,''    ,True ,'3','','','0');
  Inst.AddField('Estoque','Esto_qetiqbalanca'      ,'N',002,0,080,True ,'Etiquetas'                 ,'Quantidade de etiquetas para impress�o na balan�a'       ,''    ,True ,'3','','','0');
// 26.07.13 - Metalforte - Mari+Fatima
  Inst.AddField('Estoque','Esto_Fami_descricao'    ,'C',050,0,250,True,'Descri��o Familia'         ,'Descri��o da familia'                     ,''    ,True,'1','','','0');
// 20.01.16
  Inst.AddField('Estoque','Esto_Faix_codigo'       ,'C',03,0,40 ,True,'C�digo da faixa'            ,'C�digo da faixa de valores'                            ,''    ,False,'1','','','0');
// 02.08.16 - Novicarnes
  Inst.AddField('Estoque','Esto_taracf'            ,'N',013,5,080,True ,'Tara Camara Fria'          ,'Tara Camara Fria'                  ,''    ,True ,'3','','','0');
// 22.09.16 - Novicarnes
  Inst.AddField('Estoque','Esto_taraperc'          ,'N',013,5,080,True ,'Tara em %'                 ,'Tara em % para abate'                  ,''    ,True ,'3','','','0');
// 24.08.17 - Sport Acao - armas
  Inst.AddField('Estoque','Esto_obs'               ,'M',013,5,080,True ,'Detalhes Produto'          ,'Detalhes do Produto'                  ,''    ,True ,'3','','','0');
// 22.05.18
  Inst.AddField('Estoque','Esto_Faix_codigo002'    ,'C',003,0,040,True,'C�digo da faixa un.002'            ,'C�digo da faixa de valores para unidade 002'                            ,''    ,False,'1','','','0');
// 06.02.19 - Novicarnes
  Inst.AddField('Estoque','Esto_Grup_descricao'    ,'C',050,0,250,True,'Descri��o Grupo'         ,'Descri��o do grupo'                     ,''    ,True,'1','','','0');
  Inst.AddField('Estoque','Esto_Sugr_descricao'    ,'C',050,0,250,True,'Descri��o SubGrupo'         ,'Descri��o do subgrupo'                     ,''    ,True,'1','','','0');
// para uso futuro
  Inst.AddField('Estoque','Esto_qtde'           ,   'N',014,4,090,True,'Estoque'         ,'Quantidade em estoque'                     ,''    ,True,'3','','','0');
  Inst.AddField('Estoque','Esto_vendavis'       ,   'N',014,4,090,True,'Venda'           ,'Pre�o de Venda'                     ,''    ,True,'3','','','0');
// Novicarnes...2019
  Inst.AddField('Estoque','Esto_Cons_Codigores'     ,'N',006,0,100,True ,'Cod.Cons.Resf.'        ,'Codigo da tabela de conserva��o para produtos RESFRIADOS'       ,''    ,True ,'1','','','0');
  Inst.AddField('Estoque','Esto_validaderes'        ,'N',005,0,080,True ,'Val.Resf.'                  ,'Validade produtos RESFRIADOS em dias'                  ,''    ,True ,'3','','','0');
// 01.08.19 - A2z
  Inst.AddField('Estoque','Esto_equi_codigo'        ,'C',04  ,2,60  ,True ,'Equipamento'                ,'Codigo do equipamento'                           ,''    ,False,'1','','','0');


  Inst.AddTable('EstoqueQtde');
  Inst.AddField('EstoqueQtde','Esqt_status'            ,'C',1 ,0,30 ,False,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('EstoqueQtde','Esqt_unid_codigo'       ,'C',3 ,0,30 ,False,'Unidade'                   ,'C�digo da unidade'                            ,''    ,False,'2','','','2');
  Inst.AddField('EstoqueQtde','Esqt_esto_codigo'       ,'C',20,0,30 ,False,'C�digo'                    ,'C�digo do produto'                           ,''    ,False,'1','','','2');
  Inst.AddField('EstoqueQtde','Esqt_Qtde'              ,'N',12,3,70 ,True ,'Qtde em estoque'           ,'Qtde em estoque'                             ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_Qtdeprev'          ,'N',12,3,70 ,True ,'Qtde prevista'             ,'Qtde prevista'                               ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_vendavis'          ,'N',12,2,80 ,True ,'Pre�o de venda a vista'    ,'Pre�o de venda a vista'                      ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_custo'             ,'N',12,2,80 ,True ,'Custo do produto'          ,'Custo do produto'                            ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_custoger'          ,'N',12,2,80 ,True ,'Custo gerencial'           ,'Custo gerencial'                             ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_customedio'        ,'N',12,2,80 ,True ,'Custo m�dio do produto'    ,'Custo m�dio do produto'                      ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_customeger'        ,'N',12,2,80 ,True ,'Custo m�dio gerencial'     ,'Custo m�dio gerencial'                       ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_dtultvenda'        ,'D',8 ,0,60 ,True ,'Data �ltima venda'         ,'Data �ltima venda'                           ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_dtultcompra'       ,'D',8 ,0,60 ,True ,'Data �ltima compra'        ,'Data �ltima compra'                          ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_desconto'          ,'N',07,3,45 ,True ,'% Desconto'                ,'% Desconto'                                  ,f_aliq,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_basecomissao'      ,'N',07,3,45 ,True ,'Base c�lculo comiss�o'     ,'Base c�lculo comiss�o'                       ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_cfis_codigoest'    ,'C',03,0,45 ,True ,'Codigo icms dentro estado' ,'Codigo icms dentro estado'                   ,f_aliq,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_cfis_codigoforaest','C',03,0,45 ,True ,'Codigo icms fora estado'   ,'Codigo icms fora estado'                     ,f_aliq,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_sitt_codestado'    ,'N',2 ,0,30 ,True ,'Sit.trib.dentro estado'    ,'Sit.trib.dentro estado'                      ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_sitt_forestado'    ,'N',2 ,0,30 ,True ,'Sit.trib.fora estado'      ,'Sit.trib.fora estado'                        ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_tama_codigo'       ,'N',3 ,0,30 ,True ,'Tamanho'                   ,'C�digo do tamanho'                           ,''    ,False,'2','','','0');
  Inst.AddField('EstoqueQtde','Esqt_core_codigo'       ,'N',3 ,0,30 ,True ,'Cor'                       ,'C�digo da cor'                               ,''    ,False,'2','','','0');
  Inst.AddField('EstoqueQtde','Esqt_grad_codigo'       ,'N',2 ,0,40 ,true ,'C�digo'                    ,'C�digo da grade'                            ,''    ,False,'2','','','2');
  Inst.AddField('EstoqueQtde','Esqt_Usua_Codigo'       ,'N',3 ,0,50 ,False,'Usu�rio'                   ,'Usu�rio respons�vel pelo cadastramento'      ,''    ,False,'3','','','0');
  Inst.AddField('EstoqueQtde','Esqt_Codbarra'          ,'C',20,0,100,True ,'Codigo de barras'          ,'Codigo de barras'                            ,''    ,True ,'1','','','0');
// 01.02.06
  Inst.AddField('EstoqueQtde','Esqt_Qtdereserva'       ,'N',12,3,70 ,True ,'Qtde reservada'            ,'Qtde reservada'                              ,''    ,True ,'1','','','0');
// 05.05.06
  Inst.AddField('EstoqueQtde','Esqt_copa_codigo'       ,'N',3 ,0,30 ,True ,'Copa'                      ,'C�digo da copa'                               ,''    ,False,'2','','','0');
// 21.05.07
  Inst.AddField('EstoqueQtde','Esqt_vendamin'          ,'N',12,2,80 ,True ,'Pre�o de venda m�nimo'     ,'Pre�o de venda m�nimo'                      ,''    ,True ,'1','','','0');
// 30.05.07
  Inst.AddField('EstoqueQtde','Esqt_Pecas'             ,'N',12,3,70 ,True ,'Qtde pe�as'                ,'Qtde pe�as'                                  ,''    ,True ,'3','','','0');
// 21.11.07
  Inst.AddField('EstoqueQtde','Esqt_Localiza'          ,'C',20,0,100,True ,'Localiza��o'               ,'Localiza��o'                            ,''    ,True ,'1','','','0');
// 19.03.08
  Inst.AddField('EstoqueQtde','Esqt_custoser'          ,'N',12,2,80 ,True ,'M.Obra do produto'          ,'M.Obra do produto'                            ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_customedioser'     ,'N',12,2,80 ,True ,'M.Obra m�dia do produto'    ,'M.Obra m�dia do produto'                      ,''    ,True ,'1','','','0');
// 29.04.09
  Inst.AddField('EstoqueQtde','Esqt_ressuprimento'     ,'N',12,3,80 ,True ,'Ressuprimento'    ,'Ponto de Ressuprimento do Estoque'                      ,''    ,True ,'1','','','0');
// 15.10.09
  Inst.AddField('EstoqueQtde','Esqt_Qtdeprocesso'     ,'N',12,3,80 ,True ,'Estoque em Processo'    ,'Estoque em Processo'                      ,''    ,True ,'1','','','0');
// 24.03.11 - Asatec
  Inst.AddField('EstoqueQtde','Esqt_cfis_codestsemie'    ,'C',03,0,45 ,True ,'Codigo icms estado sem I.E.' ,'Codigo icms dentro estado para cliente sem Insc.Est.'                   ,f_aliq,True ,'1','','','0');
// 10.03.15 - coorlafs
  Inst.AddField('EstoqueQtde','Esqt_cfis_codestnc'      ,'C',03,0,45 ,True ,'Codigo icms dentro estado' ,'Codigo icms dentro estado para n�o cooperado',f_aliq,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_cfis_codforaestnc'  ,'C',03,0,45 ,True ,'Codigo icms fora estado'   ,'Codigo icms fora estado para n�o cooperado',f_aliq,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_sitt_codestadonc'   ,'N',2 ,0,30 ,True ,'Sit.trib.dentro estado'    ,'Sit.trib.dentro estado para n�o cooperado' ,''    ,True ,'1','','','0');
  Inst.AddField('EstoqueQtde','Esqt_sitt_forestadonc'   ,'N',2 ,0,30 ,True ,'Sit.trib.fora estado'      ,'Sit.trib.fora estado para n�o cooperado'   ,''    ,True ,'1','','','0');


  Inst.AddTable('SalEstoque');
  Inst.AddField('SalEstoque','Saes_status'          ,'C',1 ,0,30 ,False,'Status'                  ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('SalEstoque','Saes_mesano'          ,'C',6 ,0,30 ,False,'Mes/ano'                 ,'Mes/ano'                                      ,''    ,False,'2','','','2');
  Inst.AddField('SalEstoque','Saes_unid_codigo'     ,'C',3 ,0,30 ,False,'C�digo'                  ,'C�digo da unidade'                            ,''    ,False,'2','','','2');
  Inst.AddField('SalEstoque','Saes_Esto_codigo'     ,'C',20,0,30 ,False,'C�digo'                  ,'C�digo do produto'                           ,''    ,False,'1','','','2');
//  Inst.AddField('SalEstoque','Saes_grad_codigo'     ,'N',2 ,0,40 ,true ,'C�digo'                    ,'C�digo da grade'                            ,''    ,False,'2','','','2');
//  Inst.AddField('SalEstoque','Saes_codigolinha'     ,'N',03,0,20 ,True ,'Codigo da linha'           ,'Codigo da linha'                            ,''    ,True ,'1','','','0');
//  Inst.AddField('SalEstoque','Saes_codigocoluna'    ,'N',03,0,20 ,True ,'Codigo da coluna'          ,'Codigo da coluna'                           ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoque','Saes_tama_codigo'     ,'N',5 ,0,30 ,True ,'Tamanho'                   ,'C�digo do tamanho'                           ,''    ,False,'2','','','0');
  Inst.AddField('SalEstoque','Saes_core_codigo'     ,'N',3 ,0,30 ,True ,'Cor'                       ,'C�digo da cor'                               ,''    ,False,'2','','','0');
  Inst.AddField('SalEstoque','Saes_custo'           ,'N',12,2,80 ,True ,'Custo do produto'        ,'Custo do produto'                            ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoque','Saes_custoger'        ,'N',12,2,80 ,True ,'Custo gerencial'         ,'Custo gerencial'                             ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoque','Saes_customedio'      ,'N',12,2,80 ,True ,'Custo m�dio do produto'  ,'Custo m�dio do produto'                      ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoque','Saes_customeger'      ,'N',12,2,80 ,True ,'Custo m�dio gerencial'   ,'Custo m�dio gerencial'                       ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoque','Saes_Entradas'        ,'N',12,3,70 ,True ,'Total entradas'          ,'Total entradas'                               ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoque','Saes_Saidas'          ,'N',12,3,70 ,True ,'Total saidas'            ,'Total saidas'                                 ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoque','Saes_Qtde'            ,'N',12,3,70 ,True ,'Saldo em estoque'        ,'Saldo em estoque'                             ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoque','Saes_Qtdeprev'        ,'N',12,3,70 ,True ,'Saldo previsto'          ,'Saldo previsto'                               ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoque','Saes_Qtdeconsig'      ,'N',12,3,70 ,True ,'Saldo consignado'        ,'Saldo consignado'                               ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoque','Saes_Qtdepronta'      ,'N',12,3,70 ,True ,'Saldo pronta entrega'    ,'Saldo pronta entrega'                           ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoque','Saes_Qtderegesp'      ,'N',12,3,70 ,True ,'Saldo reg. especial'     ,'Saldo reg. especial'                            ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoque','Saes_Usua_Codigo'     ,'N',3 ,0,50 ,False,'Usu�rio'                 ,'Usu�rio respons�vel pelo cadastramento'      ,''    ,False,'3','','','0');
  Inst.AddField('SalEstoque','Saes_vendavis'        ,'N',12,2,80 ,True ,'Pre�o de venda a vista'    ,'Pre�o de venda a vista'                      ,''    ,True ,'1','','','0');
// 05.05.06
  Inst.AddField('SalEstoque','Saes_copa_codigo'     ,'N',3 ,0,30 ,True ,'Copa'                      ,'C�digo da copa'                               ,''    ,False,'2','','','0');
// 21.08.07
  Inst.AddField('SalEstoque','Saes_Pecas'           ,'N',12,3,70 ,True ,'Qtde pe�as'                ,'Qtde pe�as'                                  ,''    ,True ,'3','','','0');
// 15.10.09
  Inst.AddField('SalEstoque','Saes_Qtdeprocesso'    ,'N',12,3,70 ,True ,'Saldo estoque em processo'        ,'Saldo estoque em processo'                             ,''    ,True ,'1','','','0');

/////////////////////////////// - retirado em 15.10.09
// 21.11.07
{
  Inst.AddTable('SalEstoLoc');
  Inst.AddField('SalEstoLoc','Salo_status'          ,'C',1 ,0,30 ,False,'Status'                  ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('SalEstoLoc','Salo_mesano'          ,'C',6 ,0,30 ,False,'Mes/ano'                 ,'Mes/ano'                                      ,''    ,False,'2','','','2');
  Inst.AddField('SalEstoLoc','Salo_unid_codigo'     ,'C',3 ,0,30 ,False,'C�digo'                  ,'C�digo da unidade'                            ,''    ,False,'2','','','2');
  Inst.AddField('SalEstoLoc','Salo_Esto_codigo'     ,'C',20,0,30 ,False,'C�digo'                  ,'C�digo do produto'                           ,''    ,False,'1','','','2');
  Inst.AddField('SalEstoLoc','Salo_tama_codigo'     ,'N',5 ,0,30 ,True ,'Tamanho'                   ,'C�digo do tamanho'                           ,''    ,False,'2','','','0');
  Inst.AddField('SalEstoLoc','Salo_core_codigo'     ,'N',3 ,0,30 ,True ,'Cor'                       ,'C�digo da cor'                               ,''    ,False,'2','','','0');
  Inst.AddField('SalEstoLoc','Salo_custo'           ,'N',12,2,80 ,True ,'Custo do produto'        ,'Custo do produto'                            ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoLoc','Salo_custoger'        ,'N',12,2,80 ,True ,'Custo gerencial'         ,'Custo gerencial'                             ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoLoc','Salo_customedio'      ,'N',12,2,80 ,True ,'Custo m�dio do produto'  ,'Custo m�dio do produto'                      ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoLoc','Salo_customeger'      ,'N',12,2,80 ,True ,'Custo m�dio gerencial'   ,'Custo m�dio gerencial'                       ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoLoc','Salo_Entradas'        ,'N',12,3,70 ,True ,'Total entradas'          ,'Total entradas'                               ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoLoc','Salo_Saidas'          ,'N',12,3,70 ,True ,'Total saidas'            ,'Total saidas'                                 ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoLoc','Salo_Qtde'            ,'N',12,3,70 ,True ,'Saldo em estoque'        ,'Saldo em estoque'                             ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoLoc','Salo_Qtdeprev'        ,'N',12,3,70 ,True ,'Saldo previsto'          ,'Saldo previsto'                               ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoLoc','Salo_Usua_Codigo'     ,'N',3 ,0,50 ,False,'Usu�rio'                 ,'Usu�rio respons�vel pelo cadastramento'      ,''    ,False,'3','','','0');
  Inst.AddField('SalEstoLoc','Salo_vendavis'        ,'N',12,2,80 ,True ,'Pre�o de venda a vista'    ,'Pre�o de venda a vista'                      ,''    ,True ,'1','','','0');
  Inst.AddField('SalEstoLoc','Salo_copa_codigo'     ,'N',3 ,0,30 ,True ,'Copa'                      ,'C�digo da copa'                               ,''    ,False,'2','','','0');
  Inst.AddField('SalEstoLoc','Salo_Pecas'           ,'N',12,3,70 ,True ,'Qtde pe�as'                ,'Qtde pe�as'                                  ,''    ,True ,'3','','','0');
  Inst.AddField('SalEstoLoc','Salo_local'           ,'C',02,0,70 ,True ,'Local Estoque'             ,'Local Estoque'                                  ,''    ,True ,'3','','','0');
  }
///////////////////////////////

  Inst.AddTable('EstGrades');
  Inst.AddField('EstGrades','Esgr_status'            ,'C',1  ,0,30  ,False,'Status'                    ,'Status do registro'                          ,''    ,False,'2','','','2');
  Inst.AddField('EstGrades','Esgr_unid_codigo'       ,'C',3  ,0,30  ,False,'C�digo'                    ,'C�digo da unidade'                            ,''    ,False,'2','','','2');
  Inst.AddField('EstGrades','Esgr_esto_codigo'       ,'C',20 ,0,90  ,False,'C�digo'                    ,'C�digo do produto'                            ,''    ,False,'2','','','2');
// cada tamanho ter� q ter seu codigo de barras - prever esta quest�o
  Inst.AddField('EstGrades','Esgr_Codbarra'          ,'C',20,0,100  ,True ,'Codigo de barras'          ,'Codigo de barras'                            ,''    ,True ,'1','','','0');
  Inst.AddField('EstGrades','Esgr_grad_codigo'       ,'N',2  ,0,40  ,true ,'C�digo'                    ,'C�digo da grade'                            ,''    ,False,'2','','','2');
  Inst.AddField('EstGrades','Esgr_codigolinha'       ,'N',03 ,0,20  ,True ,'Codigo da linha'           ,'Codigo da linha'                            ,''    ,True ,'1','','','0');
  Inst.AddField('EstGrades','Esgr_codigocoluna'      ,'N',03 ,0,20  ,True ,'Codigo da coluna'          ,'Codigo da coluna'                           ,''    ,True ,'1','','','0');
  Inst.AddField('EstGrades','Esgr_Qtde'              ,'N',12,3,70   ,True ,'Qtde em estoque'           ,'Qtde em estoque'                             ,''    ,True ,'1','','','0');
  Inst.AddField('EstGrades','Esgr_Qtdeprev'          ,'N',12,3,70   ,True ,'Qtde prevista'             ,'Qtde prevista'                               ,''    ,True ,'1','','','0');
  Inst.AddField('EstGrades','Esgr_vendavis'          ,'N',12,2,80   ,True ,'Pre�o de venda a vista'    ,'Pre�o de venda a vista'                      ,''    ,True ,'1','','','0');
  Inst.AddField('EstGrades','Esgr_custo'             ,'N',12,2,80   ,True ,'Custo do produto'          ,'Custo do produto'                            ,''    ,True ,'1','','','0');
  Inst.AddField('EstGrades','Esgr_custoger'          ,'N',12,2,80   ,True ,'Custo gerencial'           ,'Custo gerencial'                             ,''    ,True ,'1','','','0');
  Inst.AddField('EstGrades','Esgr_customedio'        ,'N',12,2,80   ,True ,'Custo m�dio do produto'    ,'Custo m�dio do produto'                      ,''    ,True ,'1','','','0');
  Inst.AddField('EstGrades','Esgr_customeger'        ,'N',12,2,80   ,True ,'Custo m�dio gerencial'     ,'Custo m�dio gerencial'                       ,''    ,True ,'1','','','0');
  Inst.AddField('EstGrades','Esgr_dtultvenda'        ,'D',8 ,0,60   ,True ,'Data �ltima venda'         ,'Data �ltima venda'                           ,''    ,True ,'1','','','0');
  Inst.AddField('EstGrades','Esgr_dtultcompra'       ,'D',8 ,0,60   ,True ,'Data �ltima compra'        ,'Data �ltima compra'                          ,''    ,True ,'1','','','0');
  Inst.AddField('EstGrades','Esgr_Usua_Codigo'       ,'N',3  ,0,50  ,False,'Usu�rio'                   ,'Usu�rio respons�vel pelo cadastramento'     ,''    ,False,'3','','','0');
  Inst.AddField('EstGrades','Esgr_tama_codigo'       ,'N',5 ,0,30   ,True ,'Tamanho'                   ,'C�digo do tamanho'                           ,''    ,False,'2','','','0');
  Inst.AddField('EstGrades','Esgr_core_codigo'       ,'N',3 ,0,30   ,True ,'Cor'                       ,'C�digo da cor'                               ,''    ,False,'2','','','0');
// 05.05.06
  Inst.AddField('EstGrades','Esgr_copa_codigo'       ,'N',3 ,0,30   ,True ,'Copa'                      ,'C�digo da copa'                               ,''    ,False,'2','','','0');
// 15.04.08
  Inst.AddField('EstGrades','Esgr_custoser'          ,'N',12,2,80 ,True ,'M.Obra do produto'          ,'M.Obra do produto'                            ,''    ,True ,'3','','','0');
  Inst.AddField('EstGrades','Esgr_customedioser'     ,'N',12,2,80 ,True ,'M.Obra m�dia do produto'    ,'M.Obra m�dia do produto'                      ,''    ,True ,'3','','','0');
  Inst.AddField('EstGrades','Esgr_Pecas'             ,'N',12,3,70 ,True ,'Qtde pe�as'                ,'Qtde pe�as'                                   ,''    ,True ,'3','','','0');
// 19.06.09
  Inst.AddField('EstGrades','Esgr_ressuprimento'     ,'N',12,3,80 ,True ,'Ressuprimento'    ,'Ponto de Ressuprimento do Estoque'                      ,''    ,True ,'1','','','0');
// 15.10.09
  Inst.AddField('EstGrades','Esgr_Qtdeprocesso'      ,'N',12,3,70   ,True ,'Estoque em processo'       ,'Estoque em processo'                             ,''    ,True ,'1','','','0');
// 07.02.23 - devereda
  Inst.AddField('EstGrades','Esgr_unidade'           ,'C',10,0,70 ,True ,'Unidade do Produto'        ,'Unidade do produto'                          ,''    ,True ,'1','','','0');

  Inst.AddTable('Grades');
  Inst.AddField('Grades','Grad_codigo'            ,'N',02 ,0,40  ,False,'C�digo da grade'           ,'C�digo da grade'                            ,''    ,False,'2','','','2');
  Inst.AddField('Grades','Grad_descricao'         ,'C',50 ,0,200 ,True ,'Descri��o da grade'        ,'Descri��o da grade'                         ,''    ,True ,'1','','','0');
  Inst.AddField('Grades','Grad_codigolinha'       ,'N',03 ,0,20  ,True ,'Codigo da linha'           ,'Codigo da linha'                            ,''    ,True ,'1','','','0');
  Inst.AddField('Grades','Grad_codigocoluna'      ,'N',03 ,0,20  ,True ,'Codigo da coluna'          ,'Codigo da coluna'                           ,''    ,True ,'1','','','0');
  Inst.AddField('Grades','Grad_linha'             ,'C',100,0,200 ,True ,'C�digos da linha'          ,'C�digos da linha'                           ,''    ,True ,'1','','','0');
  Inst.AddField('Grades','Grad_coluna'            ,'C',100,0,200 ,True ,'C�digos da coluna'         ,'C�digos da coluna'                          ,''    ,True ,'1','','','1');
  Inst.AddField('Grades','Grad_Usua_Codigo'       ,'N',3  ,0,50  ,False,'Usu�rio'                   ,'Usu�rio respons�vel pelo cadastramento'     ,''    ,False,'3','','','0');

  Inst.AddTable('Grupos');
  Inst.AddField('Grupos','Grup_codigo'            ,'N',06,0,40 ,False,'C�digo do grupo'           ,'C�digo do grupo'                            ,''    ,False,'2','','','2');
  Inst.AddField('Grupos','Grup_descricao'         ,'C',50,0,250,False,'Descri��o do grupo'        ,'Descri��o do grupo'                         ,''    ,False,'1','','','2');
// 01.06.07
  Inst.AddField('Grupos','Grup_valorarroba'       ,'N',8 ,3,30 ,True ,'Valor Arroba'              ,'Valora Arroba'                        ,''    ,True ,'3','','','0');
// 18.12.08
  Inst.AddField('Grupos','Grup_Comissao'          ,'N',10,5,60 ,True,'Comiss�o','Percentual de comiss�o para o vendedor','##0.000',True,'3','','','0');
// 21.04.09
  Inst.AddField('Grupos','Grup_Markup'            ,'N',10,5,60 ,True,'Markup','Markup Divisor para c�lculo pre�o de venda','##0.000',True,'3','','','0');
// 02.09.09
  Inst.AddField('Grupos','Grup_FaixaCustoI'       ,'N',11,3,60 ,True,'Custo Inicial','Custo Inicial','',True,'3','','','0');
  Inst.AddField('Grupos','Grup_FaixaCustoF'       ,'N',11,3,60 ,True,'Custo Final'  ,'Custo Final','',True,'3','','','0');
  Inst.AddField('Grupos','Grup_Margem'            ,'N',10,5,60 ,True,'Margem','Margem sobre custo para c�lculo pre�o de venda','',True,'3','','','0');
// 20.08.12
  Inst.AddField('Grupos','Grup_Faix_codigo'       ,'C',03,0,40 ,True,'C�digo da faixa'           ,'C�digo da faixa de valores'                            ,''    ,False,'1','','','0');
// 22.09.17
  Inst.AddField('Grupos','Grup_SomenteCodBarra'   ,'C',01,0,40 ,True,'S� Cod.Barra'             ,'Venda somente com codigo de barra na balan�a'                            ,''    ,False,'1','','','0');
// 02.07.19
  Inst.AddField('Grupos','Grup_sitt_codestadocf'   ,'N',2 ,0,30 ,True ,'Sit.trib.dentro estado'    ,'Sit.trib.dentro estado para consumidor final' ,''    ,True ,'1','','','0');
  Inst.AddField('Grupos','Grup_sitt_forestadocf'   ,'N',2 ,0,30 ,True ,'Sit.trib.fora estado'      ,'Sit.trib.fora estado para consumidor final'   ,''    ,True ,'1','','','0');
// 09.01.20
  Inst.AddField('Grupos','Grup_ToleBalVen'         ,'N',10,5,60 ,True,'Toler.(%)','Toler�ncia para balan�a de vendas','',True,'3','','','0');
  Inst.AddField('Grupos','Grup_CodAdapar'          ,'C',04,0,60 ,True,'Adapar',  'Codigo ref. Adapar etiqueta abate','',True,'3','','','0');


  Inst.AddTable('SubGrupos');
  Inst.AddField('SubGrupos','Sugr_codigo'            ,'N',04,0,40 ,False,'C�digo'      ,'C�digo do subgrupo'                        ,''    ,False,'2','','','2');
  Inst.AddField('SubGrupos','Sugr_descricao'         ,'C',50,0,250,False,'Descri��o do subgrupo'   ,'Descri��o do subgrupo'                     ,''    ,False,'1','','','2');
// 13.07.06
  Inst.AddField('SubGrupos','Sugr_cfis_codigoest'    ,'C',03,0,45 ,True ,'Codigo icms dentro estado' ,'Codigo icms dentro estado'                   ,f_aliq,True ,'1','','','0');
  Inst.AddField('SubGrupos','Sugr_cfis_codigoforaest','C',03,0,45 ,True ,'Codigo icms fora estado'   ,'Codigo icms fora estado'                     ,f_aliq,True ,'1','','','0');
  Inst.AddField('SubGrupos','Sugr_sitt_codestado'    ,'N',2 ,0,30 ,True ,'Sit.trib.dentro estado'    ,'Sit.trib.dentro estado'                      ,''    ,True ,'1','','','0');
  Inst.AddField('SubGrupos','Sugr_sitt_forestado'    ,'N',2 ,0,30 ,True ,'Sit.trib.fora estado'      ,'Sit.trib.fora estado'                        ,''    ,True ,'1','','','0');
  Inst.AddField('SubGrupos','Sugr_Natf_Codigoes'     ,'C',5 ,0,50 ,True ,'CFOP no estado'            ,'C�digo da natureza fiscal','#.####;0;_',False,'','','','2');
  Inst.AddField('SubGrupos','Sugr_Natf_Codigofo'     ,'C',5 ,0,50 ,True ,'CFOP fora estado'          ,'C�digo da natureza fiscal','#.####;0;_',False,'','','','2');
// 27.05.07
  Inst.AddField('SubGrupos','Sugr_valorarroba'       ,'N',8 ,3,30 ,True ,'Valor Arroba'              ,'Valor da Arroba'                        ,''    ,True ,'3','','','0');
// 30.12.08
  Inst.AddField('SubGrupos','Sugr_percperda'         ,'N',8 ,3,30 ,True ,'% Perda'                   ,'% Perda na venda'                        ,''    ,True ,'3','','','0');
// 21.06.16
  Inst.AddField('SubGrupos','Sugr_cstpis'             ,'C',05,0,30 ,True,'CST Pis'      ,'C�digo da situa��o tribut�ria para o PIS para SAIDAS'             ,''    ,False,'1','','','0');
  Inst.AddField('SubGrupos','Sugr_cstcofins'          ,'C',05,0,30 ,True,'CST Cofins'   ,'C�digo da situa��o tribut�ria para o COFINS para SAIDAS'             ,''    ,False,'1','','','0');
// 06.02.19 - Novicarnes
  Inst.AddField('SubGrupos','Sugr_tolera'             ,'N',08,3,50 ,True,'% Toler�ncia'   ,'Toler�ncia de peso para balan�a'             ,''    ,False,'3','','','0');


  Inst.AddTable('Familias');
  Inst.AddField('Familias','Fami_codigo'            ,'N',04,0,40 ,False,'C�digo'      ,'C�digo da familia'                        ,''    ,False,'2','','','2');
  Inst.AddField('Familias','Fami_descricao'         ,'C',50,0,250,False,'Descri��o'   ,'Descri��o da familia'                     ,''    ,False,'1','','','2');

  Inst.AddTable('Tamanhos');
//  Inst.AddField('Tamanhos','Tama_codigo'            ,'N',03,0,40 ,False,'C�digo do tamanho'         ,'C�digo do tamanho'                    ,''    ,False,'2','','','2');
// 24.04.08
  Inst.AddField('Tamanhos','Tama_codigo'            ,'N',05,0,40 ,False,'C�digo do tamanho'         ,'C�digo do tamanho'                    ,''    ,False,'2','','','2');
  Inst.AddField('Tamanhos','Tama_reduzido'          ,'C',10,0,60 ,False,'Forma reduzida'            ,'Forma reduzida'                       ,''    ,False,'1','','','');
  Inst.AddField('Tamanhos','Tama_descricao'         ,'C',50,0,250,False,'Descri��o do tamanho'      ,'Descri��o do tamanho'                 ,''    ,False,'1','','','');
// 03.01.07
  Inst.AddField('Tamanhos','Tama_comprimento'       ,'N',11,4, 80,True ,'Comprimento'               ,'Comprimento'                          ,''    ,True ,'1','','','0');
  Inst.AddField('Tamanhos','Tama_largura'           ,'N',11,4, 80,True ,'Largura'                   ,'Largura'                              ,''    ,True ,'1','','','0');
  Inst.AddField('Tamanhos','Tama_espessura'         ,'N',11,4, 80,True ,'Espessura'                 ,'Espessura'                            ,''    ,True ,'1','','','0');

  Inst.AddTable('Cores');
  Inst.AddField('Cores','Core_codigo'            ,'N',03,0,40 ,False,'C�digo da cor'      ,'C�digo da cor'                        ,''    ,False,'2','','','2');
  Inst.AddField('Cores','Core_descricao'         ,'C',50,0,250,False,'Descri��o da cor'   ,'Descri��o da cor'                     ,''    ,False,'1','','','2');

  Inst.AddTable('Material');
  Inst.AddField('Material','Mate_codigo'            ,'N',04,0,40 ,False,'C�digo'      ,'C�digo do material'                       ,''    ,False,'2','','','2');
  Inst.AddField('Material','Mate_descricao'         ,'C',50,0,250,False,'Descri��o'   ,'Descri��o do material'                    ,''    ,False,'1','','','2');
// 31.07.08 -  confirmar antes de implementar
  Inst.AddTable('Similares');
  Inst.AddField('Similares','Simi_esto_codigo'       ,'C',20,0,30 ,False,'C�digo'                    ,'C�digo do produto'                           ,''    ,False,'1','','','2');
  Inst.AddField('Similares','Simi_esto_similar '     ,'C',20,0,30 ,False,'Similar'                    ,'C�digo do produto similar'                           ,''    ,False,'1','','','2');
  Inst.AddField('Similares','Simi_Usua_Codigo'       ,'N',003,0,50 ,False,'Usu�rio'                   ,'Usu�rio respons�vel pelo cadastramento'      ,''    ,False,'3','','','0');
// 20.08.12
  Inst.AddTable('Faixas');
  Inst.AddField('Faixas','Faix_Status'                 ,'C',1  ,0,50  ,True ,'Status'       ,'Status'         ,'',False,'','','','0');
  Inst.AddField('Faixas','Faix_Codigo'                 ,'C',3  ,0,50  ,True ,'Codigo'       ,'Codigo do faixa' ,'',False,'','','','2');
  Inst.AddField('Faixas','Faix_Seq'                    ,'C',4  ,0,50  ,True ,'Sequencial'   ,'Sequencial'     ,'',False,'','','','2');
  Inst.AddField('Faixas','Faix_Inicio'                 ,'N',11 ,3,60  ,True ,'Inicio Faixa' ,'Inicio Faixa'   ,'',True,'','','','0');
  Inst.AddField('Faixas','Faix_Fim'                    ,'N',11 ,3,60  ,True ,'T�rmino Faixa','T�rmino Faixa'   ,'',True,'','','','0');
  Inst.AddField('Faixas','Faix_Usua_Codigo'            ,'N',3  ,0,50  ,True ,'Usu�rio'      ,'Usu�rio que informou'   ,'',False,'','','','0');
  Inst.AddField('Faixas','Faix_Valor'                  ,'N',10 ,5,60  ,True ,'Valor'        ,'Valor da faixa de valores','',True,'3','','','0');

end;

// 08.11.19
procedure TFInstsac.CriaTabelasPonto;
///////////////////////////////////////
begin

  Inst.AddTable('MovPonto');
  Inst.AddField('MovPonto','Mvpo_Status'               ,'C',1  ,0,50  ,True ,'Status'       ,'Status'         ,'',False,'','','','0');
  Inst.AddField('MovPonto','Mvpo_Unid_Codigo'          ,'C',3  ,0,50  ,True ,'Unidade'      ,'' ,'',False,'','','','2');
  Inst.AddField('MovPonto','Mvpo_Data'                 ,'D',8  ,0,70  ,True ,'Data'         ,''     ,'',False,'','','','1');
  Inst.AddField('MovPonto','Mvpo_DataLcto'             ,'D',8  ,0,70  ,True ,'Data Lcto'     ,''     ,'',False,'','','','1');
  Inst.AddField('MovPonto','Mvpo_Hora'                 ,'C',8  ,0,50  ,True ,'Hora'         ,''     ,'',False,'','','','1');
  Inst.AddField('MovPonto','Mvpo_Tipo'                 ,'C',1  ,0,50  ,True ,'I/D'          ,'Indivudual/Dupla'     ,'',False,'','','','2');
  Inst.AddField('MovPonto','Mvpo_Cola_Codigo01'        ,'C',4  ,0,60  ,True ,'Motorista 01'  ,'C�digo do colaborador 01','0000',True,'1','','','2');
  Inst.AddField('MovPonto','Mvpo_Cola_Codigo02'        ,'C',4  ,0,60  ,True ,'Motorista 02'  ,'C�digo do colaborador 02','0000',True,'1','','','2');
  Inst.AddField('MovPonto','Mvpo_tran_codigo'          ,'C',3  ,0,30  ,True ,'C�digo'                    ,'C�digo do transportador'                   ,''    ,False,'1','','','0');

  Inst.AddField('MovPonto','Mvpo_IniHH01'              ,'N',02 ,0,60  ,True ,'Hora Inicio 01' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_IniMM01'              ,'N',02 ,0,60  ,True ,'Min. Inicio 01' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimHH01'              ,'N',02 ,0,60  ,True ,'Hora Final 01' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimMM01'              ,'N',02 ,0,60  ,True ,'Min. Final 01' ,''   ,'',True,'','','','0');

  Inst.AddField('MovPonto','Mvpo_IniHH02'              ,'N',02 ,0,60  ,True ,'Hora Inicio 02' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_IniMM02'              ,'N',02 ,0,60  ,True ,'Min. Inicio 02' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimHH02'              ,'N',02 ,0,60  ,True ,'Hora Final 02' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimMM02'              ,'N',02 ,0,60  ,True ,'Min. Final 02' ,''   ,'',True,'','','','0');

  Inst.AddField('MovPonto','Mvpo_IniHH03'              ,'N',02 ,0,60  ,True ,'Hora Inicio 03' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_IniMM03'              ,'N',02 ,0,60  ,True ,'Min. Inicio 03' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimHH03'              ,'N',02 ,0,60  ,True ,'Hora Final 03' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimMM03'              ,'N',02 ,0,60  ,True ,'Min. Final 03' ,''   ,'',True,'','','','0');

  Inst.AddField('MovPonto','Mvpo_IniHH04'              ,'N',02 ,0,60  ,True ,'Hora Inicio 04' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_IniMM04'              ,'N',02 ,0,60  ,True ,'Min. Inicio 04' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimHH04'              ,'N',02 ,0,60  ,True ,'Hora Final 04' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimMM04'              ,'N',02 ,0,60  ,True ,'Min. Final 04' ,''   ,'',True,'','','','0');

  Inst.AddField('MovPonto','Mvpo_IniHH05'              ,'N',02 ,0,60  ,True ,'Hora Inicio 05' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_IniMM05'              ,'N',02 ,0,60  ,True ,'Min. Inicio 05' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimHH05'              ,'N',02 ,0,60  ,True ,'Hora Final 05' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimMM05'              ,'N',02 ,0,60  ,True ,'Min. Final 05' ,''   ,'',True,'','','','0');

  Inst.AddField('MovPonto','Mvpo_IniHH06'              ,'N',02 ,0,60  ,True ,'Hora Inicio 06' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_IniMM06'              ,'N',02 ,0,60  ,True ,'Min. Inicio 06' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimHH06'              ,'N',02 ,0,60  ,True ,'Hora Final 06' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimMM06'              ,'N',02 ,0,60  ,True ,'Min. Final 06' ,''   ,'',True,'','','','0');

  Inst.AddField('MovPonto','Mvpo_IniRHH01'              ,'N',02 ,0,60  ,True ,'Hora Res.Inicio 01' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_IniRMM01'              ,'N',02 ,0,60  ,True ,'Min. Res.Inicio 01' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimRHH01'              ,'N',02 ,0,60  ,True ,'Hora Res.Final 01' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimRMM01'              ,'N',02 ,0,60  ,True ,'Min. Res.Final 01' ,''   ,'',True,'','','','0');

  Inst.AddField('MovPonto','Mvpo_IniRHH02'              ,'N',02 ,0,60  ,True ,'Hora Res.Inicio 02' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_IniRMM02'              ,'N',02 ,0,60  ,True ,'Min. Res.Inicio 02' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimRHH02'              ,'N',02 ,0,60  ,True ,'Hora Res.Final 02' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimRMM02'              ,'N',02 ,0,60  ,True ,'Min. Res.Final 02' ,''   ,'',True,'','','','0');

  Inst.AddField('MovPonto','Mvpo_IniRHH03'              ,'N',02 ,0,60  ,True ,'Hora Res.Inicio 03' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_IniRMM03'              ,'N',02 ,0,60  ,True ,'Min. Res.Inicio 03' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimRHH03'              ,'N',02 ,0,60  ,True ,'Hora Res.Final 03' ,''   ,'',True,'','','','0');
  Inst.AddField('MovPonto','Mvpo_FimRMM03'              ,'N',02 ,0,60  ,True ,'Min. Res.Final 03' ,''   ,'',True,'','','','0');

end;

end.



