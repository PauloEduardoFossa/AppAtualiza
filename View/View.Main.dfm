object frmMain: TfrmMain
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'AppAtualiza'
  ClientHeight = 800
  ClientWidth = 1180
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  WindowState = wsMaximized
  KeyPreview = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1180
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    OnDblClick = btnMaximizarClick
    OnMouseDown = pnlHeaderMouseDown
    object lblTitulo: TLabel
      Left = 20
      Top = 10
      Width = 89
      Height = 21
      Caption = 'AppAtualiza'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -17
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblVersao: TLabel
      Left = 118
      Top = 15
      Width = 38
      Height = 15
      Caption = 'v1.0.0'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitulo: TLabel
      Left = 20
      Top = 36
      Width = 331
      Height = 15
      Caption =
        'Executor de Scripts de Atualiza'#231#227'o de Banco de Dados'
    end
    object btnMaximizar: TButton
      Left = 1092
      Top = 16
      Width = 32
      Height = 32
      Anchors = [akTop, akRight]
      Caption = #9633
      TabOrder = 2
      OnClick = btnMaximizarClick
    end
    object btnFechar: TButton
      Left = 1132
      Top = 16
      Width = 32
      Height = 32
      Anchors = [akTop, akRight]
      Caption = 'X'
      TabOrder = 0
      OnClick = btnFecharClick
    end
  end
  object pnlSidebar: TPanel
    Left = 0
    Top = 64
    Width = 500
    Height = 736
    Align = alLeft
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object lblSecaoBanco: TLabel
      Left = 20
      Top = 16
      Width = 105
      Height = 15
      Caption = 'BANCO DE DADOS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblClienteBase: TLabel
      Left = 20
      Top = 42
      Width = 68
      Height = 15
      Caption = 'Cliente/Base'
    end
    object lblServidor: TLabel
      Left = 20
      Top = 132
      Width = 45
      Height = 15
      Caption = 'Servidor'
    end
    object lblPorta: TLabel
      Left = 20
      Top = 182
      Width = 30
      Height = 15
      Caption = 'Porta'
    end
    object lblCaminhoBanco: TLabel
      Left = 20
      Top = 232
      Width = 143
      Height = 15
      Caption = 'Caminho do Banco (.FDB)'
    end
    object lblUsuario: TLabel
      Left = 20
      Top = 282
      Width = 46
      Height = 15
      Caption = 'Usu'#225'rio'
    end
    object lblSenha: TLabel
      Left = 20
      Top = 332
      Width = 35
      Height = 15
      Caption = 'Senha'
    end
    object lblCharset: TLabel
      Left = 20
      Top = 382
      Width = 43
      Height = 15
      Caption = 'Charset'
    end
    object lblFbClient: TLabel
      Left = 20
      Top = 432
      Width = 168
      Height = 15
      Caption = 'fbclient.dll (opcional)'
    end
    object lblSecaoScripts: TLabel
      Left = 20
      Top = 487
      Width = 47
      Height = 15
      Caption = 'SCRIPTS'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblVersaoScripts: TLabel
      Left = 20
      Top = 513
      Width = 88
      Height = 15
      Caption = 'Vers'#227'o dos Scripts'
    end
    object lblPastaScripts: TLabel
      Left = 20
      Top = 563
      Width = 100
      Height = 15
      Caption = 'Pasta dos Scripts'
    end
    object lblStatusConexao: TLabel
      Left = 20
      Top = 732
      Width = 3
      Height = 15
    end
    object cbxClienteBase: TComboBox
      Left = 20
      Top = 60
      Width = 390
      Height = 23
      AutoDropDown = True
      TabOrder = 0
      OnChange = cbxClienteBaseChange
    end
    object btnRecarregarBases: TButton
      Left = 420
      Top = 59
      Width = 60
      Height = 25
      Hint = 'Recarregar lista de bases'
      Caption = #8635
      ParentShowHint = False
      ShowHint = True
      TabOrder = 20
      OnClick = btnRecarregarBasesClick
    end
    object btnAtivarBase: TButton
      Left = 20
      Top = 90
      Width = 460
      Height = 32
      Caption = 'Ativar esta base'
      TabOrder = 21
      OnClick = btnAtivarBaseClick
    end
    object lblMigrarBases: TLabel
      Left = 330
      Top = 42
      Width = 150
      Height = 15
      Cursor = crHandPoint
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'Migrar soltos'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHotLight
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsUnderline]
      ParentFont = False
      StyleElements = [seClient, seBorder]
      Visible = False
      OnClick = btnMigrarBasesClick
    end
    object edtServidor: TEdit
      Left = 20
      Top = 150
      Width = 460
      Height = 23
      TabOrder = 1
      Text = 'localhost'
    end
    object edtPorta: TEdit
      Left = 20
      Top = 200
      Width = 100
      Height = 23
      TabOrder = 2
      Text = '3050'
    end
    object edtCaminhoBanco: TEdit
      Left = 20
      Top = 250
      Width = 390
      Height = 23
      TabOrder = 3
    end
    object btnBrowseBanco: TButton
      Left = 420
      Top = 249
      Width = 60
      Height = 25
      Caption = '...'
      TabOrder = 4
      OnClick = btnBrowseBancoClick
    end
    object edtUsuario: TEdit
      Left = 20
      Top = 300
      Width = 460
      Height = 23
      TabOrder = 5
      Text = 'SYSDBA'
    end
    object edtSenha: TEdit
      Left = 20
      Top = 350
      Width = 460
      Height = 23
      PasswordChar = '*'
      TabOrder = 6
    end
    object cbxCharset: TComboBox
      Left = 20
      Top = 400
      Width = 460
      Height = 23
      Style = csDropDownList
      TabOrder = 7
      Items.Strings = (
        'NONE'
        'WIN1252'
        'ISO8859_1'
        'UTF8')
    end
    object edtFbClient: TEdit
      Left = 20
      Top = 450
      Width = 390
      Height = 23
      TabOrder = 8
    end
    object btnBrowseFbClient: TButton
      Left = 420
      Top = 449
      Width = 60
      Height = 25
      Caption = '...'
      TabOrder = 9
      OnClick = btnBrowseFbClientClick
    end
    object cbxVersaoScripts: TComboBox
      Left = 20
      Top = 531
      Width = 460
      Height = 23
      Style = csDropDownList
      TabOrder = 10
      OnChange = cbxVersaoScriptsChange
      OnDropDown = cbxVersaoScriptsDropDown
    end
    object edtPastaScripts: TEdit
      Left = 20
      Top = 581
      Width = 390
      Height = 23
      TabOrder = 11
    end
    object btnBrowsePastaScripts: TButton
      Left = 420
      Top = 580
      Width = 60
      Height = 25
      Caption = '...'
      TabOrder = 12
      OnClick = btnBrowsePastaScriptsClick
    end
    object chkPararErro: TCheckBox
      Left = 20
      Top = 616
      Width = 460
      Height = 17
      Caption = 'Parar ao encontrar erro'
      Checked = True
      State = cbChecked
      TabOrder = 13
    end
    object btnTestarConexao: TButton
      Left = 20
      Top = 652
      Width = 460
      Height = 32
      Caption = 'Testar Conex'#227'o'
      TabOrder = 14
      OnClick = btnTestarConexaoClick
    end
    object btnSalvarConfig: TButton
      Left = 20
      Top = 692
      Width = 460
      Height = 32
      Caption = 'Salvar Configura'#231#227'o'
      TabOrder = 15
      OnClick = btnSalvarConfigClick
    end
  end
  object pnlConteudo: TPanel
    Left = 500
    Top = 64
    Width = 680
    Height = 736
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 2
    object pnlToolbar: TPanel
      Left = 0
      Top = 0
      Width = 680
      Height = 56
      Align = alTop
      BevelOuter = bvNone
      ParentBackground = False
      TabOrder = 0
      object btnAtualizarLista: TButton
        Left = 16
        Top = 12
        Width = 160
        Height = 32
        Caption = 'Atualizar Lista'
        TabOrder = 0
        OnClick = btnAtualizarListaClick
      end
      object btnExecutar: TButton
        Left = 276
        Top = 12
        Width = 160
        Height = 32
        Caption = 'Executar Pendentes'
        TabOrder = 3
        OnClick = btnExecutarClick
      end
      object btnParar: TButton
        Left = 444
        Top = 12
        Width = 100
        Height = 32
        Caption = 'Parar'
        Enabled = False
        TabOrder = 4
        OnClick = btnPararClick
      end
      object btnVersaoAnterior: TButton
        Left = 184
        Top = 12
        Width = 40
        Height = 32
        Hint = 'Selecionar a vers'#227'o anterior dos scripts'
        Caption = '<'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnClick = btnVersaoAnteriorClick
      end
      object btnProximaVersao: TButton
        Left = 228
        Top = 12
        Width = 40
        Height = 32
        Hint = 'Selecionar a pr'#243'xima vers'#227'o dos scripts'
        Caption = '>'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        OnClick = btnProximaVersaoClick
      end
    end
    object pnlCards: TPanel
      Left = 0
      Top = 56
      Width = 680
      Height = 100
      Align = alTop
      BevelOuter = bvNone
      ParentBackground = False
      TabOrder = 1
      object pnlCardTotal: TPanel
        Left = 16
        Top = 12
        Width = 120
        Height = 76
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 0
        object lblCardTotalValor: TLabel
          Left = 12
          Top = 8
          Width = 24
          Height = 32
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -27
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblCardTotalTitulo: TLabel
          Left = 12
          Top = 48
          Width = 27
          Height = 15
          Caption = 'Total'
        end
      end
      object pnlCardPendentes: TPanel
        Left = 148
        Top = 12
        Width = 120
        Height = 76
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 1
        object lblCardPendentesValor: TLabel
          Left = 12
          Top = 8
          Width = 24
          Height = 32
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -27
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblCardPendentesTitulo: TLabel
          Left = 12
          Top = 48
          Width = 59
          Height = 15
          Caption = 'Pendentes'
        end
      end
      object pnlCardAplicados: TPanel
        Left = 280
        Top = 12
        Width = 120
        Height = 76
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 2
        object lblCardAplicadosValor: TLabel
          Left = 12
          Top = 8
          Width = 24
          Height = 32
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -27
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblCardAplicadosTitulo: TLabel
          Left = 12
          Top = 48
          Width = 59
          Height = 15
          Caption = 'Aplicados'
        end
      end
      object pnlCardErros: TPanel
        Left = 412
        Top = 12
        Width = 120
        Height = 76
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 3
        object lblCardErrosValor: TLabel
          Left = 12
          Top = 8
          Width = 24
          Height = 32
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -27
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblCardErrosTitulo: TLabel
          Left = 12
          Top = 48
          Width = 33
          Height = 15
          Caption = 'Erros'
        end
      end
      object pnlCardUltimo: TPanel
        Left = 544
        Top = 12
        Width = 120
        Height = 76
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 4
        object lblCardUltimoValor: TLabel
          Left = 12
          Top = 8
          Width = 11
          Height = 32
          Caption = '-'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblCardUltimoTitulo: TLabel
          Left = 12
          Top = 48
          Width = 77
          Height = 15
          Caption = #218'ltimo script'
        end
      end
    end
    object pnlLog: TPanel
      Left = 0
      Top = 440
      Width = 680
      Height = 236
      Align = alBottom
      BevelOuter = bvNone
      ParentBackground = False
      TabOrder = 2
      object lblLogTitulo: TLabel
        Left = 16
        Top = 8
        Width = 108
        Height = 15
        Caption = 'Log de Execu'#231#227'o'
      end
      object memoLog: TMemo
        Left = 16
        Top = 28
        Width = 648
        Height = 160
        Anchors = [akLeft, akTop, akRight, akBottom]
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        PopupMenu = pmLog
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
      object btnAbrirLogErros: TButton
        Left = 16
        Top = 196
        Width = 220
        Height = 32
        Anchors = [akLeft, akBottom]
        Caption = 'Abrir Log de Erros desta Execu'#231#227'o'
        TabOrder = 1
        OnClick = btnAbrirLogErrosClick
      end
    end
    object lvScripts: TListView
      Left = 0
      Top = 156
      Width = 680
      Height = 284
      Align = alClient
      Checkboxes = True
      Columns = <
        item
          Caption = 'C'#243'digo'
          Width = 120
        end
        item
          Caption = 'Arquivo'
          Width = 340
        end
        item
          Caption = 'Status'
          Width = 150
        end>
      GridLines = True
      HideSelection = False
      PopupMenu = pmScripts
      ReadOnly = True
      RowSelect = True
      TabOrder = 3
      ViewStyle = vsReport
      OnDblClick = lvScriptsDblClick
      OnMouseDown = lvScriptsMouseDown
    end
  end
  object pmScripts: TPopupMenu
    OnPopup = pmScriptsPopup
    Left = 900
    Top = 620
    object miExcluirScript: TMenuItem
      Caption = 'Excluir'
      OnClick = miExcluirScriptClick
    end
    object miExecutarScript: TMenuItem
      Caption = 'Executar somente este script'
      OnClick = miExecutarScriptClick
    end
    object miEstornarScript: TMenuItem
      Caption = 'Estornar'
      OnClick = miEstornarScriptClick
    end
    object miAbrirDiretorio: TMenuItem
      Caption = 'Abrir diret'#243'rio do script'
      OnClick = miAbrirDiretorioClick
    end
    object miDesmarcarTodos: TMenuItem
      Caption = 'Desmarcar todos'
      OnClick = miDesmarcarTodosClick
    end
  end
  object pmLog: TPopupMenu
    Left = 900
    Top = 676
    object miLimparLog: TMenuItem
      Caption = 'Limpar Log'
      OnClick = miLimparLogClick
    end
  end
end
