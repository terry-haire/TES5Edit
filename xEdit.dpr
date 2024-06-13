{******************************************************************************


  This Source Code Form is subject to the terms of the Mozilla Public License,
  v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain
  one at https://mozilla.org/MPL/2.0/.

*******************************************************************************}

{$I xeDefines.inc}

{$IFDEF EXCEPTION_LOGGING_ENABLED}
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG ON
// JCL_DEBUG_EXPERT_DELETEMAPFILE ON
{$ENDIF}

program xEdit;

{$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished]) PROPERTIES([vcPrivate, vcProtected, vcPublic, vcPublished]) FIELDS([vcPrivate, vcProtected, vcPublic, vcPublished])}

uses
  {$IFDEF EXCEPTION_LOGGING_ENABLED}
  nxExceptionHook,
  {$ENDIF }
  Winapi.Windows,
  Forms,
  Dialogs,
  SysUtils,
  VirtualTrees,
  VTEditors,
  VirtualEditTree,
  {$IFNDEF LiteVersion}
  cxVTEditors,
  {$ENDIF }
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Styles.Hooks,
  Vcl.Styles.Utils.Menus,
  Vcl.Styles.Utils.Forms,
  Vcl.Styles.Utils.StdCtrls,
  Vcl.Styles.Utils.ScreenTips,
  xeInit in 'xEdit\xeInit.pas',
  wbBetterStringList in 'Core\wbBetterStringList.pas',
  wbBSA in 'Core\wbBSA.pas',
  wbCommandLine in 'Core\wbCommandLine.pas',
  wbDataFormat in 'Core\wbDataFormat.pas',
  wbDataFormatMaterial in 'Core\wbDataFormatMaterial.pas',
  wbDataFormatMisc in 'Core\wbDataFormatMisc.pas',
  wbDataFormatNif in 'Core\wbDataFormatNif.pas',
  wbDataFormatNifTypes in 'Core\wbDataFormatNifTypes.pas',
  wbDefinitionsCommon in 'Core\wbDefinitionsCommon.pas',
  wbDefinitionsFNV in 'Core\wbDefinitionsFNV.pas',
  wbDefinitionsFNVSaves in 'Core\wbDefinitionsFNVSaves.pas',
  wbDefinitionsFO3 in 'Core\wbDefinitionsFO3.pas',
  wbDefinitionsFO3Saves in 'Core\wbDefinitionsFO3Saves.pas',
  wbDefinitionsFO4 in 'Core\wbDefinitionsFO4.pas',
  wbDefinitionsFO4Saves in 'Core\wbDefinitionsFO4Saves.pas',
  wbDefinitionsFO76 in 'Core\wbDefinitionsFO76.pas',
  wbDefinitionsTES3 in 'Core\wbDefinitionsTES3.pas',
  wbDefinitionsTES4 in 'Core\wbDefinitionsTES4.pas',
  wbDefinitionsTES4Saves in 'Core\wbDefinitionsTES4Saves.pas',
  wbDefinitionsTES5 in 'Core\wbDefinitionsTES5.pas',
  wbDefinitionsTES5Saves in 'Core\wbDefinitionsTES5Saves.pas',
  wbHalfFloat in 'Core\wbHalfFloat.pas',
  wbHardcoded in 'Core\wbHardcoded.pas' {wbHardcodedContainer: TDataModule},
  wbHelpers in 'Core\wbHelpers.pas',
  wbImplementation in 'Core\wbImplementation.pas',
  wbInterface in 'Core\wbInterface.pas',
  wbLocalization in 'Core\wbLocalization.pas',
  wbLOD in 'Core\wbLOD.pas',
  wbModGroups in 'Core\wbModGroups.pas',
  wbNifMath in 'Core\wbNifMath.pas',
  wbNifScanner in 'Core\wbNifScanner.pas',
  wbSaveInterface in 'Core\wbSaveInterface.pas',
  wbSort in 'Core\wbSort.pas',
  wbStreams in 'Core\wbStreams.pas',
  xeDeveloperMessageForm in 'xEdit\xeDeveloperMessageForm.pas' {frmDeveloperMessage},
  xeEditWarningForm in 'xEdit\xeEditWarningForm.pas' {frmEditWarning},
  xeFileSelectForm in 'xEdit\xeFileSelectForm.pas' {frmFileSelect},
  xeFilterOptionsForm in 'xEdit\xeFilterOptionsForm.pas' {frmFilterOptions},
  xeLegendForm in 'xEdit\xeLegendForm.pas' {frmLegend},
  xeLocalizationForm in 'xEdit\xeLocalizationForm.pas' {frmLocalization},
  xeLocalizePluginForm in 'xEdit\xeLocalizePluginForm.pas' {frmLocalizePlugin},
  xeLODGenForm in 'xEdit\xeLODGenForm.pas',
  xeLogAnalyzerForm in 'xEdit\xeLogAnalyzerForm.pas' {frmLogAnalyzer},
  xeMainForm in 'xEdit\xeMainForm.pas' {frmMain},
  xeModGroupEditForm in 'xEdit\xeModGroupEditForm.pas',
  xeModGroupSelectForm in 'xEdit\xeModGroupSelectForm.pas',
  xeModuleSelectForm in 'xEdit\xeModuleSelectForm.pas',
  xeOptionsForm in 'xEdit\xeOptionsForm.pas' {frmOptions},
  xeRichEditForm in 'xEdit\xeRichEditForm.pas' {frmRichEdit},
  xejviScriptAdapter in 'xEdit\JvI\xejviScriptAdapter.pas',
  xejviScriptAdapterDF in 'xEdit\JvI\xejviScriptAdapterDF.pas',
  xejviScriptAdapterMisc in 'xEdit\JvI\xejviScriptAdapterMisc.pas',
  xeScriptForm in 'xEdit\xeScriptForm.pas' {frmScript},
  xeTipForm in 'xEdit\xeTipForm.pas',
  xeViewElementsForm in 'xEdit\xeViewElementsForm.pas' {frmViewElements},
  xeWaitForm in 'xEdit\xeWaitForm.pas' {frmWait},
  xeWorldspaceCellDetailsForm in 'xEdit\xeWorldspaceCellDetailsForm.pas' {frmWorldspaceCellDetails},
  xeScriptHost in 'xEdit\xeScriptHost.pas',
  xejviScriptHost in 'xEdit\JvI\xejviScriptHost.pas',
  wbDefinitionsSF1 in 'Core\wbDefinitionsSF1.pas',
  wbDefinitionsSignatures in 'Core\wbDefinitionsSignatures.pas',
  __FNVConversionFunctions in 'xEdit\Convert\__FNVConversionFunctions.pas',
  __FNVMultiLoop3 in 'xEdit\Convert\__FNVMultiLoop3.pas',
  __FNVMultiLoopFunctions in 'xEdit\Convert\__FNVMultiLoopFunctions.pas',
  __ScriptAdapterFunctions in 'xEdit\Convert\__ScriptAdapterFunctions.pas',
  __FNVImportFuctionsTextv2 in 'xEdit\Convert\__FNVImportFuctionsTextv2.pas',
  __FNVImportCleanup in 'xEdit\Convert\__FNVImportCleanup.pas',
  converterFileManager in 'xEdit\Convert\converterFileManager.pas';

{$R *.res}
{$MAXSTACKSIZE 2097152}

const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;

{$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}

begin
  UseLatestCommonDialogs := True;
  SysUtils.FormatSettings.DecimalSeparator := '.';

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.UpdateFormatSettings := False;
  Application.HintHidePause := 10000;

  xeInitStyles;

  if not xeDoInit then
    Exit;

  if xeIconResource <> '' then begin
    var lIconHandle := LoadIcon(HInstance, PChar(xeIconResource));
    if lIconHandle <> 0 then
      Application.Icon.Handle := lIconHandle;
  end;

  {$IFDEF EXCEPTION_LOGGING_ENABLED}
  nxEHAppVersion := wbApplicationTitle;
  {$ENDIF}
  Application.Title := wbApplicationTitle;
  try
    Application.CreateForm(TfrmMain, frmMain);

    if xeHideForm then begin
      frmMain.Visible := False;
      Application.ShowMainForm := False;
      frmMain.tmrStartup.Enabled := True;
    end;

  Application.Run;
  finally
    DoRename;
  end;
end.
