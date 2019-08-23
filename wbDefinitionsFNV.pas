{*******************************************************************************

     The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

*******************************************************************************}

unit wbDefinitionsFNV;

{$I wbDefines.inc}

interface

uses
  wbInterface;

var
	wbAggroRadiusFlags: IwbFlagsDef;
	wbPKDTFlags: IwbFlagsDef;
	wbRecordFlagsFlags: IwbFlagsDef;
	wbServiceFlags: IwbFlagsDef;
	wbTemplateFlags: IwbFlagsDef;

	wbAgressionEnum: IwbEnumDef;
	wbAlignmentEnum: IwbEnumDef;
	wbArchtypeEnum: IwbEnumDef;
	wbAssistanceEnum: IwbEnumDef;
	wbAttackAnimationEnum: IwbEnumDef;
	wbAxisEnum: IwbEnumDef;
	wbBlendModeEnum: IwbEnumDef;
	wbBlendOpEnum: IwbEnumDef;
	wbBodyLocationEnum: IwbEnumDef;
	wbBodyPartIndexEnum: IwbEnumDef;
	wbConfidenceEnum: IwbEnumDef;
	wbCreatureTypeEnum: IwbEnumDef;
	wbCrimeTypeEnum: IwbEnumDef;
	wbCriticalStageEnum: IwbEnumDef;
	wbEquipTypeEnum: IwbEnumDef;
	wbFormTypeEnum: IwbEnumDef;
	wbFunctionsEnum: IwbEnumDef;
	wbHeadPartIndexEnum: IwbEnumDef;
	wbImpactMaterialTypeEnum: IwbEnumDef;
	wbMenuModeEnum: IwbEnumDef;
	wbMiscStatEnum: IwbEnumDef;
	wbModEffectEnum: IwbEnumDef;
	wbMoodEnum: IwbEnumDef;
	wbMusicEnum: IwbEnumDef;
	wbObjectTypeEnum: IwbEnumDef;
	wbPKDTType: IwbEnumDef;
	wbPlayerActionEnum: IwbEnumDef;
	wbQuadrantEnum: IwbEnumDef;
	wbReloadAnimEnum: IwbEnumDef;
	wbSexEnum: IwbEnumDef;
	wbSkillEnum: IwbEnumDef;
	wbSoundLevelEnum: IwbEnumDef;
	wbSpecializationEnum: IwbEnumDef;
	wbVatsValueFunctionEnum: IwbEnumDef;
	wbWeaponAnimTypeEnum: IwbEnumDef;
	wbZTestFuncEnum: IwbEnumDef;

function wbCreaLevelDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;

procedure DefineFNV(var gameProperties: TGameProperties);

implementation

uses
  Types,
  Classes,
  SysUtils,
  Math,
  Variants,
  wbHelpers;

const
  _00_IAD: TwbSignature = #$00'IAD';
  _40_IAD: TwbSignature = #$40'IAD';
  _01_IAD: TwbSignature = #$01'IAD';
  _41_IAD: TwbSignature = #$41'IAD';
  _02_IAD: TwbSignature = #$02'IAD';
  _42_IAD: TwbSignature = #$42'IAD';
  _03_IAD: TwbSignature = #$03'IAD';
  _43_IAD: TwbSignature = #$43'IAD';
  _04_IAD: TwbSignature = #$04'IAD';
  _44_IAD: TwbSignature = #$44'IAD';
  _05_IAD: TwbSignature = #$05'IAD';
  _45_IAD: TwbSignature = #$45'IAD';
  _06_IAD: TwbSignature = #$06'IAD';
  _46_IAD: TwbSignature = #$46'IAD';
  _07_IAD: TwbSignature = #$07'IAD';
  _47_IAD: TwbSignature = #$47'IAD';
  _08_IAD: TwbSignature = #$08'IAD';
  _48_IAD: TwbSignature = #$48'IAD';
  _09_IAD: TwbSignature = #$09'IAD';
  _49_IAD: TwbSignature = #$49'IAD';
  _0A_IAD: TwbSignature = #$0A'IAD';
  _4A_IAD: TwbSignature = #$4A'IAD';
  _0B_IAD: TwbSignature = #$0B'IAD';
  _4B_IAD: TwbSignature = #$4B'IAD';
  _0C_IAD: TwbSignature = #$0C'IAD';
  _4C_IAD: TwbSignature = #$4C'IAD';
  _0D_IAD: TwbSignature = #$0D'IAD';
  _4D_IAD: TwbSignature = #$4D'IAD';
  _0E_IAD: TwbSignature = #$0E'IAD';
  _4E_IAD: TwbSignature = #$4E'IAD';
  _0F_IAD: TwbSignature = #$0F'IAD';
  _4F_IAD: TwbSignature = #$4F'IAD';
  _10_IAD: TwbSignature = #$10'IAD';
  _50_IAD: TwbSignature = #$50'IAD';
  _11_IAD: TwbSignature = #$11'IAD';
  _51_IAD: TwbSignature = #$51'IAD';
  _12_IAD: TwbSignature = #$12'IAD';
  _52_IAD: TwbSignature = #$52'IAD';
  _13_IAD: TwbSignature = #$13'IAD';
  _53_IAD: TwbSignature = #$53'IAD';
  _14_IAD: TwbSignature = #$14'IAD';
  _54_IAD: TwbSignature = #$54'IAD';

  _0_IAD : TwbSignature = #0'IAD';
  _1_IAD : TwbSignature = #1'IAD';
  _2_IAD : TwbSignature = #2'IAD';
  _3_IAD : TwbSignature = #3'IAD';
  _4_IAD : TwbSignature = #4'IAD';
  _5_IAD : TwbSignature = #5'IAD';
  ACBS : TwbSignature = 'ACBS';
  ACHR : TwbSignature = 'ACHR';
  ACRE : TwbSignature = 'ACRE';
  ACTI : TwbSignature = 'ACTI';
  ADDN : TwbSignature = 'ADDN';
  AIDT : TwbSignature = 'AIDT';
  ALCH : TwbSignature = 'ALCH';
  AMMO : TwbSignature = 'AMMO';
  ANAM : TwbSignature = 'ANAM';
  ANIO : TwbSignature = 'ANIO';
  ARMA : TwbSignature = 'ARMA';
  ARMO : TwbSignature = 'ARMO';
  ASPC : TwbSignature = 'ASPC';
  ATTR : TwbSignature = 'ATTR';
  ATXT : TwbSignature = 'ATXT';
  AVIF : TwbSignature = 'AVIF';
  BIPL : TwbSignature = 'BIPL';
  BMCT : TwbSignature = 'BMCT';
  BMDT : TwbSignature = 'BMDT';
  BNAM : TwbSignature = 'BNAM';
  BOOK : TwbSignature = 'BOOK';
  BPND : TwbSignature = 'BPND';
  BPNI : TwbSignature = 'BPNI';
  BPNN : TwbSignature = 'BPNN';
  BPNT : TwbSignature = 'BPNT';
  BPTD : TwbSignature = 'BPTD';
  BPTN : TwbSignature = 'BPTN';
  BTXT : TwbSignature = 'BTXT';
  CAMS : TwbSignature = 'CAMS';
  CELL : TwbSignature = 'CELL';
  CLAS : TwbSignature = 'CLAS';
  CLMT : TwbSignature = 'CLMT';
  CNAM : TwbSignature = 'CNAM';
  MMRK : TwbSignature = 'MMRK';
  CNTO : TwbSignature = 'CNTO';
  COBJ : TwbSignature = 'COBJ';
  COED : TwbSignature = 'COED';
  CONT : TwbSignature = 'CONT';
  CPTH : TwbSignature = 'CPTH';
  CRDT : TwbSignature = 'CRDT';
  CREA : TwbSignature = 'CREA';
  CSAD : TwbSignature = 'CSAD';
  CSCR : TwbSignature = 'CSCR';
  CSDC : TwbSignature = 'CSDC';
  CSDI : TwbSignature = 'CSDI';
  CSDT : TwbSignature = 'CSDT';
  CSSD : TwbSignature = 'CSSD';
  CSTD : TwbSignature = 'CSTD';
  CSTY : TwbSignature = 'CSTY';
  CTDA : TwbSignature = 'CTDA';
  DATA : TwbSignature = 'DATA';
  DAT2 : TwbSignature = 'DAT2';
  DEBR : TwbSignature = 'DEBR';
  DELE : TwbSignature = 'DELE';
  DESC : TwbSignature = 'DESC';
  DEST : TwbSignature = 'DEST';
  DIAL : TwbSignature = 'DIAL';
  DMDL : TwbSignature = 'DMDL';
  DMDT : TwbSignature = 'DMDT';
  DNAM : TwbSignature = 'DNAM';
  DOBJ : TwbSignature = 'DOBJ';
  DODT : TwbSignature = 'DODT';
  DOOR : TwbSignature = 'DOOR';
  DSTD : TwbSignature = 'DSTD';
  DSTF : TwbSignature = 'DSTF';
  EAMT : TwbSignature = 'EAMT';
  ECZN : TwbSignature = 'ECZN';
  EDID : TwbSignature = 'EDID';
  EFID : TwbSignature = 'EFID';
  EFIT : TwbSignature = 'EFIT';
  EFSD : TwbSignature = 'EFSD';
  EFSH : TwbSignature = 'EFSH';
  EITM : TwbSignature = 'EITM';
  ENAM : TwbSignature = 'ENAM';
  ENCH : TwbSignature = 'ENCH';
  ENIT : TwbSignature = 'ENIT';
  EPF2 : TwbSignature = 'EPF2';
  EPF3 : TwbSignature = 'EPF3';
  EPFD : TwbSignature = 'EPFD';
  EPFT : TwbSignature = 'EPFT';
  ESCE : TwbSignature = 'ESCE';
  ETYP : TwbSignature = 'ETYP';
  EXPL : TwbSignature = 'EXPL';
  EYES : TwbSignature = 'EYES';
  FACT : TwbSignature = 'FACT';
  FGGA : TwbSignature = 'FGGA';
  FGGS : TwbSignature = 'FGGS';
  FGTS : TwbSignature = 'FGTS';
  FLST : TwbSignature = 'FLST';
  FLTV : TwbSignature = 'FLTV';
  FNAM : TwbSignature = 'FNAM';
  FULL : TwbSignature = 'FULL';
  FURN : TwbSignature = 'FURN';
  GLOB : TwbSignature = 'GLOB';
  RDID : TwbSignature = 'RDID';
  RDSI : TwbSignature = 'RDSI';
  RDSB : TwbSignature = 'RDSB';
  GMST : TwbSignature = 'GMST';
  GNAM : TwbSignature = 'GNAM';
  GRAS : TwbSignature = 'GRAS';
  HAIR : TwbSignature = 'HAIR';
  HCLR : TwbSignature = 'HCLR';
  HDPT : TwbSignature = 'HDPT';
  HEDR : TwbSignature = 'HEDR';
  HNAM : TwbSignature = 'HNAM';
  ICO2 : TwbSignature = 'ICO2';
  ICON : TwbSignature = 'ICON';
  IDLA : TwbSignature = 'IDLA';
  IDLB : TwbSignature = 'IDLB';
  IDLC : TwbSignature = 'IDLC';
  IDLE : TwbSignature = 'IDLE';
  IDLF : TwbSignature = 'IDLF';
  IDLM : TwbSignature = 'IDLM';
  IDLT : TwbSignature = 'IDLT';
  IMAD : TwbSignature = 'IMAD';
  IMGS : TwbSignature = 'IMGS';
  INAM : TwbSignature = 'INAM';
  INDX : TwbSignature = 'INDX';
  INFO : TwbSignature = 'INFO';
  INGR : TwbSignature = 'INGR';
  IPCT : TwbSignature = 'IPCT';
  IPDS : TwbSignature = 'IPDS';
  ITXT : TwbSignature = 'ITXT';
  JNAM : TwbSignature = 'JNAM';
  KEYM : TwbSignature = 'KEYM';
  KFFZ : TwbSignature = 'KFFZ';
  KNAM : TwbSignature = 'KNAM';
  LAND : TwbSignature = 'LAND';
  LGTM : TwbSignature = 'LGTM';
  LIGH : TwbSignature = 'LIGH';
  LNAM : TwbSignature = 'LNAM';
  LSCR : TwbSignature = 'LSCR';
  LTEX : TwbSignature = 'LTEX';
  LTMP : TwbSignature = 'LTMP';
  LVLC : TwbSignature = 'LVLC';
  LVLD : TwbSignature = 'LVLD';
  LVLF : TwbSignature = 'LVLF';
  LVLG : TwbSignature = 'LVLG';
  LVLI : TwbSignature = 'LVLI';
  LVLN : TwbSignature = 'LVLN';
  LVLO : TwbSignature = 'LVLO';
  MAST : TwbSignature = 'MAST';
  MESG : TwbSignature = 'MESG';
  MGEF : TwbSignature = 'MGEF';
  MICN : TwbSignature = 'MICN';
  MICO : TwbSignature = 'MICO';
  MIC2 : TwbSignature = 'MIC2';
  MISC : TwbSignature = 'MISC';
  MNAM : TwbSignature = 'MNAM';
  MO2B : TwbSignature = 'MO2B';
  MO2S : TwbSignature = 'MO2S';
  MO2T : TwbSignature = 'MO2T';
  MO3B : TwbSignature = 'MO3B';
  MO3S : TwbSignature = 'MO3S';
  MO3T : TwbSignature = 'MO3T';
  MO4B : TwbSignature = 'MO4B';
  MO4S : TwbSignature = 'MO4S';
  MO4T : TwbSignature = 'MO4T';
  MOD2 : TwbSignature = 'MOD2';
  VANM : TwbSignature = 'VANM';
  MOD3 : TwbSignature = 'MOD3';
  MOD4 : TwbSignature = 'MOD4';
  MODB : TwbSignature = 'MODB';
  MODD : TwbSignature = 'MODD';
  MODL : TwbSignature = 'MODL';
  MODS : TwbSignature = 'MODS';
  MODT : TwbSignature = 'MODT';
  MOSD : TwbSignature = 'MOSD';
  MSTT : TwbSignature = 'MSTT';
  MUSC : TwbSignature = 'MUSC';
  IMPS : TwbSignature = 'IMPS';
  IMPF : TwbSignature = 'IMPF';
  NAM0 : TwbSignature = 'NAM0';
  NAM1 : TwbSignature = 'NAM1';
  NAM2 : TwbSignature = 'NAM2';
  NAM3 : TwbSignature = 'NAM3';
  NAM4 : TwbSignature = 'NAM4';
  NAM5 : TwbSignature = 'NAM5';
  NAM6 : TwbSignature = 'NAM6';
  NAM7 : TwbSignature = 'NAM7';
  NAM8 : TwbSignature = 'NAM8';
  NAM9 : TwbSignature = 'NAM9';
  NAME : TwbSignature = 'NAME';
  NAVI : TwbSignature = 'NAVI';
  NAVM : TwbSignature = 'NAVM';
  NEXT : TwbSignature = 'NEXT';
  NIFT : TwbSignature = 'NIFT';
  NIFZ : TwbSignature = 'NIFZ';
  NNAM : TwbSignature = 'NNAM';
  XSRF : TwbSignature = 'XSRF';
  XSRD : TwbSignature = 'XSRD';
  MWD1 : TwbSignature = 'MWD1';
  MWD2 : TwbSignature = 'MWD2';
  MWD3 : TwbSignature = 'MWD3';
  MWD4 : TwbSignature = 'MWD4';
  MWD5 : TwbSignature = 'MWD5';
  MWD6 : TwbSignature = 'MWD6';
  MWD7 : TwbSignature = 'MWD7';
  WNM1 : TwbSignature = 'WNM1';
  WNM2 : TwbSignature = 'WNM2';
  WNM3 : TwbSignature = 'WNM3';
  WNM4 : TwbSignature = 'WNM4';
  WNM5 : TwbSignature = 'WNM5';
  WNM6 : TwbSignature = 'WNM6';
  WNM7 : TwbSignature = 'WNM7';
  WMI1 : TwbSignature = 'WMI1';
  WMI2 : TwbSignature = 'WMI2';
  WMI3 : TwbSignature = 'WMI3';
  WMS1 : TwbSignature = 'WMS1';
  WMS2 : TwbSignature = 'WMS2';
  NOTE : TwbSignature = 'NOTE';
  NPC_ : TwbSignature = 'NPC_';
  NULL : TwbSignature = 'NULL';
  NVCA : TwbSignature = 'NVCA';
  NVCI : TwbSignature = 'NVCI';
  NVDP : TwbSignature = 'NVDP';
  NVER : TwbSignature = 'NVER';
  NVEX : TwbSignature = 'NVEX';
  NVGD : TwbSignature = 'NVGD';
  NVMI : TwbSignature = 'NVMI';
  NVTR : TwbSignature = 'NVTR';
  NVVX : TwbSignature = 'NVVX';
  OBND : TwbSignature = 'OBND';
  OFST : TwbSignature = 'OFST';
  ONAM : TwbSignature = 'ONAM';
  PACK : TwbSignature = 'PACK';
  PBEA : TwbSignature = 'PBEA';
  PERK : TwbSignature = 'PERK';
  PFIG : TwbSignature = 'PFIG';
  PFPC : TwbSignature = 'PFPC';
  PGAG : TwbSignature = 'PGAG';
  PGRE : TwbSignature = 'PGRE';
  PMIS : TwbSignature = 'PMIS';
  TRGT : TwbSignature = 'TRGT';
  PGRI : TwbSignature = 'PGRI';
  PGRL : TwbSignature = 'PGRL';
  PGRP : TwbSignature = 'PGRP';
  PGRR : TwbSignature = 'PGRR';
  PKAM : TwbSignature = 'PKAM';
  PKDD : TwbSignature = 'PKDD';
  PKDT : TwbSignature = 'PKDT';
  PKE2 : TwbSignature = 'PKE2';
  PKED : TwbSignature = 'PKED';
  PKFD : TwbSignature = 'PKFD';
  PKID : TwbSignature = 'PKID';
  PKPT : TwbSignature = 'PKPT';
  PKW3 : TwbSignature = 'PKW3';
  PLD2 : TwbSignature = 'PLD2';
  PLDT : TwbSignature = 'PLDT';
  PLYR : TwbSignature = 'PLYR';
  PNAM : TwbSignature = 'PNAM';
  TDUM : TwbSignature = 'TDUM';
  POBA : TwbSignature = 'POBA';
  POCA : TwbSignature = 'POCA';
  POEA : TwbSignature = 'POEA';
  PRKC : TwbSignature = 'PRKC';
  PRKE : TwbSignature = 'PRKE';
  PRKF : TwbSignature = 'PRKF';
  PROJ : TwbSignature = 'PROJ';
  PSDT : TwbSignature = 'PSDT';
  PTD2 : TwbSignature = 'PTD2';
  PTDT : TwbSignature = 'PTDT';
  PUID : TwbSignature = 'PUID';
  PWAT : TwbSignature = 'PWAT';
  QNAM : TwbSignature = 'QNAM';
  RCIL : TwbSignature = 'RCIL';
  RCQY : TwbSignature = 'RCQY';
  RCOD : TwbSignature = 'RCOD';
  QOBJ : TwbSignature = 'QOBJ';
  QSDT : TwbSignature = 'QSDT';
  QSTA : TwbSignature = 'QSTA';
  QSTI : TwbSignature = 'QSTI';
  TPIC : TwbSignature = 'TPIC';
  QSTR : TwbSignature = 'QSTR';
  INFC : TwbSignature = 'INFC';
  INFX : TwbSignature = 'INFX';
  QUST : TwbSignature = 'QUST';
  RACE : TwbSignature = 'RACE';
  RADS : TwbSignature = 'RADS';
  RAFB : TwbSignature = 'RAFB';
  RAFD : TwbSignature = 'RAFD';
  RAGA : TwbSignature = 'RAGA';
  RAPS : TwbSignature = 'RAPS';
  RCLR : TwbSignature = 'RCLR';
  RDAT : TwbSignature = 'RDAT';
  RDMD : TwbSignature = 'RDMD';
  RDMO : TwbSignature = 'RDMO';
  RDMP : TwbSignature = 'RDMP';
  RDGS : TwbSignature = 'RDGS';
  RDOT : TwbSignature = 'RDOT';
  RDSD : TwbSignature = 'RDSD';
  RDWT : TwbSignature = 'RDWT';
  REFR : TwbSignature = 'REFR';
  REGN : TwbSignature = 'REGN';
  REPL : TwbSignature = 'REPL';
  RGDL : TwbSignature = 'RGDL';
  RNAM : TwbSignature = 'RNAM';
  RPLD : TwbSignature = 'RPLD';
  RPLI : TwbSignature = 'RPLI';
  SCDA : TwbSignature = 'SCDA';
  SCHR : TwbSignature = 'SCHR';
  SCOL : TwbSignature = 'SCOL';
  SCPT : TwbSignature = 'SCPT';
  SCRI : TwbSignature = 'SCRI';
  SCRN : TwbSignature = 'SCRN';
  SCRO : TwbSignature = 'SCRO';
  SCRV : TwbSignature = 'SCRV';
  SCTX : TwbSignature = 'SCTX';
  SCVR : TwbSignature = 'SCVR';
  SLCP : TwbSignature = 'SLCP';
  SLSD : TwbSignature = 'SLSD';
  SNAM : TwbSignature = 'SNAM';
  SNDD : TwbSignature = 'SNDD';
  SNDX : TwbSignature = 'SNDX';
  SOUL : TwbSignature = 'SOUL';
  SOUN : TwbSignature = 'SOUN';
  SPEL : TwbSignature = 'SPEL';
  SPIT : TwbSignature = 'SPIT';
  SPLO : TwbSignature = 'SPLO';
  STAT : TwbSignature = 'STAT';
  BRUS : TwbSignature = 'BRUS';
  TACT : TwbSignature = 'TACT';
  TCLF : TwbSignature = 'TCLF';
  TCFU : TwbSignature = 'TCFU';
  TCLT : TwbSignature = 'TCLT';
  TERM : TwbSignature = 'TERM';
  TES4 : TwbSignature = 'TES4';
  TNAM : TwbSignature = 'TNAM';
  TPLT : TwbSignature = 'TPLT';
  TRDT : TwbSignature = 'TRDT';
  TREE : TwbSignature = 'TREE';
  TX00 : TwbSignature = 'TX00';
  TX01 : TwbSignature = 'TX01';
  INTV : TwbSignature = 'INTV';
  TX02 : TwbSignature = 'TX02';
  TX03 : TwbSignature = 'TX03';
  TX04 : TwbSignature = 'TX04';
  TX05 : TwbSignature = 'TX05';
  TXST : TwbSignature = 'TXST';
  UNAM : TwbSignature = 'UNAM';
  VATS : TwbSignature = 'VATS';
  VCLR : TwbSignature = 'VCLR';
  VHGT : TwbSignature = 'VHGT';
  VNAM : TwbSignature = 'VNAM';
  VNML : TwbSignature = 'VNML';
  VTCK : TwbSignature = 'VTCK';
  VTEX : TwbSignature = 'VTEX';
  VTXT : TwbSignature = 'VTXT';
  VTYP : TwbSignature = 'VTYP';
  WATR : TwbSignature = 'WATR';
  WEAP : TwbSignature = 'WEAP';
  WLST : TwbSignature = 'WLST';
  WNAM : TwbSignature = 'WNAM';
  XATO : TwbSignature = 'XATO';
  WRLD : TwbSignature = 'WRLD';
  WTHR : TwbSignature = 'WTHR';
  XACT : TwbSignature = 'XACT';
  XAMC : TwbSignature = 'XAMC';
  XAMT : TwbSignature = 'XAMT';
  XAPD : TwbSignature = 'XAPD';
  XAPR : TwbSignature = 'XAPR';
  XCAS : TwbSignature = 'XCAS';
  XCCM : TwbSignature = 'XCCM';
  XCET : TwbSignature = 'XCET';
  XCHG : TwbSignature = 'XCHG';
  XCIM : TwbSignature = 'XCIM';
  XCLC : TwbSignature = 'XCLC';
  XCLL : TwbSignature = 'XCLL';
  XCLP : TwbSignature = 'XCLP';
  XCLR : TwbSignature = 'XCLR';
  XCLW : TwbSignature = 'XCLW';
  XCMO : TwbSignature = 'XCMO';
  XCMT : TwbSignature = 'XCMT';
  XCNT : TwbSignature = 'XCNT';
  XCWT : TwbSignature = 'XCWT';
  XEMI : TwbSignature = 'XEMI';
  XESP : TwbSignature = 'XESP';
  XEZN : TwbSignature = 'XEZN';
  XGLB : TwbSignature = 'XGLB';
  XHLP : TwbSignature = 'XHLP';
  XDCR : TwbSignature = 'XDCR';
  XHLT : TwbSignature = 'XHLT';
  XIBS : TwbSignature = 'XIBS';
  XLCM : TwbSignature = 'XLCM';
  XLKR : TwbSignature = 'XLKR';
  XLOC : TwbSignature = 'XLOC';
  XLOD : TwbSignature = 'XLOD';
  XLRM : TwbSignature = 'XLRM';
  XLTW : TwbSignature = 'XLTW';
  XMBO : TwbSignature = 'XMBO';
  XMBP : TwbSignature = 'XMBP';
  XMBR : TwbSignature = 'XMBR';
  XMRC : TwbSignature = 'XMRC';
  XMRK : TwbSignature = 'XMRK';
  XNAM : TwbSignature = 'XNAM';
  XNDP : TwbSignature = 'XNDP';
  XOCP : TwbSignature = 'XOCP';
  XORD : TwbSignature = 'XORD';
  XOWN : TwbSignature = 'XOWN';
  XPOD : TwbSignature = 'XPOD';
  XPTL : TwbSignature = 'XPTL';
  XPPA : TwbSignature = 'XPPA';
  XPRD : TwbSignature = 'XPRD';
  XPRM : TwbSignature = 'XPRM';
  XPWR : TwbSignature = 'XPWR';
  XRAD : TwbSignature = 'XRAD';
  XRDO : TwbSignature = 'XRDO';
  XRDS : TwbSignature = 'XRDS';
  XRGB : TwbSignature = 'XRGB';
  XRGD : TwbSignature = 'XRGD';
  XRMR : TwbSignature = 'XRMR';
  XRNK : TwbSignature = 'XRNK';
  XRTM : TwbSignature = 'XRTM';
  XSCL : TwbSignature = 'XSCL';
  XSED : TwbSignature = 'XSED';
  XTEL : TwbSignature = 'XTEL';
  XTRG : TwbSignature = 'XTRG';
  XTRI : TwbSignature = 'XTRI';
  XXXX : TwbSignature = 'XXXX';
  YNAM : TwbSignature = 'YNAM';
  ZNAM : TwbSignature = 'ZNAM';
  IMOD : TwbSignature = 'IMOD';
  REPU : TwbSignature = 'REPU';
  RCPE : TwbSignature = 'RCPE';
  RCCT : TwbSignature = 'RCCT';
  CHIP : TwbSignature = 'CHIP';
  CSNO : TwbSignature = 'CSNO';
  LSCT : TwbSignature = 'LSCT';
  MSET : TwbSignature = 'MSET';
  ALOC : TwbSignature = 'ALOC';
  CHAL : TwbSignature = 'CHAL';
  AMEF : TwbSignature = 'AMEF';
  CCRD : TwbSignature = 'CCRD';
  CARD : TwbSignature = 'CARD';
  CMNY : TwbSignature = 'CMNY';
  CDCK : TwbSignature = 'CDCK';
  DEHY : TwbSignature = 'DEHY';
  HUNG : TwbSignature = 'HUNG';
  SLPD : TwbSignature = 'SLPD';

var
  wbPKDTSpecificFlagsUnused : Boolean;
  wbEDID: IwbSubRecordDef;
  wbEDIDReq: IwbSubRecordDef;
  wbEDIDReqKC: IwbSubRecordDef;
  wbBMDT: IwbSubRecordDef;
  wbYNAM: IwbSubRecordDef;
  wbZNAM: IwbSubRecordDef;
  wbCOED: IwbSubRecordDef;
  wbXLCM: IwbSubRecordDef;
  wbEITM: IwbSubRecordDef;
  wbREPL: IwbSubRecordDef;
  wbBIPL: IwbSubRecordDef;
  wbOBND: IwbSubRecordDef;
  wbOBNDReq: IwbSubRecordDef;
  wbDEST: IwbSubRecordStructDef;
  wbDESTActor: IwbSubRecordStructDef;
  wbDODT: IwbSubRecordDef;
  wbXOWN: IwbSubRecordDef;
  wbXGLB: IwbSubRecordDef;
  wbXRGD: IwbSubRecordDef;
  wbXRGB: IwbSubRecordDef;
  wbSLSD: IwbSubRecordDef;
  wbSPLO: IwbSubRecordDef;
  wbSPLOs: IwbSubRecordArrayDef;
  wbCNTO: IwbSubRecordStructDef;
  wbCNTOs: IwbSubRecordArrayDef;
  wbAIDT: IwbSubRecordDef;
  wbCSDT: IwbSubRecordStructDef;
  wbCSDTs: IwbSubRecordArrayDef;
  wbFULL: IwbSubRecordDef;
  wbFULLActor: IwbSubRecordDef;
  wbFULLReq: IwbSubRecordDef;
  wbXNAM: IwbSubRecordDef;
  wbXNAMs: IwbSubRecordArrayDef;
  wbDESC: IwbSubRecordDef;
  wbDESCReq: IwbSubRecordDef;
  wbXSCL: IwbSubRecordDef;
  wbDATAPosRot : IwbSubRecordDef;
  wbPosRot : IwbStructDef;
  wbMODD: IwbSubRecordDef;
  wbMOSD: IwbSubRecordDef;
  wbMODL: IwbSubRecordStructDef;
  wbMODT: IwbSubRecordDef;
  wbMODS: IwbSubRecordDef;
  wbMO2S: IwbSubRecordDef;
  wbMO3S: IwbSubRecordDef;
  wbMO4S: IwbSubRecordDef;
  wbMODLActor: IwbSubRecordStructDef;
  wbMODLReq: IwbSubRecordStructDef;
  wbCTDA: IwbRecordMemberDef;
  wbSCHRReq: IwbSubRecordDef;
  wbCTDAs: IwbSubRecordArrayDef;
  wbCTDAsReq: IwbSubRecordArrayDef;
  wbSCROs: IwbRecordMemberDef;
//  wbPGRP: IwbSubRecordDef;
  wbEmbeddedScript: IwbSubRecordStructDef;
  wbEmbeddedScriptPerk: IwbSubRecordStructDef;
  wbEmbeddedScriptReq: IwbSubRecordStructDef;
  wbSCRI: IwbSubRecordDef;
  wbSCRIActor: IwbSubRecordDef;
  wbFaceGen: IwbSubRecordStructDef;
  wbFaceGenNPC: IwbSubRecordStructDef;
  wbENAM: IwbSubRecordDef;
//  wbFGGS: IwbSubRecordDef;
  wbXLOD: IwbSubRecordDef;
  wbXESP: IwbSubRecordDef;
  wbICON: IwbSubRecordStructDef;
  wbICONReq: IwbSubRecordStructDef;
  wbActorValue: IwbIntegerDef;
  wbETYP: IwbSubRecordDef;
  wbETYPReq: IwbSubRecordDef;
  wbEFID: IwbSubRecordDef;
  wbEFIT: IwbSubRecordDef;
  wbEffects: IwbSubRecordArrayDef;
  wbEffectsReq: IwbSubRecordArrayDef;
  wbBPNDStruct: IwbSubRecordDef;
  wbTimeInterpolator: IwbStructDef;
  wbColorInterpolator: IwbStructDef;

function wbNVTREdgeToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  Index      : Integer;
  Flags      : Cardinal;
  IsExternal : Boolean;
  Container  : IwbContainerElementRef;
begin
  Result := '';
  IsExternal := False;
  if Supports(aElement, IwbContainerElementRef, Container) then begin
    Index := StrToIntDef(Copy(Container.Name, 11, 1), -1);
    if (Index >= 0) and (Index <= 2) then begin
      Flags := Container.ElementNativeValues['..\..\Flags'];
      IsExternal := Flags and (Cardinal(1) shl Index) <> 0;
    end;
  end;

  if IsExternal then begin
    case aType of
      ctToStr: begin
        Result := IntToStr(aInt);
        if Container.ElementExists['..\..\..\..\NVEX\Connection #' + IntToStr(aInt)] then
          Result := Result + ' (Triangle #' +
            Container.ElementValues['..\..\..\..\NVEX\Connection #' + IntToStr(aInt) + '\Triangle'] + ' in ' +
            Container.ElementValues['..\..\..\..\NVEX\Connection #' + IntToStr(aInt) + '\Navigation Mesh'] + ')'
        else
          Result := Result + ' <Error: NVEX\Connection #' + IntToStr(aInt) + ' is missing>';
      end;
      ctToSortKey:
        if Container.ElementExists['..\..\..\..\NVEX\Connection #' + IntToStr(aInt)] then
          Result :=
            Container.ElementSortKeys['..\..\..\..\NVEX\Connection #' + IntToStr(aInt) + '\Navigation Mesh', True] + '|' +
            Container.ElementSortKeys['..\..\..\..\NVEX\Connection #' + IntToStr(aInt) + '\Triangle', True];
      ctCheck:
        if Container.ElementExists['..\..\..\..\NVEX\Connection #' + IntToStr(aInt)] then
          Result := ''
        else
          Result := 'NVEX\Connection #' + IntToStr(aInt) + ' is missing';
    end
  end else
    case aType of
      ctToStr: Result := IntToStr(aInt);
    end;
end;

function wbNVTREdgeToInt(const aString: string; const aElement: IwbElement): Int64;
begin
  Result := StrToInt64(aString);
end;


function wbEPFDActorValueToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  AsCardinal : Cardinal;
  AsFloat    : Single;
begin
  AsCardinal := aInt;
  AsFloat := PSingle(@AsCardinal)^;
  aInt := Round(AsFloat);
  case aType of
    ctToStr: Result := wbActorValueEnum.ToString(aInt, aElement);
    ctToSortKey: Result := wbActorValueEnum.ToSortKey(aInt, aElement);
    ctCheck: Result := wbActorValueEnum.Check(aInt, aElement);
    ctToEditValue: Result := wbActorValueEnum.ToEditValue(aInt, aElement);
    ctEditType: Result := 'ComboBox';
    ctEditInfo: Result := wbActorValueEnum.EditInfo[aInt, aElement].ToCommaText;
  end;
end;

function wbEPFDActorValueToInt(const aString: string; const aElement: IwbElement): Int64;
var
  AsCardinal : Cardinal;
  AsFloat    : Single;
begin
  AsFloat := wbActorValueEnum.FromEditValue(aString, aElement);
  PSingle(@AsCardinal)^ := AsFloat;
  Result := AsCardinal;
end;

function wbCTDAParam2VariableNameToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  Container  : IwbContainerElementRef;
  //Container2 : IwbContainerElementRef;
  Param1     : IwbElement;
  MainRecord : IwbMainRecord;
  BaseRecord : IwbMainRecord;
  ScriptRef  : IwbElement;
  Script     : IwbMainRecord;
  Variables  : TStringList;
  LocalVars  : IwbContainerElementRef;
  LocalVar   : IwbContainerElementRef;
  i, j       : Integer;
  s          : string;
begin
  case aType of
    ctToStr: Result := IntToStr(aInt) + ' <Warning: Could not resolve Parameter 1>';
    ctToEditValue: Result := IntToStr(aInt);
    ctToSortKey: begin
      Result := IntToHex64(aInt, 8);
      Exit;
    end;
    ctCheck: Result := '<Warning: Could not resolve Parameter 1>';
    ctEditType: Result := '';
    ctEditInfo: Result := '';
  end;

  if not Assigned(aElement) then Exit;
  Container := GetContainerRefFromUnionOrValue(aElement);
  if not Assigned(Container) then Exit;

  Param1 := Container.ElementByName['Parameter #1'];

  if not Assigned(Param1) then
    Exit;

  MainRecord := nil;
  if not Supports(Param1.LinksTo, IwbMainRecord, MainRecord) then
    Exit;
{    if Param1.NativeValue = 0 then
      if Supports(Container.Container, IwbContainerElementRef, Container) then
        for i := 0 to Pred(Container.ElementCount) do
          if Supports(Container.Elements[i], IwbContainerElementRef, Container2) then
            if SameText(Container2.ElementValues['Function'], 'GetIsID') then begin
              Param1 := Container2.ElementByName['Parameter #1'];
              if Supports(Param1.LinksTo, IwbMainRecord, MainRecord) then
                Break;
            end;}

  if not Assigned(MainRecord) then
    Exit;

  BaseRecord := MainRecord.BaseRecord;
  if Assigned(BaseRecord) then
    MainRecord := BaseRecord;

  MainRecord := MainRecord.WinningOverride;

  ScriptRef := MainRecord.RecordBySignature['SCRI'];

  if not Assigned(ScriptRef) then begin
    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: "'+MainRecord.ShortName+'" does not contain a SCRI subrecord>';
      ctCheck: Result := '<Warning: "'+MainRecord.ShortName+'" does not contain a SCRI subrecord>';
    end;
    Exit;
  end;

  if not Supports(ScriptRef.LinksTo, IwbMainRecord, Script) then begin
    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: "'+MainRecord.ShortName+'" does not have a valid script>';
      ctCheck: Result := '<Warning: "'+MainRecord.ShortName+'" does not have a valid script>';
    end;
    Exit;
  end;

  Script := Script.HighestOverrideOrSelf[aElement._File.LoadOrder];

  case aType of
    ctEditType: begin
      Result := 'ComboBox';
      Exit;
    end;
    ctEditInfo:
      Variables := TStringList.Create;
  else
    Variables := nil;
  end;
  try
    if Supports(Script.ElementByName['Local Variables'], IwbContainerElementRef, LocalVars) then begin
      for i := 0 to Pred(LocalVars.ElementCount) do
        if Supports(LocalVars.Elements[i], IwbContainerElementRef, LocalVar) then begin
          j := LocalVar.ElementNativeValues['SLSD\Index'];
          s := LocalVar.ElementNativeValues['SCVR'];
          if Assigned(Variables) then
            Variables.AddObject(s, TObject(j))
          else if j = aInt then begin
            case aType of
              ctToStr, ctToEditValue: Result := s;
              ctCheck: Result := '';
            end;
            Exit;
          end;
        end;
    end;

    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: Variable Index not found in "' + Script.Name + '">';
      ctCheck: Result := '<Warning: Variable Index not found in "' + Script.Name + '">';
      ctEditInfo: begin
        Variables.Sort;
        Result := Variables.CommaText;
      end;
    end;
  finally
    FreeAndNil(Variables);
  end;
end;

function wbCTDAParam2VariableNameToInt(const aString: string; const aElement: IwbElement): Int64;
var
  Container  : IwbContainerElementRef;
  Param1     : IwbElement;
  MainRecord : IwbMainRecord;
  BaseRecord : IwbMainRecord;
  ScriptRef  : IwbElement;
  Script     : IwbMainRecord;
  LocalVars  : IwbContainerElementRef;
  LocalVar   : IwbContainerElementRef;
  i, j       : Integer;
  s          : string;
begin
  Result := StrToInt64Def(aString, Low(Cardinal));
  if Result <> Low(Cardinal) then
    Exit;

  if not Assigned(aElement) then
    raise Exception.Create('aElement not specified');

  Container := GetContainerRefFromUnionOrValue(aElement);

  if not Assigned(Container) then
    raise Exception.Create('Container not assigned');

  Param1 := Container.ElementByName['Parameter #1'];

  if not Assigned(Param1) then
    raise Exception.Create('Could not find "Parameter #1"');

  if not Supports(Param1.LinksTo, IwbMainRecord, MainRecord) then
    raise Exception.Create('"Parameter #1" does not reference a valid main record');

  BaseRecord := MainRecord.BaseRecord;
  if Assigned(BaseRecord) then
    MainRecord := BaseRecord;

  MainRecord := MainRecord.WinningOverride;

  ScriptRef := MainRecord.RecordBySignature['SCRI'];

  if not Assigned(ScriptRef) then
    raise Exception.Create('"'+MainRecord.ShortName+'" does not contain a SCRI subrecord');

  if not Supports(ScriptRef.LinksTo, IwbMainRecord, Script) then
    raise Exception.Create('"'+MainRecord.ShortName+'" does not have a valid script');

  Script := Script.HighestOverrideOrSelf[aElement._File.LoadOrder];

  if Supports(Script.ElementByName['Local Variables'], IwbContainerElementRef, LocalVars) then begin
    for i := 0 to Pred(LocalVars.ElementCount) do
      if Supports(LocalVars.Elements[i], IwbContainerElementRef, LocalVar) then begin
        j := LocalVar.ElementNativeValues['SLSD\Index'];
        s := LocalVar.ElementNativeValues['SCVR'];
        if SameText(s, Trim(aString)) then begin
          Result := j;
          Exit;
        end;
      end;
  end;

  raise Exception.Create('Variable "'+aString+'" was not found in "'+MainRecord.ShortName+'"');
end;

function wbCTDAParam2QuestStageToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  Container  : IwbContainerElementRef;
  Param1     : IwbElement;
  MainRecord : IwbMainRecord;
  EditInfos  : TStringList;
  Stages     : IwbContainerElementRef;
  Stage      : IwbContainerElementRef;
  i, j       : Integer;
  s, t       : string;
begin
  case aType of
    ctToStr: Result := IntToStr(aInt) + ' <Warning: Could not resolve Parameter 1>';
    ctToEditValue: Result := IntToStr(aInt);
    ctToSortKey: begin
      Result := IntToHex64(aInt, 8);
      Exit;
    end;
    ctCheck: Result := '<Warning: Could not resolve Parameter 1>';
    ctEditType: Result := '';
    ctEditInfo: Result := '';
  end;

  if not Assigned(aElement) then Exit;
  Container := GetContainerRefFromUnionOrValue(aElement);
  if not Assigned(Container) then Exit;

  Param1 := Container.ElementByName['Parameter #1'];

  if not Assigned(Param1) then
    Exit;

  if not Supports(Param1.LinksTo, IwbMainRecord, MainRecord) then
    Exit;

  MainRecord := MainRecord.WinningOverride;

  if MainRecord.Signature <> QUST then begin
    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: "'+MainRecord.ShortName+'" is not a Quest record>';
      ctCheck: Result := '<Warning: "'+MainRecord.ShortName+'" is not a Quest record>';
    end;
    Exit;
  end;

  case aType of
    ctEditType: begin
      Result := 'ComboBox';
      Exit;
    end;
    ctEditInfo:
      EditInfos := TStringList.Create;
  else
    EditInfos := nil;
  end;
  try
    if Supports(MainRecord.ElementByName['Stages'], IwbContainerElementRef, Stages) then begin
      for i := 0 to Pred(Stages.ElementCount) do
        if Supports(Stages.Elements[i], IwbContainerElementRef, Stage) then begin
          j := Stage.ElementNativeValues['INDX'];
          s := Trim(Stage.ElementValues['Log Entries\Log Entry\CNAM']);
          t := IntToStr(j);
          while Length(t) < 3 do
            t := '0' + t;
          if s <> '' then
            t := t + ' ' + s;
          if Assigned(EditInfos) then
            EditInfos.AddObject(t, TObject(j))
          else if j = aInt then begin
            case aType of
              ctToStr, ctToEditValue: Result := t;
              ctCheck: Result := '';
            end;
            Exit;
          end;
        end;
    end;

    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: Quest Stage not found in "' + MainRecord.Name + '">';
      ctCheck: Result := '<Warning: Quest Stage not found in "' + MainRecord.Name + '">';
      ctEditInfo: begin
        EditInfos.Sort;
        Result := EditInfos.CommaText;
      end;
    end;
  finally
    FreeAndNil(EditInfos);
  end;
end;

function wbPerkDATAQuestStageToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  Container  : IwbContainerElementRef;
  Param1     : IwbElement;
  MainRecord : IwbMainRecord;
  EditInfos  : TStringList;
  Stages     : IwbContainerElementRef;
  Stage      : IwbContainerElementRef;
  i, j       : Integer;
  s, t       : string;
begin
  case aType of
    ctToStr: Result := IntToStr(aInt) + ' <Warning: Could not resolve Quest>';
    ctToEditValue: Result := IntToStr(aInt);
    ctToSortKey: begin
      Result := IntToHex64(aInt, 8);
      Exit;
    end;
    ctCheck: Result := '<Warning: Could not resolve Quest>';
    ctEditType: Result := '';
    ctEditInfo: Result := '';
  end;

  if not Assigned(aElement) then Exit;
  Container := GetContainerRefFromUnionOrValue(aElement);
  if not Assigned(Container) then Exit;

  Param1 := Container.ElementByName['Quest'];

  if not Assigned(Param1) then
    Exit;

  if not Supports(Param1.LinksTo, IwbMainRecord, MainRecord) then
    Exit;

  MainRecord := MainRecord.WinningOverride;

  if MainRecord.Signature <> QUST then begin
    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: "'+MainRecord.ShortName+'" is not a Quest record>';
      ctCheck: Result := '<Warning: "'+MainRecord.ShortName+'" is not a Quest record>';
    end;
    Exit;
  end;

  case aType of
    ctEditType: begin
      Result := 'ComboBox';
      Exit;
    end;
    ctEditInfo:
      EditInfos := TStringList.Create;
  else
    EditInfos := nil;
  end;
  try
    if Supports(MainRecord.ElementByName['Stages'], IwbContainerElementRef, Stages) then begin
      for i := 0 to Pred(Stages.ElementCount) do
        if Supports(Stages.Elements[i], IwbContainerElementRef, Stage) then begin
          j := Stage.ElementNativeValues['INDX'];
          s := Trim(Stage.ElementValues['Log Entries\Log Entry\CNAM']);
          t := IntToStr(j);
          while Length(t) < 3 do
            t := '0' + t;
          if s <> '' then
            t := t + ' ' + s;
          if Assigned(EditInfos) then
            EditInfos.AddObject(t, TObject(j))
          else if j = aInt then begin
            case aType of
              ctToStr, ctToEditValue: Result := t;
              ctCheck: Result := '';
            end;
            Exit;
          end;
        end;
    end;

    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: Quest Stage not found in "' + MainRecord.Name + '">';
      ctCheck: Result := '<Warning: Quest Stage not found in "' + MainRecord.Name + '">';
      ctEditInfo: begin
        EditInfos.Sort;
        Result := EditInfos.CommaText;
      end;
    end;
  finally
    FreeAndNil(EditInfos);
  end;
end;

function wbCTDAParam2QuestObjectiveToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  Container  : IwbContainerElementRef;
  Param1     : IwbElement;
  MainRecord : IwbMainRecord;
  EditInfos  : TStringList;
  Objectives     : IwbContainerElementRef;
  Objective      : IwbContainerElementRef;
  i, j       : Integer;
  s, t       : string;
begin
  case aType of
    ctToStr: Result := IntToStr(aInt) + ' <Warning: Could not resolve Parameter 1>';
    ctToEditValue: Result := IntToStr(aInt);
    ctToSortKey: begin
      Result := IntToHex64(aInt, 8);
      Exit;
    end;
    ctCheck: Result := '<Warning: Could not resolve Parameter 1>';
    ctEditType: Result := '';
    ctEditInfo: Result := '';
  end;

  if not Assigned(aElement) then Exit;
  Container := GetContainerRefFromUnionOrValue(aElement);
  if not Assigned(Container) then Exit;

  Param1 := Container.ElementByName['Parameter #1'];

  if not Assigned(Param1) then
    Exit;

  if not Supports(Param1.LinksTo, IwbMainRecord, MainRecord) then
    Exit;

  MainRecord := MainRecord.WinningOverride;

  if MainRecord.Signature <> QUST then begin
    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: "'+MainRecord.ShortName+'" is not a Quest record>';
      ctCheck: Result := '<Warning: "'+MainRecord.ShortName+'" is not a Quest record>';
    end;
    Exit;
  end;

  case aType of
    ctEditType: begin
      Result := 'ComboBox';
      Exit;
    end;
    ctEditInfo:
      EditInfos := TStringList.Create;
  else
    EditInfos := nil;
  end;
  try
    if Supports(MainRecord.ElementByName['Objectives'], IwbContainerElementRef, Objectives) then begin
      for i := 0 to Pred(Objectives.ElementCount) do
        if Supports(Objectives.Elements[i], IwbContainerElementRef, Objective) then begin
          j := Objective.ElementNativeValues['QOBJ'];
          s := Trim(Objective.ElementValues['NNAM']);
          t := IntToStr(j);
          while Length(t) < 3 do
            t := '0' + t;
          if s <> '' then
            t := t + ' ' + s;
          if Assigned(EditInfos) then
            EditInfos.AddObject(t, TObject(j))
          else if j = aInt then begin
            case aType of
              ctToStr, ctToEditValue: Result := t;
              ctCheck: Result := '';
            end;
            Exit;
          end;
        end;
    end;

    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: Quest Objective not found in "' + MainRecord.Name + '">';
      ctCheck: Result := '<Warning: Quest Objective not found in "' + MainRecord.Name + '">';
      ctEditInfo: begin
        EditInfos.Sort;
        Result := EditInfos.CommaText;
      end;
    end;
  finally
    FreeAndNil(EditInfos);
  end;
end;

function wbCTDAParam2QuestStageToInt(const aString: string; const aElement: IwbElement): Int64;
var
  i    : Integer;
  s    : string;
begin
  i := 1;
  s := Trim(aString);
  while (i <= Length(s)) and (s[i] in ['0'..'9']) do
    Inc(i);
  s := Copy(s, 1, Pred(i));

  Result := StrToInt(s);
end;

function wbCTDAParam2QuestObjectiveToInt(const aString: string; const aElement: IwbElement): Int64;
var
  i    : Integer;
  s    : string;
begin
  i := 1;
  s := Trim(aString);
  while (i <= Length(s)) and (s[i] in ['0'..'9']) do
    Inc(i);
  s := Copy(s, 1, Pred(i));

  Result := StrToInt(s);
end;


function wbClmtMoonsPhaseLength(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  PhaseLength : Byte;
  Masser      : Boolean;
  Secunda     : Boolean;
begin
  Result := '';
  if aType = ctToSortKey then begin
    Result := IntToHex64(aInt, 2);
  end else if aType = ctToStr then begin
    PhaseLength := aInt mod 64;
    Masser := (aInt and 64) <> 0;
    Secunda := (aInt and 128) <> 0;
    if Masser then
      if Secunda then
        Result := 'Masser, Secunda / '
      else
        Result := 'Masser / '
    else
      if Secunda then
        Result := 'Secunda / '
      else
        Result := 'No Moon / ';
    Result := Result + IntToStr(PhaseLength);
  end;
end;

function wbClmtTime(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
begin
  if aType = ctToSortKey then
    Result := IntToHex64(aInt, 4)
  else if aType = ctToStr then
    Result := TimeToStr( EncodeTime(aInt div 6, (aInt mod 6) * 10, 0, 0) )
  else
    Result := '';
end;

function wbAlocTime(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
begin
  if aType = ctToSortKey then
    Result := IntToHex64(aInt, 4)
  else if aType = ctToStr then
    Result := TimeToStr( aInt / 256 )
  else
    Result := '';
end;

function wbREFRNavmeshTriangleToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  Container  : IwbContainerElementRef;
  Navmesh    : IwbElement;
  MainRecord : IwbMainRecord;
  Triangles  : IwbContainerElementRef;
begin
  case aType of
    ctToStr: Result := IntToStr(aInt);
    ctToEditValue: Result := IntToStr(aInt);
    ctToSortKey: begin
      Result := IntToHex64(aInt, 8);
      Exit;
    end;
    ctCheck: Result := '';
    ctEditType: Result := '';
    ctEditInfo: Result := '';
  end;

  if not Assigned(aElement) then Exit;
  Container := GetContainerRefFromUnionOrValue(aElement);
  if not Assigned(Container) then Exit;

  Navmesh := Container.Elements[0];

  if not Assigned(Navmesh) then
    Exit;

  if not Supports(Navmesh.LinksTo, IwbMainRecord, MainRecord) then
    Exit;

  MainRecord := MainRecord.WinningOverride;

  if MainRecord.Signature <> NAVM then begin
    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: "'+MainRecord.ShortName+'" is not a Navmesh record>';
      ctCheck: Result := '<Warning: "'+MainRecord.ShortName+'" is not a Navmesh record>';
    end;
    Exit;
  end;

  if not wbSimpleRecords and (aType = ctCheck) and Supports(MainRecord.ElementByPath['NVTR'], IwbContainerElementRef, Triangles) then
    if aInt >= Triangles.ElementCount then
      Result := '<Warning: Navmesh triangle not found in "' + MainRecord.Name + '">';
end;

function wbStringToInt(const aString: string; const aElement: IwbElement): Int64;
begin
  Result := StrToIntDef(aString, 0);
end;


var
  wbCtdaTypeFlags : IwbFlagsDef;

function wbCtdaTypeToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  s: string;
begin
  Result := '';
  case aType of
    ctEditType:
      Result := 'CheckComboBox';
    ctEditInfo:
      Result := 'Equal,Greater,Lesser,Or,"Use Global","Run on Target"';
    ctToEditValue: begin
      Result := '000000';
      case aInt and $F0 of
        $00 : Result[1] := '1';
        $40 : Result[2] := '1';
        $60 : begin
                Result[1] := '1';
                Result[2] := '1';
              end;
        $80 : Result[3] := '1';
        $A0 : begin
                Result[1] := '1';
                Result[3] := '1';
              end;
      end;
      if (aInt and $01) <> 0 then
        Result[4] := '1';
      if (aInt and $02) <> 0 then
        Result[6] := '1';
      if (aInt and $04) <> 0 then
        Result[5] := '1';
    end;
    ctToStr: begin
      case aInt and $F0 of
        $00 : Result := 'Equal to';
        $20 : Result := 'Not equal to';
        $40 : Result := 'Greater than';
        $60 : Result := 'Greater than or equal to';
        $80 : Result := 'Less than';
        $A0 : Result := 'Less than or equal to';
      else
        Result := '<Unknown Compare operator>'
      end;

      if not Assigned(wbCtdaTypeFlags) then
        wbCtdaTypeFlags := wbFlags(gameProperties, [
          {0x01} 'Or',
          {0x02} 'Run on target',
          {0x04} 'Use global'
        ]);

      s := wbCtdaTypeFlags.ToString(aInt and $0F, aElement);

      if s <> '' then
        Result := Result + ' / ' + s;
    end;
    ctToSortKey: begin
      Result := IntToHex64(aInt, 2);
      Exit;
    end;
    ctCheck: begin
      case aInt and $F0 of
        $00, $20, $40, $60, $80, $A0 : Result := '';
      else
        Result := '<Unknown Compare operator>'
      end;

      if not Assigned(wbCtdaTypeFlags) then
        wbCtdaTypeFlags := wbFlags(gameProperties, [
          {0x01} 'Or',
          {0x02} 'Run on target',
          {0x04} 'Use global'
        ]);

      s := wbCtdaTypeFlags.Check(aInt and $0F, aElement);

      if s <> '' then
        Result := Result + ' / ' + s;
    end;
  end;
end;

function wbCtdaTypeToInt(const aString: string; const aElement: IwbElement): Int64;
var
  s: string;
begin
  s := aString + '000000';
//  Result := 0;
  if s[1] = '1' then begin
    if s[2] = '1' then begin
      if s[3] = '1' then begin
        Result := $00;
      end else begin
        Result := $60;
      end;
    end else begin
      if s[3] = '1' then begin
        Result := $A0;
      end else begin
        Result := $00;
      end;
    end;
  end else begin
    if s[2] = '1' then begin
      if s[3] = '1' then begin
        Result := $20;
      end else begin
        Result := $40;
      end;
    end else begin
      if s[3] = '1' then begin
        Result := $80;
      end else begin
        Result := $20;
      end;
    end;
  end;
  if s[4] = '1' then
    Result := Result or $01;
  if s[6] = '1' then
    Result := Result or $02;
  if s[5] = '1' then
    Result := Result or $04;
end;

procedure wbHeadPartsAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  Container : IwbContainerElementRef;
begin
  if wbBeginInternalEdit then try
    if Supports(aElement, IwbContainerElementRef, Container) then
      if (Container.Elements[0].NativeValue = 1) and (Container.ElementCount > 2) then
        Container.RemoveElement(1);
  finally
    wbEndInternalEdit;
  end;
end;

procedure wbMESGDNAMAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  OldValue, NewValue : Integer;
  Container          : IwbContainerElementRef;
begin
  if VarSameValue(aOldValue, aNewValue) then
    Exit;
  if Supports(aElement.Container, IwbContainerElementRef, Container) then begin
    OldValue := Integer(aOldValue) and 1;
    NewValue := Integer(aNewValue) and 1;
    if NewValue = OldValue then
      Exit;
    if NewValue = 1 then
      Container.RemoveElement('TNAM')
    else
      Container.Add('TNAM', True);
  end;
end;

procedure wbGMSTEDIDAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  OldValue, NewValue : string;
  Container          : IwbContainerElementRef;
begin
  if VarSameValue(aOldValue, aNewValue) then
    Exit;
  if Supports(aElement.Container, IwbContainerElementRef, Container) then begin
    OldValue := aOldValue;
    NewValue := aNewValue;
    if (Length(OldValue) < 1) or (Length(OldValue) < 1) or (OldValue[1] <> NewValue[1]) then begin
      Container.RemoveElement('DATA');
      Container.Add('DATA', True);
    end;
  end;
end;

procedure wbFLSTEDIDAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  OldValue, NewValue     : string;
  OldOrdered, NewOrdered : Boolean;
  Container              : IwbContainerElementRef;
const
  OrderedList = 'OrderedList';
begin
  if VarSameValue(aOldValue, aNewValue) then
    Exit;
  if Supports(aElement.Container, IwbContainerElementRef, Container) then begin
    OldValue := aOldValue;
    NewValue := aNewValue;

    if Length(OldValue) > Length(OrderedList) then
      Delete(OldValue, 1, Length(OldValue)-Length(OrderedList));
    if Length(NewValue) > Length(OrderedList) then
      Delete(NewValue, 1, Length(NewValue)-Length(OrderedList));

    OldOrdered := SameText(OldValue, OrderedList);
    NewOrdered := SameText(NewValue, OrderedList);

    if OldOrdered <> NewOrdered then
      Container.RemoveElement('FormIDs');
  end;
end;

procedure wbCtdaTypeAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  OldValue, NewValue: Integer;
  Container: IwbContainerElementRef;
begin
  if VarSameValue(aOldValue, aNewValue) then
    Exit;
  if not Supports(aElement, IwbContainerElementRef, Container) then
    Exit;

  OldValue := aOldValue and $04;
  NewValue := aNewValue and $04;
  if OldValue <> NewValue then
    Container.ElementNativeValues['..\Comparison Value'] := 0;

  if aNewValue and $02 then begin
    Container.ElementNativeValues['..\Run On'] := 1;
    if Integer(Container.ElementNativeValues['..\Run On']) = 1 then
      aElement.NativeValue := Byte(aNewValue) and not $02;
  end;
end;

function wbMODTCallback(aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  Strings: TDynStrings;
  i: Integer;
begin
  Result := '';
  if wbLoaderDone and (aType in [ctToStr, ctToSortKey] ) then begin
    Strings := wbContainerHandler.ResolveHash(aInt);
    for i := Low(Strings) to High(Strings) do
      Result := Result + Strings[i] + ', ';
    SetLength(Result, Length(Result) -2 );
  end;
  if Result = '' then
    Result := 'Unresolved: ' + IntToHex64(aInt, 16);
end;


function wbIdleAnam(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
begin
  Result := '';
  case aType of
    ctToStr: begin
      case aInt and not $C0 of
        0: Result := 'Idle';
        1: Result := 'Movement';
        2: Result := 'Left Arm';
        3: Result := 'Left Hand';
        4: Result := 'Weapon';
        5: Result := 'Weapon Up';
        6: Result := 'Weapon Down';
        7: Result := 'Special Idle';
       20: Result := 'Whole Body';
       21: Result := 'Upper Body';
      else
        Result := '<Unknown: '+IntToStr(aInt and not $C0)+'>';
      end;

      if (aInt and $80) = 0 then
        Result := Result + ', Must return a file';
      if (aInt and $40) = 1 then
        Result := Result + ', Unknown Flag';
    end;
    ctToSortKey: begin
      Result := IntToHex64(aInt, 2);
    end;
    ctCheck: begin
      case aInt and not $C0 of
        0..7, 20, 21: Result := '';
      else
        Result := '<Unknown: '+IntToStr(aInt and not $C0)+'>';
      end;
    end;
  end;
end;

function wbScaledInt4ToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
const
  PlusMinus : array[Boolean] of string = ('+', '-');
begin
  Result := '';
  case aType of
    ctToStr, ctToEditValue: Result := FloatToStrF(aInt / 10000, ffFixed, 99, 4);
    ctToSortKey: begin
      Result := FloatToStrF(aInt / 10000, ffFixed, 99, 4);
      if Length(Result) < 22 then
        Result := StringOfChar('0', 22 - Length(Result)) + Result;
      Result := PlusMinus[aInt < 0] + Result;
    end;
    ctCheck: Result := '';
  end;
end;

function wbScaledInt4ToInt(const aString: string; const aElement: IwbElement): Int64;
var
  f: Extended;
begin
  f := StrToFloat(aString);
  f := f * 10000;
  Result := Round(f);
end;

function wbHideFFFF(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
begin
  Result := '';
  if aType = ctToSortKey then
    Result := IntToHex64(aInt, 4)
  else if aType = ctToStr then
    if aInt = $FFFF then
      Result := 'None'
    else
      Result := IntToStr(aInt);
end;

function wbAtxtPosition(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
begin
  Result := '';
  if aType = ctToSortKey then
    Result := IntToHex64(aInt div 17, 2) + IntToHex64(aInt mod 17, 2)
  else if aType = ctCheck then begin
    if (aInt < 0) or (aInt > 288) then
      Result := '<Out of range: '+IntToStr(aInt)+'>'
    else
      Result := '';
  end else if aType = ctToStr then
    Result := IntToStr(aInt) + ' -> ' + IntToStr(aInt div 17) + ':' + IntToStr(aInt mod 17);
end;

function wbGLOBFNAM(aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
begin
  Result := '';
  case aType of
    ctToStr: begin
      case aInt of
        Ord('s'): Result := 'Short';
        Ord('l'): Result := 'Long';
        Ord('f'): Result := 'Float';
      else
        Result := '<Unknown: '+IntToStr(aInt)+'>';
      end;
    end;
    ctToSortKey: Result := Chr(aInt);
    ctCheck: begin
      case aInt of
        Ord('s'), Ord('l'), Ord('f'): Result := '';
      else
        Result := '<Unknown: '+IntToStr(aInt)+'>';
      end;
    end;
  end;
end;

function wbPlacedAddInfo(var gameProperties: TGameProperties; const aMainRecord: IwbMainRecord): string;
var
  Rec: IwbRecord;
  Container: IwbContainer;
  s: string;
  Cell: IwbMainRecord;
  Position: TwbVector;
  Grid: TwbGridCell;
begin
  Result := '';

  Rec := aMainRecord.RecordBySignature['NAME'];
  if Assigned(Rec) then begin
    s := Trim(Rec.Value);
    if s <> '' then
      Result := 'places ' + s;
  end;

  Container := aMainRecord.Container;
  while Assigned(Container) and (Container.ElementType <> etGroupRecord) do
    Container := Container.Container;

  if Assigned(Container) then begin
    s := Trim(Container.Name);
    if s <> '' then begin
      if Result <> '' then
        Result := Result + ' ';
      Result := Result + 'in ' + s;

      // grid position of persistent reference in exterior persistent cell (interior cells are not persistent)
      if Supports(aMainRecord.Container, IwbGroupRecord, Container) then
        Cell := IwbGroupRecord(Container).ChildrenOf;
      if Assigned(Cell) and Cell.IsPersistent and (Cell.Signature = 'CELL') then
        if aMainRecord.GetPosition(Position) then begin
          Grid := wbPositionToGridCell(Position);
          Result := Result + ' at ' + IntToStr(Grid.x) + ',' + IntToStr(Grid.y);
        end;
    end;
  end;
end;

function wbINFOAddInfo(var gameProperties: TGameProperties; const aMainRecord: IwbMainRecord): string;
var
  Container: IwbContainer;
  s: string;
begin
  Result := Trim(aMainRecord.ElementValues['Responses\Response\NAM1']);
  if Result <> '' then
    Result := '''' + Result + '''';

  Container := aMainRecord.Container;
  while Assigned(Container) and (Container.ElementType <> etGroupRecord) do
    Container := Container.Container;

  if Assigned(Container) then begin
    s := Trim(Container.Name);
    if s <> '' then begin
      if Result <> '' then
        Result := Result + ' ';
      Result := Result + 'in ' + s;
    end;
  end;

  s := Trim(aMainRecord.ElementValues['QSTI']);
  if s <> '' then begin
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + 'for ' + s;
  end;
end;

function wbNAVMAddInfo(var gameProperties: TGameProperties; const aMainRecord: IwbMainRecord): string;
var
  Rec        : IwbRecord;
  Element    : IwbElement;
  s          : string;
begin
  Result := '';

  Rec := aMainRecord.RecordBySignature['DATA'];
  if Assigned(Rec) then begin
    Element := Rec.ElementByName['Cell'];
    if Assigned(Element) then
      Element := Element.LinksTo;
    if Assigned(Element) then
      s := Trim(Element.Name);
    if s <> '' then
      Result := 'for ' + s;
  end;
end;

function wbCellAddInfo(var gameProperties: TGameProperties; const aMainRecord: IwbMainRecord): string;
var
  Rec: IwbRecord;
  Container: IwbContainer;
  GroupRecord : IwbGroupRecord;
  s: string;
begin
  Result := '';

  if not aMainRecord.IsPersistent then begin
    Rec := aMainRecord.RecordBySignature['XCLC'];
    if Assigned(Rec) then
      Result := 'at ' + Rec.Elements[0].Value + ',' + Rec.Elements[1].Value;
  end;

  Container := aMainRecord.Container;
  while Assigned(Container) and not
    (Supports(Container, IwbGroupRecord, GroupRecord) and (GroupRecord.GroupType = 1))  do
    Container := Container.Container;

  if Assigned(Container) then begin
    s := wbFormID(gameProperties).ToString(GroupRecord.GroupLabel, aMainRecord);
    if s <> '' then begin
      if Result <> '' then
        s := s + ' ';
      Result := 'in ' + s + Result;
    end;
  end;
end;

function wbWthrDataClassification(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
begin
  Result := '';
  case aType of
    ctToStr: begin
      case aInt and not 192 of
        0: Result := 'None';
        1: Result := 'Pleasant';
        2: Result := 'Cloudy';
        4: Result := 'Rainy';
        8: Result := 'Snow';
      else
        Result := '<Unknown: '+IntToStr(aInt and not 192)+'>';
      end;
    end;
    ctToSortKey: begin
      Result := IntToHex64(aInt, 2)
    end;
    ctCheck: begin
      case aInt and not 192 of
        0, 1, 2, 4, 8: Result := '';
      else
        Result := '<Unknown: '+IntToStr(aInt and not 192)+'>';
      end;
    end;
  end;
end;

function wbNOTETNAMDecide(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  rDATA: IwbRecord;
begin
  Result := 0;
  rDATA := aElement.Container.RecordBySignature[DATA];
  if Assigned(rDATA) then
    if rDATA.NativeValue = 3 then //Voice
      Result := 1;
end;

function wbNOTESNAMDecide(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  rDATA: IwbRecord;
begin
  Result := 0;
  rDATA := aElement.Container.RecordBySignature[DATA];
  if Assigned(rDATA) then
    if rDATA.NativeValue = 3 then //Voice
      Result := 1;
end;

function wbIPDSDATACount(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
begin
  if Assigned(aBasePtr) and Assigned(aEndPtr) then
    Result := (NativeUInt(aBasePtr) - NativeUInt(aBasePtr)) div 4
  else
    Result := 12;
end;

function wbNAVINAVMGetCount1(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  DataContainer : IwbDataContainer;
begin
  Result := 0;

  if Supports(aElement, IwbDataContainer, DataContainer) then begin
    if DataContainer.ElementType = etArray then
      if not Supports(DataContainer.Container, IwbDataContainer, DataContainer) then
        Exit;
    Assert(DataContainer.Name = 'Data');
    Result := PWord(NativeUInt(DataContainer.DataBasePtr) + 3*3*4)^;
  end;
end;

function wbNAVINAVMGetCount2(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  DataContainer : IwbDataContainer;
begin
  Result := 0;

  if Supports(aElement, IwbDataContainer, DataContainer) then begin
    if DataContainer.ElementType = etArray then
      if not Supports(DataContainer.Container, IwbDataContainer, DataContainer) then
        Exit;
    Assert(DataContainer.Name = 'Data');
    Result := PWord(NativeUInt(DataContainer.DataBasePtr) + 3*3*4 + 2)^;
  end;
end;

function wbCTDARunOnDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container     : IwbContainer;
  i             : Integer;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;

  i := Container.ElementNativeValues['Function'];
  // IsFacingUp, IsLeftUp
  if (i = 106) or (i = 285) then
    Result := 1;
end;

procedure wbCTDARunOnAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
begin
  if aOldValue <> aNewValue then
    if aNewValue <> 2 then
      aElement.Container.ElementNativeValues['Reference'] := 0;
end;

procedure wbPERKPRKETypeAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  Container : IwbContainerElementRef;
//  rDATA     : IwbRecord;
begin
  if aOldValue <> aNewValue then
    if Supports(aElement.Container, IwbContainerElementRef, Container) then begin
      if Supports(Container.Container, IwbContainerElementRef, Container) then begin
        Container.RemoveElement('DATA');
        Container.Add('DATA', True);
        Container.RemoveElement('Perk Conditions');
        Container.RemoveElement('Entry Point Function Parameters');
        if aNewValue = 2 then begin
          Container.Add('EPFT', True);
          Container.ElementNativeValues['DATA\Entry Point\Function'] := 2;
        end;
      end;
    end;
end;

function wbMGEFFAssocItemDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container     : IwbContainer;
  Archtype      : Variant;
  DataContainer : IwbDataContainer;
  Element       : IwbElement;
const
  OffsetArchtype = 56;

begin
  Result := 1;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;

  VarClear(ArchType);
  Element := Container.ElementByName['Archtype'];
  if Assigned(Element) then
    ArchType := Element.NativeValue
  else if Supports(Container, IwbDataContainer, DataContainer) and
          DataContainer.IsValidOffset(aBasePtr, aEndPtr, OffsetArchtype) then
    begin // we are part of a proper structure
      aBasePtr := PByte(aBasePtr) + OffsetArchtype;
      ArchType := PCardinal(aBasePtr)^;
    end;

  if not VarIsEmpty(ArchType) then
    case Integer(ArchType) of
      01: Result := 2;//Script
      18: Result := 3;//Bound Item
      19: Result := 4;//Summon Creature
    else
      Result := 0;
    end;
end;

procedure wbMGEFFAssocItemAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  Container : IwbContainer;
  Element   : IwbElement;
begin
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;
  if (aNewValue <> 0) then begin
    Element := Container.ElementByName['Archtype'];
    if Assigned(Element) and Element.NativeValue = 0 then
        Element.NativeValue := $FF; // Signals ArchType that it should not mess with us on the next change!
  end;
end;

procedure wbMGEFArchtypeAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  Container: IwbContainerElementRef;
begin
  if VarSameValue(aOldValue, aNewValue) then
    Exit;
  if not Supports(aElement, IwbContainerElementRef, Container) then
    Exit;
  if (aNewValue < $FF) and (aOldValue < $FF) then begin
    Container.ElementNativeValues['..\Assoc. Item'] := 0;
    case Integer(aNewValue) of
      11: Container.ElementNativeValues['..\Actor Value'] := 48;//Invisibility
      12: Container.ElementNativeValues['..\Actor Value'] := 49;//Chameleon
      24: Container.ElementNativeValues['..\Actor Value'] := 47;//Paralysis
      36: Container.ElementNativeValues['..\Actor Value'] := 51;//Turbo
    else
      Container.ElementNativeValues['..\Actor Value'] := -1;
    end;
  end;
end;

procedure wbCounterEffectsAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
begin
  wbCounterByPathAfterSet('DATA - Data\Counter effect count', aElement);
end;

procedure wbMGEFAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
begin
  wbCounterContainerByPathAfterSet('DATA - Data\Counter effect count', 'Counter Effects', aElement);
end;

function wbCTDAReferenceDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container     : IwbContainer;
  i             : Integer;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;

  i := Container.ElementNativeValues['Function'];
  // IsFacingUp, IsLeftUp
  if (i <> 106) and (i <> 285) then
    if Integer(Container.ElementNativeValues['Run On']) = 2 then
      Result := 1;
end;

procedure wbConditionToStr(var aValue:string; aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement; aType: TwbCallbackType);
var
  Condition: IwbContainerElementRef;
  RunOn, Param1, Param2: IwbElement;
  Typ: Byte;
  i: Integer;
begin
  if not Supports(aElement, IwbContainerElementRef, Condition) then
    Exit;
  if Condition.Collapsed <> tbTrue then
    Exit;

  Typ := Condition.Elements[0].NativeValue;

  if (Condition.ElementCount >= 9) and (Condition.Elements[7].Def.DefType <> dtEmpty) and (Condition.Elements[8].Def.DefType <> dtEmpty) then begin
    i := Condition.Elements[3].NativeValue;
    RunOn := Condition.Elements[7];
    if (i <> 106) and (i <> 285) and (RunOn.NativeValue = 2) then
      aValue := Condition.Elements[8].Value
    else
      aValue := RunOn.Value;
  end else
    if (Typ and $02) = 0 then
      aValue := 'Subject'
    else
      aValue := 'Target';

  aValue := aValue + '.' + Condition.Elements[3].Value;

  Param1 := Condition.Elements[5];
  if Param1.ConflictPriority <> cpIgnore then begin
    aValue := aValue + '(' {+ Param1.Name + ': '} + Param1.Value;
    Param2 := Condition.Elements[6];
    if Param2.ConflictPriority <> cpIgnore then begin
      aValue := aValue + ', ' {+ Param2.Name + ': '} + Param2.Value;
    end;
    aValue := aValue + ')';
  end;

  case Typ and $E0 of
    $00 : aValue := aValue + ' = ';
    $20 : aValue := aValue + ' <> ';
    $40 : aValue := aValue + ' > ';
    $60 : aValue := aValue + ' >= ';
    $80 : aValue := aValue + ' < ';
    $A0 : aValue := aValue + ' <= ';
  end;

  aValue := aValue + Condition.Elements[2].Value;

  if (Typ and $01) = 0 then
    aValue := aValue + ' AND'
  else
    aValue := aValue + ' OR';
end;

function wbNAVINVMIDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container     : IwbContainer;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;

  case Integer(Container.ElementNativeValues['Type']) of
    $00: Result :=1;
    $20: Result :=2;
    $30: Result :=3;
  end;
end;

function wbIMGSSkinDimmerDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container : IwbContainer;
  SubRecord : IwbSubRecord;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;
  if Supports(Container, IwbSubRecord, SubRecord) then
    if SubRecord.SubRecordHeaderSize in [132, 148] then
      Result := 1;
end;

function wbCOEDOwnerDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container  : IwbContainer;
  LinksTo    : IwbElement;
  MainRecord : IwbMainRecord;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;

  LinksTo := Container.ElementByName['Owner'].LinksTo;

  if Supports(LinksTo, IwbMainRecord, MainRecord) then
    if MainRecord.Signature = 'NPC_' then
      Result := 1
    else if MainRecord.Signature = 'FACT' then
      Result := 2;
end;

function wbCreaLevelDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container: IwbContainer;
  i: Int64;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;
  i := Container.ElementByName['Flags'].NativeValue;
  if i and $00000080 <> 0 then
    Result := 1;
end;


function wbGMSTUnionDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  rEDID: IwbRecord;
  s: string;
begin
  Result := 1;
  rEDID := aElement.Container.RecordBySignature[EDID];
  if Assigned(rEDID) then begin
    s := rEDID.Value;
    if Length(s) > 0 then
      case s[1] of
        's': Result := 0;
        'f': Result := 2;
      end;
  end;
end;

function wbFLSTLNAMIsSorted(const aContainer: IwbContainer): Boolean;
var
  rEDID      : IwbRecord;
  s          : string;
  _File      : IwbFile;
  MainRecord : IwbMainRecord;
const
  OrderedList = 'OrderedList';
begin
  Result := wbSortFLST; {>>> Should not be sorted according to Arthmoor and JustinOther, left as sorted for compatibility <<<}
  if Result then begin
    rEDID := aContainer.RecordBySignature[EDID];
    if Assigned(rEDID) then begin
      s := rEDID.Value;
      if Length(s) > Length(OrderedList) then
        Delete(s, 1, Length(s)-Length(OrderedList));
      if SameText(s, OrderedList) then
        Result := False;
    end;
  end;
  if Result then begin
    MainRecord := aContainer.ContainingMainRecord;
    if not Assigned(MainRecord) then
      Exit;
    MainRecord := MainRecord.MasterOrSelf;
    if not Assigned(MainRecord) then
      Exit;
    _File := MainRecord._File;
    if not Assigned(_File) then
      Exit;
    if not SameText(_File.FileName, 'WeaponModKits.esp') then
      Exit;
    case MainRecord.FormID.ObjectID of
      $0130EB, $0130ED, $01522D, $01522E, $0158D5, $0158D6, $0158D7, $0158D8, $0158D9, $0158DA, $0158DC, $0158DD, $018E20:
        Result := False;
    end;
  end;
end;

function wbPerkDATADecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  rPRKE: IwbRecord;
  eType: IwbElement;
begin
  Result := 0;
  rPRKE := aElement.Container.RecordBySignature[PRKE];
  if Assigned(rPRKE) then begin
    eType := rPRKE.ElementByName['Type'];
    if Assigned(eType) then begin
      Result := eType.NativeValue;
    end;
  end;
end;

function wbEPFDDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container: IwbContainerElementRef;
begin
  Result := 0;
  if not Assigned(aElement) then
    Exit;
  if not Supports(aElement.Container, IwbContainerElementRef, Container) then
    Exit;
  Result := Container.ElementNativeValues['EPFT'];
  if Result = 2 then
    if Integer(Container.ElementNativeValues['..\DATA\Entry Point\Function']) = 5 then
      Result := 5;
end;

type
  TCTDAFunctionParamType = (
    ptNone,
    ptInteger,
    ptVariableName,  //Integer
    ptSex,           //Enum: Male, Female
    ptActorValue,    //Enum: wbActorValue
    ptCrimeType,     //?? Enum
    ptAxis,          //?? Char
    ptQuestStage,    //?? Integer
    ptMiscStat,      //?? Enum
    ptAlignment,     //?? Enum
    ptEquipType,     //?? Enum
    ptFormType,      //?? Enum
    ptCriticalStage, //?? Enum

    ptObjectReference,    //REFR, ACHR, ACRE, PGRE
    ptInventoryObject,    //ARMO, BOOK, MISC, WEAP, AMMO, KEYM, ALCH, NOTE, ARMA
    ptActor,              //ACHR, ACRE
    ptVoiceType,          //VTYP
    ptIdleForm,           //IDLE
    ptFormList,           //FLST
    ptNote,               //NOTE
    ptQuest,              //QUST
    ptFaction,            //FACT
    ptWeapon,             //WEAP
    ptCell,               //CELL
    ptClass,              //CLAS
    ptRace,               //RACE
    ptActorBase,          //NPC_, CREA
    ptGlobal,             //GLOB
    ptWeather,            //WTHR
    ptPackage,            //PACK
    ptEncounterZone,      //ECZN
    ptPerk,               //PERK
    ptOwner,              //FACT, NPC_
    ptFurniture,          //FURN
    ptMagicItem,          //SPEL
    ptMagicEffect,        //MGEF
    ptWorldspace,         //WRLD
    ptVATSValueFunction,
    ptVATSValueParam,
    ptCreatureType,
    ptMenuMode,
    ptPlayerAction,
    ptBodyLocation,
    ptReferencableObject, //TREE, SOUN, ACTI, DOOR, STAT, FURN, CONT, ARMO, AMMO, MISC, WEAP, BOOK, KEYM, ALCH, LIGH, GRAS, ASPC, IDLM, ARMA, MSTT, NOTE, PWAT, SCOL, TACT, TERM
    ptQuestObjective,     //?? Integer
    ptReputation,         //REPU
    ptRegion,             //REGN
    ptChallenge,          //CHAL
    ptCasino,             //CSNO
    ptAnyForm             // Any form
  );

  PCTDAFunction = ^TCTDAFunction;
  TCTDAFunction = record
    Index: Integer;
    Name: string;
    ParamType1: TCTDAFunctionParamType;
    ParamType2: TCTDAFunctionParamType;
  end;

const
  wbCTDAFunctions : array[0..325] of TCTDAFunction = (
    (Index:   1; Name: 'GetDistance'; ParamType1: ptObjectReference),
    (Index:   5; Name: 'GetLocked'),
    (Index:   6; Name: 'GetPos'; ParamType1: ptAxis),
    (Index:   8; Name: 'GetAngle'; ParamType1: ptAxis),
    (Index:  10; Name: 'GetStartingPos'; ParamType1: ptAxis),
    (Index:  11; Name: 'GetStartingAngle'; ParamType1: ptAxis),
    (Index:  12; Name: 'GetSecondsPassed'),
    (Index:  14; Name: 'GetActorValue'; ParamType1: ptActorValue),
    (Index:  18; Name: 'GetCurrentTime'),
    (Index:  24; Name: 'GetScale'),
    (Index:  25; Name: 'IsMoving'),
    (Index:  26; Name: 'IsTurning'),
    (Index:  27; Name: 'GetLineOfSight'; ParamType1: ptObjectReference),
    (Index:  32; Name: 'GetInSameCell'; ParamType1: ptObjectReference),
    (Index:  35; Name: 'GetDisabled'),
    (Index:  36; Name: 'MenuMode'; ParamType1: ptMenuMode),
    (Index:  39; Name: 'GetDisease'),
    (Index:  40; Name: 'GetVampire'),
    (Index:  41; Name: 'GetClothingValue'),
    (Index:  42; Name: 'SameFaction'; ParamType1: ptActor),
    (Index:  43; Name: 'SameRace'; ParamType1: ptActor),
    (Index:  44; Name: 'SameSex'; ParamType1: ptActor),
    (Index:  45; Name: 'GetDetected'; ParamType1: ptActor),
    (Index:  46; Name: 'GetDead'),
    (Index:  47; Name: 'GetItemCount'; ParamType1: ptInventoryObject),
    (Index:  48; Name: 'GetGold'),
    (Index:  49; Name: 'GetSleeping'),
    (Index:  50; Name: 'GetTalkedToPC'),
    (Index:  53; Name: 'GetScriptVariable'; ParamType1: ptObjectReference; ParamType2: ptVariableName),
    (Index:  56; Name: 'GetQuestRunning'; ParamType1: ptQuest),
    (Index:  58; Name: 'GetStage'; ParamType1: ptQuest),
    (Index:  59; Name: 'GetStageDone'; ParamType1: ptQuest; ParamType2: ptQuestStage),
    (Index:  60; Name: 'GetFactionRankDifference'; ParamType1: ptFaction; ParamType2: ptActor),
    (Index:  61; Name: 'GetAlarmed'),
    (Index:  62; Name: 'IsRaining'),
    (Index:  63; Name: 'GetAttacked'),
    (Index:  64; Name: 'GetIsCreature'),
    (Index:  65; Name: 'GetLockLevel'),
    (Index:  66; Name: 'GetShouldAttack'; ParamType1: ptActor),
    (Index:  67; Name: 'GetInCell'; ParamType1: ptCell),
    (Index:  68; Name: 'GetIsClass'; ParamType1: ptClass),
    (Index:  69; Name: 'GetIsRace'; ParamType1: ptRace),
    (Index:  70; Name: 'GetIsSex'; ParamType1: ptSex),
    (Index:  71; Name: 'GetInFaction'; ParamType1: ptFaction),
    (Index:  72; Name: 'GetIsID'; ParamType1: ptReferencableObject),
    (Index:  73; Name: 'GetFactionRank'; ParamType1: ptFaction),
    (Index:  74; Name: 'GetGlobalValue'; ParamType1: ptGlobal),
    (Index:  75; Name: 'IsSnowing'),
    (Index:  76; Name: 'GetDisposition'; ParamType1: ptActor),
    (Index:  77; Name: 'GetRandomPercent'),
    (Index:  79; Name: 'GetQuestVariable'; ParamType1: ptQuest; ParamType2: ptVariableName),
    (Index:  80; Name: 'GetLevel'),
    (Index:  81; Name: 'GetArmorRating'),
    (Index:  84; Name: 'GetDeadCount'; ParamType1: ptActorBase),
    (Index:  91; Name: 'GetIsAlerted'),
    (Index:  98; Name: 'GetPlayerControlsDisabled'; ParamType1: ptInteger; ParamType2: ptInteger{; ParamType3: ptInteger; ParamType4: ptInteger; ParamType5: ptInteger; ParamType6: ptInteger; ParamType7: ptInteger}),
    (Index:  99; Name: 'GetHeadingAngle'; ParamType1: ptObjectReference),
    (Index: 101; Name: 'IsWeaponOut'),
    (Index: 102; Name: 'IsTorchOut'),
    (Index: 103; Name: 'IsShieldOut'),
    (Index: 106; Name: 'IsFacingUp'),
    (Index: 107; Name: 'GetKnockedState'),
    (Index: 108; Name: 'GetWeaponAnimType'),
    (Index: 109; Name: 'IsWeaponSkillType'; ParamType1: ptActorValue),
    (Index: 110; Name: 'GetCurrentAIPackage'),
    (Index: 111; Name: 'IsWaiting'),
    (Index: 112; Name: 'IsIdlePlaying'),
    (Index: 116; Name: 'GetMinorCrimeCount'),
    (Index: 117; Name: 'GetMajorCrimeCount'),
    (Index: 118; Name: 'GetActorAggroRadiusViolated'),
    (Index: 122; Name: 'GetCrime'; ParamType1: ptActor; ParamType2: ptCrimeType),
    (Index: 123; Name: 'IsGreetingPlayer'),
    (Index: 125; Name: 'IsGuard'),
    (Index: 127; Name: 'HasBeenEaten'),
    (Index: 128; Name: 'GetFatiguePercentage'),
    (Index: 129; Name: 'GetPCIsClass'; ParamType1: ptClass),
    (Index: 130; Name: 'GetPCIsRace'; ParamType1: ptRace),
    (Index: 131; Name: 'GetPCIsSex'; ParamType1: ptSex),
    (Index: 132; Name: 'GetPCInFaction'; ParamType1: ptFaction),
    (Index: 133; Name: 'SameFactionAsPC'),
    (Index: 134; Name: 'SameRaceAsPC'),
    (Index: 135; Name: 'SameSexAsPC'),
    (Index: 136; Name: 'GetIsReference'; ParamType1: ptObjectReference),
    (Index: 141; Name: 'IsTalking'),
    (Index: 142; Name: 'GetWalkSpeed'),
    (Index: 143; Name: 'GetCurrentAIProcedure'),
    (Index: 144; Name: 'GetTrespassWarningLevel'),
    (Index: 145; Name: 'IsTrespassing'),
    (Index: 146; Name: 'IsInMyOwnedCell'),
    (Index: 147; Name: 'GetWindSpeed'),
    (Index: 148; Name: 'GetCurrentWeatherPercent'),
    (Index: 149; Name: 'GetIsCurrentWeather'; ParamType1: ptWeather),
    (Index: 150; Name: 'IsContinuingPackagePCNear'),
    (Index: 153; Name: 'CanHaveFlames'),
    (Index: 154; Name: 'HasFlames'),
    (Index: 157; Name: 'GetOpenState'),
    (Index: 159; Name: 'GetSitting'),
    (Index: 160; Name: 'GetFurnitureMarkerID'),
    (Index: 161; Name: 'GetIsCurrentPackage'; ParamType1: ptPackage),
    (Index: 162; Name: 'IsCurrentFurnitureRef'; ParamType1: ptObjectReference),
    (Index: 163; Name: 'IsCurrentFurnitureObj'; ParamType1: ptFurniture),
    (Index: 170; Name: 'GetDayOfWeek'),
    (Index: 172; Name: 'GetTalkedToPCParam'; ParamType1: ptActor),
    (Index: 175; Name: 'IsPCSleeping'),
    (Index: 176; Name: 'IsPCAMurderer'),
    (Index: 180; Name: 'GetDetectionLevel'; ParamType1: ptActor),
    (Index: 182; Name: 'GetEquipped'; ParamType1: ptInventoryObject),
    (Index: 185; Name: 'IsSwimming'),
    (Index: 190; Name: 'GetAmountSoldStolen'),
    (Index: 192; Name: 'GetIgnoreCrime'),
    (Index: 193; Name: 'GetPCExpelled'; ParamType1: ptFaction),
    (Index: 195; Name: 'GetPCFactionMurder'; ParamType1: ptFaction),
    (Index: 197; Name: 'GetPCEnemyofFaction'; ParamType1: ptFaction),
    (Index: 199; Name: 'GetPCFactionAttack'; ParamType1: ptFaction),
    (Index: 203; Name: 'GetDestroyed'),
    (Index: 214; Name: 'HasMagicEffect'; ParamType1: ptMagicEffect),
    (Index: 215; Name: 'GetDefaultOpen'),
    (Index: 219; Name: 'GetAnimAction'),
    (Index: 223; Name: 'IsSpellTarget'; ParamType1: ptMagicItem),
    (Index: 224; Name: 'GetVATSMode'),
    (Index: 225; Name: 'GetPersuasionNumber'),
    (Index: 226; Name: 'GetSandman'),
    (Index: 227; Name: 'GetCannibal'),
    (Index: 228; Name: 'GetIsClassDefault'; ParamType1: ptClass),
    (Index: 229; Name: 'GetClassDefaultMatch'),
    (Index: 230; Name: 'GetInCellParam'; ParamType1: ptCell; ParamType2: ptObjectReference),
    (Index: 235; Name: 'GetVatsTargetHeight'),
    (Index: 237; Name: 'GetIsGhost'),
    (Index: 242; Name: 'GetUnconscious'),
    (Index: 244; Name: 'GetRestrained'),
    (Index: 246; Name: 'GetIsUsedItem'; ParamType1: ptReferencableObject),
    (Index: 247; Name: 'GetIsUsedItemType'; ParamType1: ptFormType),
    (Index: 254; Name: 'GetIsPlayableRace'),
    (Index: 255; Name: 'GetOffersServicesNow'),
    (Index: 258; Name: 'GetUsedItemLevel'),
    (Index: 259; Name: 'GetUsedItemActivate'),
    (Index: 264; Name: 'GetBarterGold'),
    (Index: 265; Name: 'IsTimePassing'),
    (Index: 266; Name: 'IsPleasant'),
    (Index: 267; Name: 'IsCloudy'),
    (Index: 274; Name: 'GetArmorRatingUpperBody'),
    (Index: 277; Name: 'GetBaseActorValue'; ParamType1: ptActorValue),
    (Index: 278; Name: 'IsOwner'; ParamType1: ptOwner),
    (Index: 280; Name: 'IsCellOwner'; ParamType1: ptCell; ParamType2: ptOwner),
    (Index: 282; Name: 'IsHorseStolen'),
    (Index: 285; Name: 'IsLeftUp'),
    (Index: 286; Name: 'IsSneaking'),
    (Index: 287; Name: 'IsRunning'),
    (Index: 288; Name: 'GetFriendHit'),
    (Index: 289; Name: 'IsInCombat'),
    (Index: 300; Name: 'IsInInterior'),
    (Index: 304; Name: 'IsWaterObject'),
    (Index: 306; Name: 'IsActorUsingATorch'),
    (Index: 309; Name: 'IsXBox'),
    (Index: 310; Name: 'GetInWorldspace'; ParamType1: ptWorldSpace),
    (Index: 312; Name: 'GetPCMiscStat'; ParamType1: ptMiscStat),
    (Index: 313; Name: 'IsActorEvil'),
    (Index: 314; Name: 'IsActorAVictim'),
    (Index: 315; Name: 'GetTotalPersuasionNumber'),
    (Index: 318; Name: 'GetIdleDoneOnce'),
    (Index: 320; Name: 'GetNoRumors'),
    (Index: 323; Name: 'WhichServiceMenu'),
    (Index: 327; Name: 'IsRidingHorse'),
    (Index: 332; Name: 'IsInDangerousWater'),
    (Index: 338; Name: 'GetIgnoreFriendlyHits'),
    (Index: 339; Name: 'IsPlayersLastRiddenHorse'),
    (Index: 353; Name: 'IsActor'),
    (Index: 354; Name: 'IsEssential'),
    (Index: 358; Name: 'IsPlayerMovingIntoNewSpace'),
    (Index: 361; Name: 'GetTimeDead'),
    (Index: 362; Name: 'GetPlayerHasLastRiddenHorse'),
    (Index: 365; Name: 'IsChild'),
    (Index: 367; Name: 'GetLastPlayerAction'),
    (Index: 368; Name: 'IsPlayerActionActive'; ParamType1: ptPlayerAction),
    (Index: 370; Name: 'IsTalkingActivatorActor'; ParamType1: ptActor),
    (Index: 372; Name: 'IsInList'; ParamType1: ptFormList),
    (Index: 382; Name: 'GetHasNote'; ParamType1: ptNote),
    (Index: 391; Name: 'GetHitLocation'),
    (Index: 392; Name: 'IsPC1stPerson'),
    (Index: 397; Name: 'GetCauseofDeath'),
    (Index: 398; Name: 'IsLimbGone'; ParamType1: ptBodyLocation),
    (Index: 399; Name: 'IsWeaponInList'; ParamType1: ptFormList),
    (Index: 403; Name: 'HasFriendDisposition'),
    (Index: 408; Name: 'GetVATSValue'; ParamType1: ptVATSValueFunction; ParamType2: ptVATSValueParam),
    (Index: 409; Name: 'IsKiller'; ParamType1: ptActor),
    (Index: 410; Name: 'IsKillerObject'; ParamType1: ptFormList),
    (Index: 411; Name: 'GetFactionCombatReaction'; ParamType1: ptFaction; ParamType2: ptFaction),
    (Index: 415; Name: 'Exists'; ParamType1: ptObjectReference),
    (Index: 416; Name: 'GetGroupMemberCount'),
    (Index: 417; Name: 'GetGroupTargetCount'),
    (Index: 420; Name: 'GetObjectiveCompleted'; ParamType1: ptQuest; ParamType2: ptQuestObjective),
    (Index: 421; Name: 'GetObjectiveDisplayed'; ParamType1: ptQuest; ParamType2: ptQuestObjective),
    (Index: 427; Name: 'GetIsVoiceType'; ParamType1: ptVoiceType),
    (Index: 428; Name: 'GetPlantedExplosive'),
    (Index: 430; Name: 'IsActorTalkingThroughActivator'),
    (Index: 431; Name: 'GetHealthPercentage'),
    (Index: 433; Name: 'GetIsObjectType'; ParamType1: ptFormType),
    (Index: 435; Name: 'GetDialogueEmotion'),
    (Index: 436; Name: 'GetDialogueEmotionValue'),
    (Index: 438; Name: 'GetIsCreatureType'; ParamType1: ptCreatureType),
    (Index: 446; Name: 'GetInZone'; ParamType1: ptEncounterZone),
    (Index: 449; Name: 'HasPerk'; ParamType1: ptPerk; ParamType2: ptInteger {boolean Alt}),	// PlayerCharacter has 2 lists of perks
    (Index: 450; Name: 'GetFactionRelation'; ParamType1: ptActor),
    (Index: 451; Name: 'IsLastIdlePlayed'; ParamType1: ptIdleForm),
    (Index: 454; Name: 'GetPlayerTeammate'),
    (Index: 455; Name: 'GetPlayerTeammateCount'),
    (Index: 459; Name: 'GetActorCrimePlayerEnemy'),
    (Index: 460; Name: 'GetActorFactionPlayerEnemy'),
    (Index: 462; Name: 'IsPlayerTagSkill'; ParamType1: ptActorValue),
    (Index: 464; Name: 'IsPlayerGrabbedRef'; ParamType1: ptObjectReference),
    (Index: 471; Name: 'GetDestructionStage'),
    (Index: 474; Name: 'GetIsAlignment'; ParamType1: ptAlignment),
    (Index: 478; Name: 'GetThreatRatio'; ParamType1: ptActor),
    (Index: 480; Name: 'GetIsUsedItemEquipType'; ParamType1: ptEquipType),
    (Index: 489; Name: 'GetConcussed'),
    (Index: 492; Name: 'GetMapMarkerVisible'),
    (Index: 495; Name: 'GetPermanentActorValue'; ParamType1: ptActorValue),
    (Index: 496; Name: 'GetKillingBlowLimb'),
    (Index: 500; Name: 'GetWeaponHealthPerc'),
    (Index: 503; Name: 'GetRadiationLevel'),
    (Index: 510; Name: 'GetLastHitCritical'),
    (Index: 515; Name: 'IsCombatTarget'; ParamType1: ptActor),
    (Index: 518; Name: 'GetVATSRightAreaFree'; ParamType1: ptObjectReference),
    (Index: 519; Name: 'GetVATSLeftAreaFree'; ParamType1: ptObjectReference),
    (Index: 520; Name: 'GetVATSBackAreaFree'; ParamType1: ptObjectReference),
    (Index: 521; Name: 'GetVATSFrontAreaFree'; ParamType1: ptObjectReference),
    (Index: 522; Name: 'GetIsLockBroken'),
    (Index: 523; Name: 'IsPS3'),
    (Index: 524; Name: 'IsWin32'),
    (Index: 525; Name: 'GetVATSRightTargetVisible'; ParamType1: ptObjectReference),
    (Index: 526; Name: 'GetVATSLeftTargetVisible'; ParamType1: ptObjectReference),
    (Index: 527; Name: 'GetVATSBackTargetVisible'; ParamType1: ptObjectReference),
    (Index: 528; Name: 'GetVATSFrontTargetVisible'; ParamType1: ptObjectReference),
    (Index: 531; Name: 'IsInCriticalStage'; ParamType1: ptCriticalStage),
    (Index: 533; Name: 'GetXPForNextLevel'),
    (Index: 546; Name: 'GetQuestCompleted'; ParamType1: ptQuest),
    (Index: 550; Name: 'IsGoreDisabled'),
    (Index: 555; Name: 'GetSpellUsageNum'; ParamType1: ptMagicItem),
    (Index: 557; Name: 'GetActorsInHigh'),
    (Index: 558; Name: 'HasLoaded3D'),
    (Index: 573; Name: 'GetReputation'; ParamType1: ptReputation; ParamType2: ptInteger),
    (Index: 574; Name: 'GetReputationPct'; ParamType1: ptReputation; ParamType2: ptInteger),
    (Index: 575; Name: 'GetReputationThreshold'; ParamType1: ptReputation; ParamType2: ptInteger),
    (Index: 586; Name: 'IsHardcore'),
    (Index: 601; Name: 'GetForceHitReaction'),
    (Index: 607; Name: 'ChallengeLocked'; ParamType1: ptChallenge),
    (Index: 610; Name: 'GetCasinoWinningStage'; ParamType1: ptCasino),
    (Index: 612; Name: 'PlayerInRegion'; ParamType1: ptRegion),
    (Index: 614; Name: 'GetChallengeCompleted'; ParamType1: ptChallenge),
    (Index: 619; Name: 'IsAlwaysHardcore'),

    // Added by NVSE
    (Index: 1024; Name: 'GetNVSEVersion'; ),
    (Index: 1025; Name: 'GetNVSERevision'; ),
    (Index: 1026; Name: 'GetNVSEBeta'; ),
    (Index: 1028; Name: 'GetWeight'; ParamType1: ptInventoryObject; ),
    (Index: 1076; Name: 'GetWeaponHasScope'; ParamType1: ptInventoryObject; ),
    (Index: 1089; Name: 'ListGetFormIndex'; ParamType1: ptFormList; ParamType2: ptFormType;),
    (Index: 1107; Name: 'IsKeyPressed'; ParamType1: ptInteger; ParamType2: ptInteger;),
    (Index: 1131; Name: 'IsControlPressed'; ParamType1: ptInteger; ),
    (Index: 1271; Name: 'HasOwnership'; ParamType1: ptObjectReference; ),
    (Index: 1272; Name: 'IsOwned'; ParamType1: ptActor ),
    (Index: 1274; Name: 'GetDialogueTarget'; ParamType1: ptActor; ),
    (Index: 1275; Name: 'GetDialogueSubject'; ParamType1: ptActor; ),
    (Index: 1276; Name: 'GetDialogueSpeaker'; ParamType1: ptActor; ),
    (Index: 1278; Name: 'GetAgeClass'; ParamType1: ptActorBase; ),
    (Index: 1286; Name: 'GetTokenValue'; ParamType1: ptFormType; ),
    (Index: 1288; Name: 'GetTokenRef'; ParamType1: ptFormType; ),
    (Index: 1291; Name: 'GetPaired'; ParamType1: ptInventoryObject; ParamType2: ptActorBase;),
    (Index: 1292; Name: 'GetRespawn'; ParamType1: ptACtorBase; ),
    (Index: 1294; Name: 'GetPermanent'; ParamType1: ptObjectReference; ),
    (Index: 1297; Name: 'IsRefInList'; ParamType1: ptFormList; ParamType2: ptFormType;),
    (Index: 1301; Name: 'GetPackageCount'; ParamType1: ptObjectReference; ),
    (Index: 1440; Name: 'IsPlayerSwimming'; ),
    (Index: 1441; Name: 'GetTFC'; ),
    (Index: 1475; Name: 'GetPerkRank'; ParamType1: ptPerk; ParamType2: ptActor;),
    (Index: 1476; Name: 'GetAltPerkRank'; ParamType1: ptPerk; ParamType2: ptActor;),
    (Index: 1541; Name: 'GetActorFIKstatus'; ),

    // Added by nvse_plugin_ExtendedActorVariables
    (Index: 4352; Name: 'GetExtendedActorVariable'; ParamType1: ptInventoryObject; ),
    (Index: 4353; Name: 'GetBaseExtendedActorVariable'; ParamType1: ptInventoryObject; ),
    (Index: 4355; Name: 'GetModExtendedActorVariable'; ParamType1: ptInventoryObject; ),

    // Added by nvse_extender
    (Index: 4420; Name: 'NX_GetEVFl'; ParamType1: ptNone; ),  // Actually ptString, but it cannot be used in GECK
    (Index: 4426; Name: 'NX_GetQVEVFl'; ParamType1: ptQuest; ParamType2: ptInteger;),

    // Added by lutana_nvse - now in JIP NVSE Plugin
    (Index: 4612; Name: 'IsButtonPressed'; ParamType1: ptInteger; ),
    (Index: 4613; Name: 'GetLeftStickX'; ),
    (Index: 4614; Name: 'GetLeftStickY'; ),
    (Index: 4615; Name: 'GetRightStickX'; ),
    (Index: 4616; Name: 'GetRightStickY'; ),
    (Index: 4617; Name: 'GetLeftTrigger'; ),
    (Index: 4618; Name: 'GetRightTrigger'; ),
    (Index: 4708; Name: 'GetArmorClass'; ParamType1: ptAnyForm; ),
    (Index: 4709; Name: 'IsRaceInList'; ParamType1: ptFormList; ),
    (Index: 4758; Name: 'IsButtonDisabled'; ParamType1: ptInteger; ),
    (Index: 4761; Name: 'IsButtonHeld'; ParamType1: ptInteger; ),
    (Index: 4774; Name: 'IsTriggerDisabled'; ParamType1: ptInteger; ),
    (Index: 4777; Name: 'IsTriggerHeld'; ParamType1: ptInteger; ),
    (Index: 4822; Name: 'GetReferenceFlag'; ParamType1: ptInteger; ),
    (Index: 4832; Name: 'GetDistance2D'; ParamType1: ptObjectReference; ),
    (Index: 4833; Name: 'GetDistance3D'; ParamType1: ptObjectReference; ),
    (Index: 4843; Name: 'PlayerHasKey'; ),
	(Index: 4897; Name: 'ActorHasEffect'; ParamType1: ptMagicEffect; ),

    // Added by JIP NVSE Plugin  - up to v48
    (Index: 5637; Name: 'GetIsPoisoned'; ),
    (Index: 5708; Name: 'IsEquippedWeaponSilenced'; ),
    (Index: 5709; Name: 'IsEquippedWeaponScoped'; ),
    // No longer in the sources.(Index: 5953; Name: 'GetPCInRegion'; ParamType1: ptRegion; ),
    (Index: 5947; Name: 'GetActorLightAmount'; ),
    (Index: 5951; Name: 'GetGameDifficulty'; ),
    (Index: 5962; Name: 'GetPCDetectionState'; ),
    (Index: 5993; Name: 'IsAttacking'; ),
    (Index: 5994; Name: 'GetPCUsingScope'; ),
    (Index: 6010; Name: 'GetPCUsingIronSights'; ),
    (Index: 6012; Name: 'GetRadiationLevelAlt'; ),
    (Index: 6013; Name: 'IsInWater'; ),
    (Index: 6058; Name: 'GetAlwaysRun'; ),
    (Index: 6059; Name: 'GetAutoMove'; ),
    (Index: 6061; Name: 'GetIsRagdolled'; ),
    (Index: 6065; Name: 'AuxVarGetFltCond'; ParamType1: ptQuest; ParamType2: ptInteger;),
    (Index: 6069; Name: 'IsInAir'; ),
    (Index: 6070; Name: 'GetHasContact'; ParamType1: ptAnyForm; ),
    (Index: 6072; Name: 'GetHasContactBase'; ParamType1: ptAnyForm; ),
    (Index: 6073; Name: 'GetHasContactType'; ParamType1: ptInteger; ),
    (Index: 6124; Name: 'IsSpellTargetAlt'; ParamType1: ptMagicItem; ),
    (Index: 6167; Name: 'IsIdlePlayingEx'; ParamType1: ptAnyForm; ),
    (Index: 6186; Name: 'IsInCharGen'; ),
    (Index: 6192; Name: 'GetWaterImmersionPerc'; ),
    (Index: 6204; Name: 'IsFleeing'; ),
    (Index: 6217; Name: 'GetTargetUnreachable'; ),
    (Index: 6268; Name: 'IsInKillCam'; ),
	// Added by nvse plugin
    (Index: 10247; Name: 'TTW_GetEquippedWeaponSkill'; )
);

var
  wbCTDAFunctionEditInfo: string;

function wbCTDAParamDescFromIndex(aIndex: Integer): PCTDAFunction;
var
  L, H, I, C: Integer;
begin
  Result := nil;

  L := Low(wbCTDAFunctions);
  H := High(wbCTDAFunctions);
  while L <= H do begin
    I := (L + H) shr 1;
    C := CmpW32(wbCTDAFunctions[I].Index, aIndex);
    if C < 0 then
      L := I + 1
    else begin
      H := I - 1;
      if C = 0 then begin
        L := I;
        Result := @wbCTDAFunctions[L];
      end;
    end;
  end;
end;

function wbCTDACompValueDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container: IwbContainer;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;
  if Integer(Container.ElementByName['Type'].NativeValue) and $04 <> 0 then
    Result := 1;
end;

function wbCTDAParam1Decider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Desc: PCTDAFunction;
  Container: IwbContainer;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;
  Desc := wbCTDAParamDescFromIndex(Container.ElementByName['Function'].NativeValue);
  if Assigned(Desc) then
    Result := Succ(Integer(Desc.ParamType1));
end;

function wbCTDAParam2VATSValueParam(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container : IwbContainer;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;
  Result := Container.ElementByName['Parameter #1'].NativeValue;
end;

function wbCTDAParam2Decider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Desc: PCTDAFunction;
  Container: IwbContainer;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;
  Desc := wbCTDAParamDescFromIndex(Container.ElementByName['Function'].NativeValue);
  if Assigned(Desc) then
    Result := Succ(Integer(Desc.ParamType2));
end;

function wbCTDAFunctionToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  Desc : PCTDAFunction;
  i    : Integer;
begin
  Result := '';
  case aType of
    ctToStr, ctToEditValue: begin
      Desc := wbCTDAParamDescFromIndex(aInt);
      if Assigned(Desc) then
        Result := Desc.Name
      else if aType = ctToEditValue then
        Result := IntToStr(aInt)
      else
        Result := '<Unknown: '+IntToStr(aInt)+'>';
    end;
    ctToSortKey: Result := IntToHex(aInt, 8);
    ctCheck: begin
      Desc := wbCTDAParamDescFromIndex(aInt);
      if Assigned(Desc) then
        Result := ''
      else
        Result := '<Unknown: '+IntToStr(aInt)+'>';
    end;
    ctEditType:
      Result := 'ComboBox';
    ctEditInfo: begin
      Result := wbCTDAFunctionEditInfo;
      if Result = '' then begin
        with TStringList.Create do try
          for i := Low(wbCTDAFunctions) to High(wbCTDAFunctions) do
            Add(wbCTDAFunctions[i].Name);
          Sort;
          Result := CommaText;
        finally
          Free;
        end;
        wbCTDAFunctionEditInfo := Result;
      end;
    end;
  end;
end;

function wbCTDAFunctionToInt(const aString: string; const aElement: IwbElement): Int64;
var
  i: Integer;
begin
  for i := Low(wbCTDAFunctions) to High(wbCTDAFunctions) do
    with wbCTDAFunctions[i] do
      if SameText(Name, aString) then begin
        Result := Index;
        Exit;
      end;
  Result := StrToInt64(aString);
end;

type
  TPERKEntryPointConditionType = (
    epcDefault,
    epcItem,
    epcWeapon,
    epcWeaponTarget,
    epcTarget,
    epcAttacker,
    epcAttackerAttackee,
    epcAttackerAttackerWeapon
  );

  TPERKEntryPointFunctionType = (
    epfFloat,
    epfLeveledItem,
    epfScript,
    epfUnknown
  );

  TPERKEntryPointFunctionParamType = (
    epfpNone,
    epfpFloat,
    epfpFloatFloat,
    epfpLeveledItem,
    epfpScript
  );

  TPERKEntryPointFunctionTable = (
    epftDefault,
    epftSubtract
  );

  PPERKEntryPoint = ^TPERKEntryPoint;
  TPERKEntryPoint = record
    Name         : string;
    Condition    : TPERKEntryPointConditionType;
    FunctionType : TPERKEntryPointFunctionType;
    FunctionTable: TPERKEntryPointFunctionTable;
  end;

  PPERKCondition = ^TPERKCondition;
  TPERKCondition = record
    Count    : Integer;
    Caption1 : string;
    Caption2 : string;
    Caption3 : string;
  end;

  PPERKFunction = ^TPERKFunction;
  TPERKFunction = record
    //Name         : string;
    FunctionType : TPERKEntryPointFunctionType;
    ParamType    : TPERKEntryPointFunctionParamType;
  end;

const
  wbPERKCondition : array[TPERKEntryPointConditionType] of TPERKCondition = (
    (Count: 1; Caption1: 'Perk Owner'),
    (Count: 2; Caption1: 'Perk Owner'; Caption2: 'Item'),
    (Count: 2; Caption1: 'Perk Owner'; Caption2: 'Weapon'),
    (Count: 3; Caption1: 'Perk Owner'; Caption2: 'Weapon'; Caption3: 'Target'),
    (Count: 2; Caption1: 'Perk Owner'; Caption2: 'Target'),
    (Count: 2; Caption1: 'Perk Owner'; Caption2: 'Attacker'),
    (Count: 3; Caption1: 'Perk Owner'; Caption2: 'Attacker'; Caption3: 'Attackee'),
    (Count: 3; Caption1: 'Perk Owner'; Caption2: 'Attacker'; Caption3: 'Attacker Weapon')
  );

  wbPERKFunctions : array[0..9] of TPERKFunction = (
    ({Name: '';} FunctionType: epfUnknown; ParamType: epfpNone),
    ({Name: 'Set Value';} FunctionType: epfFloat; ParamType: epfpFloat),
    ({Name: 'Add Value';} FunctionType: epfFloat; ParamType: epfpFloat),
    ({Name: 'Multiply Value';} FunctionType: epfFloat; ParamType: epfpFloat),
    ({Name: 'Add Range To Value';} FunctionType: epfFloat; ParamType: epfpFloatFloat),
    ({Name: 'Add Actor Value Mult';} FunctionType: epfFloat; ParamType: epfpFloatFloat),
    ({Name: 'Absolute Value';} FunctionType: epfFloat; ParamType: epfpNone),
    ({Name: 'Negative Absolute Value';} FunctionType: epfFloat; ParamType: epfpNone),
    ({Name: 'Add Leveled List';} FunctionType: epfLeveledItem; ParamType: epfpLeveledItem),
    ({Name: 'Add Activate Choice';} FunctionType: epfScript; ParamType: epfpScript)
  );

  wbPERKFunctionNames : array[TPERKEntryPointFunctionTable, 0..9] of string = (
    (
      '',
      'Set Value',
      'Add Value',
      'Multiply Value',
      'Add Range To Value',
      'Add Actor Value Mult',
      'Absolute Value',
      'Negative Absolute Value',
      'Add Leveled List',
      'Add Activate Choice'
    ), (
      '',
      'Subtract Value',
      'Add Value',
      'Multiply Value',
      'Add Range To Value',
      'Add Actor Value Mult',
      'Absolute Value',
      'Negative Absolute Value',
      'Add Leveled List',
      'Add Activate Choice'
    )
  );

  wbPERKEntryPoints : array[0..73] of TPERKEntryPoint = (
    (Name: 'Calculate Weapon Damage'; Condition: epcWeaponTarget),
    (Name: 'Calculate My Critical Hit Chance'; Condition: epcWeaponTarget),
    (Name: 'Calculate My Critical Hit Damage'; Condition: epcWeaponTarget),
    (Name: 'Calculate Weapon Attack AP Cost'; Condition: epcWeapon),
    (Name: 'Calculate Mine Explode Chance'; Condition: epcItem),
    (Name: 'Adjust Range Penalty'; Condition: epcWeapon),
    (Name: 'Adjust Limb Damage'; Condition: epcAttackerAttackerWeapon),
    (Name: 'Calculate Weapon Range'; Condition: epcWeapon),
    (Name: 'Calculate To Hit Chance'; Condition: epcWeaponTarget),
    (Name: 'Adjust Experience Points'),
    (Name: 'Adjust Gained Skill Points'),
    (Name: 'Adjust Book Skill Points'),
    (Name: 'Modify Recovered Health'),
    (Name: 'Calculate Inventory AP Cost'),
    (Name: 'Get Disposition'; Condition: epcTarget),
    (Name: 'Get Should Attack'; Condition: epcAttacker),
    (Name: 'Get Should Assist'; Condition: epcAttackerAttackee),
    (Name: 'Calculate Buy Price'; Condition: epcItem),
    (Name: 'Get Bad Karma'),
    (Name: 'Get Good Karma'),
    (Name: 'Ignore Locked Terminal'),
    (Name: 'Add Leveled List On Death'; Condition: epcTarget; FunctionType: epfLeveledItem),
    (Name: 'Get Max Carry Weight'),
    (Name: 'Modify Addiction Chance'),
    (Name: 'Modify Addiction Duration'),
    (Name: 'Modify Positive Chem Duration'),
    (Name: 'Adjust Drinking Radiation'),
    (Name: 'Activate'; Condition: epcTarget; FunctionType: epfScript),
    (Name: 'Mysterious Stranger'),
    (Name: 'Has Paralyzing Palm'),
    (Name: 'Hacking Science Bonus'),
    (Name: 'Ignore Running During Detection'),
    (Name: 'Ignore Broken Lock'),
    (Name: 'Has Concentrated Fire'),
    (Name: 'Calculate Gun Spread'; Condition: epcWeapon),
    (Name: 'Player Kill AP Reward'; Condition: epcWeaponTarget),
{36}(Name: 'Modify Enemy Critical Hit Chance'; Condition: epcWeaponTarget),
{37}(Name: 'Reload Speed'; Condition: epcWeapon),
{38}(Name: 'Equip Speed'; Condition: epcWeapon),
{39}(Name: 'Action Point Regen'; Condition: epcWeapon),
{40}(Name: 'Action Point Cost'; Condition: epcWeapon),
{41}(Name: 'Miss Fortune'; Condition: epcDefault),
{42}(Name: 'Modify Run Speed'; Condition: epcDefault),
{43}(Name: 'Modify Attack Speed'; Condition: epcWeapon),
{44}(Name: 'Modify Radiation Consumed'; Condition: epcDefault),
{45}(Name: 'Has Pip Hacker'; Condition: epcDefault),
{46}(Name: 'Has Meltdown'; Condition: epcDefault),
{47}(Name: 'See Enemy Health'; Condition: epcDefault),
{48}(Name: 'Has Jury Rigging'; Condition: epcDefault),
{49}(Name: 'Modify Threat Range'; Condition: epcWeapon),
{50}(Name: 'Modify Thread'; Condition: epcWeapon),
{51}(Name: 'Has Fast Travel Always'; Condition: epcDefault),
{52}(Name: 'Knockdown Chance'; Condition: epcWeapon),
{53}(Name: 'Modify Weapon Strength Req'; Condition: epcWeapon; FunctionTable: epftSubtract),
{54}(Name: 'Modify Aiming Move Speed'; Condition: epcWeapon),
{55}(Name: 'Modify Light Items'; Condition: epcDefault),
{56}(Name: 'Modify Damage Threshold (defender)'; Condition: epcWeaponTarget; FunctionTable: epftSubtract),
{57}(Name: 'Modify Chance for Ammo Item'; Condition: epcWeapon),
{58}(Name: 'Modify Damage Threshold (attacker)'; Condition: epcWeaponTarget; FunctionTable: epftSubtract),
{59}(Name: 'Modify Throwing Velocity'; Condition: epcWeapon),
{60}(Name: 'Chance for Item on Fire'; Condition: epcWeapon),
{61}(Name: 'Has Unarmed Forward Power Attack'; Condition: epcDefault),
{62}(Name: 'Has Unarmed Back Power Attack'; Condition: epcWeaponTarget),
{63}(Name: 'Has Unarmed Crouched Power Attack'; Condition: epcDefault),
{64}(Name: 'Has Unarmed Counter Attack'; Condition: epcWeaponTarget),
{65}(Name: 'Has Unarmed Left Power Attack'; Condition: epcDefault),
{66}(Name: 'Has Unarmed Right Power Attack'; Condition: epcDefault),
{67}(Name: 'VATS HelperChance'; Condition: epcDefault),
{68}(Name: 'Modify Item Damage'; Condition: epcDefault),
{69}(Name: 'Has Improved Detection'; Condition: epcDefault),
{70}(Name: 'Has Improved Spotting'; Condition: epcDefault),
{71}(Name: 'Has Improved Item Detection'; Condition: epcDefault),
{72}(Name: 'Adjust Explosion Radius'; Condition: epcWeapon),
{73}(Name: 'Reserved'; Condition: epcWeapon)
  );

  wbPERKFunctionParams: array[TPERKEntryPointFunctionParamType] of string = (
    'None',
    'Float',
    'Float, Float',
    'Leveled Item',
    'Script'
  );

procedure wbPERKEntryPointAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  OldEntryPoint   : PPERKEntryPoint;
  NewEntryPoint   : PPERKEntryPoint;
  OldCondition    : PPERKCondition;
  NewCondition    : PPERKCondition;
  OldFunction     : PPERKFunction;
  EntryPoint      : IwbContainerElementRef;
  Effect          : IwbContainerElementRef;
  PerkConditions  : IwbContainerElementRef;
  PerkCondition   : IwbContainerElementRef;
  Container       : IwbContainerElementRef;
  i               : Integer;
begin
  if aOldValue <> aNewValue then begin
    OldEntryPoint := @wbPERKEntryPoints[Integer(aOldValue)];
    NewEntryPoint := @wbPERKEntryPoints[Integer(aNewValue)];
    OldCondition := @wbPERKCondition[OldEntryPoint.Condition];
    NewCondition := @wbPERKCondition[NewEntryPoint.Condition];
    if not Assigned(aElement) then
      Exit;
    if not Supports(aElement.Container, IwbContainerElementRef, EntryPoint) then
      Exit;
    i := EntryPoint.ElementNativeValues['Function'];
    if (i >= Low(wbPERKFunctions)) and (i <= High(wbPERKFunctions)) then
      OldFunction := @wbPERKFunctions[i]
    else
      OldFunction := nil;
    if not Assigned(OldFunction) or (OldFunction.FunctionType <> NewEntryPoint.FunctionType) then
      for i := Low(wbPERKFunctions) to High(wbPERKFunctions) do
        with wbPERKFunctions[i] do
          if FunctionType = NewEntryPoint.FunctionType then begin
            EntryPoint.ElementNativeValues['Function'] := i;
            Break;
          end;
    EntryPoint.ElementNativeValues['Perk Condition Tab Count'] := NewCondition.Count;

    if not Supports(EntryPoint.Container, IwbContainerElementRef, Container) then
      Exit;
    if not Supports(Container.Container, IwbContainerElementRef, Effect) then
      Exit;

    if not Supports(Effect.ElementByName['Perk Conditions'], IwbContainerElementRef, PerkConditions) then
      Exit;

    for i := Pred(PerkConditions.ElementCount) downto 0 do
      if Supports(PerkConditions.Elements[i], IwbContainerElementRef, PerkCondition) then
        if Integer(PerkCondition.ElementNativeValues['PRKC']) >= NewCondition.Count then
          PerkCondition.Remove
        else
          case Integer(PerkCondition.ElementNativeValues['PRKC']) of
            2: if OldCondition.Caption2 <> NewCondition.Caption2 then
                 PerkCondition.Remove;
            3: if OldCondition.Caption3 <> NewCondition.Caption3 then
                 PerkCondition.Remove;
          end;
  end;
end;

function wbPRKCToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  Container     : IwbContainerElementRef;
  EntryPointVar : Variant;
  EntryPoint    : Integer;
begin
  case aType of
    ctToStr: Result := IntToStr(aInt) + ' <Warning: Could not resolve Entry Point>';
    ctToEditValue: Result := IntToStr(aInt);
    ctToSortKey: begin
      Result := IntToHex64(aInt, 2);
      Exit;
    end;
    ctCheck: Result := '<Warning: Could not resolve Entry Point>';
    ctEditType: Result := '';
    ctEditInfo: Result := '';
  end;

  if not Supports(aElement, IwbContainerElementRef, Container) then
    Exit;
  EntryPointVar := Container.ElementNativeValues['..\..\..\DATA\Entry Point\Entry Point'];
  if VarIsNull(EntryPointVar) or VarIsClear(EntryPointVar) then
    Exit;
  EntryPoint := EntryPointVar;
  if (EntryPoint < Low(wbPERKEntryPoints)) or (EntryPoint > High(wbPERKEntryPoints)) then begin
    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: Unknown Entry Point #'+IntToStr(EntryPoint)+'>';
      ctCheck: Result := '<Warning: Unknown Entry Point #'+IntToStr(EntryPoint)+'>';
    end;
    Exit;
  end;

  with wbPERKEntryPoints[EntryPoint] do begin
    with wbPERKCondition[Condition] do begin
      case aType of
        ctEditType: Result := 'ComboBox';
        ctEditInfo: with TStringList.Create do try
          if Caption1 <> '' then
            Add(Caption1);
          if Caption2 <> '' then
            Add(Caption2);
          if Caption3 <> '' then
            Add(Caption3);
          Sort;
          Result := CommaText;
        finally
          Free;
        end;
      else
        if (aInt < 0) or (aInt >= Count) then
          case aType of
            ctToStr: Result := IntToStr(aInt) + ' <Warning: Value out of Bounds for this Entry Point>';
            ctCheck: Result := '<Warning: Value out of Bounds for this Entry Point>';
          end
        else
          case aType of
            ctToStr, ctToEditValue: case Integer(aInt) of
              0: Result := Caption1;
              1: Result := Caption2;
              2: Result := Caption3;
            end;
            ctCheck: Result := '';
          end;
      end;
    end;
  end;
end;

function wbPRKCToInt(const aString: string; const aElement: IwbElement): Int64;
var
  Container     : IwbContainerElementRef;
  EntryPointVar : Variant;
  EntryPoint    : Integer;
  s             : string;
begin
  s := Trim(aString);

  Result := StrToInt64Def(s, Low(Integer));
  if Result <> Low(Integer) then
    Exit;
  if s = '' then begin
    Result := 0;
    Exit;
  end;

  if not Supports(aElement, IwbContainerElementRef, Container) then
    raise Exception.Create('Could not resolve Entry Point');
  EntryPointVar := Container.ElementNativeValues['..\..\..\DATA\Entry Point\Entry Point'];
  if VarIsNull(EntryPointVar) or VarIsClear(EntryPointVar) then
    raise Exception.Create('Could not resolve Entry Point');

  EntryPoint := EntryPointVar;
  if (EntryPoint < Low(wbPERKEntryPoints)) or (EntryPoint > High(wbPERKEntryPoints)) then
    raise Exception.Create('Unknown Entry Point #'+IntToStr(EntryPoint));

  with wbPERKEntryPoints[EntryPoint] do
    with wbPERKCondition[Condition] do
      if SameText(aString, Caption1) then
        Result := 0
      else if SameText(aString, Caption2) then
        Result := 1
      else if SameText(aString, Caption3) then
        Result := 2
      else
        raise Exception.Create('"'+s+'" is not valid for this Entry Point');
end;

function wbNeverShow(const aElement: IwbElement): Boolean;
begin
  Result := wbHideNeverShow;
end;

function GetREGNType(aElement: IwbElement): Integer;
var
  Container: IwbContainerElementRef;
begin
  Result := -1;
  if not Assigned(aElement) then
    Exit;
  while aElement.Name <> 'Region Data Entry' do begin
    aElement := aElement.Container;
    if not Assigned(aElement) then
      Exit;
  end;
  if not Supports(aElement, IwbContainerElementRef, Container) then
    Exit;
  Result := Container.ElementNativeValues['RDAT\Type'];
end;

function wbREGNObjectsDontShow(const aElement: IwbElement): Boolean;
begin
  Result := GetREGNType(aElement) <> 2;
end;

function wbREGNWeatherDontShow(const aElement: IwbElement): Boolean;
begin
  Result := GetREGNType(aElement) <> 3;
end;

function wbREGNMapDontShow(const aElement: IwbElement): Boolean;
begin
  Result := GetREGNType(aElement) <> 4;
end;

function wbREGNLandDontShow(const aElement: IwbElement): Boolean;
begin
  Result := GetREGNType(aElement) <> 5;
end;

function wbREGNGrassDontShow(const aElement: IwbElement): Boolean;
begin
  Result := GetREGNType(aElement) <> 6;
end;

function wbREGNSoundDontShow(const aElement: IwbElement): Boolean;
begin
  Result := GetREGNType(aElement) <> 7;
end;

function wbREGNImposterDontShow(const aElement: IwbElement): Boolean;
begin
  Result := GetREGNType(aElement) <> 8;
end;

function wbMESGTNAMDontShow(const aElement: IwbElement): Boolean;
var
  Container  : IwbContainerElementRef;
  MainRecord : IwbMainRecord;
begin
  Result := False;
  if not Supports(aElement, IwbMainRecord, MainRecord) then
    Exit;
  if not Supports(aElement, IwbContainerElementRef, Container) then
    Exit;
  if Integer(Container.ElementNativeValues['DNAM']) and 1 <> 0 then
    Result := True;
end;

function wbEPFDDontShow(const aElement: IwbElement): Boolean;
var
  Container: IwbContainerElementRef;
begin
  Result := False;
  if aElement.Name <> 'Entry Point Function Parameters' then
    Exit;
  if not Supports(aElement, IwbContainerElementRef, Container) then
    Exit;
  if not (Integer(Container.ElementNativeValues['EPFT']) in [1..3]) then
    Result := True;
end;

function wbTES4ONAMDontShow(const aElement: IwbElement): Boolean;
var
  MainRecord : IwbMainRecord;
begin
  Result := False;
  if not Assigned(aElement) then
    Exit;
  MainRecord := aElement.ContainingMainRecord;
  if not Assigned(MainRecord) then
    Exit;
  if not MainRecord.IsESM then
    Result := True;
end;


function wbEPF2DontShow(const aElement: IwbElement): Boolean;
var
  Container: IwbContainerElementRef;
begin
  Result := False;
  if aElement.Name <> 'Entry Point Function Parameters' then
    Exit;
  if not Supports(aElement, IwbContainerElementRef, Container) then
    Exit;
  if not (Integer(Container.ElementNativeValues['EPFT']) in [4]) then
    Result := True;
end;

function wbPERKPRKCDontShow(const aElement: IwbElement): Boolean;
var
  Container: IwbContainerElementRef;
begin
  Result := False;
  if aElement.Name <> 'Effect' then
    Exit;
  if not Supports(aElement, IwbContainerElementRef, Container) then
    Exit;
  if Integer(Container.ElementNativeValues['PRKE\Type']) <> 2 then
    Result := True;
end;

function wbPerkDATAFunctionToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  Container     : IwbContainerElementRef;
  EntryPointVar : Variant;
  EntryPoint    : Integer;
  i             : Integer;
begin
  case aType of
    ctToStr: Result := IntToStr(aInt) + ' <Warning: Could not resolve Entry Point>';
    ctToEditValue: Result := IntToStr(aInt);
    ctToSortKey: begin
      Result := IntToHex64(aInt, 2);
      Exit;
    end;
    ctCheck: Result := '<Warning: Could not resolve Entry Point>';
    ctEditType: Result := '';
    ctEditInfo: Result := '';
  end;

  if not Supports(aElement, IwbContainerElementRef, Container) then
    Exit;
  EntryPointVar := Container.ElementNativeValues['..\Entry Point'];
  if VarIsNull(EntryPointVar) or VarIsClear(EntryPointVar) then
    Exit;
  EntryPoint := EntryPointVar;
  if (EntryPoint < Low(wbPERKEntryPoints)) or (EntryPoint > High(wbPERKEntryPoints)) then begin
    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: Unknown Entry Point #'+IntToStr(EntryPoint)+'>';
      ctCheck: Result := '<Warning: Unknown Entry Point #'+IntToStr(EntryPoint)+'>';
    end;
    Exit;
  end;

  with wbPERKEntryPoints[EntryPoint] do begin
    case aType of
      ctEditType: Result := 'ComboBox';
      ctEditInfo: with TStringList.Create do try
        for i := Low(wbPERKFunctions) to High(wbPERKFunctions) do
          if wbPERKFunctions[i].FunctionType = FunctionType then
            if (wbPERKFunctionNames[FunctionTable, i] <> '') then
              Add(wbPERKFunctionNames[FunctionTable, i]);
        Sort;
        Result := CommaText;
      finally
        Free;
      end;
    else
      if (aInt < Low(wbPERKFunctions)) or (aInt > High(wbPERKFunctions)) then
        case aType of
          ctToStr: Result := IntToStr(aInt) + ' <Warning: Unknown Function>';
          ctCheck: Result := '<Warning: Unknown Function>';
        end
      else
        case aType of
          ctToStr, ctToEditValue: begin
            Result := wbPERKFunctionNames[FunctionTable, Integer(aInt)];
            if (aType = ctToStr) and (wbPERKFunctions[Integer(aInt)].FunctionType <> FunctionType) then
              Result := Result + ' <Warning: Value out of Bounds for this Entry Point>';
          end;
          ctCheck:
            if wbPERKFunctions[Integer(aInt)].FunctionType <> FunctionType then
              Result := '<Warning: Value out of Bounds for this Entry Point>'
            else
              Result := '';
        end;
    end;
  end;
end;

function wbPerkDATAFunctionToInt(const aString: string; const aElement: IwbElement): Int64;
var
  Container     : IwbContainerElementRef;
  EntryPointVar : Variant;
  EntryPoint    : Integer;
  s             : string;
  i             : Integer;
begin
  s := Trim(aString);

  Result := StrToInt64Def(s, Low(Integer));
  if Result <> Low(Integer) then
    Exit;
  if s = '' then
    raise Exception.Create('"" is not a valid value for this field');

  if not Supports(aElement, IwbContainerElementRef, Container) then
    raise Exception.Create('Could not resolve Entry Point');
  EntryPointVar := Container.ElementNativeValues['..\Entry Point'];
  if VarIsNull(EntryPointVar) or VarIsClear(EntryPointVar) then
    raise Exception.Create('Could not resolve Entry Point');

  EntryPoint := EntryPointVar;
  if (EntryPoint < Low(wbPERKEntryPoints)) or (EntryPoint > High(wbPERKEntryPoints)) then
    raise Exception.Create('Unknown Entry Point #'+IntToStr(EntryPoint));

  with wbPERKEntryPoints[EntryPoint] do
    for i := Low(wbPERKFunctions) to High(wbPERKFunctions) do
      if wbPERKFunctions[i].FunctionType = FunctionType then
        if SameText(s, wbPERKFunctionNames[FunctionTable,i]) then begin
          Result := i;
          Exit;
        end;

  raise Exception.Create('"'+s+'" is not valid for this Entry Point');
end;

procedure wbPerkDATAFunctionAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  NewFunction : Integer;
  Container   : IwbContainerElementRef;
  OldParamType: Integer;
  NewParamType: Integer;
begin
  NewFunction := aNewValue;
  if (NewFunction < Low(wbPERKFunctions)) or (NewFunction > High(wbPERKFunctions)) then
    Exit;
  if not Supports(aElement, IwbContainerElementRef, Container) then
    Exit;
  OldParamType := Container.ElementNativeValues['..\..\..\Entry Point Function Parameters\EPFT'];
  NewParamType := Ord(wbPERKFunctions[NewFunction].ParamType);
  if (OldParamType = NewParamType) and not VarSameValue(aOldValue, aNewValue) and (NewFunction in [4,5]) then
    Container.ElementNativeValues['..\..\..\Entry Point Function Parameters\EPFT'] := 0;
  Container.ElementNativeValues['..\..\..\Entry Point Function Parameters\EPFT'] := NewParamType;
end;

function wbPerkEPFTToStr(var gameProperties: TGameProperties; aInt: Int64; const aElement: IwbElement; aType: TwbCallbackType): string;
var
  Container       : IwbContainerElementRef;
  FunctionTypeVar : Variant;
  FunctionType    : Integer;
//  i               : Integer;
begin
  case aType of
    ctToStr: Result := IntToStr(aInt) + ' <Warning: Could not resolve Function>';
    ctToEditValue: Result := IntToStr(aInt);
    ctToSortKey: begin
      Result := IntToHex64(aInt, 2);
      Exit;
    end;
    ctCheck: Result := '<Warning: Could not resolve Function>';
    ctEditType: Result := '';
    ctEditInfo: Result := '';
  end;

  if not Supports(aElement, IwbContainerElementRef, Container) then
    Exit;
  FunctionTypeVar := Container.ElementNativeValues['..\..\DATA\Entry Point\Function'];
  if VarIsNull(FunctionTypeVar) or VarIsClear(FunctionTypeVar) then
    Exit;
  FunctionType := FunctionTypeVar;
  if (FunctionType < Low(wbPERKFunctions)) or (FunctionType > High(wbPERKFunctions)) then begin
    case aType of
      ctToStr: Result := IntToStr(aInt) + ' <Warning: Unknown Function #'+IntToStr(FunctionType)+'>';
      ctCheck: Result := '<Warning: Unknown Function #'+IntToStr(FunctionType)+'>';
    end;
    Exit;
  end;

  with wbPERKFunctions[FunctionType] do begin
    case aType of
      ctEditType: Result := 'ComboBox';
      ctEditInfo: Result := '"' + wbPERKFunctionParams[ParamType] + '"';
    else
      if (aInt < Ord(Low(wbPERKFunctionParams))) or (aInt > Ord(High(wbPERKFunctionParams))) then
        case aType of
          ctToStr: Result := IntToStr(aInt) + ' <Warning: Unknown Function Param Type>';
          ctCheck: Result := '<Warning: Unknown Function Param Type>';
        end
      else
        case aType of
          ctToStr, ctToEditValue: begin
            Result := wbPERKFunctionParams[TPERKEntryPointFunctionParamType(aInt)];
            if (aType = ctToStr) and (TPERKEntryPointFunctionParamType(aInt) <> ParamType) then
              Result := Result + ' <Warning: Value out of Bounds for this Function>';
          end;
          ctCheck:
            if TPERKEntryPointFunctionParamType(aInt) <> ParamType then
              Result := Result + ' <Warning: Value out of Bounds for this Function>'
            else
              Result := '';
        end;
    end;
  end;
end;

function wbPerkEPFTToInt(const aString: string; const aElement: IwbElement): Int64;
var
  Container       : IwbContainerElementRef;
  FunctionTypeVar : Variant;
  FunctionType    : Integer;
  s               : string;
//  i               : Integer;
  j               : TPERKEntryPointFunctionParamType;
begin
  s := Trim(aString);

  Result := StrToInt64Def(s, Low(Integer));
  if Result <> Low(Integer) then
    Exit;
  if s = '' then
    raise Exception.Create('"" is not a valid value for this field');

  if not Supports(aElement, IwbContainerElementRef, Container) then
    raise Exception.Create('Could not resolve Function');
  FunctionTypeVar := Container.ElementNativeValues['..\..\DATA\Entry Point\Function'];
  if VarIsNull(FunctionTypeVar) or VarIsClear(FunctionTypeVar) then
    raise Exception.Create('Could not resolve Function');

  FunctionType := FunctionTypeVar;
  if (FunctionType < Low(wbPERKFunctions)) or (FunctionType > High(wbPERKFunctions)) then
    raise Exception.Create('Unknown Function #'+IntToStr(FunctionType));

  with wbPERKFunctions[FunctionType] do begin
    for j := Low(wbPERKFunctionParams) to High(wbPERKFunctionParams) do
      if SameText(s, wbPERKFunctionParams[j]) then begin
        if j <> ParamType then
          raise Exception.Create('"'+s+'" is not a valid Parameter Type for Function "'+Name+'"');
        Result := Ord(j);
        Exit;
      end;
  end;

  raise Exception.Create('"'+s+'" is not a valid Parameter Type');
end;

procedure wbPerkEPFTAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  i: Integer;
  Container: IwbContainerElementRef;
begin
  if VarSameValue(aOldValue, aNewValue) then
    Exit;
  i := aNewValue;
  if (i < Ord(Low(wbPERKFunctionParams))) or (i> Ord(High(wbPERKFunctionParams))) then
    Exit;
  if not Supports(aElement.Container, IwbContainerElementRef, Container) then
    Exit;
  Container.RemoveElement('EPFD');
  Container.RemoveElement('EPF2');
  Container.RemoveElement('EPF3');
  Container.RemoveElement('Embedded Script');
  case TPERKEntryPointFunctionParamType(i) of
    epfpFloat, epfpFloatFloat, epfpLeveledItem:
      Container.Add('EPFD', True);
    epfpScript: begin
      Container.Add('EPF2', True);
      Container.Add('EPF3', True);
      Container.Add('SCHR', True);
    end;
  end;
end;

procedure wbRemoveOFST(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container: IwbContainer;
  rOFST: IwbRecord;
begin
  if not wbRemoveOffsetData then
    Exit;

  if Supports(aElement, IwbContainer, Container) then begin
    if wbBeginInternalEdit then try
      Container.RemoveElement(OFST);
    finally
      wbEndInternalEdit;
    end else begin
      rOFST := Container.RecordBySignature[OFST];
      if Assigned(rOFST) then
        Container.RemoveElement(rOFST);
    end;
  end;
end;

function wbActorTemplateUseTraits(const aElement: IwbElement): Boolean;
var
  Element    : IwbElement;
  MainRecord : IwbMainRecord;
  i          : Int64;
begin
  Result := False;
  if not wbActorTemplateHide then Exit;
  Element := GetElementFromUnion(aElement);
  MainRecord := nil;
  while Assigned(Element) and not Supports(Element, IwbMainRecord, MainRecord) do
    Element := Element.Container;
  if Assigned(MainRecord) then begin
    i := MainRecord.ElementNativeValues['ACBS\Template Flags'];
    Result := (i and $00000001) <> 0;
  end;
end;

function wbActorTemplateUseStats(const aElement: IwbElement): Boolean;
var
  Element    : IwbElement;
  MainRecord : IwbMainRecord;
  i          : Int64;
begin
  Result := False;
  if not wbActorTemplateHide then Exit;
  Element := GetElementFromUnion(aElement);
  MainRecord := nil;
  while Assigned(Element) and not Supports(Element, IwbMainRecord, MainRecord) do
    Element := Element.Container;
  if Assigned(MainRecord) then begin
    i := MainRecord.ElementNativeValues['ACBS\Template Flags'];
    Result := (i and $00000002) <> 0;
  end;
end;

function wbActorAutoCalcDontShow(const aElement: IwbElement): Boolean;
var
  Element    : IwbElement;
  MainRecord : IwbMainRecord;
  i          : Int64;
begin
  Result := False;
  if not wbActorTemplateHide then Exit;
  Element := GetElementFromUnion(aElement);
  MainRecord := nil;
  while Assigned(Element) and not Supports(Element, IwbMainRecord, MainRecord) do
    Element := Element.Container;
  if Assigned(MainRecord) then begin
    i := MainRecord.ElementNativeValues['ACBS\Flags'];
    Result := (i and $00000010) <> 0;
  end;
end;

function wbActorTemplateUseStatsAutoCalc(const aElement: IwbElement): Boolean;
begin
  if not wbActorTemplateHide then
    Result := False
  else
    Result := wbActorTemplateUseStats(aElement) or wbActorAutoCalcDontShow(aElement);
end;

function wbActorTemplateUseFactions(const aElement: IwbElement): Boolean;
var
  Element    : IwbElement;
  MainRecord : IwbMainRecord;
  i          : Int64;
begin
  Result := False;
  if not wbActorTemplateHide then Exit;
  Element := GetElementFromUnion(aElement);
  MainRecord := nil;
  while Assigned(Element) and not Supports(Element, IwbMainRecord, MainRecord) do
    Element := Element.Container;
  if Assigned(MainRecord) then begin
    i := MainRecord.ElementNativeValues['ACBS\Template Flags'];
    Result := (i and $00000004) <> 0;
  end;
end;

function wbActorTemplateUseActorEffectList(const aElement: IwbElement): Boolean;
var
  Element    : IwbElement;
  MainRecord : IwbMainRecord;
  i          : Int64;
begin
  Result := False;
  if not wbActorTemplateHide then Exit;
  Element := GetElementFromUnion(aElement);
  MainRecord := nil;
  while Assigned(Element) and not Supports(Element, IwbMainRecord, MainRecord) do
    Element := Element.Container;
  if Assigned(MainRecord) then begin
    i := MainRecord.ElementNativeValues['ACBS\Template Flags'];
    Result := (i and $00000008) <> 0;
  end;
end;

function wbActorTemplateUseAIData(const aElement: IwbElement): Boolean;
var
  Element    : IwbElement;
  MainRecord : IwbMainRecord;
  i          : Int64;
begin
  Result := False;
  if not wbActorTemplateHide then Exit;
  Element := GetElementFromUnion(aElement);
  MainRecord := nil;
  while Assigned(Element) and not Supports(Element, IwbMainRecord, MainRecord) do
    Element := Element.Container;
  if Assigned(MainRecord) then begin
    i := MainRecord.ElementNativeValues['ACBS\Template Flags'];
    Result := (i and $00000010) <> 0;
  end;
end;

function wbActorTemplateUseAIPackages(const aElement: IwbElement): Boolean;
var
  Element    : IwbElement;
  MainRecord : IwbMainRecord;
  i          : Int64;
begin
  Result := False;
  if not wbActorTemplateHide then Exit;
  Element := GetElementFromUnion(aElement);
  MainRecord := nil;
  while Assigned(Element) and not Supports(Element, IwbMainRecord, MainRecord) do
    Element := Element.Container;
  if Assigned(MainRecord) then begin
    i := MainRecord.ElementNativeValues['ACBS\Template Flags'];
    Result := (i and $00000020) <> 0;
  end;
end;

function wbActorTemplateUseModelAnimation(const aElement: IwbElement): Boolean;
var
  Element    : IwbElement;
  MainRecord : IwbMainRecord;
  i          : Int64;
begin
  Result := False;
  if not wbActorTemplateHide then Exit;
  Element := GetElementFromUnion(aElement);
  MainRecord := nil;
  while Assigned(Element) and not Supports(Element, IwbMainRecord, MainRecord) do
    Element := Element.Container;
  if Assigned(MainRecord) then begin
    i := MainRecord.ElementNativeValues['ACBS\Template Flags'];
    Result := (i and $00000040) <> 0;
  end;
end;

function wbActorTemplateUseBaseData(const aElement: IwbElement): Boolean;
var
  Element    : IwbElement;
  MainRecord : IwbMainRecord;
  i          : Int64;
begin
  Result := False;
  if not wbActorTemplateHide then Exit;
  Element := GetElementFromUnion(aElement);
  MainRecord := nil;
  while Assigned(Element) and not Supports(Element, IwbMainRecord, MainRecord) do
    Element := Element.Container;
  if Assigned(MainRecord) then begin
    i := MainRecord.ElementNativeValues['ACBS\Template Flags'];
    Result := (i and $00000080) <> 0;
  end;
end;

function wbActorTemplateUseInventory(const aElement: IwbElement): Boolean;
var
  Element    : IwbElement;
  MainRecord : IwbMainRecord;
  i          : Int64;
begin
  Result := False;
  if not wbActorTemplateHide then Exit;
  Element := GetElementFromUnion(aElement);
  MainRecord := nil;
  while Assigned(Element) and not Supports(Element, IwbMainRecord, MainRecord) do
    Element := Element.Container;
  if Assigned(MainRecord) then begin
    i := MainRecord.ElementNativeValues['ACBS\Template Flags'];
    Result := (i and $00000100) <> 0;
  end;
end;

function wbActorTemplateUseScript(const aElement: IwbElement): Boolean;
var
  Element    : IwbElement;
  MainRecord : IwbMainRecord;
  i          : Int64;
begin
  Result := False;
  if not wbActorTemplateHide then Exit;
  Element := GetElementFromUnion(aElement);
  MainRecord := nil;
  while Assigned(Element) and not Supports(Element, IwbMainRecord, MainRecord) do
    Element := Element.Container;
  if Assigned(MainRecord) then begin
    i := MainRecord.ElementNativeValues['ACBS\Template Flags'];
    Result := (i and $00000200) <> 0;
  end;
end;

procedure wbCTDAAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container  : IwbContainerElementRef;
  //Size       : Cardinal;
  TypeFlags  : Cardinal;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    TypeFlags := Container.ElementNativeValues['Type'];
    if (TypeFlags and $02) <> 0 then begin
      if Container.DataSize = 20 then
        Container.DataSize := 28;
      Container.ElementNativeValues['Type'] := TypeFlags and not $02;
      Container.ElementEditValues['Run On'] := 'Target';
    end;
  finally
    wbEndInternalEdit;
  end;
end;

procedure wbMGEFAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container     : IwbContainerElementRef;
  MainRecord    : IwbMainRecord;
  OldActorValue : Integer;
  NewActorValue : Integer;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    OldActorValue := Container.ElementNativeValues['DATA - Data\Actor Value'];
    NewActorValue := OldActorValue;
    case Integer(Container.ElementNativeValues['DATA - Data\Archtype']) of
      01, //Script
      02, //Dispel
      03, //Cure Disease
      13, //Light
      16, //Lock
      17, //Open
      18, //Bound Item
      19, //Summon Creature
      30, //Cure Paralysis
      31, //Cure Addiction
      32, //Cure Poison
      33, //Concussion
      35: //Limb Condition
        NewActorValue := -1;
      11: //Invisibility
        NewActorValue := 48; //Invisibility
      12: //Chameleon
        NewActorValue := 49; //Chameleon
      24: //Paralysis
        NewActorValue := 47; //Paralysis
      36: //Turbo
        NewActorValue := 51; //Turbo
    end;
    if OldActorValue <> NewActorValue then
      Container.ElementNativeValues['DATA - Data\Actor Value'] := NewActorValue;
  finally
    wbEndInternalEdit;
  end;
end;

procedure wbPACKAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container     : IwbContainerElementRef;
  MainRecord    : IwbMainRecord;
//  OldContainer  : IwbContainerElementRef;
  NewContainer  : IwbContainerElementRef;
//  NewContainer2 : IwbContainerElementRef;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    case Integer(Container.ElementNativeValues['PKDT - General\Type']) of
       0: begin {Find}
         Container.Add('PTDT');
       end;
       1: begin {Follow}
         Container.Add('PKFD');
       end;
       2: begin {Escort}
       end;
       3: begin {Eat}
         Container.Add('PTDT');
         Container.Add('PKED');
       end;
       4: begin {Sleep}
         if not Container.ElementExists['Locations'] then
           if Supports(Container.Add('Locations'), IwbContainerElementRef, NewContainer) then
             NewContainer.ElementEditValues['PLDT - Location 1\Type'] := 'Near editor location';
       end;
       5: begin {Wander}
       end;
       6: begin {Travel}
       end;
       7: begin {Accompany}
       end;
       8: begin {Use Item At}
       end;
       9: begin {Ambush}
       end;
      10: begin {Flee Not Combat}
      end;
      12: begin {Sandbox}
      end;
      13: begin {Patrol}
         if not Container.ElementExists['Locations'] then
           if Supports(Container.Add('Locations'), IwbContainerElementRef, NewContainer) then
             NewContainer.ElementEditValues['PLDT - Location 1\Type'] := 'Near linked reference';
        Container.Add('PKPT');
      end;
      14: begin {Guard}
      end;
      15: begin {Dialogue}
      end;
      16: begin {Use Weapon}
      end;
    end;

  finally
    wbEndInternalEdit;
  end;
end;

procedure wbNPCAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container  : IwbContainerElementRef;
  MainRecord : IwbMainRecord;
//  BaseRecord : IwbMainRecord;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    if Container.ElementNativeValues['NAM5'] > 255 then
      Container.ElementNativeValues['NAM5'] := 255;
  finally
    wbEndInternalEdit;
  end;
end;

procedure wbREFRAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container  : IwbContainerElementRef;
  MainRecord : IwbMainRecord;
  BaseRecord : IwbMainRecord;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    Container.RemoveElement('RCLR');

    if Container.ElementExists['Ammo'] then begin
      BaseRecord := MainRecord.BaseRecord;
      if Assigned(BaseRecord) and (BaseRecord.Signature <> 'WEAP') then
        Container.RemoveElement('Ammo');
    end;
  finally
    wbEndInternalEdit;
  end;
end;

procedure wbINFOAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container  : IwbContainerElementRef;
  MainRecord : IwbMainRecord;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    if (Integer(Container.ElementNativeValues['DATA\Flags 1']) and $80) = 0 then
      Container.RemoveElement('DNAM');

    Container.RemoveElement('SNDD');

    if Container.ElementNativeValues['DATA\Type'] = 3 {Persuasion} then
      Container.ElementNativeValues['DATA\Type'] := 0 {Topic};
  finally
    wbEndInternalEdit;
  end;
end;

procedure wbCELLAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container    : IwbContainerElementRef;
//  Container2   : IwbContainerElementRef;
  MainRecord   : IwbMainRecord;
//  i            : Integer;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    if (not Container.ElementExists['XCLW']) and ((Integer(Container.ElementNativeValues['DATA']) and $02) <> 0) then begin
      Container.Add('XCLW', True);
      Container.ElementEditValues['XCLW'] := 'Default';
    end;

    if (not Container.ElementExists['XNAM']) and ((Integer(Container.ElementNativeValues['DATA']) and $02) <> 0) then
      Container.Add('XNAM', True);

//    if Supports(Container.ElementBySignature[XCLR], IwbContainerElementRef, Container2) then begin
//      for i:= Pred(Container2.ElementCount) downto 0 do
//        if not Supports(Container2.Elements[i].LinksTo, IwbMainRecord, MainRecord) or (MainRecord.Signature <> 'REGN') then
//          Container2.RemoveElement(i);
//      if Container2.ElementCount < 1 then
//        Container2.Remove;
//    end;
  finally
    wbEndInternalEdit;
  end;
end;

procedure wbEmbeddedScriptAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container: IwbContainerElementRef;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if Container.ElementEditValues['SCHR\Type'] = 'Quest' then
      Container.ElementEditValues['SCHR\Type'] := 'Object';
  finally
    wbEndInternalEdit;
  end;
end;


procedure wbSOUNAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container: IwbContainerElementRef;
  MainRecord   : IwbMainRecord;
  OldCntr: IwbContainerElementRef;
  NewCntr: IwbContainerElementRef;
  NewCntr2: IwbContainerElementRef;
  i: Integer;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    if Container.ElementExists['SNDD'] then
      Exit;

    if not Supports(Container.RemoveElement('SNDX - Sound Data'), IwbContainerElementRef, OldCntr) then
      Exit;
    if not Supports(Container.Add('SNDD', True), IwbContainerElementRef, NewCntr) then
      Exit;
    for i := 0 to Pred(Min(OldCntr.ElementCount, NewCntr.ElementCount)) do
      NewCntr.Elements[i].Assign(Low(Integer), OldCntr.Elements[i], False);

    if not Supports(NewCntr.ElementByName['Attenuation Curve'], IwbContainerElementRef, NewCntr2) then
      Assert(False);
    Assert(NewCntr2.ElementCount = 5);

    if Supports(Container.RemoveElement('ANAM'), IwbContainerElementRef, OldCntr) then begin
      Assert(OldCntr.ElementCount = 5);
      for i := 0 to Pred(Min(OldCntr.ElementCount, NewCntr2.ElementCount)) do
        NewCntr2.Elements[i].Assign(Low(Integer), OldCntr.Elements[i], False);
    end else begin
      NewCntr2.Elements[0].NativeValue := 100;
      NewCntr2.Elements[1].NativeValue := 50;
      NewCntr2.Elements[2].NativeValue := 20;
      NewCntr2.Elements[3].NativeValue := 5;
      NewCntr2.Elements[4].NativeValue := 0;
    end;

    if not Supports(NewCntr.ElementByName['Reverb Attenuation Control'], IwbContainerElementRef, NewCntr2) then
      Assert(False);

    if Supports(Container.RemoveElement('GNAM'), IwbContainerElementRef, OldCntr) then
      NewCntr2.Assign(Low(Integer), OldCntr, False)
    else
      NewCntr2.NativeValue := 80;

    if not Supports(NewCntr.ElementByName['Priority'], IwbContainerElementRef, NewCntr2) then
      Assert(False);

    if Supports(Container.RemoveElement('HNAM'), IwbContainerElementRef, OldCntr) then
      NewCntr2.Assign(Low(Integer), OldCntr, False)
    else
      NewCntr2.NativeValue := 128;

  finally
    wbEndInternalEdit;
  end;
end;

procedure wbWATRAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container: IwbContainerElementRef;
  MainRecord   : IwbMainRecord;
//  AnimationMultiplier : Extended;
//  AnimationAttackMultiplier : Extended;
  OldCntr: IwbContainerElementRef;
  NewCntr: IwbContainerElementRef;
  i: Integer;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    if Container.ElementExists['DNAM'] then
      Exit;

    if not Supports(Container.RemoveElement('DATA - Visual Data'), IwbContainerElementRef, OldCntr) then
      Exit;
    if not Supports(Container.Add('DNAM', True), IwbContainerElementRef, NewCntr) then
      Exit;
    for i := 0 to Pred(Min(OldCntr.ElementCount, NewCntr.ElementCount)) do
      if OldCntr.Elements[i].Name = 'Damage (Old Format)' then
        Container.ElementNativeValues['DATA - Damage'] := OldCntr.Elements[i].NativeValue
      else
        NewCntr.Elements[i].Assign(Low(Integer), OldCntr.Elements[i], False);

    NewCntr.ElementNativeValues['Noise Properties - Noise Layer One - Amplitude Scale'] := 1.0;
    NewCntr.ElementNativeValues['Noise Properties - Noise Layer Two - Amplitude Scale'] := 0.5;
    NewCntr.ElementNativeValues['Noise Properties - Noise Layer Three - Amplitude Scale'] := 0.25;
  finally
    wbEndInternalEdit;
  end;
end;


procedure wbWEAPAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container: IwbContainerElementRef;
  MainRecord   : IwbMainRecord;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    if not Container.ElementExists['DNAM'] then
      Exit;

    if Container.ElementNativeValues['DNAM\Animation Multiplier'] = 0.0 then
      Container.ElementNativeValues['DNAM\Animation Multiplier'] := 1.0;
    if Container.ElementNativeValues['DNAM\Animation Attack Multiplier'] = 0.0 then
      Container.ElementNativeValues['DNAM\Animation Attack Multiplier'] := 1.0;
  finally
    wbEndInternalEdit;
  end;
end;

procedure wbMESGAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container    : IwbContainerElementRef;
  MainRecord   : IwbMainRecord;
  IsMessageBox : Boolean;
  HasTimeDelay : Boolean;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    IsMessageBox := (Integer(Container.ElementNativeValues['DNAM']) and 1) = 1;
    HasTimeDelay := Container.ElementExists['TNAM'];

    if IsMessageBox = HasTimeDelay then
      if IsMessageBox then
        Container.RemoveElement('TNAM')
      else begin
        if not Container.ElementExists['DNAM'] then
          Container.Add('DNAM', True);
        Container.ElementNativeValues['DNAM'] := Integer(Container.ElementNativeValues['DNAM']) or 1;
      end;

  finally
    wbEndInternalEdit;
  end;
end;


procedure wbEFSHAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container: IwbContainerElementRef;
  MainRecord   : IwbMainRecord;
  FullParticleBirthRatio : Extended;
  PersistantParticleBirthRatio : Extended;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    if not Container.ElementExists['DATA'] then
      Exit;

    FullParticleBirthRatio := Container.ElementNativeValues['DATA\Particle Shader - Full Particle Birth Ratio'];
    PersistantParticleBirthRatio := Container.ElementNativeValues['DATA\Particle Shader - Persistant Particle Birth Ratio'];

    if ((FullParticleBirthRatio <> 0) and (FullParticleBirthRatio <= 1)) then begin
      FullParticleBirthRatio := FullParticleBirthRatio * 78.0;
      Container.ElementNativeValues['DATA\Particle Shader - Full Particle Birth Ratio'] := FullParticleBirthRatio;
    end;

    if ((PersistantParticleBirthRatio <> 0) and (PersistantParticleBirthRatio <= 1)) then begin
      PersistantParticleBirthRatio := PersistantParticleBirthRatio * 78.0;
      Container.ElementNativeValues['DATA\Particle Shader - Persistant Particle Birth Ratio'] := PersistantParticleBirthRatio;
    end;

  finally
    wbEndInternalEdit;
  end;
end;

procedure wbFACTAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container: IwbContainerElementRef;
  MainRecord   : IwbMainRecord;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Container.ElementExists['CNAM'] then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    Container.RemoveElement('CNAM');
  finally
    wbEndInternalEdit;
  end;
end;

procedure wbLIGHAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container: IwbContainerElementRef;
  MainRecord   : IwbMainRecord;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    if not Supports(aElement, IwbMainRecord, MainRecord) then
      Exit;

    if MainRecord.IsDeleted then
      Exit;

    if not Container.ElementExists['FNAM'] then begin
      Container.Add('FNAM', True);
      Container.ElementNativeValues['FNAM'] := 1.0;
    end;

    if Container.ElementExists['DATA'] then begin
      if SameValue(Container.ElementNativeValues['DATA\Falloff Exponent'], 0.0) then
        Container.ElementNativeValues['DATA\Falloff Exponent'] := 1.0;
      if SameValue(Container.ElementNativeValues['DATA\FOV'], 0.0) then
        Container.ElementNativeValues['DATA\FOV'] := 90.0;
    end;

  finally
    wbEndInternalEdit;
  end;
end;

procedure wbEFITAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container : IwbContainerElementRef;
  Element   : IwbElement;
  ActorValue: Variant;
  MainRecord: IwbMainRecord;
begin
  if wbBeginInternalEdit then try
    if not Supports(aElement, IwbContainerElementRef, Container) then
      Exit;

    if Container.ElementCount < 1 then
      Exit;

    MainRecord := Container.ContainingMainRecord;
    if not Assigned(MainRecord) or MainRecord.IsDeleted then
      Exit;

    Element := Container.ElementByPath['..\EFID'];
    if not Assigned(Element) then
      Exit;
    if not Supports(Element.LinksTo, IwbMainRecord, MainRecord) then
      Exit;
    if MainRecord.Signature <> 'MGEF' then
      Exit;
    ActorValue := MainRecord.ElementNativeValues['DATA - Data\Actor Value'];
    if VarIsNull(ActorValue) or VarIsClear(ActorValue) then
      Exit;
    if VarCompareValue(ActorValue, Container.ElementNativeValues['Actor Value']) <> vrEqual then
      Container.ElementNativeValues['Actor Value'] := ActorValue;
  finally
    wbEndInternalEdit;
  end;
end;

procedure wbRPLDAfterLoad(var gameProperties: TGameProperties; const aElement: IwbElement);
var
  Container: IwbContainer;
  a, b: Single;
  NeedsFlip: Boolean;
begin
  if wbBeginInternalEdit then try
    if Supports(aElement, IwbContainer, Container) then begin
      NeedsFlip := False;
      if Container.ElementCount > 1 then begin
        a := StrToFloat((Container.Elements[0] as IwbContainer).Elements[0].Value);
        b := StrToFloat((Container.Elements[Pred(Container.ElementCount)] as IwbContainer).Elements[0].Value);
        case CompareValue(a, b) of
          EqualsValue: begin
            a := StrToFloat((Container.Elements[0] as IwbContainer).Elements[1].Value);
            b := StrToFloat((Container.Elements[Pred(Container.ElementCount)] as IwbContainer).Elements[1].Value);
            NeedsFlip := CompareValue(a, b) = GreaterThanValue;
          end;
          GreaterThanValue:
            NeedsFlip := True;
        end;
      end;
      if NeedsFlip then
        Container.ReverseElements;
    end;
  finally
    wbEndInternalEdit;
  end;
end;

function wbPxDTLocationDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container: IwbContainer;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;
  Result := Container.ElementByName['Type'].NativeValue;
end;

function wbPKDTFalloutBehaviorFlagsDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container : IwbContainer;
  SubRecord : IwbSubRecord;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;
  if Supports(Container, IwbSubRecord, SubRecord) then
    if SubRecord.SubRecordHeaderSize = 8 then
      Result := 1;
end;

function wbPKDTSpecificFlagsDecider(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Integer;
var
  Container : IwbContainer;
  SubRecord : IwbSubRecord;
begin
  Result := 0;
  if not Assigned(aElement) then Exit;
  Container := GetContainerFromUnion(aElement);
  if not Assigned(Container) then Exit;
  if Supports(Container, IwbSubRecord, SubRecord) then
    if SubRecord.SubRecordHeaderSize = 8 then
      Exit;
  Result := Container.ElementByName['Type'].NativeValue + 1;
end;

procedure wbIDLAsAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  Element         : IwbElement;
  Container       : IwbContainer;
  SelfAsContainer : IwbContainer;
begin
  if wbBeginInternalEdit then try
//    if not wbCounterAfterSet('IDLC - Animation Count', aElement) then
      if Supports(aElement.Container, IwbContainer, Container) then begin
        Element := Container.ElementByPath['IDLC\Animation Count'];
        if Assigned(Element) and Supports(aElement, IwbContainer, SelfAsContainer) and
          (Element.GetNativeValue<>SelfAsContainer.GetElementCount) then
          Element.SetNativeValue(SelfAsContainer.GetElementCount);
      end;
  finally
    wbEndInternalEdit;
  end;
end;

procedure wbAnimationsAfterSet(var gameProperties: TGameProperties; const aElement: IwbElement; const aOldValue, aNewValue: Variant);
var
  Element         : IwbElement;
  Elems           : IwbElement;
  Container       : IwbContainer;
begin
  if wbBeginInternalEdit then try
//    if not wbCounterContainerAfterSet('IDLC - Animation Count', 'IDLA - Animations', aElement) then
      if Supports(aElement, IwbContainer, Container) then begin
        Element := Container.ElementByPath['IDLC\Animation Count'];
        Elems   := Container.ElementByName['IDLA - Animations'];
        if Assigned(Element) and not Assigned(Elems) then
          if Element.GetNativeValue<>0 then
            Element.SetNativeValue(0);
      end;
  finally
    wbEndInternalEdit;
  end;
end;

function wbOffsetDataColsCounter(aBasePtr: Pointer; aEndPtr: Pointer; const aElement: IwbElement): Cardinal;
var
  Container : IwbDataContainer;
  Element   : IwbElement;
  fResult   : Extended;
begin
  Result := 0;

  if Supports(aElement.Container, IwbDataContainer, Container) and (Container.Name = 'OFST - Offset Data') and
     Supports(Container.Container, IwbDataContainer, Container) then begin
    Element := Container.ElementByPath['Object Bounds\NAM0 - Min\X'];
    if Assigned(Element) then begin
      fResult :=  Element.NativeValue;
      if fResult >= MaxInt then
        Result := 0
      else
        Result := Trunc(fResult);
      Element := Container.ElementByPath['Object Bounds\NAM9 - Max\X'];
      if Assigned(Element) then begin
        fResult :=  Element.NativeValue;
        if fResult >= MaxInt then
          Result := 1
        else
          Result := Trunc(fResult) - Result + 1;
      end;
    end;
  end;
end;

procedure DefineFNVa(var gameProperties: TGameProperties);
begin
  wbRecordFlags := wbInteger(gameProperties, 'Record Flags', itU32, wbFlags(gameProperties, [
    {0x00000001}'ESM',
    {0x00000002}'',
    {0x00000004}'',   // Plugin selected (Editor)
    {0x00000008}'Form initialized (Runtime only)',   // Form cannot be saved (Runtime)/Plugin active (Editor)
    {0x00000010}'',  // Plugin cannot be active or selected (Editor)
    {0x00000020}'Deleted',
    {0x00000040}'Border Region / Has Tree LOD / Constant / Hidden From Local Map / Plugin Endian',
    {0x00000080}'Turn Off Fire',
    {0x00000100}'Inaccessible',
    {0x00000200}'Casts shadows / On Local Map / Motion Blur',
    {0x00000400}'Quest item / Persistent reference',
    {0x00000800}'Initially disabled',
    {0x00001000}'Ignored',
    {0x00002000}'No Voice Filter',
    {0x00004000}'Cannot Save (Runtime only)',
    {0x00008000}'Visible when distant',
    {0x00010000}'Random Anim Start / High Priority LOD',
    {0x00020000}'Dangerous / Off limits (Interior cell) / Radio Station (Talking Activator)',
    {0x00040000}'Compressed',
    {0x00080000}'Can''t wait / Platform Specific Texture / Dead',
    {0x00100000}'Unknown 21',
    {0x00200000}'Load Started (Runtime Only)', // set when beginning to load the form from save
    {0x00400000}'Unknown 23',
    {0x00800000}'Unknown 24',   // Runtime might use it for "Not dead" on non actors.
    {0x01000000}'Destructible (Runtime only)',
    {0x02000000}'Obstacle / No AI Acquire',
    {0x03000000}'NavMesh Generation - Filter',
    {0x08000000}'NavMesh Generation - Bounding Box',
    {0x10000000}'Non-Pipboy / Reflected by Auto Water',
    {0x20000000}'Child Can Use / Refracted by Auto Water',
    {0x40000000}'NavMesh Generation - Ground',
    {0x80000000}'Multibound'
  ]));

(*   wbInteger('Record Flags 2', itU32, wbFlags(gameProperties, [
    {0x00000001}'Unknown 1',
    {0x00000002}'Unknown 2',
    {0x00000004}'Unknown 3',
    {0x00000008}'Unknown 4',
    {0x00000010}'Unknown 5',
    {0x00000020}'Unknown 6',
    {0x00000040}'Unknown 7',
    {0x00000080}'Unknown 8',
    {0x00000100}'Unknown 9',
    {0x00000200}'Unknown 10',
    {0x00000400}'Unknown 11',
    {0x00000800}'Unknown 12',
    {0x00001000}'Unknown 13',
    {0x00002000}'Unknown 14',
    {0x00004000}'Unknown 15',
    {0x00008000}'Unknown 16',
    {0x00010000}'Unknown 17',
    {0x00020000}'Unknown 18',
    {0x00040000}'Unknown 19',
    {0x00080000}'Unknown 20',
    {0x00100000}'Unknown 21',
    {0x00200000}'Unknown 22',
    {0x00400000}'Unknown 23',
    {0x00800000}'Unknown 24',
    {0x01000000}'Unknown 25',
    {0x02000000}'Unknown 26',
    {0x03000000}'Unknown 27',
    {0x08000000}'Unknown 28',
    {0x10000000}'Unknown 29',
    {0x20000000}'Unknown 30',
    {0x40000000}'Unknown 31',
    {0x80000000}'Unknown 32'
  ]));                (**)

  wbMainRecordHeader := wbStruct(gameProperties, 'Record Header', [
    wbString(gameProperties, 'Signature', 4, cpCritical),
    wbInteger(gameProperties, 'Data Size', itU32, nil, cpIgnore),
    wbRecordFlags,
    wbFormID(gameProperties, 'FormID', cpFormID),
    wbByteArray(gameProperties, 'Version Control Info 1', 4, cpIgnore).SetToStr(wbVCI1ToStrBeforeFO4),
    wbInteger(gameProperties, 'Form Version', itU16, nil, cpIgnore),
    wbByteArray(gameProperties, 'Version Control Info 2', 2, cpIgnore)
  ]);

  wbSizeOfMainRecordStruct := 24;

  wbIgnoreRecords.Add(XXXX);

  wbXRGD := wbByteArray(gameProperties, XRGD, 'Ragdoll Data');
  wbXRGB := wbByteArray(gameProperties, XRGB, 'Ragdoll Biped Data');

  wbMusicEnum := wbEnum(gameProperties, ['Default', 'Public', 'Dungeon']);
  wbSoundLevelEnum := wbEnum(gameProperties, [
     'Loud',
     'Normal',
     'Silent'
    ]);

  wbWeaponAnimTypeEnum := wbEnum(gameProperties, [
    {00} 'Hand to Hand',
    {01} 'Melee (1 Hand)',
    {02} 'Melee (2 Hand)',
    {03} 'Pistol - Balistic (1 Hand)',
    {04} 'Pistol - Energy (1 Hand)',
    {05} 'Rifle - Balistic (2 Hand)',
    {06} 'Rifle - Automatic (2 Hand)',
    {07} 'Rifle - Energy (2 Hand)',
    {08} 'Handle (2 Hand)',
    {09} 'Launcher (2 Hand)',
    {10} 'Grenade Throw (1 Hand)',
    {11} 'Land Mine (1 Hand)',
    {12} 'Mine Drop (1 Hand)',
    {13} 'Thrown (1 Hand)'
  ]);

  wbReloadAnimEnum := wbEnum(gameProperties, [
    'ReloadA',
    'ReloadB',
    'ReloadC',
    'ReloadD',
    'ReloadE',
    'ReloadF',
    'ReloadG',
    'ReloadH',
    'ReloadI',
    'ReloadJ',
    'ReloadK',
    'ReloadL',
    'ReloadM',
    'ReloadN',
    'ReloadO',
    'ReloadP',
    'ReloadQ',
    'ReloadR',
    'ReloadS',
//    'ReloadT',
//    'ReloadU',
//    'ReloadV',
    'ReloadW',
    'ReloadX',
    'ReloadY',
    'ReloadZ'
  ],[255, 'None']);   // 255 seen in DLC, though Geck converts to 0

  wbEDID := wbString(gameProperties, EDID, 'Editor ID', 0, cpNormal); // not cpBenign according to Arthmoor
  wbEDIDReq := wbString(gameProperties, EDID, 'Editor ID', 0, cpNormal, True); // not cpBenign according to Arthmoor
  wbEDIDReqKC := wbStringKC(gameProperties, EDID, 'Editor ID', 0, cpNormal, True); // not cpBenign according to Arthmoor
  wbFULL := wbStringKC(gameProperties, FULL, 'Name', 0, cpTranslate);
  wbFULLActor := wbStringKC(gameProperties, FULL, 'Name', 0, cpTranslate, False, wbActorTemplateUseBaseData);
  wbFULLReq := wbStringKC(gameProperties, FULL, 'Name', 0, cpTranslate, True);
  wbDESC := wbStringKC(gameProperties, DESC, 'Description', 0, cpTranslate);
  wbDESCReq := wbStringKC(gameProperties, DESC, 'Description', 0, cpTranslate, True);
  wbXSCL := wbFloat(gameProperties, XSCL, 'Scale');
  wbOBND := wbStruct(gameProperties, OBND, 'Object Bounds', [
    wbInteger(gameProperties, 'X1', itS16),
    wbInteger(gameProperties, 'Y1', itS16),
    wbInteger(gameProperties, 'Z1', itS16),
    wbInteger(gameProperties, 'X2', itS16),
    wbInteger(gameProperties, 'Y2', itS16),
    wbInteger(gameProperties, 'Z2', itS16)
  ]);
  wbOBNDReq := wbStruct(gameProperties, OBND, 'Object Bounds', [
    wbInteger(gameProperties, 'X1', itS16),
    wbInteger(gameProperties, 'Y1', itS16),
    wbInteger(gameProperties, 'Z1', itS16),
    wbInteger(gameProperties, 'X2', itS16),
    wbInteger(gameProperties, 'Y2', itS16),
    wbInteger(gameProperties, 'Z2', itS16)
  ], cpNormal, True);
  wbREPL := wbFormIDCkNoReach(gameProperties, REPL, 'Repair List', [FLST]);
  wbEITM := wbFormIDCk(gameProperties, EITM, 'Object Effect', [ENCH, SPEL]);
  wbBIPL := wbFormIDCk(gameProperties, BIPL, 'Biped Model List', [FLST]);
  wbCOED := wbStructExSK(gameProperties, COED, [2], [0, 1], 'Extra Data', [
    {00} wbFormIDCkNoReach(gameProperties, 'Owner', [NPC_, FACT, NULL]),
    {04} wbUnion(gameProperties, 'Global Variable / Required Rank', wbCOEDOwnerDecider, [
           wbByteArray(gameProperties, 'Unused', 4, cpIgnore),
           wbFormIDCk(gameProperties, 'Global Variable', [GLOB, NULL]),
           wbInteger(gameProperties, 'Required Rank', itS32)
         ]),
    {08} wbFloat(gameProperties, 'Item Condition')
  ]);

  wbYNAM := wbFormIDCk(gameProperties, YNAM, 'Sound - Pick Up', [SOUN]);
  wbZNAM := wbFormIDCk(gameProperties, ZNAM, 'Sound - Drop', [SOUN]);

  wbPosRot :=
    wbStruct(gameProperties, 'Position/Rotation', [
      wbStruct(gameProperties, 'Position', [
        wbFloat(gameProperties, 'X'),
        wbFloat(gameProperties, 'Y'),
        wbFloat(gameProperties, 'Z')
      ]),
      wbStruct(gameProperties, 'Rotation', [
        wbFloat(gameProperties, 'X', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize),
        wbFloat(gameProperties, 'Y', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize),
        wbFloat(gameProperties, 'Z', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize)
      ])
    ]);

  wbDATAPosRot :=
    wbStruct(gameProperties, DATA, 'Position/Rotation', [
      wbStruct(gameProperties, 'Position', [
        wbFloat(gameProperties, 'X'),
        wbFloat(gameProperties, 'Y'),
        wbFloat(gameProperties, 'Z')
      ]),
      wbStruct(gameProperties, 'Rotation', [
        wbFloat(gameProperties, 'X', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize),
        wbFloat(gameProperties, 'Y', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize),
        wbFloat(gameProperties, 'Z', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize)
      ])
    ], cpNormal, True);

  wbMODS :=
    wbArrayS(gameProperties, MODS, 'Alternate Textures',
      wbStructSK(gameProperties, [0, 2], 'Alternate Texture', [
        wbLenString(gameProperties, '3D Name'),
        wbFormIDCk(gameProperties, 'New Texture', [TXST]),
        wbInteger(gameProperties, '3D Index', itS32)
      ]),
    -1);
  wbMO2S :=
    wbArrayS(gameProperties, MO2S, 'Alternate Textures',
      wbStructSK(gameProperties, [0, 2], 'Alternate Texture', [
        wbLenString(gameProperties, '3D Name'),
        wbFormIDCk(gameProperties, 'New Texture', [TXST]),
        wbInteger(gameProperties, '3D Index', itS32)
      ]),
    -1);
  wbMO3S :=
    wbArrayS(gameProperties, MO3S, 'Alternate Textures',
      wbStructSK(gameProperties, [0, 2], 'Alternate Texture', [
        wbLenString(gameProperties, '3D Name'),
        wbFormIDCk(gameProperties, 'New Texture', [TXST]),
        wbInteger(gameProperties, '3D Index', itS32)
      ]),
    -1);
  wbMO4S :=
    wbArrayS(gameProperties, MO4S, 'Alternate Textures',
      wbStructSK(gameProperties, [0, 2], 'Alternate Texture', [
        wbLenString(gameProperties, '3D Name'),
        wbFormIDCk(gameProperties, 'New Texture', [TXST]),
        wbInteger(gameProperties, '3D Index', itS32)
      ]),
    -1);

  wbMODD :=
    wbInteger(gameProperties, MODD, 'FaceGen Model Flags', itU8, wbFlags(gameProperties, [
      'Head',
      'Torso',
      'Right Hand',
      'Left Hand'
    ]));
  wbMOSD :=
    wbInteger(gameProperties, MOSD, 'FaceGen Model Flags', itU8, wbFlags(gameProperties, [
      'Head',
      'Torso',
      'Right Hand',
      'Left Hand'
    ]));

  wbMODT := wbByteArray(gameProperties, MODT, 'Texture Files Hashes', 0, cpIgnore);

  {wbMODT := wbStruct(MODT, 'Texture Files Hashes', [
    wbArray(gameProperties, 'Textures', wbStruct('Texture', [
      wbInteger(gameProperties, 'File', itU64, wbMODTCallback),
      wbByteArray(gameProperties, 'Unknown', 8),
      wbInteger(gameProperties, 'Folder', itU64, wbMODTCallback)
    ]))]
  );}

  wbMODL :=
    wbRStructSK(gameProperties, [0], 'Model', [
      wbString(gameProperties, MODL, 'Model FileName', 0, cpNormal, True),
      wbByteArray(gameProperties, MODB, 'Unknown', 4, cpIgnore),
      wbMODT,
      wbMODS,
      wbMODD
    ], [], cpNormal, False, nil, True);

  wbMODLActor :=
    wbRStructSK(gameProperties, [0], 'Model', [
      wbString(gameProperties, MODL, 'Model FileName', 0, cpNormal, True),
      wbByteArray(gameProperties, MODB, 'Unknown', 4, cpIgnore),
      wbMODT,
      wbMODS,
      wbMODD
    ], [], cpNormal, False, wbActorTemplateUseModelAnimation, True);

  wbMODLReq :=
    wbRStructSK(gameProperties, [0], 'Model', [
      wbString(gameProperties, MODL, 'Model FileName', 0, cpNormal, True),
      wbByteArray(gameProperties, MODB, 'Unknown', 4, cpIgnore),
      wbMODT,
      wbMODS,
      wbMODD
    ], [], cpNormal, True, nil, True);


  wbDEST := wbRStruct(gameProperties, 'Destructible', [
    wbStruct(gameProperties, DEST, 'Header', [
      wbInteger(gameProperties, 'Health', itS32),
      wbInteger(gameProperties, 'Count', itU8),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        'VATS Targetable'
      ], True)),
      wbByteArray(gameProperties, 'Unused', 2)
    ]),
    wbRArray(gameProperties, 'Stages',
      wbRStruct(gameProperties, 'Stage', [
        wbStruct(gameProperties, DSTD, 'Destruction Stage Data', [
          wbInteger(gameProperties, 'Health %', itU8),
          wbInteger(gameProperties, 'Index', itU8),
          wbInteger(gameProperties, 'Damage Stage', itU8),
          wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
            'Cap Damage',
            'Disable',
            'Destroy'
          ])),
          wbInteger(gameProperties, 'Self Damage per Second', itS32),
          wbFormIDCk(gameProperties, 'Explosion', [EXPL, NULL]),
          wbFormIDCk(gameProperties, 'Debris', [DEBR, NULL]),
          wbInteger(gameProperties, 'Debris Count', itS32)
        ], cpNormal, True),
        wbRStructSK(gameProperties, [0], 'Model', [
          wbString(gameProperties, DMDL, 'Model FileName'),
          wbByteArray(gameProperties, DMDT, 'Texture Files Hashes', 0, cpIgnore)
//          wbArray(gameProperties, DMDT, 'Unknown',
//            wbByteArray(gameProperties, 'Unknown', 24, cpBenign),
//          0, nil, nil, cpBenign)
        ], []),
        wbEmpty(gameProperties, DSTF, 'End Marker', cpNormal, True)
      ], [])
    )
  ], []);

  wbDESTActor := wbRStruct(gameProperties, 'Destructible', [
    wbStruct(gameProperties, DEST, 'Header', [
      wbInteger(gameProperties, 'Health', itS32),
      wbInteger(gameProperties, 'Count', itU8),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        'VATS Targetable'
      ])),
      wbByteArray(gameProperties, 'Unused', 2)
    ]),
    wbRArray(gameProperties, 'Stages',
      wbRStruct(gameProperties, 'Stage', [
        wbStruct(gameProperties, DSTD, 'Destruction Stage Data', [
          wbInteger(gameProperties, 'Health %', itU8),
          wbInteger(gameProperties, 'Index', itU8),
          wbInteger(gameProperties, 'Damage Stage', itU8),
          wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
            'Cap Damage',
            'Disable',
            'Destroy'
          ])),
          wbInteger(gameProperties, 'Self Damage per Second', itS32),
          wbFormIDCk(gameProperties, 'Explosion', [EXPL, NULL]),
          wbFormIDCk(gameProperties, 'Debris', [DEBR, NULL]),
          wbInteger(gameProperties, 'Debris Count', itS32)
        ], cpNormal, True),
        wbRStructSK(gameProperties, [0], 'Model', [
          wbString(gameProperties, DMDL, 'Model FileName'),
          wbByteArray(gameProperties, DMDT, 'Texture Files Hashes', 0, cpIgnore)
//          wbArray(gameProperties, DMDT, 'Unknown',
//            wbByteArray(gameProperties, 'Unknown', 24, cpBenign),
//          0, nil, nil, cpBenign)
        ], []),
        wbEmpty(gameProperties, DSTF, 'End Marker', cpNormal, True)
      ], [])
    )
  ], [], cpNormal, False, wbActorTemplateUseModelAnimation);

  wbSCRI := wbFormIDCk(gameProperties, SCRI, 'Script', [SCPT]);
  wbSCRIActor := wbFormIDCk(gameProperties, SCRI, 'Script', [SCPT], False, cpNormal, False, wbActorTemplateUseScript);
  wbENAM := wbFormIDCk(gameProperties, ENAM, 'Object Effect', [ENCH]);

  wbXLOD := wbArray(gameProperties, XLOD, 'Distant LOD Data', wbFloat(gameProperties, 'Unknown'), 3);

  wbXESP := wbStruct(gameProperties, XESP, 'Enable Parent', [
    wbFormIDCk(gameProperties, 'Reference', [PLYR, REFR, ACRE, ACHR, PGRE, PMIS, PBEA]),
    wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
      'Set Enable State to Opposite of Parent',
      'Pop In'
    ])),
    wbByteArray(gameProperties, 'Unused', 3)
  ]);

  wbSCHRReq := wbStruct(gameProperties, SCHR, 'Basic Script Data', [
    wbByteArray(gameProperties, 'Unused', 4),
    wbInteger(gameProperties, 'RefCount', itU32),
    wbInteger(gameProperties, 'CompiledSize', itU32),
    wbInteger(gameProperties, 'VariableCount', itU32),
    wbInteger(gameProperties, 'Type', itU16, wbEnum(gameProperties, [
      'Object',
      'Quest'
    ], [
      $100, 'Effect'
    ])),
    wbInteger(gameProperties, 'Flags', itU16, wbFlags(gameProperties, [
      'Enabled'
    ]), cpNormal, False, nil, nil, 1)
  ], cpNormal, True);

  wbSCROs :=
    wbRArray(gameProperties, 'References',
      wbRUnion(gameProperties, '', [
        wbFormID(gameProperties, SCRO, 'Global Reference'),
//        wbFormIDCk(gameProperties, SCRO, 'Global Reference',
//          [ACTI, DOOR, STAT, FURN, CREA, SPEL, NPC_, CONT, ARMO, AMMO, MISC, WEAP, IMAD,
//           BOOK, KEYM, ALCH, LIGH, QUST, PLYR, PACK, LVLI, ECZN, EXPL, FLST, IDLM, PMIS,
//           FACT, ACHR, REFR, ACRE, GLOB, DIAL, CELL, SOUN, MGEF, WTHR, CLAS, EFSH, RACE,
//           LVLC, CSTY, WRLD, SCPT, IMGS, MESG, MSTT, MUSC, NOTE, PERK, PGRE, PROJ, LVLN,
//           WATR, ENCH, TREE, REPU, REGN, CSNO, CHAL, IMOD, RCCT, CMNY, CDCK, CHIP, CCRD,
//           TERM, HAIR, EYES, ADDN, RCPE, NULL]),
        wbInteger(gameProperties, SCRV, 'Local Variable', itU32)
      ], [])
    ).IncludeFlag(dfNotAlignable);

  wbSLSD := wbStructSK(gameProperties, SLSD, [0], 'Local Variable Data', [
    wbInteger(gameProperties, 'Index', itU32),
    wbByteArray(gameProperties, 'Unused', 12),
    wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, ['IsLongOrShort']), cpCritical),
    wbByteArray(gameProperties, 'Unused', 7)
  ]);

  wbEmbeddedScript := wbRStruct(gameProperties, 'Embedded Script', [
    wbSCHRReq,
    wbByteArray(gameProperties, SCDA, 'Compiled Embedded Script', 0, cpNormal{, True}),
    wbStringScript(gameProperties, SCTX, 'Embedded Script Source', 0, cpNormal{, True}),
    wbRArrayS(gameProperties, 'Local Variables', wbRStructSK(gameProperties, [0], 'Local Variable', [
      wbSLSD,
      wbString(gameProperties, SCVR, 'Name', 0, cpCritical, True)
    ], [])),
    wbSCROs
  ], [], cpNormal, False, nil, False, wbEmbeddedScriptAfterLoad);

  wbEmbeddedScriptPerk := wbRStruct(gameProperties, 'Embedded Script', [
    wbSCHRReq,
    wbByteArray(gameProperties, SCDA, 'Compiled Embedded Script', 0, cpNormal, True),
    wbStringScript(gameProperties, SCTX, 'Embedded Script Source', 0, cpNormal, True),
    wbRArrayS(gameProperties, 'Local Variables', wbRStructSK(gameProperties, [0], 'Local Variable', [
      wbSLSD,
      wbString(gameProperties, SCVR, 'Name', 0, cpCritical, True)
    ], [])),
    wbSCROs
  ], [], cpNormal, False, wbEPF2DontShow, False, wbEmbeddedScriptAfterLoad);

  wbEmbeddedScriptReq := wbRStruct(gameProperties, 'Embedded Script', [
    wbSCHRReq,
    wbByteArray(gameProperties, SCDA, 'Compiled Embedded Script', 0, cpNormal{, True}),
    wbStringScript(gameProperties, SCTX, 'Embedded Script Source', 0, cpNormal{, True}),
    wbRArrayS(gameProperties, 'Local Variables', wbRStructSK(gameProperties, [0], 'Local Variable', [
      wbSLSD,
      wbString(gameProperties, SCVR, 'Name', 0, cpCritical, True)
    ], [])),
    wbSCROs
  ], [], cpNormal, True, nil, False, wbEmbeddedScriptAfterLoad);


  wbXLCM := wbInteger(gameProperties, XLCM, 'Level Modifier', itS32);

  wbRefRecord(
    gameProperties,
    ACHR, 'Placed NPC', [
    wbEDID,
    wbFormIDCk(gameProperties, NAME, 'Base', [NPC_], False, cpNormal, True),
    wbFormIDCk(gameProperties, XEZN, 'Encounter Zone', [ECZN]),

    {--- Ragdoll ---}
    wbXRGD,
    wbXRGB,

    {--- Patrol Data ---}
    wbRStruct(gameProperties, 'Patrol Data', [
      wbFloat(gameProperties, XPRD, 'Idle Time', cpNormal, True),
      wbEmpty(gameProperties, XPPA, 'Patrol Script Marker', cpNormal, True),
      wbFormIDCk(gameProperties, INAM, 'Idle', [IDLE, NULL], False, cpNormal, True),
      wbEmbeddedScriptReq,
      wbFormIDCk(gameProperties, TNAM, 'Topic', [DIAL, NULL], False, cpNormal, True)
    ], []),

    {--- Leveled Actor ----}
    wbXLCM,

    {--- Merchant Container ----}
    wbFormIDCk(gameProperties, XMRC, 'Merchant Container', [REFR], True),

    {--- Extra ---}
    wbInteger(gameProperties, XCNT, 'Count', itS32),
    wbFloat(gameProperties, XRDS, 'Radius'),
    wbFloat(gameProperties, XHLP, 'Health'),

    {--- Decals ---}
    wbRArrayS(gameProperties, 'Linked Decals',
      wbStructSK(gameProperties, XDCR, [0], 'Decal', [
        wbFormIDCk(gameProperties, 'Reference', [REFR]),
        wbUnknown(gameProperties)
      ])
    ),

    {--- Linked Ref ---}
    wbFormIDCk(gameProperties, XLKR, 'Linked Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, PLYR]),
    wbStruct(gameProperties, XCLP, 'Linked Reference Color', [
      wbStruct(gameProperties, 'Link Start Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Link End Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ])
    ]),

    {--- Activate Parents ---}
    wbRStruct(gameProperties, 'Activate Parents', [
      wbInteger(gameProperties, XAPD, 'Flags', itU8, wbFlags(gameProperties, [
        'Parent Activate Only'
      ], True)),
      wbRArrayS(gameProperties, 'Activate Parent Refs',
        wbStructSK(gameProperties, XAPR, [0], 'Activate Parent Ref', [
          wbFormIDCk(gameProperties, 'Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, PLYR]),
          wbFloat(gameProperties, 'Delay')
        ])
      )
    ], []),

    wbStringKC(gameProperties, XATO, 'Activation Prompt'),

    {--- Enable Parent ---}
    wbXESP,

    {--- Emittance ---}
    wbFormIDCk(gameProperties, XEMI, 'Emittance', [LIGH, REGN]),

    {--- MultiBound ---}
    wbFormIDCk(gameProperties, XMBR, 'MultiBound Reference', [REFR]),

    {--- Flags ---}
    wbEmpty(gameProperties, XIBS, 'Ignored By Sandbox'),

    {--- 3D Data ---}
    wbXSCL,
    wbDATAPosRot
  ], True, wbPlacedAddInfo);

  wbXOWN := wbFormIDCkNoReach(gameProperties, XOWN, 'Owner', [FACT, ACHR, CREA, NPC_]); // Ghouls can own too aparently !
  wbXGLB := wbFormIDCk(gameProperties, XGLB, 'Global variable', [GLOB]);

  wbRefRecord(
  gameProperties,
  ACRE, 'Placed Creature', [
    wbEDID,
    wbFormIDCk(gameProperties, NAME, 'Base', [CREA], False, cpNormal, True),
    wbFormIDCk(gameProperties, XEZN, 'Encounter Zone', [ECZN]),

    wbXRGD,
    wbXRGB,

    {--- Patrol Data ---}
    wbRStruct(gameProperties, 'Patrol Data', [
      wbFloat(gameProperties, XPRD, 'Idle Time', cpNormal, True),
      wbEmpty(gameProperties, XPPA, 'Patrol Script Marker', cpNormal, True),
      wbFormIDCk(gameProperties, INAM, 'Idle', [IDLE, NULL], False, cpNormal, True),
      wbEmbeddedScriptReq,
      wbFormIDCk(gameProperties, TNAM, 'Topic', [DIAL, NULL], False, cpNormal, True)
    ], []),

    {--- Leveled Actor ----}
    wbXLCM,

    {--- Ownership ---}
    wbRStruct(gameProperties, 'Ownership', [
      wbXOWN,
      wbInteger(gameProperties, XRNK, 'Faction rank', itS32)
    ], [XCMT, XCMO]),

    {--- Merchant Container ----}
    wbFormIDCk(gameProperties, XMRC, 'Merchant Container', [REFR], True),

    {--- Extra ---}
    wbInteger(gameProperties, XCNT, 'Count', itS32),
    wbFloat(gameProperties, XRDS, 'Radius'),
    wbFloat(gameProperties, XHLP, 'Health'),

    {--- Decals ---}
    wbRArrayS(gameProperties, 'Linked Decals',
      wbStructSK(gameProperties, XDCR, [0], 'Decal', [
        wbFormIDCk(gameProperties, 'Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA]),
        wbUnknown(gameProperties)
      ])
    ),

    {--- Linked Ref ---}
    wbFormIDCk(gameProperties, XLKR, 'Linked Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, PLYR]),
    wbStruct(gameProperties, XCLP, 'Linked Reference Color', [
      wbStruct(gameProperties, 'Link Start Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Link End Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ])
    ]),

    {--- Activate Parents ---}
    wbRStruct(gameProperties, 'Activate Parents', [
      wbInteger(gameProperties, XAPD, 'Flags', itU8, wbFlags(gameProperties, [
        'Parent Activate Only'
      ], True)),
      wbRArrayS(gameProperties, 'Activate Parent Refs',
        wbStructSK(gameProperties, XAPR, [0], 'Activate Parent Ref', [
          wbFormIDCk(gameProperties, 'Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, PLYR]),
          wbFloat(gameProperties, 'Delay')
        ])
      )
    ], []),

    wbStringKC(gameProperties, XATO, 'Activation Prompt'),

    {--- Enable Parent ---}
    wbXESP,

    {--- Emittance ---}
    wbFormIDCk(gameProperties, XEMI, 'Emittance', [LIGH, REGN]),

    {--- MultiBound ---}
    wbFormIDCk(gameProperties, XMBR, 'MultiBound Reference', [REFR]),

    {--- Flags ---}
    wbEmpty(gameProperties, XIBS, 'Ignored By Sandbox'),

    {--- 3D Data ---}
    wbXSCL,
    wbDATAPosRot
  ], True, wbPlacedAddInfo);

  wbRecord(
  gameProperties,
  ACTI, 'Activator', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbSCRI,
    wbDEST,
    wbFormIDCk(gameProperties, SNAM, 'Sound - Looping', [SOUN]),
    wbFormIDCk(gameProperties, VNAM, 'Sound - Activation', [SOUN]),
    wbFormIDCk(gameProperties, INAM, 'Radio Template', [SOUN]),
    wbFormIDCk(gameProperties, RNAM, 'Radio Station', [TACT]),
    wbFormIDCk(gameProperties, WNAM, 'Water Type', [WATR]),
    wbStringKC(gameProperties, XATO, 'Activation Prompt')
  ]);

  wbICON := wbRStruct(gameProperties, 'Icon', [
    wbString(gameProperties, ICON, 'Large Icon FileName', 0, cpNormal, True),
    wbString(gameProperties, MICO, 'Small Icon FileName')
  ], [], cpNormal, False, nil, True);

  wbICONReq := wbRStruct(gameProperties, 'Icon', [
    wbString(gameProperties, ICON, 'Large Icon FileName', 0, cpNormal, True),
    wbString(gameProperties, MICO, 'Small Icon FileName')
  ], [], cpNormal, True, nil, True);

  wbVatsValueFunctionEnum :=
    wbEnum(gameProperties, [
      'Weapon Is',
      'Weapon In List',
      'Target Is',
      'Target In List',
      'Target Distance',
      'Target Part',
      'VATS Action',
      'Is Success',
      'Is Critical',
      'Critical Effect Is',
      'Critical Effect In List',
      'Is Fatal',
      'Explode Part',
      'Dismember Part',
      'Cripple Part',
      'Weapon Type Is',
      'Is Stranger',
      'Is Paralyzing Palm'
    ]);

  wbActorValueEnum :=
    wbEnum(gameProperties, [
        {00} 'Aggresion',
        {01} 'Confidence',
        {02} 'Energy',
        {03} 'Responsibility',
        {04} 'Mood',
        {05} 'Strength',
        {06} 'Perception',
        {07} 'Endurance',
        {08} 'Charisma',
        {09} 'Intelligence',
        {10} 'Agility',
        {11} 'Luck',
        {12} 'Action Points',
        {13} 'Carry Weight',
        {14} 'Critical Chance',
        {15} 'Heal Rate',
        {16} 'Health',
        {17} 'Melee Damage',
        {18} 'Damage Resistance',
        {19} 'Poison Resistance',
        {20} 'Rad Resistance',
        {21} 'Speed Multiplier',
        {22} 'Fatigue',
        {23} 'Karma',
        {24} 'XP',
        {25} 'Perception Condition',
        {26} 'Endurance Condition',
        {27} 'Left Attack Condition',
        {28} 'Right Attack Condition',
        {29} 'Left Mobility Condition',
        {30} 'Right Mobility Condition',
        {31} 'Brain Condition',
        {32} 'Barter',
        {33} 'Big Guns',
        {34} 'Energy Weapons',
        {35} 'Explosives',
        {36} 'Lockpick',
        {37} 'Medicine',
        {38} 'Melee Weapons',
        {39} 'Repair',
        {40} 'Science',
        {41} 'Guns',
        {42} 'Sneak',
        {43} 'Speech',
        {44} 'Survival',
        {45} 'Unarmed',
        {46} 'Inventory Weight',
        {47} 'Paralysis',
        {48} 'Invisibility',
        {49} 'Chameleon',
        {50} 'Night Eye',
        {51} 'Turbo',
        {52} 'Fire Resistance',
        {53} 'Water Breathing',
        {54} 'Rad Level',
        {55} 'Bloody Mess',
        {56} 'Unarmed Damage',
        {57} 'Assistance',
        {58} 'Electric Resistance',
        {59} 'Frost Resistance',
        {60} 'Energy Resistance',
        {61} 'EMP Resistance',
        {62} 'Variable01',
        {63} 'Variable02',
        {64} 'Variable03',
        {65} 'Variable04',
        {66} 'Variable05',
        {67} 'Variable06',
        {68} 'Variable07',
        {79} 'Variable08',
        {70} 'Variable09',
        {71} 'Variable10',
        {72} 'Ignore Crippled Limbs',
        {73} 'Dehydration',
        {74} 'Hunger',
        {75} 'Sleep Deprivation',
        {76} 'Damage Threshold'
      ], [
        -1, 'None'
      ]);

  wbModEffectEnum :=
    wbEnum(gameProperties, [
      {00} 'None',
      {01} 'Increase Weapon Damage',
      {02} 'Increase Clip Capacity',
      {03} 'Decrease Spread',
      {04} 'Decrease Weight',
      {05} 'Regenerate Ammo (shots)',
      {06} 'Regenerate Ammo (seconds)',
      {07} 'Decrease Equip Time',
      {08} 'Increase Rate of Fire',
      {09} 'Increase Projectile Speed',
      {10} 'Increase Max. Condition',
      {11} 'Silence',
      {12} 'Split Beam',
      {13} 'VATS Bonus',
      {14} 'Increase Zoom',
      {15} 'Decrease Equip Time',
      {16} 'Suppressor'
    ]);

  wbSkillEnum :=
    wbEnum(gameProperties, [
      'Barter',
      'Big Guns',
      'Energy Weapons',
      'Explosives',
      'Lockpick',
      'Medicine',
      'Melee Weapons',
      'Repair',
      'Science',
      'Guns',
      'Sneak',
      'Speech',
      'Survival',
      'Unarmed'
    ], [
      -1, 'None'
    ]);

  wbCrimeTypeEnum :=
    wbEnum(gameProperties, [
      'Steal',
      'Pickpocket',
      'Trespass',
      'Attack',
      'Murder'
    ], [
      -1, 'None'
    ]);

  wbActorValue := wbInteger(gameProperties, 'Actor Value', itS32, wbActorValueEnum);

  wbEquipTypeEnum :=
    wbEnum(gameProperties, [
        {00} 'Big Guns',
        {01} 'Energy Weapons',
        {02} 'Small Guns',
        {03} 'Melee Weapons',
        {04} 'Unarmed Weapon',
        {05} 'Thrown Weapons',
        {06} 'Mine',
        {07} 'Body Wear',
        {08} 'Head Wear',
        {09} 'Hand Wear',
        {10} 'Chems',
        {11} 'Stimpack',
        {12} 'Food',
        {13} 'Alcohol'
      ], [
        -1, 'None'
      ]);

  wbETYP := wbInteger(gameProperties, ETYP, 'Equipment Type', itS32, wbEquipTypeEnum);
  wbETYPReq := wbInteger(gameProperties, ETYP, 'Equipment Type', itS32, wbEquipTypeEnum, cpNormal, True);

  wbFormTypeEnum :=
    wbEnum(gameProperties, [], [
      $04, 'Texture Set',
      $05, 'Menu Icon',
      $06, 'Global',
      $07, 'Class',
      $08, 'Faction',
      $09, 'Head Part',
      $0A, 'Hair',
      $0B, 'Eyes',
      $0C, 'Race',
      $0D, 'Sound',
      $0E, 'Acoustic Space',
      $0F, 'Skill',
      $10, 'Base Effect',
      $11, 'Script',
      $12, 'Landscape Texture',
      $13, 'Object Effect',
      $14, 'Actor Effect',
      $15, 'Activator',
      $16, 'Talking Activator',
      $17, 'Terminal',
      $18, 'Armor',
      $19, 'Book',
      $1A, 'Clothing',
      $1B, 'Container',
      $1C, 'Door',
      $1D, 'Ingredient',
      $1E, 'Light',
      $1F, 'Misc',
      $20, 'Static',
      $21, 'Static Collection',
      $22, 'Movable Static',
      $23, 'Placeable Water',
      $24, 'Grass',
      $25, 'Tree',
      $26, 'Flora',
      $27, 'Furniture',
      $28, 'Weapon',
      $29, 'Ammo',
      $2A, 'NPC',
      $2B, 'Creature',
      $2C, 'Leveled Creature',
      $2D, 'Leveled NPC',
      $2E, 'Key',
      $2F, 'Ingestible',
      $30, 'Idle Marker',
      $31, 'Note',
      $32, 'Constructible Object',
      $33, 'Projectile',
      $34, 'Leveled Item',
      $35, 'Weather',
      $36, 'Climate',
      $37, 'Region',
      $39, 'Cell',
      $3A, 'Placed Object',
      $3B, 'Placed Character',
      $3C, 'Placed Creature',
      $3E, 'Placed Grenade',
      $41, 'Worldspace',
      $42, 'Landscape',
      $43, 'Navigation Mesh',
      $45, 'Dialog Topic',
      $46, 'Dialog Response',
      $47, 'Quest',
      $48, 'Idle Animation',
      $49, 'Package',
      $4A, 'Combat Style',
      $4B, 'Load Screen',
      $4C, 'Leveled Spell',
      $4D, 'Animated Object',
      $4E, 'Water',
      $4F, 'Effect Shader',
      $51, 'Explosion',
      $52, 'Debris',
      $53, 'Image Space',
      $54, 'Image Space Modifier',
      $55, 'FormID List',
      $56, 'Perk',
      $57, 'Body Part Data',
      $58, 'Addon Node',
      $59, 'Actor Value Info',
      $5A, 'Radiation Stage',
      $5B, 'Camera Shot',
      $5C, 'Camera Path',
      $5D, 'Voice Type',
      $5E, 'Impact Data',
      $5F, 'Impact DataSet',
      $60, 'Armor Addon',
      $61, 'Encounter Zone',
      $62, 'Message',
      $63, 'Ragdoll',
      $64, 'Default Object Manager',
      $65, 'Lighting Template',
      $66, 'Music Type',
      $67, 'Item Mod',
      $68, 'Reputation',
      $69, '?PCBE', //no such records in FalloutNV.esm
      $6A, 'Recipe',
      $6B, 'Recipe Category',
      $6C, 'Casino Chip',
      $6D, 'Casino',
      $6E, 'Load Screen Type',
      $6F, 'Media Set',
      $70, 'Media Location Controller',
      $71, 'Challenge',
      $72, 'Ammo Effect',
      $73, 'Caravan Card',
      $74, 'Caravan Money',
      $75, 'Caravan Deck',
      $76, 'Dehydration Stages',
      $77, 'Hunger Stages',
      $78, 'Sleep Deprivation Stages'
  ]);

  wbMenuModeEnum :=
    wbEnum(gameProperties, [],[
      1, 'Type: Character Interface',
      2, 'Type: Other',
      3, 'Type: Console',
      1001, 'Specific: Message',
      1002, 'Specific: Inventory',
      1003, 'Specific: Stats',
      1004, 'Specific: HUDMainMenu',
      1007, 'Specific: Loading',
      1008, 'Specific: Container',
      1009, 'Specific: Dialog',
      1012, 'Specific: Sleep/Wait',
      1013, 'Specific: Pause',
      1014, 'Specific: LockPick',
      1016, 'Specific: Quantity',
      1027, 'Specific: Level Up',
      1035, 'Specific: Pipboy Repair',
      1036, 'Specific: Race / Sex',
      1047, 'Specific: Credits',
      1048, 'Specific: CharGen',
      1051, 'Specific: TextEdit',
      1053, 'Specific: Barter',
      1054, 'Specific: Surgery',
      1055, 'Specific: Hacking',
      1056, 'Specific: VATS',
      1057, 'Specific: Computers',
      1058, 'Specific: Vendor Repair',
      1059, 'Specific: Tutorial',
      1060, 'Specific: You''re SPECIAL book'
    ]);
end;

procedure DefineFNVb(var gameProperties: TGameProperties);
begin
  wbMiscStatEnum :=
    wbEnum(gameProperties, [
      'Quests Completed',
      'Locations Discovered',
      'People Killed',
      'Creatures Killed',
      'Locks Picked',
      'Computers Hacked',
      'Stimpaks Taken',
      'Rad-X Taken',
      'RadAway Taken',
      'Chems Taken',
      'Times Addicted',
      'Mines Disarmed',
      'Speech Successes',
      'Pockets Picked',
      'Pants Exploded',
      'Books Read',
      'Bobbleheads Found',
      'Weapons Created',
      'People Mezzed',
      'Captives Rescued',
      'Sandman Kills',
      'Paralyzing Punches',
      'Robots Disabled',
      'Contracts Completed',
      'Corpses Eaten',
      'Mysterious Stranger Visits',
      'Doctor Bags Used',
      'Challenges Completed',
      'Miss Fortunate Occurrences',
      'Disintegrations',
      'Have Limbs Crippled',
      'Speech Failures',
      'Items Crafted',
      'Weapon Modifications',
      'Items Repaired',
      'Total Things Killed',
      'Dismembered Limbs',
      'Caravan Games Won',
      'Caravan Games Lost',
      'Barter Amount Traded',
      'Roulette Games Played',
      'Blackjack Games Played',
      'Slots Games Played'
    ]);

  wbAlignmentEnum :=
    wbEnum(gameProperties, [
      'Good',
      'Neutral',
      'Evil',
      'Very Good',
      'Very Evil'
    ]);

  wbAxisEnum :=
    wbEnum(gameProperties, [], [
      88, 'X',
      89, 'Y',
      90, 'Z'
    ]);

  wbCriticalStageEnum :=
    wbEnum(gameProperties, [
      'None',
      'Goo Start',
      'Goo End',
      'Disintegrate Start',
      'Disintegrate End'
    ]);

  wbSexEnum :=
    wbEnum(gameProperties, ['Male','Female']);

  wbCreatureTypeEnum :=
    wbEnum(gameProperties, [
      'Animal',
      'Mutated Animal',
      'Mutated Insect',
      'Abomination',
      'Super Mutant',
      'Feral Ghoul',
      'Robot',
      'Giant'
    ]);

  wbPlayerActionEnum :=
    wbEnum(gameProperties, [
      '',
      'Swinging Melee Weapon',
      'Throwing Grenade',
      'Fire Weapon',
      'Lay Mine',
      'Z Key Object',
      'Jumping',
      'Knocking over Objects',
      'Stand on Table/Chair',
      'Iron Sites',
      'Destroying Object'
    ]);

  wbBodyLocationEnum :=
    wbEnum(gameProperties, [
      'Torso',
      'Head 1',
      'Head 2',
      'Left Arm 1',
      'Left Arm 2',
      'Right Arm 1',
      'Right Arm 2',
      'Left Leg 1',
      'Left Leg 2',
      'Left Leg 3',
      'Right Leg 1',
      'Right Leg 2',
      'Right Leg 3',
      'Brain'
    ], [
      -1, 'None'
    ]);


  wbEFID := wbFormIDCk(gameProperties, EFID, 'Base Effect', [MGEF]);

  wbEFIT :=
    wbStructSK(gameProperties, EFIT, [3, 4], '', [
      wbInteger(gameProperties, 'Magnitude', itU32),
      wbInteger(gameProperties, 'Area', itU32),
      wbInteger(gameProperties, 'Duration', itU32),
      wbInteger(gameProperties, 'Type', itU32, wbEnum(gameProperties, ['Self', 'Touch', 'Target'])),
      wbActorValue
    ], cpNormal, True, nil, -1, wbEFITAfterLoad);

  wbCTDA :=
    wbStructSK(gameProperties, CTDA, [3, 4], 'Condition', [
   {0}wbInteger(gameProperties, 'Type', itU8, wbCtdaTypeToStr, wbCtdaTypeToInt, cpNormal, False, nil, wbCtdaTypeAfterSet),
   {1}wbByteArray(gameProperties, 'Unused', 3),
   {2}wbUnion(gameProperties, 'Comparison Value', wbCTDACompValueDecider, [
        wbFloat(gameProperties, 'Comparison Value - Float'),
        wbFormIDCk(gameProperties, 'Comparison Value - Global', [GLOB])
      ]),
   {3}wbInteger(gameProperties, 'Function', itU16, wbCTDAFunctionToStr, wbCTDAFunctionToInt),   // Limited to itu16
   {4}wbByteArray(gameProperties, 'Unused', 2, cpIgnore, False, wbNeverShow),
   {5}wbUnion(gameProperties, 'Parameter #1', wbCTDAParam1Decider, [
        {00} wbByteArray(gameProperties, 'Unknown', 4),
        {01} wbByteArray(gameProperties, 'None', 4, cpIgnore).IncludeFlag(dfZeroSortKey),
        {02} wbInteger(gameProperties, 'Integer', itS32),
        {03} wbInteger(gameProperties, 'Variable Name (INVALID)', itS32).IncludeFlag(dfZeroSortKey),
        {04} wbInteger(gameProperties, 'Sex', itU32, wbSexEnum),
        {05} wbInteger(gameProperties, 'Actor Value', itS32, wbActorValueEnum),
        {06} wbInteger(gameProperties, 'Crime Type', itU32, wbCrimeTypeEnum),
        {07} wbInteger(gameProperties, 'Axis', itU32, wbAxisEnum),
        {08} wbInteger(gameProperties, 'Quest Stage (INVALID)', itS32).IncludeFlag(dfZeroSortKey),
        {09} wbInteger(gameProperties, 'Misc Stat', itU32, wbMiscStatEnum),
        {10} wbInteger(gameProperties, 'Alignment', itU32, wbAlignmentEnum),
        {11} wbInteger(gameProperties, 'Equip Type', itU32, wbEquipTypeEnum),
        {12} wbInteger(gameProperties, 'Form Type', itU32, wbFormTypeEnum),
        {13} wbInteger(gameProperties, 'Critical Stage', itU32, wbCriticalStageEnum),
        {14} wbFormIDCkNoReach(gameProperties, 'Object Reference', [PLYR, REFR, ACHR, ACRE, PGRE, PMIS, PBEA, TRGT], True),
        {16} wbFormIDCkNoReach(gameProperties, 'Inventory Object', [ARMO, BOOK, MISC, WEAP, AMMO, KEYM, ALCH, NOTE, FLST, CHIP, CMNY, IMOD]),
        {17} wbFormIDCkNoReach(gameProperties, 'Actor', [PLYR, ACHR, ACRE, TRGT], True),
        {18} wbFormIDCkNoReach(gameProperties, 'Voice Type', [VTYP]),
        {19} wbFormIDCkNoReach(gameProperties, 'Idle', [IDLE]),
        {20} wbFormIDCkNoReach(gameProperties, 'Form List', [FLST]),
        {21} wbFormIDCkNoReach(gameProperties, 'Note', [NOTE]),
        {22} wbFormIDCkNoReach(gameProperties, 'Quest', [QUST]),
        {23} wbFormIDCkNoReach(gameProperties, 'Faction', [FACT]),
        {24} wbFormIDCkNoReach(gameProperties, 'Weapon', [WEAP]),
        {25} wbFormIDCkNoReach(gameProperties, 'Cell', [CELL]),
        {26} wbFormIDCkNoReach(gameProperties, 'Class', [CLAS]),
        {27} wbFormIDCkNoReach(gameProperties, 'Race', [RACE]),
        {28} wbFormIDCkNoReach(gameProperties, 'Actor Base', [NPC_, CREA, ACTI, TACT, NULL]),
        {29} wbFormIDCkNoReach(gameProperties, 'Global', [GLOB]),
        {30} wbFormIDCkNoReach(gameProperties, 'Weather', [WTHR]),
        {31} wbFormIDCkNoReach(gameProperties, 'Package', [PACK]),
        {32} wbFormIDCkNoReach(gameProperties, 'Encounter Zone', [ECZN]),
        {33} wbFormIDCkNoReach(gameProperties, 'Perk', [PERK]),
        {34} wbFormIDCkNoReach(gameProperties, 'Owner', [FACT, NPC_]),
        {35} wbFormIDCkNoReach(gameProperties, 'Furniture', [FURN, FLST]),
        {36} wbFormIDCkNoReach(gameProperties, 'Effect Item', [SPEL, ENCH, ALCH, INGR]),
        {37} wbFormIDCkNoReach(gameProperties, 'Base Effect', [MGEF]),
        {38} wbFormIDCkNoReach(gameProperties, 'Worldspace', [WRLD]),
        {39} wbInteger(gameProperties, 'VATS Value Function', itU32, wbVATSValueFunctionEnum),
        {40} wbInteger(gameProperties, 'VATS Value Param (INVALID)', itU32).IncludeFlag(dfZeroSortKey),
        {41} wbInteger(gameProperties, 'Creature Type', itU32, wbCreatureTypeEnum),
        {42} wbInteger(gameProperties, 'Menu Mode', itU32, wbMenuModeEnum),
        {43} wbInteger(gameProperties, 'Player Action', itU32, wbPlayerActionEnum),
        {44} wbInteger(gameProperties, 'Body Location', itS32, wbBodyLocationEnum),
        {45} wbFormIDCkNoReach(gameProperties, 'Referenceable Object', [CREA, NPC_, PROJ, TREE, SOUN, ACTI, DOOR, STAT, FURN, CONT, ARMO, AMMO, MISC, WEAP, BOOK, KEYM, ALCH, LIGH, GRAS, ASPC, IDLM, ARMA, MSTT, NOTE, PWAT, SCOL, TACT, TERM, FLST, CHIP, CMNY, CCRD, IMOD, LVLC, LVLN],
                                                [CREA, NPC_, PROJ, TREE, SOUN, ACTI, DOOR, STAT, FURN, CONT, ARMO, AMMO, MISC, WEAP, BOOK, KEYM, ALCH, LIGH, GRAS, ASPC, IDLM, ARMA, MSTT, NOTE, PWAT, SCOL, TACT, TERM, CHIP, CMNY, CCRD, IMOD, LVLC, LVLN]),
        {46} wbInteger(gameProperties, 'Quest Objective (INVALID)', itS32).IncludeFlag(dfZeroSortKey),
        {47} wbFormIDCkNoReach(gameProperties, 'Reputation', [REPU]),
        {48} wbFormIDCkNoReach(gameProperties, 'Region', [REGN]),
        {49} wbFormIDCkNoReach(gameProperties, 'Challenge', [CHAL]),
        {50} wbFormIDCkNoReach(gameProperties, 'Casino', [CSNO]),
        {51} wbFormID(gameProperties, 'Form')
      ]),
   {6}wbUnion(gameProperties, 'Parameter #2', wbCTDAParam2Decider, [
        {00} wbByteArray(gameProperties, 'Unknown', 4),
        {01} wbByteArray(gameProperties, 'None', 4, cpIgnore),
        {02} wbInteger(gameProperties, 'Integer', itS32),
        {03} wbInteger(gameProperties, 'Variable Name', itS32, wbCTDAParam2VariableNameToStr, wbCTDAParam2VariableNameToInt),
        {04} wbInteger(gameProperties, 'Sex', itU32, wbSexEnum),
        {05} wbInteger(gameProperties, 'Actor Value', itS32, wbActorValueEnum),
        {06} wbInteger(gameProperties, 'Crime Type', itU32, wbCrimeTypeEnum),
        {07} wbInteger(gameProperties, 'Axis', itU32, wbAxisEnum),
        {08} wbInteger(gameProperties, 'Quest Stage', itS32, wbCTDAParam2QuestStageToStr, wbCTDAParam2QuestStageToInt),
        {09} wbInteger(gameProperties, 'Misc Stat', itU32, wbMiscStatEnum),
        {10} wbInteger(gameProperties, 'Alignment', itU32, wbAlignmentEnum),
        {11} wbInteger(gameProperties, 'Equip Type', itU32, wbEquipTypeEnum),
        {12} wbInteger(gameProperties, 'Form Type', itU32, wbFormTypeEnum),
        {13} wbInteger(gameProperties, 'Critical Stage', itU32, wbCriticalStageEnum),
        {14} wbFormIDCkNoReach(gameProperties, 'Object Reference', [PLYR, REFR, PMIS, PBEA, ACHR, ACRE, PGRE, TRGT], True),
        {16} wbFormIDCkNoReach(gameProperties, 'Inventory Object', [ARMO, BOOK, MISC, WEAP, AMMO, KEYM, ALCH, NOTE, FLST, CHIP, CMNY, CCRD, IMOD]),
        {17} wbFormIDCkNoReach(gameProperties, 'Actor', [PLYR, ACHR, ACRE, TRGT], True),
        {18} wbFormIDCkNoReach(gameProperties, 'Voice Type', [VTYP]),
        {19} wbFormIDCkNoReach(gameProperties, 'Idle', [IDLE]),
        {20} wbFormIDCkNoReach(gameProperties, 'Form List', [FLST]),
        {21} wbFormIDCkNoReach(gameProperties, 'Note', [NOTE]),
        {22} wbFormIDCkNoReach(gameProperties, 'Quest', [QUST]),
        {23} wbFormIDCkNoReach(gameProperties, 'Faction', [FACT]),
        {24} wbFormIDCkNoReach(gameProperties, 'Weapon', [WEAP]),
        {25} wbFormIDCkNoReach(gameProperties, 'Cell', [CELL]),
        {26} wbFormIDCkNoReach(gameProperties, 'Class', [CLAS]),
        {27} wbFormIDCkNoReach(gameProperties, 'Race', [RACE]),
        {28} wbFormIDCkNoReach(gameProperties, 'Actor Base', [NPC_, CREA, ACTI, TACT]),
        {29} wbFormIDCkNoReach(gameProperties, 'Global', [GLOB]),
        {30} wbFormIDCkNoReach(gameProperties, 'Weather', [WTHR]),
        {31} wbFormIDCkNoReach(gameProperties, 'Package', [PACK]),
        {32} wbFormIDCkNoReach(gameProperties, 'Encounter Zone', [ECZN]),
        {33} wbFormIDCkNoReach(gameProperties, 'Perk', [PERK]),
        {34} wbFormIDCkNoReach(gameProperties, 'Owner', [FACT, NPC_]),
        {35} wbFormIDCkNoReach(gameProperties, 'Furniture', [FURN, FLST]),
        {36} wbFormIDCkNoReach(gameProperties, 'Effect Item', [SPEL, ENCH, ALCH, INGR]),
        {37} wbFormIDCkNoReach(gameProperties, 'Base Effect', [MGEF]),
        {38} wbFormIDCkNoReach(gameProperties, 'Worldspace', [WRLD]),
        {39} wbInteger(gameProperties, 'VATS Value Function (INVALID)', itU32),
        {40} wbUnion(gameProperties, 'VATS Value Param', wbCTDAParam2VATSValueParam, [
               wbFormIDCkNoReach(gameProperties, 'Weapon', [WEAP]),
               wbFormIDCkNoReach(gameProperties, 'Weapon List', [FLST], [WEAP]),
               wbFormIDCkNoReach(gameProperties, 'Target', [NPC_, CREA]),
               wbFormIDCkNoReach(gameProperties, 'Target List', [FLST], [NPC_, CREA]),
               wbByteArray(gameProperties, 'Unused', 4, cpIgnore),
               wbInteger(gameProperties, 'Target Part', itS32, wbActorValueEnum),
               wbInteger(gameProperties, 'VATS Action', itU32, wbEnum(gameProperties, [
                 'Unarmed Attack',
                 'One Hand Melee Attack',
                 'Two Hand Melee Attack',
                 'Fire Pistol',
                 'Fire Rifle',
                 'Fire Handle Weapon',
                 'Fire Launcher',
                 'Throw Grenade',
                 'Place Mine',
                 'Reload',
                 'Crouch',
                 'Stand',
                 'Switch Weapon',
                 'Toggle Weapon Drawn',
                 'Heal',
                 'Player Death',
                 'Special Weapon Attack',
                 'Special Unarmed Attack',
                 'Kill Camera Shot',
                 'Throw Weapon'
               ])),
               wbByteArray(gameProperties, 'Unused', 4, cpIgnore).IncludeFlag(dfZeroSortKey),
               wbByteArray(gameProperties, 'Unused', 4, cpIgnore).IncludeFlag(dfZeroSortKey),
               wbFormIDCkNoReach(gameProperties, 'Critical Effect', [SPEL]),
               wbFormIDCkNoReach(gameProperties, 'Critical Effect List', [FLST], [SPEL]),
               wbByteArray(gameProperties, 'Unused', 4, cpIgnore).IncludeFlag(dfZeroSortKey),
               wbByteArray(gameProperties, 'Unused', 4, cpIgnore).IncludeFlag(dfZeroSortKey),
               wbByteArray(gameProperties, 'Unused', 4, cpIgnore).IncludeFlag(dfZeroSortKey),
               wbByteArray(gameProperties, 'Unused', 4, cpIgnore).IncludeFlag(dfZeroSortKey),
               wbInteger(gameProperties, 'Weapon Type', itU32, wbWeaponAnimTypeEnum),
               wbByteArray(gameProperties, 'Unused', 4, cpIgnore).IncludeFlag(dfZeroSortKey),
               wbByteArray(gameProperties, 'Unused', 4, cpIgnore).IncludeFlag(dfZeroSortKey)
             ]),
        {41} wbInteger(gameProperties, 'Creature Type', itU32, wbCreatureTypeEnum),
        {42} wbInteger(gameProperties, 'Menu Mode', itU32, wbMenuModeEnum),
        {43} wbInteger(gameProperties, 'Player Action', itU32, wbPlayerActionEnum),
        {44} wbInteger(gameProperties, 'Body Location', itS32, wbBodyLocationEnum),
        {45} wbFormIDCkNoReach(gameProperties, 'Referenceable Object', [CREA, NPC_, PROJ, TREE, SOUN, ACTI, DOOR, STAT, FURN, CONT, ARMO, AMMO, MISC, WEAP, BOOK, KEYM, ALCH, LIGH, GRAS, ASPC, IDLM, ARMA, MSTT, NOTE, PWAT, SCOL, TACT, TERM, FLST, CHIP, CMNY, CCRD, IMOD, LVLC, LVLN],
                                                [CREA, NPC_, PROJ, TREE, SOUN, ACTI, DOOR, STAT, FURN, CONT, ARMO, AMMO, MISC, WEAP, BOOK, KEYM, ALCH, LIGH, GRAS, ASPC, IDLM, ARMA, MSTT, NOTE, PWAT, SCOL, TACT, TERM, CHIP, CMNY, CCRD, IMOD, LVLC, LVLN]),
        {46} wbInteger(gameProperties, 'Quest Objective', itS32, wbCTDAParam2QuestObjectiveToStr, wbCTDAParam2QuestObjectiveToInt),
        {47} wbFormIDCkNoReach(gameProperties, 'Reputation', [REPU]),
        {48} wbFormIDCkNoReach(gameProperties, 'Region', [REGN]),
        {49} wbFormIDCkNoReach(gameProperties, 'Challenge', [CHAL]),
        {50} wbFormIDCkNoReach(gameProperties, 'Casino', [CSNO]),
        {51} wbFormID(gameProperties, 'Form')
      ]),
   {7}wbUnion(gameProperties, 'Run On', wbCTDARunOnDecider, [
        wbInteger(gameProperties, 'Run On', itU32, wbEnum(gameProperties, [
          {0} 'Subject',
          {1} 'Target',
          {2} 'Reference',
          {3} 'Combat Target',
          {4} 'Linked Reference'
        ]), cpNormal, False, nil, wbCTDARunOnAfterSet),
        { Idle Animations }
        wbInteger(gameProperties, 'Run On', itU32, wbEnum(gameProperties, [], [
          0, 'Idle',
          1, 'Movement',
          2, 'Left Arm',
          3, 'Left Hand',
          4, 'Weapon',
          5, 'Weapon Up',
          6, 'Weapon Down',
          7, 'Special Idle',
          20, 'Whole Body',
          21, 'Upper Body'
        ]))
      ]),
   {8}wbUnion(gameProperties, 'Reference', wbCTDAReferenceDecider, [
        wbInteger(gameProperties, 'Unused', itU32, nil, cpIgnore),
        wbFormIDCkNoReach(gameProperties, 'Reference', [PLYR, ACHR, ACRE, REFR, PMIS, PBEA, PGRE, NULL], True)    // Can end up NULL if the original function requiring a reference is replaced by another who has no Run on prerequisite
      ])
    ], cpNormal, False, nil, 7, wbCTDAAfterLoad).SetToStr(wbConditionToStr).IncludeFlag(dfCollapsed, wbCollapseConditions);
  wbCTDAs := wbRArray(gameProperties, 'Conditions', wbCTDA);
  wbCTDAsReq := wbRArray(gameProperties, 'Conditions', wbCTDA, cpNormal, True);

  wbEffects :=
    wbRStructs(gameProperties, 'Effects','Effect', [
      wbEFID,
      wbEFIT,
      wbCTDAs
    ], []);

  wbEffectsReq :=
    wbRStructs(gameProperties, 'Effects','Effect', [
      wbEFID,
      wbEFIT,
      wbCTDAs
    ], [], cpNormal, True);


  wbRecord(
  gameProperties,
  ALCH, 'Ingestible', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULLReq,
    wbMODL,
    wbICON,
    wbSCRI,
    wbDEST,
    wbYNAM,
    wbZNAM,
    wbETYPReq,
    wbFloat(gameProperties, DATA, 'Weight', cpNormal, True),
    wbStruct(gameProperties, ENIT, 'Effect Data', [
      wbInteger(gameProperties, 'Value', itS32),
      wbInteger(gameProperties, 'Flags?', itU8, wbFlags(gameProperties, [
        'No Auto-Calc (Unused)',
        'Food Item',
        'Medicine'
      ])),
      wbByteArray(gameProperties, 'Unused', 3),
      wbFormIDCk(gameProperties, 'Withdrawal Effect', [SPEL, NULL]),
      wbFloat(gameProperties, 'Addiction Chance'),
      wbFormIDCk(gameProperties, 'Sound - Consume', [SOUN, NULL])
    ], cpNormal, True),
    wbEffectsReq
  ]);

  wbRecord(
  gameProperties,
  AMMO, 'Ammunition', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULLReq,
    wbMODL,
    wbICON,
    wbSCRI,
    wbDEST,
    wbYNAM,
    wbZNAM,
    wbStruct(gameProperties, DATA, 'Data', [
      wbFloat(gameProperties, 'Speed'),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        'Ignores Normal Weapon Resistance',
        'Non-Playable'
      ])),
      wbByteArray(gameProperties, 'Unused', 3),
      wbInteger(gameProperties, 'Value', itS32),
      wbInteger(gameProperties, 'Clip Rounds', itU8)
    ], cpNormal, True),
    wbStruct(gameProperties, DAT2, 'Data 2', [
      wbInteger(gameProperties, 'Proj. per Shot', itU32),
      wbFormIDCk(gameProperties, 'Projectile', [PROJ, NULL]),
      wbFloat(gameProperties, 'Weight'),
      wbFormIDCk(gameProperties, 'Consumed Ammo', [AMMO, MISC, NULL]),
      wbFloat(gameProperties, 'Consumed Percentage')
    ], cpNormal, False, nil, 3),
    wbStringKC(gameProperties, ONAM, 'Short Name', 0, cpTranslate),
    wbStringKC(gameProperties, QNAM, 'Abbrev.', 0, cpTranslate),
    wbRArray(gameProperties, 'Ammo Effects',
      wbFormIDCk(gameProperties, RCIL, 'Effect', [AMEF])
    )
  ]);

  wbRecord(
  gameProperties,
  ANIO, 'Animated Object', [
    wbEDIDReq,
    wbMODLReq,
    wbFormIDCk(gameProperties, DATA, 'Animation', [IDLE], False, cpNormal, True)
  ]);

  wbBMDT := wbStruct(gameProperties, BMDT, 'Biped Data', [
      wbInteger(gameProperties, 'Biped Flags', itU32, wbFlags(gameProperties, [
        {0x00000001} 'Head',
        {0x00000002} 'Hair',
        {0x00000004} 'Upper Body',
        {0x00000008} 'Left Hand',
        {0x00000010} 'Right Hand',
        {0x00000020} 'Weapon',
        {0x00000040} 'PipBoy',
        {0x00000080} 'Backpack',
        {0x00000100} 'Necklace',
        {0x00000200} 'Headband',
        {0x00000400} 'Hat',
        {0x00000800} 'Eye Glasses',
        {0x00001000} 'Nose Ring',
        {0x00002000} 'Earrings',
        {0x00004000} 'Mask',
        {0x00008000} 'Choker',
        {0x00010000} 'Mouth Object',
        {0x00020000} 'Body AddOn 1',
        {0x00040000} 'Body AddOn 2',
        {0x00080000} 'Body AddOn 3'
      ])),
      wbInteger(gameProperties, 'General Flags', itU8, wbFlags(gameProperties, [
        {0x0001} '1',
        {0x0002} '2',
        {0x0004} 'Has Backpack',
        {0x0008} 'Medium',
        {0x0010} '5',
        {0x0020} 'Power Armor',
        {0x0040} 'Non-Playable',
        {0x0080} 'Heavy'
      ], True)),
      wbByteArray(gameProperties, 'Unused', 3)
    ], cpNormal, True);

  wbRecord(
  gameProperties,
  ARMO, 'Armor', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbSCRI,
    wbEITM,
    wbBMDT,
    wbRStruct(gameProperties, 'Male biped model', [
      wbString(gameProperties, MODL, 'Model FileName', 0, cpNormal, True),
      wbByteArray(gameProperties, MODT, 'Texture Files Hashes', 0, cpIgnore),
      wbMODS,
      wbMODD
    ], [], cpNormal, False, nil, True),
    wbRStruct(gameProperties, 'Male world model', [
      wbString(gameProperties, MOD2, 'Model FileName'),
      wbByteArray(gameProperties, MO2T, 'Texture Files Hashes', 0, cpIgnore),
      wbMO2S
    ], []),
    wbString(gameProperties, ICON, 'Male icon FileName'),
    wbString(gameProperties, MICO, 'Male mico FileName'),
    wbRStruct(gameProperties, 'Female biped model', [
      wbString(gameProperties, MOD3, 'Model FileName', 0, cpNormal, True),
      wbByteArray(gameProperties, MO3T, 'Texture Files Hashes', 0, cpIgnore),
      wbMO3S,
      wbMOSD
    ], [], cpNormal, False, nil, True),
    wbRStruct(gameProperties, 'Female world model', [
      wbString(gameProperties, MOD4, 'Model FileName'),
      wbByteArray(gameProperties, MO4T, 'Texture Files Hashes', 0, cpIgnore),
      wbMO4S
    ], []),
    wbString(gameProperties, ICO2, 'Female icon FileName'),
    wbString(gameProperties, MIC2, 'Female mico FileName'),
    wbString(gameProperties, BMCT, 'Ragdoll Constraint Template'),
    wbDEST,
    wbREPL,
    wbBIPL,
    wbETYPReq,
    wbYNAM,
    wbZNAM,
    wbStruct(gameProperties, DATA, 'Data', [
      wbInteger(gameProperties, 'Value', itS32),
      wbInteger(gameProperties, 'Health', itS32),
      wbFloat(gameProperties, 'Weight')
    ], cpNormal, True),
    wbStruct(gameProperties, DNAM, '', [
      wbInteger(gameProperties, 'AR', itS16, wbDiv(gameProperties, 100)),
      wbByteArray(gameProperties, 'Unused', 2),
      wbFloat(gameProperties, 'DT'),
      wbInteger(gameProperties, 'Flags', itU16, wbFlags(gameProperties, [
        'Modulates Voice'
      ])),
      wbByteArray(gameProperties, 'Unused', 2)
    ], cpNormal, True, nil, 2),
    wbInteger(gameProperties, BNAM, 'Overrides Animation Sounds', itU32, wbEnum(gameProperties, ['No', 'Yes'])),
    wbRArray(gameProperties, 'Animation Sounds',
      wbStruct(gameProperties, SNAM, 'Animation Sound', [
        wbFormIDCk(gameProperties, 'Sound', [SOUN]),
        wbInteger(gameProperties, 'Chance', itU8),
        wbByteArray(gameProperties, 'Unused', 3),
        wbInteger(gameProperties, 'Type', itU32, wbEnum(gameProperties, [], [
          19, 'Run',
          21, 'Run (Armor)',
          18, 'Sneak',
          20, 'Sneak (Armor)',
          17, 'Walk',
          22, 'Walk (Armor)'
        ]))
      ])
    ),
    wbFormIDCk(gameProperties, TNAM, 'Animation Sounds Template', [ARMO])
  ]);

  wbRecord(
  gameProperties,
  ARMA, 'Armor Addon', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbBMDT,
    wbRStruct(gameProperties, 'Male biped model', [
      wbString(gameProperties, MODL, 'Model FileName', 0, cpNormal, True),
      wbByteArray(gameProperties, MODT, 'Texture Files Hashes', 0, cpIgnore),
      wbMODS,
      wbMODD
    ], [], cpNormal, False, nil, True),
    wbRStruct(gameProperties, 'Male world model', [
      wbString(gameProperties, MOD2, 'Model FileName'),
      wbByteArray(gameProperties, MO2T, 'Texture Files Hashes', 0, cpIgnore),
      wbMO2S
    ], []),
    wbString(gameProperties, ICON, 'Male icon FileName'),
    wbString(gameProperties, MICO, 'Male mico FileName'),
    wbRStruct(gameProperties, 'Female biped model', [
      wbString(gameProperties, MOD3, 'Model FileName', 0, cpNormal, True),
      wbByteArray(gameProperties, MO3T, 'Texture Files Hashes', 0, cpIgnore),
      wbMO3S,
      wbMOSD
    ], [], cpNormal, False, nil, True),
    wbRStruct(gameProperties, 'Female world model', [
      wbString(gameProperties, MOD4, 'Model FileName'),
      wbByteArray(gameProperties, MO4T, 'Texture Files Hashes', 0, cpIgnore),
      wbMO4S
    ], []),
    wbString(gameProperties, ICO2, 'Female icon FileName'),
    wbString(gameProperties, MIC2, 'Female mico FileName'),
    wbETYPReq,
    wbStruct(gameProperties, DATA, 'Data', [
      wbInteger(gameProperties, 'Value', itS32),
      wbInteger(gameProperties, 'Max Condition', itS32),
      wbFloat(gameProperties, 'Weight')
    ], cpNormal, True),
    wbStruct(gameProperties, DNAM, '', [
      wbInteger(gameProperties, 'AR', itS16, wbDiv(gameProperties, 100)),
      wbInteger(gameProperties, 'Flags', itU16, wbFlags(gameProperties, [ // Only a byte or 2 distincts byte
        'Modulates Voice'
      ])),
      wbFloat(gameProperties, 'DT'),
      wbByteArray(gameProperties, 'Unused', 4)
    ], cpNormal, True, nil, 2)
  ]);

  wbRecord(
  gameProperties,
  BOOK, 'Book', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbICON,
    wbSCRI,
    wbDESCReq,
    wbDEST,
    wbYNAM,
    wbZNAM,
    wbStruct(gameProperties, DATA, 'Data', [
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        '',
        'Can''t be Taken'
      ])),
      wbInteger(gameProperties, 'Skill', itS8, wbSkillEnum),
      wbInteger(gameProperties, 'Value', itS32),
      wbFloat(gameProperties, 'Weight')
    ], cpNormal, True)
  ]);

  wbSPLO := wbFormIDCk(gameProperties, SPLO, 'Actor Effect', [SPEL]);
  wbSPLOs := wbRArrayS(gameProperties, 'Actor Effects', wbSPLO, cpNormal, False, nil, nil, wbActorTemplateUseActorEffectList);

  wbRecord(
  gameProperties,
  CELL, 'Cell', [
    wbEDID,
    wbFULL,
    wbInteger(gameProperties, DATA, 'Flags', itU8, wbFlags(gameProperties, [
      {0x01} 'Is Interior Cell',
      {0x02} 'Has water',
      {0x04} 'Invert Fast Travel behavior',
      {0x08} 'No LOD Water',
      {0x10} '',
      {0x20} 'Public place',
      {0x40} 'Hand changed',
      {0x80} 'Behave like exterior'
    ]), cpNormal, True),
    wbStruct(gameProperties, XCLC, 'Grid', [
      wbInteger(gameProperties, 'X', itS32),
      wbInteger(gameProperties, 'Y', itS32),
      wbInteger(gameProperties, 'Force Hide Land', itU32, wbFlags(gameProperties, [
        'Quad 1',
        'Quad 2',
        'Quad 3',
        'Quad 4'
      ], True))
    ], cpNormal, False, nil, 2),
    wbStruct(gameProperties, XCLL, 'Lighting', [
      wbStruct(gameProperties, 'Ambient Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Directional Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Fog Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbFloat(gameProperties, 'Fog Near'),
      wbFloat(gameProperties, 'Fog Far'),
      wbInteger(gameProperties, 'Directional Rotation XY', itS32),
      wbInteger(gameProperties, 'Directional Rotation Z', itS32),
      wbFloat(gameProperties, 'Directional Fade'),
      wbFloat(gameProperties, 'Fog Clip Dist'),
      wbFloat(gameProperties, 'Fog Power')
    ], cpNormal, False, nil, 7),
    wbArray(gameProperties, IMPF, 'Footstep Materials', wbString(gameProperties, 'Unknown', 30), [
      'ConcSolid',
      'ConcBroken',
      'MetalSolid',
      'MetalHollow',
      'MetalSheet',
      'Wood',
      'Sand',
      'Dirt',
      'Grass',
      'Water'
    ]),
    wbRStruct(gameProperties, 'Light Template', [
      wbFormIDCk(gameProperties, LTMP, 'Template', [LGTM, NULL]),
      wbInteger(gameProperties, LNAM, 'Inherit', itU32, wbFlags(gameProperties, [
        {0x00000001}'Ambient Color',
        {0x00000002}'Directional Color',
        {0x00000004}'Fog Color',
        {0x00000008}'Fog Near',
        {0x00000010}'Fog Far',
        {0x00000020}'Directional Rotation',
        {0x00000040}'Directional Fade',
        {0x00000080}'Clip Distance',
        {0x00000100}'Fog Power'
      ]), cpNormal, True)
    ], [], cpNormal, True ),
    wbFloat(gameProperties, XCLW, 'Water Height'),
    wbString(gameProperties, XNAM, 'Water Noise Texture'),
    wbArrayS(gameProperties, XCLR, 'Regions', wbFormIDCk(gameProperties, 'Region', [REGN])),
    wbFormIDCk(gameProperties, XCIM, 'Image Space', [IMGS]),
    wbByteArray(gameProperties, XCET, 'Unknown', 1, cpIgnore),
    wbFormIDCk(gameProperties, XEZN, 'Encounter Zone', [ECZN]),
    wbFormIDCk(gameProperties, XCCM, 'Climate', [CLMT]),
    wbFormIDCk(gameProperties, XCWT, 'Water', [WATR]),
    wbRStruct(gameProperties, 'Ownership', [
      wbXOWN,
      wbInteger(gameProperties, XRNK, 'Faction rank', itS32)
    ], [XCMT, XCMO]),
    wbFormIDCk(gameProperties, XCAS, 'Acoustic Space', [ASPC]),
    wbByteArray(gameProperties, XCMT, 'Unused', 1, cpIgnore),
    wbFormIDCk(gameProperties, XCMO, 'Music Type', [MUSC])
  ], True, wbCellAddInfo, cpNormal, False, wbCELLAfterLoad);

  wbServiceFlags :=
    wbFlags(gameProperties, [
      {0x00000001} 'Weapons',
      {0x00000002} 'Armor',
      {0x00000004} 'Alcohol',
      {0x00000008} 'Books',
      {0x00000010} 'Food',
      {0x00000020} 'Chems',
      {0x00000040} 'Stimpacks',
      {0x00000080} 'Lights?',
      {0x00000100} '',
      {0x00000200} '',
      {0x00000400} 'Miscellaneous',
      {0x00000800} '',
      {0x00001000} '',
      {0x00002000} 'Potions?',
      {0x00004000} 'Training',
      {0x00008000} '',
      {0x00010000} 'Recharge',
      {0x00020000} 'Repair'
    ]);

  wbSpecializationEnum := wbEnum(gameProperties, ['Combat', 'Magic', 'Stealth']);

  wbRecord(
  gameProperties,
  CLAS, 'Class', [
    wbEDIDReq,
    wbFULLReq,
    wbDESCReq,
    wbICON,
    wbStruct(gameProperties, DATA, '', [
      wbArray(gameProperties, 'Tag Skills', wbInteger(gameProperties, 'Tag Skill', itS32, wbActorValueEnum), 4),
      wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, ['Playable', 'Guard'], True)),
      wbInteger(gameProperties, 'Buys/Sells and Services', itU32, wbServiceFlags),
      wbInteger(gameProperties, 'Teaches', itS8, wbSkillEnum),
      wbInteger(gameProperties, 'Maximum training level', itU8),
      wbByteArray(gameProperties, 'Unused', 2)
    ], cpNormal, True),
    wbArray(gameProperties, ATTR, 'Attributes', wbInteger(gameProperties, 'Attribute', itU8), [
      'Strength',
      'Perception',
      'Endurance',
      'Charisma',
      'Intelligence',
      'Agility',
      'Luck'
    ], cpNormal, True)
  ]);
end;

procedure DefineFNVc(var gameProperties: TGameProperties);
begin
  wbRecord(
  gameProperties,
  CLMT, 'Climate', [
    wbEDIDReq,
    wbArrayS(gameProperties, WLST, 'Weather Types', wbStructSK(gameProperties, [0], 'Weather Type', [
      wbFormIDCk(gameProperties, 'Weather', [WTHR, NULL]),
      wbInteger(gameProperties, 'Chance', itS32),
      wbFormIDCk(gameProperties, 'Global', [GLOB, NULL])
    ])),
    wbString(gameProperties, FNAM, 'Sun Texture'),
    wbString(gameProperties, GNAM, 'Sun Glare Texture'),
    wbMODL,
    wbStruct(gameProperties, TNAM, 'Timing', [
      wbStruct(gameProperties, 'Sunrise', [
        wbInteger(gameProperties, 'Begin', itU8, wbClmtTime),
        wbInteger(gameProperties, 'End', itU8, wbClmtTime)
      ]),
      wbStruct(gameProperties, 'Sunset', [
        wbInteger(gameProperties, 'Begin', itU8, wbClmtTime),
        wbInteger(gameProperties, 'End', itU8, wbClmtTime)
      ]),
      wbInteger(gameProperties, 'Volatility', itU8),
      wbInteger(gameProperties, 'Moons / Phase Length', itU8, wbClmtMoonsPhaseLength)
    ], cpNormal, True)
  ]);

  wbCNTO :=
    wbRStructExSK(gameProperties, [0], [1], 'Item', [
      wbStructExSK(gameProperties, CNTO, [0], [1], 'Item', [
        wbFormIDCk(gameProperties, 'Item', [ARMO, AMMO, MISC, WEAP, BOOK, LVLI, KEYM, ALCH, NOTE, IMOD, CMNY, CCRD, LIGH, CHIP{, MSTT{?}{, STAT{?}]),
        wbInteger(gameProperties, 'Count', itS32)
      ]),
      wbCOED
    ], []);

  wbCNTOs := wbRArrayS(gameProperties, 'Items', wbCNTO);

  wbRecord(
  gameProperties,
  CONT, 'Container', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbSCRI,
    wbCNTOs,
    wbDEST,
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, ['', 'Respawns'])),
      wbFloat(gameProperties, 'Weight')
    ], cpNormal, True),
    wbFormIDCk(gameProperties, SNAM, 'Sound - Open', [SOUN]),
    wbFormIDCk(gameProperties, QNAM, 'Sound - Close', [SOUN]),
    wbFormIDCk(gameProperties, RNAM, 'Sound - Random/Looping', [SOUN])
  ], True);

  wbCSDT := wbRStructSK(gameProperties, [0], 'Sound Type', [
    wbInteger(gameProperties, CSDT, 'Type', itU32,wbEnum(gameProperties, [
      {00} 'Left Foot',
      {01} 'Right Foot',
      {02} 'Left Back Foot',
      {03} 'Right Back Foot',
      {04} 'Idle',
      {05} 'Aware',
      {06} 'Attack',
      {07} 'Hit',
      {08} 'Death',
      {09} 'Weapon',
      {10} 'Movement Loop',
      {11} 'Conscious Loop',
      {12} 'Auxiliary 1',
      {13} 'Auxiliary 2',
      {14} 'Auxiliary 3',
      {15} 'Auxiliary 4',
      {16} 'Auxiliary 5',
      {17} 'Auxiliary 6',
      {18} 'Auxiliary 7',
      {19} 'Auxiliary 8',
      {19} 'Auxiliary 8',
      {20} 'Jump',
      {21} 'PlayRandom/Loop'
    ])),
    wbRArrayS(gameProperties, 'Sounds', wbRStructSK(gameProperties, [0], 'Sound', [
      wbFormIDCk(gameProperties, CSDI, 'Sound', [SOUN, NULL], False, cpNormal, True),
      wbInteger(gameProperties, CSDC, 'Sound Chance', itU8, nil, cpNormal, True)
    ], []), cpNormal, True)
  ], []);

  wbCSDTs := wbRArrayS(gameProperties, 'Sound Types', wbCSDT, cpNormal, False, nil, nil, wbActorTemplateUseModelAnimation);

  wbAgressionEnum := wbEnum(gameProperties, [
    'Unaggressive',
    'Aggressive',
    'Very Aggressive',
    'Frenzied'
  ]);

  wbConfidenceEnum := wbEnum(gameProperties, [
    'Cowardly',
    'Cautious',
    'Average',
    'Brave',
    'Foolhardy'
  ]);

  wbMoodEnum := wbEnum(gameProperties, [
    'Neutral',
    'Afraid',
    'Annoyed',
    'Cocky',
    'Drugged',
    'Pleasant',
    'Angry',
    'Sad'
  ]);

  wbAssistanceEnum := wbEnum(gameProperties, [
    'Helps Nobody',
    'Helps Allies',
    'Helps Friends and Allies'
  ]);

  wbAggroRadiusFlags := wbFlags(gameProperties, [
    'Aggro Radius Behavior'
  ]);

  wbAIDT :=
    wbStruct(gameProperties, AIDT, 'AI Data', [
     {00} wbInteger(gameProperties, 'Aggression', itU8, wbAgressionEnum),
     {01} wbInteger(gameProperties, 'Confidence', itU8, wbConfidenceEnum),
     {02} wbInteger(gameProperties, 'Energy Level', itU8),
     {03} wbInteger(gameProperties, 'Responsibility', itU8),
     {04} wbInteger(gameProperties, 'Mood', itU8, wbMoodEnum),
     {05} wbByteArray(gameProperties, 'Unused', 3),   // Mood is stored as a DWord as shown by endianSwapping but is truncated to byte during load :)
     {08} wbInteger(gameProperties, 'Buys/Sells and Services', itU32, wbServiceFlags),
     {0C} wbInteger(gameProperties, 'Teaches', itS8, wbSkillEnum),
     {0D} wbInteger(gameProperties, 'Maximum training level', itU8),
     {0E} wbInteger(gameProperties, 'Assistance', itS8, wbAssistanceEnum),
     {0F} wbInteger(gameProperties, 'Aggro Radius Behavior', itU8, wbAggroRadiusFlags),
     {10} wbInteger(gameProperties, 'Aggro Radius', itS32)
    ], cpNormal, True, wbActorTemplateUseAIData);

  wbAttackAnimationEnum :=
    wbEnum(gameProperties, [
    ], [
       26, 'AttackLeft',
       27, 'AttackLeftUp',
       28, 'AttackLeftDown',
       29, 'AttackLeftIS',
       30, 'AttackLeftISUp',
       31, 'AttackLeftISDown',
       32, 'AttackRight',
       33, 'AttackRightUp',
       34, 'AttackRightDown',
       35, 'AttackRightIS',
       36, 'AttackRightISUp',
       37, 'AttackRightISDown',
       38, 'Attack3',
       39, 'Attack3Up',
       40, 'Attack3Down',
       41, 'Attack3IS',
       42, 'Attack3ISUp',
       43, 'Attack3ISDown',
       44, 'Attack4',
       45, 'Attack4Up',
       46, 'Attack4Down',
       47, 'Attack4IS',
       48, 'Attack4ISUp',
       49, 'Attack4ISDown',
       50, 'Attack5',
       51, 'Attack5Up',
       52, 'Attack5Down',
       53, 'Attack5IS',
       54, 'Attack5ISUp',
       55, 'Attack5ISDown',
       56, 'Attack6',
       57, 'Attack6Up',
       58, 'Attack6Down',
       59, 'Attack6IS',
       60, 'Attack6ISUp',
       61, 'Attack6ISDown',
       62, 'Attack7',
       63, 'Attack7Up',
       64, 'Attack7Down',
       65, 'Attack7IS',
       66, 'Attack7ISUp',
       67, 'Attack7ISDown',
       68, 'Attack8',
       69, 'Attack8Up',
       70, 'Attack8Down',
       71, 'Attack8IS',
       72, 'Attack8ISUp',
       73, 'Attack8ISDown',
       74, 'AttackLoop',
       75, 'AttackLoopUp',
       76, 'AttackLoopDown',
       77, 'AttackLoopIS',
       78, 'AttackLoopISUp',
       79, 'AttackLoopISDown',
       80, 'AttackSpin',
       81, 'AttackSpinUp',
       82, 'AttackSpinDown',
       83, 'AttackSpinIS',
       84, 'AttackSpinISUp',
       85, 'AttackSpinISDown',
       86, 'AttackSpin2',
       87, 'AttackSpin2Up',
       88, 'AttackSpin2Down',
       89, 'AttackSpin2IS',
       90, 'AttackSpin2ISUp',
       91, 'AttackSpin2ISDown',
       92, 'AttackPower',
       93, 'AttackForwardPower',
       94, 'AttackBackPower',
       95, 'AttackLeftPower',
       96, 'AttackRightPower',
       97, 'PlaceMine',
       98, 'PlaceMineUp',
       99, 'PlaceMineDown',
      100, 'PlaceMineIS',
      101, 'PlaceMineISUp',
      102, 'PlaceMineISDown',
      103, 'PlaceMine2',
      104, 'PlaceMine2Up',
      105, 'PlaceMine2Down',
      106, 'PlaceMine2IS',
      107, 'PlaceMine2ISUp',
      108, 'PlaceMine2ISDown',
      109, 'AttackThrow',
      110, 'AttackThrowUp',
      111, 'AttackThrowDown',
      112, 'AttackThrowIS',
      113, 'AttackThrowISUp',
      114, 'AttackThrowISDown',
      115, 'AttackThrow2',
      116, 'AttackThrow2Up',
      117, 'AttackThrow2Down',
      118, 'AttackThrow2IS',
      119, 'AttackThrow2ISUp',
      120, 'AttackThrow2ISDown',
      121, 'AttackThrow3',
      122, 'AttackThrow3Up',
      123, 'AttackThrow3Down',
      124, 'AttackThrow3IS',
      125, 'AttackThrow3ISUp',
      126, 'AttackThrow3ISDown',
      127, 'AttackThrow4',
      128, 'AttackThrow4Up',
      129, 'AttackThrow4Down',
      130, 'AttackThrow4IS',
      131, 'AttackThrow4ISUp',
      132, 'AttackThrow4ISDown',
      133, 'AttackThrow5',
      134, 'AttackThrow5Up',
      135, 'AttackThrow5Down',
      136, 'AttackThrow5IS',
      137, 'AttackThrow5ISUp',
      138, 'AttackThrow5ISDown',

      167, 'PipBoy',
      178, 'PipBoyChild',

      255, ' ANY'
    ]);

  wbImpactMaterialTypeEnum :=
    wbEnum(gameProperties, [
      'Stone',
      'Dirt',
      'Grass',
      'Glass',
      'Metal',
      'Wood',
      'Organic',
      'Cloth',
      'Water',
      'Hollow Metal',
      'Organic Bug',
      'Organic Glow'
    ]);

  wbTemplateFlags := wbFlags(gameProperties, [
    'Use Traits',
    'Use Stats',
    'Use Factions',
    'Use Actor Effect List',
    'Use AI Data',
    'Use AI Packages',
    'Use Model/Animation',
    'Use Base Data',
    'Use Inventory',
    'Use Script'
  ]);

  wbRecord(
  gameProperties,
  CREA, 'Creature', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULLActor,
    wbMODLActor,
    wbSPLOs,
    wbFormIDCk(gameProperties, EITM, 'Unarmed Attack Effect', [ENCH, SPEL], False, cpNormal, False, wbActorTemplateUseActorEffectList),
    wbInteger(gameProperties, EAMT, 'Unarmed Attack Animation', itU16, wbAttackAnimationEnum, cpNormal, True, False, wbActorTemplateUseActorEffectList),
    wbArrayS(gameProperties, NIFZ, 'Model List', wbStringLC(gameProperties, 'Model'), 0, cpNormal, False, nil, nil, wbActorTemplateUseModelAnimation),
    wbByteArray(gameProperties, NIFT, 'Texture Files Hashes', 0, cpIgnore, False, False, wbActorTemplateUseModelAnimation),
    wbStruct(gameProperties, ACBS, 'Configuration', [
      {00} wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
             {0x000001} 'Biped',
             {0x000002} 'Essential',
             {0x000004} 'Weapon & Shield?',
             {0x000008} 'Respawn',
             {0x000010} 'Swims',
             {0x000020} 'Flies',
             {0x000040} 'Walks',
             {0x000080} 'PC Level Mult',
             {0x000100} 'Unknown 8',
             {0x000200} 'No Low Level Processing',
             {0x000400} '',
             {0x000800} 'No Blood Spray',
             {0x001000} 'No Blood Decal',
             {0x002000} '',
             {0x004000} '',
             {0x008000} 'No Head',
             {0x010000} 'No Right Arm',
             {0x020000} 'No Left Arm',
             {0x040000} 'No Combat in Water',
             {0x080000} 'No Shadow',
             {0x100000} 'No VATS Melee',
           {0x00200000} 'Allow PC Dialogue',
           {0x00400000} 'Can''t Open Doors',
           {0x00800000} 'Immobile',
           {0x01000000} 'Tilt Front/Back',
           {0x02000000} 'Tilt Left/Right',
           {0x03000000} 'No Knockdowns',
           {0x08000000} 'Not Pushable',
           {0x10000000} 'Allow Pickpocket',
           {0x20000000} 'Is Ghost',
           {0x40000000} 'No Rotating To Head-track',
           {0x80000000} 'Invulnerable'
           ], [
             {0x000001 Biped} wbActorTemplateUseModelAnimation,
             {0x000002 Essential} wbActorTemplateUseBaseData,
             {0x000004 Weapon & Shield} nil,
             {0x000008 Respawn} wbActorTemplateUseBaseData,
             {0x000010 Swims} wbActorTemplateUseModelAnimation,
             {0x000020 Flies} wbActorTemplateUseModelAnimation,
             {0x000040 Walks} wbActorTemplateUseModelAnimation,
             {0x000080 PC Level Mult} wbActorTemplateUseStats,
             {0x000100 Unknown 8} nil,
             {0x000200 No Low Level Processing} wbActorTemplateUseBaseData,
             {0x000400 } nil,
             {0x000800 No Blood Spray} wbActorTemplateUseModelAnimation,
             {0x001000 No Blood Decal} wbActorTemplateUseModelAnimation,
             {0x002000 } nil,
             {0x004000 } nil,
             {0x008000 No Head} wbActorTemplateUseModelAnimation,
             {0x010000 No Right Arm} wbActorTemplateUseModelAnimation,
             {0x020000 No Left Arm} wbActorTemplateUseModelAnimation,
             {0x040000 No Combat in Water} wbActorTemplateUseModelAnimation,
             {0x080000 No Shadow} wbActorTemplateUseModelAnimation,
             {0x100000 No VATS Melee} nil,
           {0x00200000 Allow PC Dialogue} wbActorTemplateUseBaseData,
           {0x00400000 Can''t Open Doors} wbActorTemplateUseBaseData,
           {0x00800000 Immobile} wbActorTemplateUseModelAnimation,
           {0x01000000 Tilt Front/Back} wbActorTemplateUseModelAnimation,
           {0x02000000 Tilt Left/Right} wbActorTemplateUseModelAnimation,
           {0x03000000 No Knockdowns} nil,
           {0x08000000 Not Pushable} wbActorTemplateUseModelAnimation,
           {0x10000000 Allow Pickpocket} wbActorTemplateUseBaseData,
           {0x20000000 Is Ghost} nil,
           {0x40000000 No Rotating To Head-track} wbActorTemplateUseModelAnimation,
           {0x80000000 Invulnerable} nil
           ])),
      {04} wbInteger(gameProperties, 'Fatigue', itU16, nil, cpNormal, False, wbActorTemplateUseStats),
      {06} wbInteger(gameProperties, 'Barter gold', itU16, nil, cpNormal, False, wbActorTemplateUseAIData),
      {08} wbUnion(gameProperties, 'Level', wbCreaLevelDecider, [
             wbInteger(gameProperties, 'Level', itS16, nil, cpNormal, False, wbActorTemplateUseStats),
             wbInteger(gameProperties, 'Level Mult', itS16, wbDiv(gameProperties, 1000), cpNormal, False, wbActorTemplateUseStats)
           ], cpNormal, False, wbActorTemplateUseStats),
      {10} wbInteger(gameProperties, 'Calc min', itU16, nil, cpNormal, False, wbActorTemplateUseStats),
      {12} wbInteger(gameProperties, 'Calc max', itU16, nil, cpNormal, False, wbActorTemplateUseStats),
      {14} wbInteger(gameProperties, 'Speed Multiplier', itU16, nil, cpNormal, False, wbActorTemplateUseStats),
      {16} wbFloat(gameProperties, 'Karma (Alignment)', cpNormal, False, 1, -1, wbActorTemplateUseTraits),
      {20} wbInteger(gameProperties, 'Disposition Base', itS16, nil, cpNormal, False, wbActorTemplateUseTraits),
      {22} wbInteger(gameProperties, 'Template Flags', itU16, wbTemplateFlags)
    ], cpNormal, True),
    wbRArrayS(gameProperties, 'Factions',
      wbStructSK(gameProperties, SNAM, [0], 'Faction', [
        wbFormIDCk(gameProperties, 'Faction', [FACT]),
        wbInteger(gameProperties, 'Rank', itU8),
        wbByteArray(gameProperties, 'Unused', 3)
      ]),
    cpNormal, False, nil, nil, wbActorTemplateUseFactions),
    wbFormIDCk(gameProperties, INAM, 'Death item', [LVLI], False, cpNormal, False, wbActorTemplateUseTraits),
    wbFormIDCk(gameProperties, VTCK, 'Voice', [VTYP], False, cpNormal, False, wbActorTemplateUseTraits),
    wbFormIDCk(gameProperties, TPLT, 'Template', [CREA, LVLC]),
    wbDESTActor,
    wbSCRIActor,
    wbRArrayS(gameProperties, 'Items', wbCNTO, cpNormal, False, nil, nil, wbActorTemplateUseInventory),
    wbAIDT,
    wbRArray(gameProperties, 'Packages', wbFormIDCk(gameProperties, PKID, 'Package', [PACK]), cpNormal, False, nil, nil, wbActorTemplateUseAIPackages),
    wbArrayS(gameProperties, KFFZ, 'Animations', wbStringLC(gameProperties, 'Animation'), 0, cpNormal, False, nil, nil, wbActorTemplateUseModelAnimation),
    wbStruct(gameProperties, DATA, '', [
      {00} wbInteger(gameProperties, 'Type', itU8, wbCreatureTypeEnum, cpNormal, False, wbActorTemplateUseTraits),
      {01} wbInteger(gameProperties, 'Combat Skill', itU8, nil, cpNormal, False, wbActorTemplateUseStats),
      {02} wbInteger(gameProperties, 'Magic Skill', itU8, nil, cpNormal, False, wbActorTemplateUseStats),
      {03} wbInteger(gameProperties, 'Stealth Skill', itU8, nil, cpNormal, False, wbActorTemplateUseStats),
      {04} wbInteger(gameProperties, 'Health', itS16, nil, cpNormal, False, wbActorTemplateUseStats),
      {06} wbByteArray(gameProperties, 'Unused', 2),
      {08} wbInteger(gameProperties, 'Damage', itS16, nil, cpNormal, False, wbActorTemplateUseStats),
      {10} wbArray(gameProperties, 'Attributes', wbInteger(gameProperties, 'Attribute', itU8), [
            'Strength',
            'Perception',
            'Endurance',
            'Charisma',
            'Intelligence',
            'Agility',
            'Luck'
          ], cpNormal, False, wbActorTemplateUseStats)
    ], cpNormal, True),
    wbInteger(gameProperties, RNAM, 'Attack reach', itU8, nil, cpNormal, True, False, wbActorTemplateUseTraits),
    wbFormIDCk(gameProperties, ZNAM, 'Combat Style', [CSTY], False, cpNormal, False, wbActorTemplateUseTraits),
    wbFormIDCk(gameProperties, PNAM, 'Body Part Data', [BPTD], False, cpNormal, True, wbActorTemplateUseModelAnimation),
    wbFloat(gameProperties, TNAM, 'Turning Speed', cpNormal, True, 1, -1, wbActorTemplateUseStats),
    wbFloat(gameProperties, BNAM, 'Base Scale', cpNormal, True, 1, -1, wbActorTemplateUseStats),
    wbFloat(gameProperties, WNAM, 'Foot Weight', cpNormal, True, 1, -1, wbActorTemplateUseStats),
    wbInteger(gameProperties, NAM4, 'Impact Material Type', itU32, wbImpactMaterialTypeEnum, cpNormal, True, False, wbActorTemplateUseModelAnimation),
    wbInteger(gameProperties, NAM5, 'Sound Level', itU32, wbSoundLevelEnum, cpNormal, True, False, wbActorTemplateUseModelAnimation),
    wbFormIDCk(gameProperties, CSCR, 'Inherits Sounds from', [CREA], False, cpNormal, False, wbActorTemplateUseModelAnimation),
    wbCSDTs,
    wbFormIDCk(gameProperties, CNAM, 'Impact Dataset', [IPDS], False, cpNormal, False, wbActorTemplateUseModelAnimation),
    wbFormIDCk(gameProperties, LNAM, 'Melee Weapon List', [FLST], False, cpNormal, False, wbActorTemplateUseTraits)
  ], True);

end;

procedure DefineFNVd(var gameProperties: TGameProperties);
begin
  wbRecord(
  gameProperties,
  CSTY, 'Combat Style', [
    wbEDIDReq,
    wbStruct(gameProperties, CSTD, 'Advanced - Standard', [
      {000}wbInteger(gameProperties, 'Maneuver Decision - Dodge % Chance', itU8),
      {001}wbInteger(gameProperties, 'Maneuver Decision - Left/Right % Chance', itU8),
      {002}wbByteArray(gameProperties, 'Unused', 2),
      {004}wbFloat(gameProperties, 'Maneuver Decision - Dodge L/R Timer (min)'),
      {008}wbFloat(gameProperties, 'Maneuver Decision - Dodge L/R Timer (max)'),
      {012}wbFloat(gameProperties, 'Maneuver Decision - Dodge Forward Timer (min)'),
      {016}wbFloat(gameProperties, 'Maneuver Decision - Dodge Forward Timer (max)'),
      {020}wbFloat(gameProperties, 'Maneuver Decision - Dodge Back Timer Min'),
      {024}wbFloat(gameProperties, 'Maneuver Decision - Dodge Back Timer Max'),
      {028}wbFloat(gameProperties, 'Maneuver Decision - Idle Timer min'),
      {032}wbFloat(gameProperties, 'Maneuver Decision - Idle Timer max'),
      {036}wbInteger(gameProperties, 'Melee Decision - Block % Chance', itU8),
      {037}wbInteger(gameProperties, 'Melee Decision - Attack % Chance', itU8),
      {038}wbByteArray(gameProperties, 'Unused', 2),
      {040}wbFloat(gameProperties, 'Melee Decision - Recoil/Stagger Bonus to Attack'),
      {044}wbFloat(gameProperties, 'Melee Decision - Unconscious Bonus to Attack'),
      {048}wbFloat(gameProperties, 'Melee Decision - Hand-To-Hand Bonus to Attack'),
      {052}wbInteger(gameProperties, 'Melee Decision - Power Attacks - Power Attack % Chance', itU8),
      {053}wbByteArray(gameProperties, 'Unused', 3),
      {056}wbFloat(gameProperties, 'Melee Decision - Power Attacks - Recoil/Stagger Bonus to Power'),
      {060}wbFloat(gameProperties, 'Melee Decision - Power Attacks - Unconscious Bonus to Power Attack'),
      {064}wbInteger(gameProperties, 'Melee Decision - Power Attacks - Normal', itU8),
      {065}wbInteger(gameProperties, 'Melee Decision - Power Attacks - Forward', itU8),
      {066}wbInteger(gameProperties, 'Melee Decision - Power Attacks - Back', itU8),
      {067}wbInteger(gameProperties, 'Melee Decision - Power Attacks - Left', itU8),
      {068}wbInteger(gameProperties, 'Melee Decision - Power Attacks - Right', itU8),
      {069}wbByteArray(gameProperties, 'Unused', 3),
      {072}wbFloat(gameProperties, 'Melee Decision - Hold Timer (min)'),
      {076}wbFloat(gameProperties, 'Melee Decision - Hold Timer (max)'),
      {080}wbInteger(gameProperties, 'Flags', itU16, wbFlags(gameProperties, [
             'Choose Attack using % Chance',
             'Melee Alert OK',
             'Flee Based on Personal Survival',
             '',
             'Ignore Threats',
             'Ignore Damaging Self',
             'Ignore Damaging Group',
             'Ignore Damaging Spectators',
             'Cannot Use Stealthboy'
           ])),
      {082}wbByteArray(gameProperties, 'Unused', 2),
      {085}wbInteger(gameProperties, 'Maneuver Decision - Acrobatic Dodge % Chance', itU8),
      {085}wbInteger(gameProperties, 'Melee Decision - Power Attacks - Rushing Attack % Chance', itU8),
      {086}wbByteArray(gameProperties, 'Unused', 2),
      {088}wbFloat(gameProperties, 'Melee Decision - Power Attacks - Rushing Attack Distance Mult')
    ], cpNormal, True),
    wbStruct(gameProperties, CSAD, 'Advanced - Advanced', [
      wbFloat(gameProperties, 'Dodge Fatigue Mod Mult'),
      wbFloat(gameProperties, 'Dodge Fatigue Mod Base'),
      wbFloat(gameProperties, 'Encumb. Speed Mod Base'),
      wbFloat(gameProperties, 'Encumb. Speed Mod Mult'),
      wbFloat(gameProperties, 'Dodge While Under Attack Mult'),
      wbFloat(gameProperties, 'Dodge Not Under Attack Mult'),
      wbFloat(gameProperties, 'Dodge Back While Under Attack Mult'),
      wbFloat(gameProperties, 'Dodge Back Not Under Attack Mult'),
      wbFloat(gameProperties, 'Dodge Forward While Attacking Mult'),
      wbFloat(gameProperties, 'Dodge Forward Not Attacking Mult'),
      wbFloat(gameProperties, 'Block Skill Modifier Mult'),
      wbFloat(gameProperties, 'Block Skill Modifier Base'),
      wbFloat(gameProperties, 'Block While Under Attack Mult'),
      wbFloat(gameProperties, 'Block Not Under Attack Mult'),
      wbFloat(gameProperties, 'Attack Skill Modifier Mult'),
      wbFloat(gameProperties, 'Attack Skill Modifier Base'),
      wbFloat(gameProperties, 'Attack While Under Attack Mult'),
      wbFloat(gameProperties, 'Attack Not Under Attack Mult'),
      wbFloat(gameProperties, 'Attack During Block Mult'),
      wbFloat(gameProperties, 'Power Att. Fatigue Mod Base'),
      wbFloat(gameProperties, 'Power Att. Fatigue Mod Mult')
    ], cpNormal, True),
    wbStruct(gameProperties, CSSD, 'Simple', [
      {00} wbFloat(gameProperties, 'Cover Search Radius'),
      {04} wbFloat(gameProperties, 'Take Cover Chance'),
      {08} wbFloat(gameProperties, 'Wait Timer (min)'),
      {12} wbFloat(gameProperties, 'Wait Timer (max)'),
      {16} wbFloat(gameProperties, 'Wait to Fire Timer (min)'),
      {20} wbFloat(gameProperties, 'Wait to Fire Timer (max)'),
      {24} wbFloat(gameProperties, 'Fire Timer (min)'),
      {28} wbFloat(gameProperties, 'Fire Timer (max)'),
      {32} wbFloat(gameProperties, 'Ranged Weapon Range Mult (min)'),
      {36} wbByteArray(gameProperties, 'Unused', 4),
      {40} wbInteger(gameProperties, 'Weapon Restrictions', itU32, wbEnum(gameProperties, [
        'None',
        'Melee Only',
        'Ranged Only'
      ])),
      {44} wbFloat(gameProperties, 'Ranged Weapon Range Mult (max)'),
      {48} wbFloat(gameProperties, 'Max Targeting FOV'),
      {52} wbFloat(gameProperties, 'Combat Radius'),
      {56} wbFloat(gameProperties, 'Semi-Auto Firing Delay Mult (min)'),
      {60} wbFloat(gameProperties, 'Semi-Auto Firing Delay Mult (max)')
    ], cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  DIAL, 'Dialog Topic', [
    wbEDIDReqKC,
    wbRArrayS(gameProperties, 'Added Quests', wbRStructSK(gameProperties, [0], 'Added Quest', [
      wbFormIDCkNoReach(gameProperties, QSTI, 'Quest', [QUST], False, cpBenign),
      wbRArray(gameProperties, 'Shared Infos', wbRStruct(gameProperties, 'Shared Info', [
        wbFormIDCk(gameProperties, INFC, 'Info Connection', [INFO], False, cpBenign),
        wbInteger(gameProperties, INFX, 'Info Index', itS32, nil, cpBenign)
      ], []))
    ], [])),
    // no QSTR in FNV, but keep it just in case
    wbRArrayS(gameProperties, 'Removed Quests', wbRStructSK(gameProperties, [0], 'Removed Quest', [
      wbFormIDCkNoReach(gameProperties, QSTR, 'Quest', [QUST], False, cpBenign)
    ], [])),
    // some records have INFC INFX (with absent formids) but no QSTI, probably error in GECK
    // i.e. [DIAL:001287C6] and [DIAL:000E9084]
    wbRArray(gameProperties, 'Unused', wbRStruct(gameProperties, 'Unused', [
      wbUnknown(gameProperties, INFC, cpIgnore),
      wbUnknown(gameProperties, INFX, cpIgnore)
    ], []), cpIgnore, False, nil, nil, wbNeverShow),
    wbFULL,
    wbFloat(gameProperties, PNAM, 'Priority', cpNormal, True, 1, -1, nil, nil, 50.0),
    wbStringKC(gameProperties, TDUM, 'Dumb Response'),
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Type', itU8, wbEnum(gameProperties, [
        {0} 'Topic',
        {1} 'Conversation',
        {2} 'Combat',
        {3} 'Persuasion',
        {4} 'Detection',
        {5} 'Service',
        {6} 'Miscellaneous',
        {7} 'Radio'
      ])),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        'Rumors',
        'Top-level'
      ]))
    ], cpNormal, True, nil, 1)
  ], True);

  wbRecord(
  gameProperties,
  DOOR, 'Door', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODLReq,
    wbSCRI,
    wbDEST,
    wbFormIDCk(gameProperties, SNAM, 'Sound - Open', [SOUN]),
    wbFormIDCk(gameProperties, ANAM, 'Sound - Close', [SOUN]),
    wbFormIDCk(gameProperties, BNAM, 'Sound - Looping', [SOUN]),
    wbInteger(gameProperties, FNAM, 'Flags', itU8, wbFlags(gameProperties, [
      '',
      'Automatic Door',
      'Hidden',
      'Minimal Use',
      'Sliding Door'
    ]), cpNormal, True)
  ]);

  wbBlendModeEnum := wbEnum(gameProperties, [
    '',
    'Zero',
    'One',
    'Source Color',
    'Source Inverse Color',
    'Source Alpha',
    'Source Inverted Alpha',
    'Dest Alpha',
    'Dest Inverted Alpha',
    'Dest Color',
    'Dest Inverse Color',
    'Source Alpha SAT'
  ]);

  wbBlendOpEnum := wbEnum(gameProperties, [
    '',
    'Add',
    'Subtract',
    'Reverse Subtract',
    'Minimum',
    'Maximum'
  ]);
  wbZTestFuncEnum := wbEnum(gameProperties, [
    '',
    '',
    '',
    'Equal To',
    'Normal',
    'Greater Than',
    '',
    'Greater Than or Equal Than',
    'Always Show'
  ]);

  wbRecord(
  gameProperties,
  EFSH, 'Effect Shader', [
    wbEDID,
    wbString(gameProperties, ICON, 'Fill Texture'),
    wbString(gameProperties, ICO2, 'Particle Shader Texture'),
    wbString(gameProperties, NAM7, 'Holes Texture'),
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        {0} 'No Membrane Shader',
        {1} '',
        {2} '',
        {3} 'No Particle Shader',
        {4} 'Edge Effect - Inverse',
        {5} 'Membrane Shader - Affect Skin Only'
      ])),
      wbByteArray(gameProperties, 'Unused', 3),
      wbInteger(gameProperties, 'Membrane Shader - Source Blend Mode', itU32, wbBlendModeEnum),
      wbInteger(gameProperties, 'Membrane Shader - Blend Operation', itU32, wbBlendOpEnum),
      wbInteger(gameProperties, 'Membrane Shader - Z Test Function', itU32, wbZTestFuncEnum),
      wbStruct(gameProperties, 'Fill/Texture Effect - Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbFloat(gameProperties, 'Fill/Texture Effect - Alpha Fade In Time'),
      wbFloat(gameProperties, 'Fill/Texture Effect - Full Alpha Time'),
      wbFloat(gameProperties, 'Fill/Texture Effect - Alpha Fade Out Time'),
      wbFloat(gameProperties, 'Fill/Texture Effect - Presistent Alpha Ratio'),
      wbFloat(gameProperties, 'Fill/Texture Effect - Alpha Pulse Amplitude'),
      wbFloat(gameProperties, 'Fill/Texture Effect - Alpha Pulse Frequency'),
      wbFloat(gameProperties, 'Fill/Texture Effect - Texture Animation Speed (U)'),
      wbFloat(gameProperties, 'Fill/Texture Effect - Texture Animation Speed (V)'),
      wbFloat(gameProperties, 'Edge Effect - Fall Off'),
      wbStruct(gameProperties, 'Edge Effect - Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbFloat(gameProperties, 'Edge Effect - Alpha Fade In Time'),
      wbFloat(gameProperties, 'Edge Effect - Full Alpha Time'),
      wbFloat(gameProperties, 'Edge Effect - Alpha Fade Out Time'),
      wbFloat(gameProperties, 'Edge Effect - Persistent Alpha Ratio'),
      wbFloat(gameProperties, 'Edge Effect - Alpha Pulse Amplitude'),
      wbFloat(gameProperties, 'Edge Effect - Alpha Pusle Frequence'),
      wbFloat(gameProperties, 'Fill/Texture Effect - Full Alpha Ratio'),
      wbFloat(gameProperties, 'Edge Effect - Full Alpha Ratio'),
      wbInteger(gameProperties, 'Membrane Shader - Dest Blend Mode', itU32, wbBlendModeEnum),
      wbInteger(gameProperties, 'Particle Shader - Source Blend Mode', itU32, wbBlendModeEnum),
      wbInteger(gameProperties, 'Particle Shader - Blend Operation', itU32, wbBlendOpEnum),
      wbInteger(gameProperties, 'Particle Shader - Z Test Function', itU32, wbZTestFuncEnum),
      wbInteger(gameProperties, 'Particle Shader - Dest Blend Mode', itU32, wbBlendModeEnum),
      wbFloat(gameProperties, 'Particle Shader - Particle Birth Ramp Up Time'),
      wbFloat(gameProperties, 'Particle Shader - Full Particle Birth Time'),
      wbFloat(gameProperties, 'Particle Shader - Particle Birth Ramp Down Time'),
      wbFloat(gameProperties, 'Particle Shader - Full Particle Birth Ratio'),
      wbFloat(gameProperties, 'Particle Shader - Persistant Particle Birth Ratio'),
      wbFloat(gameProperties, 'Particle Shader - Particle Lifetime'),
      wbFloat(gameProperties, 'Particle Shader - Particle Lifetime +/-'),
      wbFloat(gameProperties, 'Particle Shader - Initial Speed Along Normal'),
      wbFloat(gameProperties, 'Particle Shader - Acceleration Along Normal'),
      wbFloat(gameProperties, 'Particle Shader - Initial Velocity #1'),
      wbFloat(gameProperties, 'Particle Shader - Initial Velocity #2'),
      wbFloat(gameProperties, 'Particle Shader - Initial Velocity #3'),
      wbFloat(gameProperties, 'Particle Shader - Acceleration #1'),
      wbFloat(gameProperties, 'Particle Shader - Acceleration #2'),
      wbFloat(gameProperties, 'Particle Shader - Acceleration #3'),
      wbFloat(gameProperties, 'Particle Shader - Scale Key 1'),
      wbFloat(gameProperties, 'Particle Shader - Scale Key 2'),
      wbFloat(gameProperties, 'Particle Shader - Scale Key 1 Time'),
      wbFloat(gameProperties, 'Particle Shader - Scale Key 2 Time'),
      wbStruct(gameProperties, 'Color Key 1 - Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Color Key 2 - Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Color Key 3 - Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbFloat(gameProperties, 'Color Key 1 - Color Alpha'),
      wbFloat(gameProperties, 'Color Key 2 - Color Alpha'),
      wbFloat(gameProperties, 'Color Key 3 - Color Alpha'),
      wbFloat(gameProperties, 'Color Key 1 - Color Key Time'),
      wbFloat(gameProperties, 'Color Key 2 - Color Key Time'),
      wbFloat(gameProperties, 'Color Key 3 - Color Key Time'),
      wbFloat(gameProperties, 'Particle Shader - Initial Speed Along Normal +/-'),
      wbFloat(gameProperties, 'Particle Shader - Initial Rotation (deg)'),
      wbFloat(gameProperties, 'Particle Shader - Initial Rotation (deg) +/-'),
      wbFloat(gameProperties, 'Particle Shader - Rotation Speed (deg/sec)'),
      wbFloat(gameProperties, 'Particle Shader - Rotation Speed (deg/sec) +/-'),
      wbFormIDCk(gameProperties, 'Addon Models', [DEBR, NULL]),
      wbFloat(gameProperties, 'Holes - Start Time'),
      wbFloat(gameProperties, 'Holes - End Time'),
      wbFloat(gameProperties, 'Holes - Start Val'),
      wbFloat(gameProperties, 'Holes - End Val'),
      wbFloat(gameProperties, 'Edge Width (alpha units)'),
      wbStruct(gameProperties, 'Edge Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbFloat(gameProperties, 'Explosion Wind Speed'),
      wbInteger(gameProperties, 'Texture Count U', itU32),
      wbInteger(gameProperties, 'Texture Count V', itU32),
      wbFloat(gameProperties, 'Addon Models - Fade In Time'),
      wbFloat(gameProperties, 'Addon Models - Fade Out Time'),
      wbFloat(gameProperties, 'Addon Models - Scale Start'),
      wbFloat(gameProperties, 'Addon Models - Scale End'),
      wbFloat(gameProperties, 'Addon Models - Scale In Time'),
      wbFloat(gameProperties, 'Addon Models - Scale Out Time')
    ], cpNormal, True, nil, 57)
  ], False, nil, cpNormal, False, wbEFSHAfterLoad);

  wbRecord(
  gameProperties,
  ENCH, 'Object Effect', [
    wbEDIDReq,
    wbFULL,
    wbStruct(gameProperties, ENIT, 'Effect Data', [
      wbInteger(gameProperties, 'Type', itU32, wbEnum(gameProperties, [
        {0} '',
        {1} '',
        {2} 'Weapon',
        {3} 'Apparel'
      ])),
      wbByteArray(gameProperties, 'Unused', 4),
      wbByteArray(gameProperties, 'Unused', 4),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        'No Auto-Calc',
        'Auto Calculate',
        'Hide Effect'
      ])),
      wbByteArray(gameProperties, 'Unused', 3)
    ], cpNormal, True),
    wbEffectsReq
  ]);

  wbRecord(
  gameProperties,
  EYES, 'Eyes', [
    wbEDIDReq,
    wbFULLReq,
    wbString(gameProperties, ICON, 'Texture', 0{, cpNormal, True??}),
    wbInteger(gameProperties, DATA, 'Flags', itU8, wbFlags(gameProperties, [
      'Playable',
      'Not Male',
      'Not Female'
    ]), cpNormal, True)
  ]);

  wbXNAM :=
    wbStructSK(gameProperties, XNAM, [0], 'Relation', [
      wbFormIDCkNoReach(gameProperties, 'Faction', [FACT, RACE]),
      wbInteger(gameProperties, 'Modifier', itS32),
      wbInteger(gameProperties, 'Group Combat Reaction', itU32, wbEnum(gameProperties, [
        'Neutral',
        'Enemy',
        'Ally',
        'Friend'
      ]))
    ]);

  wbXNAMs := wbRArrayS(gameProperties, 'Relations', wbXNAM);

  wbRecord(
  gameProperties,
  FACT, 'Faction', [
    wbEDIDReq,
    wbFULL,
    wbXNAMs,
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Flags 1', itU8, wbFlags(gameProperties, [
        'Hidden from PC',
        'Evil',
        'Special Combat'
      ])),
      wbInteger(gameProperties, 'Flags 2', itU8, wbFlags(gameProperties, [
        'Track Crime',
        'Allow Sell'
      ])),
      wbByteArray(gameProperties, 'Unused', 2)
    ], cpNormal, True, nil, 1),
    wbFloat(gameProperties, CNAM, 'Unused'),
    wbRStructsSK(gameProperties, 'Ranks', 'Rank', [0], [
      wbInteger(gameProperties, RNAM, 'Rank#', itS32),
      wbString(gameProperties, MNAM, 'Male', 0, cpTranslate),
      wbString(gameProperties, FNAM, 'Female', 0, cpTranslate),
      wbString(gameProperties, INAM, 'Insignia (Unused)')
    ], []),
    wbFormIDCk(gameProperties, WMI1, 'Reputation', [REPU])
  ], False, nil, cpNormal, False, wbFACTAfterLoad);

  wbRecord(
  gameProperties,
  FURN, 'Furniture', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODLReq,
    wbSCRI,
    wbDEST,
    wbByteArray(gameProperties, MNAM, 'Marker Flags', 0, cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  GLOB, 'Global', [
    wbEDIDReq,
    wbInteger(gameProperties, FNAM, 'Type', itU8, wbEnum(gameProperties, [], [
      Ord('s'), 'Short',
      Ord('l'), 'Long',
      Ord('f'), 'Float'
    ]), cpNormal, True).SetDefaultEditValue('Float'),
    wbFloat(gameProperties, FLTV, 'Value', cpNormal, True)
  ]);


  wbRecord(
  gameProperties,
  GMST, 'Game Setting', [
    wbString(gameProperties, EDID, 'Editor ID', 0, cpCritical, True, nil, wbGMSTEDIDAfterSet),
    wbUnion(gameProperties, DATA, 'Value', wbGMSTUnionDecider, [
      wbString(gameProperties, '', 0, cpTranslate),
      wbInteger(gameProperties, '', itS32),
      wbFloat(gameProperties, '')
    ], cpNormal, True)
  ]);

  wbDODT := wbStruct(gameProperties, DODT, 'Decal Data', [
              wbFloat(gameProperties, 'Min Width'),
              wbFloat(gameProperties, 'Max Width'),
              wbFloat(gameProperties, 'Min Height'),
              wbFloat(gameProperties, 'Max Height'),
              wbFloat(gameProperties, 'Depth'),
              wbFloat(gameProperties, 'Shininess'),
              wbStruct(gameProperties, 'Parallax', [
                wbFloat(gameProperties, 'Scale'),
                wbInteger(gameProperties, 'Passes', itU8)
              ]),
              wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
                'Parallax',
                'Alpha - Blending',
                'Alpha - Testing'
              ], True)),
              wbByteArray(gameProperties, 'Unused', 2),
              wbStruct(gameProperties, 'Color', [
                wbInteger(gameProperties, 'Red', itU8),
                wbInteger(gameProperties, 'Green', itU8),
                wbInteger(gameProperties, 'Blue', itU8),
                wbByteArray(gameProperties, 'Unused', 1)
              ])
            ]);

  wbRecord(
  gameProperties,
  TXST, 'Texture Set', [
    wbEDIDReq,
    wbOBNDReq,
    wbRStruct(gameProperties, 'Textures (RGB/A)', [
      wbString(gameProperties, TX00,'Base Image / Transparency'),
      wbString(gameProperties, TX01,'Normal Map / Specular'),
      wbString(gameProperties, TX02,'Environment Map Mask / ?'),
      wbString(gameProperties, TX03,'Glow Map / Unused'),
      wbString(gameProperties, TX04,'Parallax Map / Unused'),
      wbString(gameProperties, TX05,'Environment Map / Unused')
    ], []),
    wbDODT,
    wbInteger(gameProperties, DNAM, 'Flags', itU16, wbFlags(gameProperties, [
      'No Specular Map'
    ]), cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  MICN, 'Menu Icon', [
    wbEDIDReq,
    wbICONReq
  ]);

  wbRecord(
  gameProperties,
  HDPT, 'Head Part', [
    wbEDIDReq,
    wbFULLReq,
    wbMODL,
    wbInteger(gameProperties, DATA, 'Flags', itU8, wbFlags(gameProperties, [
      'Playable'
    ]), cpNormal, True),
    wbRArrayS(gameProperties, 'Extra Parts',
      wbFormIDCk(gameProperties, HNAM, 'Part', [HDPT])
    )
  ]);

  wbRecord(
  gameProperties,
  ASPC, 'Acoustic Space', [
    wbEDIDReq,
    wbOBNDReq,

    wbFormIDCk(gameProperties, SNAM, 'Dawn / Default Loop', [NULL, SOUN], False, cpNormal, True),
    wbFormIDCk(gameProperties, SNAM, 'Afternoon', [NULL, SOUN], False, cpNormal, True),
    wbFormIDCk(gameProperties, SNAM, 'Dusk', [NULL, SOUN], False, cpNormal, True),
    wbFormIDCk(gameProperties, SNAM, 'Night', [NULL, SOUN], False, cpNormal, True),
    wbFormIDCk(gameProperties, SNAM, 'Walla', [NULL, SOUN], False, cpNormal, True),

    wbInteger(gameProperties, WNAM, 'Walla Trigger Count', itU32, nil, cpNormal, True),
    wbFormIDCk(gameProperties, RDAT, 'Use Sound from Region (Interiors Only)', [REGN]),
    wbInteger(gameProperties, ANAM, 'Environment Type', itU32, wbEnum(gameProperties, [
      'None',
      'Default',
      'Generic',
      'Padded Cell',
      'Room',
      'Bathroom',
      'Livingroom',
      'Stone Room',
      'Auditorium',
      'Concerthall',
      'Cave',
      'Arena',
      'Hangar',
      'Carpeted Hallway',
      'Hallway',
      'Stone Corridor',
      'Alley',
      'Forest',
      'City',
      'Mountains',
      'Quarry',
      'Plain',
      'Parkinglot',
      'Sewerpipe',
      'Underwater',
      'Small Room',
      'Medium Room',
      'Large Room',
      'Medium Hall',
      'Large Hall',
      'Plate'
    ]), cpNormal, True),
    wbInteger(gameProperties, INAM, 'Is Interior', itU32, wbEnum(gameProperties, ['No', 'Yes']), cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  TACT, 'Talking Activator', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODLReq,
    wbSCRI,
    wbDEST,
    wbFormIDCk(gameProperties, SNAM, 'Looping Sound', [SOUN]),
    wbFormIDCk(gameProperties, VNAM, 'Voice Type', [VTYP]),
    wbFormIDCk(gameProperties, INAM, 'Radio Template', [SOUN])
  ]);

  wbRecord(
  gameProperties,
  SCPT, 'Script', [
    wbEDIDReq,
    wbSCHRReq,
    wbByteArray(gameProperties, SCDA, 'Compiled Script'),
    wbStringScript(gameProperties, SCTX, 'Script Source', 0, cpNormal{, True}),
    wbRArrayS(gameProperties, 'Local Variables', wbRStructSK(gameProperties, [0], 'Local Variable', [
      wbSLSD,
      wbString(gameProperties, SCVR, 'Name', 0, cpCritical, True)
    ], [])),
    wbSCROs
  ]);

  wbRecord(
  gameProperties,
  TERM, 'Terminal', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbSCRI,
    wbDEST,
    wbDESCReq,
    wbFormIDCk(gameProperties, SNAM, 'Sound - Looping', [SOUN]),
    wbFormIDCk(gameProperties, PNAM, 'Password Note', [NOTE]),
    wbStruct(gameProperties, DNAM, '', [
      wbInteger(gameProperties, 'Base Hacking Difficulty', itU8, wbEnum(gameProperties, [
        'Very Easy',
        'Easy',
        'Average',
        'Hard',
        'Very Hard',
        'Requires Key'
      ])),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        'Leveled',
        'Unlocked',
        'Alternate Colors',
        'Hide Welcome Text when displaying Image'
      ])),
      wbInteger(gameProperties, 'ServerType', itU8, wbEnum(gameProperties, [
        '-Server 1-',
        '-Server 2-',
        '-Server 3-',
        '-Server 4-',
        '-Server 5-',
        '-Server 6-',
        '-Server 7-',
        '-Server 8-',
        '-Server 9-',
        '-Server 10-'
      ])),
      wbByteArray(gameProperties, 'Unused', 1)
    ], cpNormal, True),
    wbRArray(gameProperties, 'Menu Items',
      wbRStruct(gameProperties, 'Menu Item', [
        wbStringKC(gameProperties, ITXT, 'Item Text', 0, cpTranslate),
        wbStringKC(gameProperties, RNAM, 'Result Text', 0, cpTranslate, True),
        wbInteger(gameProperties, ANAM, 'Flags', itU8, wbFlags(gameProperties, [
          'Add Note',
          'Force Redraw'
        ]), cpNormal, True),
        wbFormIDCk(gameProperties, INAM, 'Display Note', [NOTE]),
        wbFormIDCk(gameProperties, TNAM, 'Sub Menu', [TERM]),
        wbEmbeddedScriptReq,
        wbCTDAs
      ], [])
    )
  ]);

  wbRecord(
  gameProperties,
  SCOL, 'Static Collection', [
    wbEDIDReq,
    wbOBNDReq,
    wbMODLReq,
    wbRStructs(gameProperties, 'Parts', 'Part', [
      wbFormIDCk(gameProperties, ONAM, 'Static', [STAT]),
      wbArrayS(gameProperties, DATA, 'Placements', wbStruct(gameProperties, 'Placement', [
        wbStruct(gameProperties, 'Position', [
          wbFloat(gameProperties, 'X'),
          wbFloat(gameProperties, 'Y'),
          wbFloat(gameProperties, 'Z')
        ]),
        wbStruct(gameProperties, 'Rotation', [
          wbFloat(gameProperties, 'X', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize),
          wbFloat(gameProperties, 'Y', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize),
          wbFloat(gameProperties, 'Z', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize)
        ]),
        wbFloat(gameProperties, 'Scale')
      ]), 0, cpNormal, True)
    ], [], cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  MSTT, 'Moveable Static', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODLReq,
    wbDEST,
    wbByteArray(gameProperties, DATA, 'Unknown', 1, cpNormal, True),
    wbFormIDCk(gameProperties, SNAM, 'Sound', [SOUN])
  ]);

  wbRecord(
  gameProperties,
  PWAT, 'Placeable Water', [
    wbEDIDReq,
    wbOBNDReq,
    wbMODLReq,
    wbStruct(gameProperties, DNAM, '', [
      wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
        {0x00000001}'Reflects',
        {0x00000002}'Reflects - Actors',
        {0x00000004}'Reflects - Land',
        {0x00000008}'Reflects - LOD Land',
        {0x00000010}'Reflects - LOD Buildings',
        {0x00000020}'Reflects - Trees',
        {0x00000040}'Reflects - Sky',
        {0x00000080}'Reflects - Dynamic Objects',
        {0x00000100}'Reflects - Dead Bodies',
        {0x00000200}'Refracts',
        {0x00000400}'Refracts - Actors',
        {0x00000800}'Refracts - Land',
        {0x00001000}'',
        {0x00002000}'',
        {0x00004000}'',
        {0x00008000}'',
        {0x00010000}'Refracts - Dynamic Objects',
        {0x00020000}'Refracts - Dead Bodies',
        {0x00040000}'Silhouette Reflections',
        {0x00080000}'',
        {0x00100000}'',
        {0x00200000}'',
        {0x00400000}'',
        {0x00800000}'',
        {0x01000000}'',
        {0x02000000}'',
        {0x03000000}'',
        {0x08000000}'',
        {0x10000000}'Depth',
        {0x20000000}'Object Texture Coordinates',
        {0x40000000}'',
        {0x80000000}'No Underwater Fog'
      ])),
      wbFormIDCk(gameProperties, 'Water', [WATR])
    ], cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  IDLM, 'Idle Marker', [
    wbEDIDReq,
    wbOBNDReq,
    wbInteger(gameProperties, IDLF, 'Flags', itU8, wbFlags(gameProperties, [
      'Run in Sequence',
      '',
      'Do Once'
    ]), cpNormal, True),
    wbStruct(gameProperties, IDLC, '', [
      wbInteger(gameProperties, 'Animation Count', itU8),
      wbByteArray(gameProperties, 'Unused', 3)
    ], cpNormal, True, nil, 1),
    wbFloat(gameProperties, IDLT, 'Idle Timer Setting', cpNormal, True),
    wbArray(gameProperties, IDLA, 'Animations', wbFormIDCk(gameProperties, 'Animation', [IDLE, NULL]), 0, nil, wbIDLAsAfterSet, cpNormal, True)  // NULL looks valid if IDLS\Animation Count is 0
  ], False, nil, cpNormal, False, nil, wbAnimationsAfterSet);

  wbRecord(
  gameProperties,
  NOTE, 'Note', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbICON,
    wbYNAM,
    wbZNAM,
    wbInteger(gameProperties, DATA, 'Type', itU8, wbEnum(gameProperties, [
      'Sound',
      'Text',
      'Image',
      'Voice'
    ]), cpNormal, True),
    wbRArrayS(gameProperties, 'Quests',
      wbFormIDCkNoReach(gameProperties, ONAM, 'Quest', [QUST])
    ),
    wbString(gameProperties, XNAM, 'Texture'),
    wbUnion(gameProperties, TNAM, 'Text / Topic', wbNOTETNAMDecide, [
      wbStringKC(gameProperties, 'Text'),
      wbFormIDCk(gameProperties, 'Topic', [DIAL])
    ]),
    wbUnion(gameProperties, SNAM, 'Sound / NPC', wbNOTESNAMDecide, [
      wbFormIDCk(gameProperties, 'Sound', [SOUN]),
      wbFormIDCk(gameProperties, 'Actor', [NPC_, CREA])
    ])
  ]);

end;

procedure DefineFNVe(var gameProperties: TGameProperties);
begin
  wbRecord(
  gameProperties,
  PROJ, 'Projectile', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODLReq,
    wbDEST,
    wbStruct(gameProperties, DATA, 'Data', [
      {00} wbInteger(gameProperties, 'Flags', itU16, wbFlags(gameProperties, [
        'Hitscan',
        'Explosion',
        'Alt. Trigger',
        'Muzzle Flash',
        '',
        'Can Be Disabled',
        'Can Be Picked Up',
        'Supersonic',
        'Pins Limbs',
        'Pass Through Small Transparent',
        'Detonates',
        'Rotation'
      ])),
      {02} wbInteger(gameProperties, 'Type', itU16, wbEnum(gameProperties, [
        {00} '',
        {01} 'Missile',
        {02} 'Lobber',
        {03} '',
        {04} 'Beam',
        {05} '',
        {06} '',
        {07} '',
        {08} 'Flame',
        {09} '',
        {10} '',
        {11} '',
        {12} '',
        {13} '',
        {14} '',
        {15} '',
        {16} 'Continuous Beam'
      ])),
      {04} wbFloat(gameProperties, 'Gravity'),
      {08} wbFloat(gameProperties, 'Speed'),
      {12} wbFloat(gameProperties, 'Range'),
      {16} wbFormIDCk(gameProperties, 'Light', [LIGH, NULL]),
      {20} wbFormIDCk(gameProperties, 'Muzzle Flash - Light', [LIGH, NULL]),
      {24} wbFloat(gameProperties, 'Tracer Chance'),
      {28} wbFloat(gameProperties, 'Explosion - Alt. Trigger - Proximity'),
      {32} wbFloat(gameProperties, 'Explosion - Alt. Trigger - Timer'),
      {36} wbFormIDCk(gameProperties, 'Explosion', [EXPL, NULL]),
      {40} wbFormIDCk(gameProperties, 'Sound', [SOUN, NULL]),
      {44} wbFloat(gameProperties, 'Muzzle Flash - Duration'),
      {48} wbFloat(gameProperties, 'Fade Duration'),
      {52} wbFloat(gameProperties, 'Impact Force'),
      {56} wbFormIDCk(gameProperties, 'Sound - Countdown', [SOUN, NULL]),
      {60} wbFormIDCk(gameProperties, 'Sound - Disable', [SOUN, NULL]),
      {64} wbFormIDCk(gameProperties, 'Default Weapon Source', [WEAP, NULL]),
      {68} wbStruct(gameProperties, 'Rotation', [
      {68}   wbFloat(gameProperties, 'X'),
      {72}   wbFloat(gameProperties, 'Y'),
      {76}   wbFloat(gameProperties, 'Z')
           ]),
      {80} wbFloat(gameProperties, 'Bouncy Mult')
    ], cpNormal, True, nil, 18),
    wbRStructSK(gameProperties, [0], 'Muzzle Flash Model', [
      wbString(gameProperties, NAM1, 'Model FileName'),
      wbByteArray(gameProperties, NAM2, 'Texture Files Hashes', 0, cpIgnore)
    ], [], cpNormal, True),
    wbInteger(gameProperties, VNAM, 'Sound Level', itU32, wbSoundLevelEnum, cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  NAVI, 'Navigation Mesh Info Map', [
    wbEDID,
    wbInteger(gameProperties, NVER, 'Version', itU32),
    wbRArray(gameProperties, 'Navigation Map Infos',
      wbStruct(gameProperties, NVMI, 'Navigation Map Info', [
        wbByteArray(gameProperties, 'Unknown', 4),
        wbFormIDCk(gameProperties, 'Navigation Mesh', [NAVM]),
        wbFormIDCk(gameProperties, 'Location', [CELL, WRLD]),
        wbStruct(gameProperties, 'Grid', [
          wbInteger(gameProperties, 'X', itS16),
          wbInteger(gameProperties, 'Y', itS16)
        ]),
        wbUnknown(gameProperties)
{        wbUnion(gameProperties, 'Data', wbNAVINVMIDecider, [
          wbStruct(gameProperties, 'Data', [
            wbUnknown
          ]),
          wbStruct(gameProperties, 'Data', [
            wbArray(gameProperties, 'Unknown', wbFloat(gameProperties, 'Unknown'), 3),
            wbByteArray(gameProperties, 'Unknown', 4)
          ]),
          wbStruct(gameProperties, 'Data', [
            wbArray(gameProperties, 'Unknown', wbArray(gameProperties, 'Unknown', wbFloat(gameProperties, 'Unknown'), 3), 3),
            wbInteger(gameProperties, 'Count 1', itU16),
            wbInteger(gameProperties, 'Count 2', itU16),
            wbArray(gameProperties, 'Unknown', wbArray(gameProperties, 'Unknown', wbFloat(gameProperties, 'Unknown'), 3), [], wbNAVINAVMGetCount1),
            wbUnknown
          ]),
          wbStruct(gameProperties, 'Data', [
            wbUnknown
          ])
        ])}
      ])
    ),
    wbRArray(gameProperties, 'Navigation Connection Infos',
      wbStruct(gameProperties, NVCI, 'Navigation Connection Info', [
        wbFormIDCk(gameProperties, 'Unknown', [NAVM]),
        wbArray(gameProperties, 'Unknown', wbFormIDCk(gameProperties, 'Unknown', [NAVM]), -1),
        wbArray(gameProperties, 'Unknown', wbFormIDCk(gameProperties, 'Unknown', [NAVM]), -1),
        wbArray(gameProperties, 'Doors', wbFormIDCk(gameProperties, 'Door', [REFR]), -1)
      ])
    )
  ]);

  if wbSimpleRecords then begin

    wbRecord(
    gameProperties,
    NAVM, 'Navigation Mesh', [
      wbEDID,
      wbInteger(gameProperties, NVER, 'Version', itU32),
      wbStruct(gameProperties, DATA, '', [
        wbFormIDCk(gameProperties, 'Cell', [CELL]),
        wbInteger(gameProperties, 'Vertex Count', itU32),
        wbInteger(gameProperties, 'Triangle Count', itU32),
        wbInteger(gameProperties, 'External Connections Count', itU32),
        wbInteger(gameProperties, 'Cover Triangle Count', itU32),
        wbInteger(gameProperties, 'Doors Count', itU32)
      ]),
      wbByteArray(gameProperties, NVVX, 'Vertices'),
      wbByteArray(gameProperties, NVTR, 'Triangles'),
      wbByteArray(gameProperties, NVCA, 'Cover Triangles'),
      wbArray(gameProperties, NVDP, 'Doors', wbStruct(gameProperties, 'Door', [
        wbFormIDCk(gameProperties, 'Reference', [REFR]),
        wbInteger(gameProperties, 'Triangle', itU16),
        wbByteArray(gameProperties, 'Unused', 2)
      ])).IncludeFlag(dfNotAlignable),
      wbByteArray(gameProperties, NVGD, 'NavMesh Grid'),
      wbArray(gameProperties, NVEX, 'External Connections', wbStruct(gameProperties, 'Connection', [
        wbByteArray(gameProperties, 'Unknown', 4),
        wbFormIDCk(gameProperties, 'Navigation Mesh', [NAVM], False, cpNormal),
        wbInteger(gameProperties, 'Triangle', itU16, nil, cpNormal)
      ])).IncludeFlag(dfNotAlignable)
    ], False, wbNAVMAddInfo);

  end else begin

    wbRecord(
    gameProperties,
    NAVM, 'Navigation Mesh', [
      wbEDID,
      wbInteger(gameProperties, NVER, 'Version', itU32),
      wbStruct(gameProperties, DATA, '', [
        wbFormIDCk(gameProperties, 'Cell', [CELL]),
        wbInteger(gameProperties, 'Vertex Count', itU32),
        wbInteger(gameProperties, 'Triangle Count', itU32),
        wbInteger(gameProperties, 'External Connections Count', itU32),
        wbInteger(gameProperties, 'Cover Triangle Count', itU32),
        wbInteger(gameProperties, 'Doors Count', itU32) // as of version = 5 (earliest NavMesh version I saw (Fallout3 1.7) is already 11)
      ]),
      wbArray(gameProperties, NVVX, 'Vertices', wbStruct(gameProperties, 'Vertex', [
        wbFloat(gameProperties, 'X'),
        wbFloat(gameProperties, 'Y'),
        wbFloat(gameProperties, 'Z')
      ])).IncludeFlag(dfNotAlignable),
      wbArray(gameProperties, NVTR, 'Triangles', wbStruct(gameProperties, 'Triangle', [
        wbArray(gameProperties, 'Vertices', wbInteger(gameProperties, 'Vertex', itS16), 3),
        wbArray(gameProperties, 'Edges', wbInteger(gameProperties, 'Triangle', itS16, wbNVTREdgeToStr, wbNVTREdgeToInt), [
          '0 <-> 1',
          '1 <-> 2',
          '2 <-> 0'
        ]),
        wbInteger(gameProperties, 'Flags', itU16, wbFlags(gameProperties, [
          'Edge 0 <-> 1 external',  // 0 $0001 1
          'Edge 1 <-> 2 external',  // 1 $0002 2
          'Edge 2 <-> 0 external',  // 2 $0004 4
          '',                       // 3 $0008 8
          'No Large Creatures',     // 4 $0010 16
          'Overlapping',            // 5 $0020 32
          'Preferred',              // 6 $0040 64
          '',                       // 7 $0080 128
          'Unknown 9',              // 8 $0100 256  used in SSE CK source according to Nukem
          'Water',                  // 9 $0200 512
          'Door',                   //10 $0400 1024
          'Found',                  //11 $0800 2048
          'Unknown 13',             //12 $1000 4096 used in SSE CK source according to Nukem
          '',                       //13 $2000 \
          '',                       //14 $4000  |-- used as 3 bit counter inside CK, probably stripped before save
          ''                        //15 $8000 /
        ])),
        { Flags below are wrong. The first 4 bit are an enum as follows:
        0000 = Open Edge No Cover
        1000 = wall no cover
        0100 = ledge cover
        1100 = UNUSED
        0010 = cover  64
        1010 = cover  80
        0110 = cover  96
        1110 = cover 112
        0001 = cover 128
        1001 = cover 144
        0101 = cover 160
        1101 = cover 176
        0011 = cover 192
        1011 = cover 208
        0111 = cover 224
        1111 = max cover
        then 2 bit flags, then another such enum, and the rest is probably flags.
        Can't properly represent that with current record definition methods.
        }
        wbInteger(gameProperties, 'Cover Flags', itU16, wbFlags(gameProperties, [
          'Edge 0 <-> 1 Cover Value 1/4',
          'Edge 0 <-> 1 Cover Value 2/4',
          'Edge 0 <-> 1 Cover Value 3/4',
          'Edge 0 <-> 1 Cover Value 4/4',
          'Edge 0 <-> 1 Left',
          'Edge 0 <-> 1 Right',
          'Edge 1 <-> 2 Cover Value 1/4',
          'Edge 1 <-> 2 Cover Value 2/4',
          'Edge 1 <-> 2 Cover Value 3/4',
          'Edge 1 <-> 2 Cover Value 4/4',
          'Edge 1 <-> 2 Left',
          'Edge 1 <-> 2 Right',
          'Unknown 13',
          'Unknown 14',
          'Unknown 15',
          'Unknown 16'
        ]))
      ])).IncludeFlag(dfNotAlignable),
      wbArray(gameProperties, NVCA, 'Cover Triangles', wbInteger(gameProperties, 'Cover Triangle', itS16)),
      wbArray(gameProperties, NVDP, 'Doors', wbStruct(gameProperties, 'Door', [
        wbFormIDCk(gameProperties, 'Reference', [REFR]),
        wbInteger(gameProperties, 'Triangle', itU16),
        wbByteArray(gameProperties, 'Unused', 2)
      ])).IncludeFlag(dfNotAlignable),
      wbStruct(gameProperties, NVGD, 'NavMesh Grid', [
        wbInteger(gameProperties, 'NavMeshGrid Divisor', itU32),
        wbFloat(gameProperties, 'Max X Distance'),                // Floats named after TES5 definition
        wbFloat(gameProperties, 'Max Y Distance'),
        wbFloat(gameProperties, 'Min X'),
        wbFloat(gameProperties, 'Min Y'),
        wbFloat(gameProperties, 'Min Z'),
        wbFloat(gameProperties, 'Max X'),
        wbFloat(gameProperties, 'Max Y'),
        wbFloat(gameProperties, 'Max Z'),
        wbArray(gameProperties, 'Cells', wbArray(gameProperties, 'Cell', wbInteger(gameProperties, 'Triangle', itS16).IncludeFlag(dfNotAlignable), -2)).IncludeFlag(dfNotAlignable) // Divisor is row count² , assumed triangle as the values fit the triangle id's
      ]),
      wbArray(gameProperties, NVEX, 'External Connections', wbStruct(gameProperties, 'Connection', [
        wbByteArray(gameProperties, 'Unknown', 4),  // absent in ver<9, not endian swap in ver>=9, so char or byte array
        wbFormIDCk(gameProperties, 'Navigation Mesh', [NAVM, NULL], False, cpNormal),  // NULL values are ignored silently.
        wbInteger(gameProperties, 'Triangle', itU16, nil, cpNormal)
      ])).IncludeFlag(dfNotAlignable)  // Different if ver<5: Length = $2E/$30 and contains other data between NavMesh and Triangle
    ], False, wbNAVMAddInfo);

  end;

  wbRefRecord(
  gameProperties,
  PGRE, 'Placed Grenade', [
    wbEDID,
    wbFormIDCk(gameProperties, NAME, 'Base', [PROJ], False, cpNormal, True),
    wbFormIDCk(gameProperties, XEZN, 'Encounter Zone', [ECZN]),

    wbXRGD,
    wbXRGB,

    {--- Patrol Data ---}
    wbRStruct(gameProperties, 'Patrol Data', [
      wbFloat(gameProperties, XPRD, 'Idle Time', cpNormal, True),
      wbEmpty(gameProperties, XPPA, 'Patrol Script Marker', cpNormal, True),
      wbFormIDCk(gameProperties, INAM, 'Idle', [IDLE, NULL], False, cpNormal, True),
      wbEmbeddedScriptReq,
      wbFormIDCk(gameProperties, TNAM, 'Topic', [DIAL, NULL], False, cpNormal, True)
    ], []),

    {--- Ownership ---}
    wbRStruct(gameProperties, 'Ownership', [
      wbXOWN,
      wbInteger(gameProperties, XRNK, 'Faction rank', itS32)
    ], [XCMT, XCMO]),

    {--- Extra ---}
    wbInteger(gameProperties, XCNT, 'Count', itS32),
    wbFloat(gameProperties, XRDS, 'Radius'),
    wbFloat(gameProperties, XHLP, 'Health'),

    {--- Reflected By / Refracted By ---}
    wbRArrayS(gameProperties, 'Reflected/Refracted By',
      wbStructSK(gameProperties, XPWR, [0], 'Water', [
        wbFormIDCk(gameProperties, 'Reference', [REFR]),
        wbInteger(gameProperties, 'Type', itU32, wbFlags(gameProperties, [
          'Reflection',
          'Refraction'
        ]))
      ])
    ),

    {--- Decals ---}
    wbRArrayS(gameProperties, 'Linked Decals',
      wbStructSK(gameProperties, XDCR, [0], 'Decal', [
        wbFormIDCk(gameProperties, 'Reference', [REFR]),
        wbUnknown(gameProperties)
      ])
    ),

    {--- Linked Ref ---}
    wbFormIDCk(gameProperties, XLKR, 'Linked Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, PLYR]),
    wbStruct(gameProperties, XCLP, 'Linked Reference Color', [
      wbStruct(gameProperties, 'Link Start Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Link End Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ])
    ]),

    {--- Activate Parents ---}
    wbRStruct(gameProperties, 'Activate Parents', [
      wbInteger(gameProperties, XAPD, 'Flags', itU8, wbFlags(gameProperties, [
        'Parent Activate Only'
      ], True)),
      wbRArrayS(gameProperties, 'Activate Parent Refs',
        wbStructSK(gameProperties, XAPR, [0], 'Activate Parent Ref', [
          wbFormIDCk(gameProperties, 'Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, PLYR]),
          wbFloat(gameProperties, 'Delay')
        ])
      )
    ], []),

    wbStringKC(gameProperties, XATO, 'Activation Prompt'),

    {--- Enable Parent ---}
    wbXESP,

    {--- Emittance ---}
    wbFormIDCk(gameProperties, XEMI, 'Emittance', [LIGH, REGN]),

    {--- MultiBound ---}
    wbFormIDCk(gameProperties, XMBR, 'MultiBound Reference', [REFR]),

    {--- Flags ---}
    wbEmpty(gameProperties, XIBS, 'Ignored By Sandbox'),

    {--- 3D Data ---}
    wbXSCL,
    wbDATAPosRot
  ], True, wbPlacedAddInfo);

  wbRefRecord(
  gameProperties,
  PMIS, 'Placed Missile', [
    wbEDID,
    wbFormIDCk(gameProperties, NAME, 'Base', [PROJ], False, cpNormal, True),
    wbFormIDCk(gameProperties, XEZN, 'Encounter Zone', [ECZN]),

    wbXRGD,
    wbXRGB,

    {--- Patrol Data ---}
    wbRStruct(gameProperties, 'Patrol Data', [
      wbFloat(gameProperties, XPRD, 'Idle Time', cpNormal, True),
      wbEmpty(gameProperties, XPPA, 'Patrol Script Marker', cpNormal, True),
      wbFormIDCk(gameProperties, INAM, 'Idle', [IDLE, NULL], False, cpNormal, True),
      wbEmbeddedScriptReq,
      wbFormIDCk(gameProperties, TNAM, 'Topic', [DIAL, NULL], False, cpNormal, True)
    ], []),

    {--- Ownership ---}
    wbRStruct(gameProperties, 'Ownership', [
      wbXOWN,
      wbInteger(gameProperties, XRNK, 'Faction rank', itS32)
    ], [XCMT, XCMO]),

    {--- Extra ---}
    wbInteger(gameProperties, XCNT, 'Count', itS32),
    wbFloat(gameProperties, XRDS, 'Radius'),
    wbFloat(gameProperties, XHLP, 'Health'),

    {--- Reflected By / Refracted By ---}
    wbRArrayS(gameProperties, 'Reflected/Refracted By',
      wbStructSK(gameProperties, XPWR, [0], 'Water', [
        wbFormIDCk(gameProperties, 'Reference', [REFR]),
        wbInteger(gameProperties, 'Type', itU32, wbFlags(gameProperties, [
          'Reflection',
          'Refraction'
        ]))
      ])
    ),

    {--- Decals ---}
    wbRArrayS(gameProperties, 'Linked Decals',
      wbStructSK(gameProperties, XDCR, [0], 'Decal', [
        wbFormIDCk(gameProperties, 'Reference', [REFR]),
        wbUnknown(gameProperties)
      ])
    ),

    {--- Linked Ref ---}
    wbFormIDCk(gameProperties, XLKR, 'Linked Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, PLYR]),
    wbStruct(gameProperties, XCLP, 'Linked Reference Color', [
      wbStruct(gameProperties, 'Link Start Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Link End Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ])
    ]),

    {--- Activate Parents ---}
    wbRStruct(gameProperties, 'Activate Parents', [
      wbInteger(gameProperties, XAPD, 'Flags', itU8, wbFlags(gameProperties, [
        'Parent Activate Only'
      ], True)),
      wbRArrayS(gameProperties, 'Activate Parent Refs',
        wbStructSK(gameProperties, XAPR, [0], 'Activate Parent Ref', [
          wbFormIDCk(gameProperties, 'Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, PLYR]),
          wbFloat(gameProperties, 'Delay')
        ])
      )
    ], []),

    wbStringKC(gameProperties, XATO, 'Activation Prompt'),

    {--- Enable Parent ---}
    wbXESP,

    {--- Emittance ---}
    wbFormIDCk(gameProperties, XEMI, 'Emittance', [LIGH, REGN]),

    {--- MultiBound ---}
    wbFormIDCk(gameProperties, XMBR, 'MultiBound Reference', [REFR]),

    {--- Flags ---}
    wbEmpty(gameProperties, XIBS, 'Ignored By Sandbox'),

    {--- 3D Data ---}
    wbXSCL,
    wbDATAPosRot
  ], True, wbPlacedAddInfo);

  wbRefRecord(
  gameProperties,
  PBEA, 'Placed Beam', [
    wbEDID,
    wbFormIDCk(gameProperties, NAME, 'Base', [PROJ], False, cpNormal, True),
    wbFormIDCk(gameProperties, XEZN, 'Encounter Zone', [ECZN]),

    wbXRGD,
    wbXRGB,

    {--- Patrol Data ---}
    wbRStruct(gameProperties, 'Patrol Data', [
      wbFloat(gameProperties, XPRD, 'Idle Time', cpNormal, True),
      wbEmpty(gameProperties, XPPA, 'Patrol Script Marker', cpNormal, True),
      wbFormIDCk(gameProperties, INAM, 'Idle', [IDLE, NULL], False, cpNormal, True),
      wbEmbeddedScriptReq,
      wbFormIDCk(gameProperties, TNAM, 'Topic', [DIAL, NULL], False, cpNormal, True)
    ], []),

    {--- Ownership ---}
    wbRStruct(gameProperties, 'Ownership', [
      wbXOWN,
      wbInteger(gameProperties, XRNK, 'Faction rank', itS32)
    ], [XCMT, XCMO]),

    {--- Extra ---}
    wbInteger(gameProperties, XCNT, 'Count', itS32),
    wbFloat(gameProperties, XRDS, 'Radius'),
    wbFloat(gameProperties, XHLP, 'Health'),

    {--- Reflected By / Refracted By ---}
    wbRArrayS(gameProperties, 'Reflected/Refracted By',
      wbStructSK(gameProperties, XPWR, [0], 'Water', [
        wbFormIDCk(gameProperties, 'Reference', [REFR]),
        wbInteger(gameProperties, 'Type', itU32, wbFlags(gameProperties, [
          'Reflection',
          'Refraction'
        ]))
      ])
    ),

    {--- Decals ---}
    wbRArrayS(gameProperties, 'Linked Decals',
      wbStructSK(gameProperties, XDCR, [0], 'Decal', [
        wbFormIDCk(gameProperties, 'Reference', [REFR]),
        wbUnknown(gameProperties)
      ])
    ),

    {--- Linked Ref ---}
    wbFormIDCk(gameProperties, XLKR, 'Linked Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, PLYR]),
    wbStruct(gameProperties, XCLP, 'Linked Reference Color', [
      wbStruct(gameProperties, 'Link Start Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Link End Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ])
    ]),

    {--- Activate Parents ---}
    wbRStruct(gameProperties, 'Activate Parents', [
      wbInteger(gameProperties, XAPD, 'Flags', itU8, wbFlags(gameProperties, [
        'Parent Activate Only'
      ], True)),
      wbRArrayS(gameProperties, 'Activate Parent Refs',
        wbStructSK(gameProperties, XAPR, [0], 'Activate Parent Ref', [
          wbFormIDCk(gameProperties, 'Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, PLYR]),
          wbFloat(gameProperties, 'Delay')
        ])
      )
    ], []),

    wbStringKC(gameProperties, XATO, 'Activation Prompt'),

    {--- Enable Parent ---}
    wbXESP,

    {--- Emittance ---}
    wbFormIDCk(gameProperties, XEMI, 'Emittance', [LIGH, REGN]),

    {--- MultiBound ---}
    wbFormIDCk(gameProperties, XMBR, 'MultiBound Reference', [REFR]),

    {--- Flags ---}
    wbEmpty(gameProperties, XIBS, 'Ignored By Sandbox'),

    {--- 3D Data ---}
    wbXSCL,
    wbDATAPosRot
  ], True, wbPlacedAddInfo);

   wbRecord(
   gameProperties,
   EXPL, 'Explosion', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbEITM,
    wbFormIDCk(gameProperties, MNAM, 'Image Space Modifier', [IMAD]),
    wbStruct(gameProperties, DATA, 'Data', [
      {00} wbFloat(gameProperties, 'Force'),
      {04} wbFloat(gameProperties, 'Damage'),
      {08} wbFloat(gameProperties, 'Radius'),
      {12} wbFormIDCk(gameProperties, 'Light', [LIGH, NULL]),
      {16} wbFormIDCk(gameProperties, 'Sound 1', [SOUN, NULL]),
      {20} wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
             {0x00000001}'Unknown 1',
             {0x00000002}'Always Uses World Orientation',
             {0x00000004}'Knock Down - Always',
             {0x00000008}'Knock Down - By Formula',
             {0x00000010}'Ignore LOS Check',
             {0x00000020}'Push Explosion Source Ref Only',
             {0x00000040}'Ignore Image Space Swap'
           ])),
      {24} wbFloat(gameProperties, 'IS Radius'),
      {28} wbFormIDCk(gameProperties, 'Impact DataSet', [IPDS, NULL]),
      {32} wbFormIDCk(gameProperties, 'Sound 2', [SOUN, NULL]),
           wbStruct(gameProperties, 'Radiation', [
             {36} wbFloat(gameProperties, 'Level'),
             {40} wbFloat(gameProperties, 'Dissipation Time'),
             {44} wbFloat(gameProperties, 'Radius')
           ]),
      {48} wbInteger(gameProperties, 'Sound Level', itU32, wbSoundLevelEnum, cpNormal, True)
    ], cpNormal, True),
    wbFormIDCk(gameProperties, INAM, 'Placed Impact Object', [TREE, SOUN, ACTI, DOOR, STAT, FURN,
          CONT, ARMO, AMMO, LVLN, LVLC, MISC, WEAP, BOOK, KEYM, ALCH, LIGH, GRAS,
          ASPC, IDLM, ARMA, MSTT, NOTE, PWAT, SCOL, TACT, TERM, TXST, CHIP, CMNY,
          CCRD, IMOD])
  ]);

  wbRecord(
  gameProperties,
  DEBR, 'Debris', [
    wbEDIDReq,
    wbRStructs(gameProperties, 'Models', 'Model', [
      wbStruct(gameProperties, DATA, 'Data', [
        wbInteger(gameProperties, 'Percentage', itU8),
        wbString(gameProperties, 'Model FileName'),
        wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
          'Has Collission Data'
        ]))
      ], cpNormal, True),
      wbByteArray(gameProperties, MODT, 'Texture Files Hashes', 0, cpIgnore)
    ], [], cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  IMGS, 'Image Space', [
    wbEDIDReq,
    wbStruct(gameProperties, DNAM, '', [
      wbStruct(gameProperties, 'HDR', [
        {00} wbFloat(gameProperties, 'Eye Adapt Speed'),
        {04} wbFloat(gameProperties, 'Blur Radius'),
        {08} wbFloat(gameProperties, 'Blur Passes'),
        {12} wbFloat(gameProperties, 'Emissive Mult'),
        {16} wbFloat(gameProperties, 'Target LUM'),
        {20} wbFloat(gameProperties, 'Upper LUM Clamp'),
        {24} wbFloat(gameProperties, 'Bright Scale'),
        {28} wbFloat(gameProperties, 'Bright Clamp'),
        {32} wbFloat(gameProperties, 'LUM Ramp No Tex'),
        {36} wbFloat(gameProperties, 'LUM Ramp Min'),
        {40} wbFloat(gameProperties, 'LUM Ramp Max'),
        {44} wbFloat(gameProperties, 'Sunlight Dimmer'),
        {48} wbFloat(gameProperties, 'Grass Dimmer'),
        {52} wbFloat(gameProperties, 'Tree Dimmer'),
        {56} wbUnion(gameProperties, 'Skin Dimmer', wbIMGSSkinDimmerDecider, [
               wbFloat(gameProperties, 'Skin Dimmer'),
               wbEmpty(gameProperties, 'Skin Dimmer', cpIgnore)
             ])
      ], cpNormal, False, nil, 14),
      wbStruct(gameProperties, 'Bloom', [
        {60} wbFloat(gameProperties, 'Blur Radius'),
        {64} wbFloat(gameProperties, 'Alpha Mult Interior'),
        {68} wbFloat(gameProperties, 'Alpha Mult Exterior')
      ]),
      wbStruct(gameProperties, 'Get Hit', [
        {72} wbFloat(gameProperties, 'Blur Radius'),
        {76} wbFloat(gameProperties, 'Blur Damping Constant'),
        {80} wbFloat(gameProperties, 'Damping Constant')
      ]),
      wbStruct(gameProperties, 'Night Eye', [
        wbStruct(gameProperties, 'Tint Color', [
          {84} wbFloat(gameProperties, 'Red', cpNormal, False, 255, 0),
          {88} wbFloat(gameProperties, 'Green', cpNormal, False, 255, 0),
          {92} wbFloat(gameProperties, 'Blue', cpNormal, False, 255, 0)
        ]),
      {96} wbFloat(gameProperties, 'Brightness')
      ]),
      wbStruct(gameProperties, 'Cinematic', [
        {100} wbFloat(gameProperties, 'Saturation'),
        wbStruct(gameProperties, 'Contrast', [
          {104} wbFloat(gameProperties, 'Avg Lum Value'),
          {108} wbFloat(gameProperties, 'Value')
        ]),
        {112} wbFloat(gameProperties, 'Cinematic - Brightness - Value'),
        wbStruct(gameProperties, 'Tint', [
          wbStruct(gameProperties, 'Color', [
            {116} wbFloat(gameProperties, 'Red', cpNormal, False, 255, 0),
            {120} wbFloat(gameProperties, 'Green', cpNormal, False, 255, 0),
            {124} wbFloat(gameProperties, 'Blue', cpNormal, False, 255, 0)
          ]),
        {128} wbFloat(gameProperties, 'Value')
        ])
      ]),
      wbByteArray(gameProperties, 'Unused', 4),
      wbByteArray(gameProperties, 'Unused', 4),
      wbByteArray(gameProperties, 'Unused', 4),
      wbByteArray(gameProperties, 'Unused', 4),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        'Saturation',
        'Contrast',
        'Tint',
        'Brightness'
      ], True)),
      wbByteArray(gameProperties, 'Unused', 3)
    ], cpNormal, True, nil, 5)
  ]);

  wbTimeInterpolator := wbStructSK(gameProperties, [0], 'Data', [
    wbFloat(gameProperties, 'Time'),
    wbFloat(gameProperties, 'Value')
  ]);

  wbColorInterpolator := wbStructSK(gameProperties, [0], 'Data', [
    wbFloat(gameProperties, 'Time'),
    wbFloat(gameProperties, 'Red', cpNormal, False, 255, 0),
    wbFloat(gameProperties, 'Green', cpNormal, False, 255, 0),
    wbFloat(gameProperties, 'Blue', cpNormal, False, 255, 0),
    wbFloat(gameProperties, 'Alpha', cpNormal, False, 255, 0)
  ]);

  wbRecord(
  gameProperties,
  IMAD, 'Image Space Adapter', [
    wbEDID,
    wbStruct(gameProperties, DNAM, 'Data Count', [
      wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, ['Animatable'])),
      wbFloat(gameProperties, 'Duration'),
      wbStruct(gameProperties, 'HDR', [
        wbInteger(gameProperties, 'Eye Adapt Speed Mult', itU32),
        wbInteger(gameProperties, 'Eye Adapt Speed Add', itU32),
        wbInteger(gameProperties, 'Bloom Blur Radius Mult', itU32),
        wbInteger(gameProperties, 'Bloom Blur Radius Add', itU32),
        wbInteger(gameProperties, 'Bloom Threshold Mult', itU32),
        wbInteger(gameProperties, 'Bloom Threshold Add', itU32),
        wbInteger(gameProperties, 'Bloom Scale Mult', itU32),
        wbInteger(gameProperties, 'Bloom Scale Add', itU32),
        wbInteger(gameProperties, 'Target Lum Min Mult', itU32),
        wbInteger(gameProperties, 'Target Lum Min Add', itU32),
        wbInteger(gameProperties, 'Target Lum Max Mult', itU32),
        wbInteger(gameProperties, 'Target Lum Max Add', itU32),
        wbInteger(gameProperties, 'Sunlight Scale Mult', itU32),
        wbInteger(gameProperties, 'Sunlight Scale Add', itU32),
        wbInteger(gameProperties, 'Sky Scale Mult', itU32),
        wbInteger(gameProperties, 'Sky Scale Add', itU32)
      ]),
      wbInteger(gameProperties, 'Unknown08 Mult', itU32),
      wbInteger(gameProperties, 'Unknown48 Add', itU32),
      wbInteger(gameProperties, 'Unknown09 Mult', itU32),
      wbInteger(gameProperties, 'Unknown49 Add', itU32),
      wbInteger(gameProperties, 'Unknown0A Mult', itU32),
      wbInteger(gameProperties, 'Unknown4A Add', itU32),
      wbInteger(gameProperties, 'Unknown0B Mult', itU32),
      wbInteger(gameProperties, 'Unknown4B Add', itU32),
      wbInteger(gameProperties, 'Unknown0C Mult', itU32),
      wbInteger(gameProperties, 'Unknown4C Add', itU32),
      wbInteger(gameProperties, 'Unknown0D Mult', itU32),
      wbInteger(gameProperties, 'Unknown4D Add', itU32),
      wbInteger(gameProperties, 'Unknown0E Mult', itU32),
      wbInteger(gameProperties, 'Unknown4E Add', itU32),
      wbInteger(gameProperties, 'Unknown0F Mult', itU32),
      wbInteger(gameProperties, 'Unknown4F Add', itU32),
      wbInteger(gameProperties, 'Unknown10 Mult', itU32),
      wbInteger(gameProperties, 'Unknown50 Add', itU32),
      wbStruct(gameProperties, 'Cinematic', [
        wbInteger(gameProperties, 'Saturation Mult', itU32),
        wbInteger(gameProperties, 'Saturation Add', itU32),
        wbInteger(gameProperties, 'Brightness Mult', itU32),
        wbInteger(gameProperties, 'Brightness Add', itU32),
        wbInteger(gameProperties, 'Contrast Mult', itU32),
        wbInteger(gameProperties, 'Contrast Add', itU32)
      ]),
      wbInteger(gameProperties, 'Unknown14 Mult', itU32),
      wbInteger(gameProperties, 'Unknown54 Add', itU32),
      wbInteger(gameProperties, 'Tint Color', itU32),
      wbInteger(gameProperties, 'Blur Radius', itU32),
      wbInteger(gameProperties, 'Double Vision Strength', itU32),
      wbInteger(gameProperties, 'Radial Blur Strength', itU32),
      wbInteger(gameProperties, 'Radial Blur Ramp Up', itU32),
      wbInteger(gameProperties, 'Radial Blur Start', itU32),
      wbInteger(gameProperties, 'Radial Blur Flags', itU32, wbFlags(gameProperties, ['Use Target'])),
      wbFloat(gameProperties, 'Radial Blur Center X'),
      wbFloat(gameProperties, 'Radial Blur Center Y'),
      wbInteger(gameProperties, 'DoF Strength', itU32),
      wbInteger(gameProperties, 'DoF Distance', itU32),
      wbInteger(gameProperties, 'DoF Range', itU32),
      wbInteger(gameProperties, 'DoF Flags', itU32, wbFlags(gameProperties, ['Use Target'])),
      wbInteger(gameProperties, 'Radial Blur Ramp Down', itU32),
      wbInteger(gameProperties, 'Radial Blur Down Start', itU32),
      wbInteger(gameProperties, 'Fade Color', itU32),
      wbInteger(gameProperties, 'Motion Blur Strength', itU32)
    ], cpNormal, True, nil, 26),
    wbArray(gameProperties, BNAM, 'Blur Radius', wbTimeInterpolator),
    wbArray(gameProperties, VNAM, 'Double Vision Strength', wbTimeInterpolator),
    wbArray(gameProperties, TNAM, 'Tint Color', wbColorInterpolator),
    wbArray(gameProperties, NAM3, 'Fade Color', wbColorInterpolator),
    wbArray(gameProperties, RNAM, 'Radial Blur Strength', wbTimeInterpolator),
    wbArray(gameProperties, SNAM, 'Radial Blur Ramp Up', wbTimeInterpolator),
    wbArray(gameProperties, UNAM, 'Radial Blur Start', wbTimeInterpolator),
    wbArray(gameProperties, NAM1, 'Radial Blur Ramp Down', wbTimeInterpolator),
    wbArray(gameProperties, NAM2, 'Radial Blur Down Start', wbTimeInterpolator),
    wbArray(gameProperties, WNAM, 'DoF Strength', wbTimeInterpolator),
    wbArray(gameProperties, XNAM, 'DoF Distance', wbTimeInterpolator),
    wbArray(gameProperties, YNAM, 'DoF Range', wbTimeInterpolator),
    wbArray(gameProperties, NAM4, 'Motion Blur Strength', wbTimeInterpolator),
    wbRStruct(gameProperties, 'HDR', [
      wbArray(gameProperties, _00_IAD, 'Eye Adapt Speed Mult', wbTimeInterpolator),
      wbArray(gameProperties, _40_IAD, 'Eye Adapt Speed Add', wbTimeInterpolator),
      wbArray(gameProperties, _01_IAD, 'Bloom Blur Radius Mult', wbTimeInterpolator),
      wbArray(gameProperties, _41_IAD, 'Bloom Blur Radius Add', wbTimeInterpolator),
      wbArray(gameProperties, _02_IAD, 'Bloom Threshold Mult', wbTimeInterpolator), // Skin Dimmer
      wbArray(gameProperties, _42_IAD, 'Bloom Threshold Add', wbTimeInterpolator), // Skin Dimmer
      wbArray(gameProperties, _03_IAD, 'Bloom Scale Mult', wbTimeInterpolator), // Emissive
      wbArray(gameProperties, _43_IAD, 'Bloom Scale Add', wbTimeInterpolator), // Emissive
      wbArray(gameProperties, _04_IAD, 'Target Lum Min Mult', wbTimeInterpolator),
      wbArray(gameProperties, _44_IAD, 'Target Lum Min Add', wbTimeInterpolator),
      wbArray(gameProperties, _05_IAD, 'Target Lum Max Mult', wbTimeInterpolator),
      wbArray(gameProperties, _45_IAD, 'Target Lum Max Add', wbTimeInterpolator),
      wbArray(gameProperties, _06_IAD, 'Sunlight Scale Mult', wbTimeInterpolator), // Birght Scale
      wbArray(gameProperties, _46_IAD, 'Sunlight Scale Add', wbTimeInterpolator), // Birght Scale
      wbArray(gameProperties, _07_IAD, 'Sky Scale Mult', wbTimeInterpolator), // Bright Clamp
      wbArray(gameProperties, _47_IAD, 'Sky Scale Add', wbTimeInterpolator), // Bright Clamp
      wbArray(gameProperties, _08_IAD, 'LUM Ramp No Tex Mult', wbTimeInterpolator),
      wbArray(gameProperties, _48_IAD, 'LUM Ramp No Tex Add', wbTimeInterpolator),
      wbArray(gameProperties, _09_IAD, 'LUM Ramp Min Mult', wbTimeInterpolator),
      wbArray(gameProperties, _49_IAD, 'LUM Ramp Min Add', wbTimeInterpolator),
      wbArray(gameProperties, _0A_IAD, 'LUM Ramp Max Mult', wbTimeInterpolator),
      wbArray(gameProperties, _4A_IAD, 'LUM Ramp Max Add', wbTimeInterpolator),
      wbArray(gameProperties, _0B_IAD, 'Sunlight Dimmer Mult', wbTimeInterpolator),
      wbArray(gameProperties, _4B_IAD, 'Sunlight Dimmer Add', wbTimeInterpolator),
      wbArray(gameProperties, _0C_IAD, 'Grass Dimmer Mult', wbTimeInterpolator),
      wbArray(gameProperties, _4C_IAD, 'Grass Dimmer Add', wbTimeInterpolator),
      wbArray(gameProperties, _0D_IAD, 'Tree Dimmer Mult', wbTimeInterpolator),
      wbArray(gameProperties, _4D_IAD, 'Tree Dimmer Add', wbTimeInterpolator)
    ], []),
    wbRStruct(gameProperties, 'Bloom', [
      wbArray(gameProperties, _0E_IAD, 'Blur Radius Mult', wbTimeInterpolator),
      wbArray(gameProperties, _4E_IAD, 'Blur Radius Add', wbTimeInterpolator),
      wbArray(gameProperties, _0F_IAD, 'Alpha Mult Interior Mult', wbTimeInterpolator),
      wbArray(gameProperties, _4F_IAD, 'Alpha Mult Interior Add', wbTimeInterpolator),
      wbArray(gameProperties, _10_IAD, 'Alpha Mult Exterior Mult', wbTimeInterpolator),
      wbArray(gameProperties, _50_IAD, 'Alpha Mult Exterior Add', wbTimeInterpolator)
    ], []),
    wbRStruct(gameProperties, 'Cinematic', [
      wbArray(gameProperties, _11_IAD, 'Saturation Mult', wbTimeInterpolator),
      wbArray(gameProperties, _51_IAD, 'Saturation Add', wbTimeInterpolator),
      wbArray(gameProperties, _12_IAD, 'Contrast Mult', wbTimeInterpolator),
      wbArray(gameProperties, _52_IAD, 'Contrast Add', wbTimeInterpolator),
      wbArray(gameProperties, _13_IAD, 'Contrast Avg Mult', wbTimeInterpolator),
      wbArray(gameProperties, _53_IAD, 'Contrast Avg Add', wbTimeInterpolator),
      wbArray(gameProperties, _14_IAD, 'Brightness Mult', wbTimeInterpolator),
      wbArray(gameProperties, _54_IAD, 'Brightness Add', wbTimeInterpolator)
    ], []),
    wbFormIDCk(gameProperties, RDSD, 'Sound - Intro', [SOUN]),
    wbFormIDCk(gameProperties, RDSI, 'Sound - Outro', [SOUN])
  ]);

  wbRecord(
  gameProperties,
  FLST, 'FormID List', [
    wbString(gameProperties, EDID, 'Editor ID', 0, cpBenign, True, nil, wbFLSTEDIDAfterSet),
    wbRArrayS(gameProperties, 'FormIDs', wbFormID(gameProperties, LNAM, 'FormID'), cpNormal, False, nil, nil, nil, wbFLSTLNAMIsSorted)
  ]);

  wbRecord(
  gameProperties,
  PERK, 'Perk', [
    wbEDIDReq,
    wbFULL,
    wbDESCReq,
    wbICON,
    wbCTDAs,
    wbStruct(gameProperties, DATA, 'Data', [
      wbInteger(gameProperties, 'Trait', itU8, wbEnum(gameProperties, ['No', 'Yes'])),
      wbInteger(gameProperties, 'Min Level', itU8),
      wbInteger(gameProperties, 'Ranks', itU8),
      wbInteger(gameProperties, 'Playable', itU8, wbEnum(gameProperties, ['No', 'Yes'])),
      wbInteger(gameProperties, 'Hidden', itU8, wbEnum(gameProperties, ['No', 'Yes']))
    ], cpNormal, True, nil, 4),
    wbRStructsSK(gameProperties, 'Effects', 'Effect', [0, 1], [
      wbStructSK(gameProperties, PRKE, [1, 2, 0], 'Header', [
        wbInteger(gameProperties, 'Type', itU8, wbEnum(gameProperties, [
          'Quest + Stage',
          'Ability',
          'Entry Point'
        ]), cpNormal, False, nil, wbPERKPRKETypeAfterSet),
        wbInteger(gameProperties, 'Rank', itU8),
        wbInteger(gameProperties, 'Priority', itU8)
      ]),
      wbUnion(gameProperties, DATA, 'Effect Data', wbPerkDATADecider, [
        wbStructSK(gameProperties, [0, 1], 'Quest + Stage', [
          wbFormIDCk(gameProperties, 'Quest', [QUST]),
          wbInteger(gameProperties, 'Quest Stage', itU8, wbPerkDATAQuestStageToStr, wbCTDAParam2QuestStageToInt),
          wbByteArray(gameProperties, 'Unused', 3)
        ]),
        wbFormIDCk(gameProperties, 'Ability', [SPEL]),
        wbStructSK(gameProperties, [0, 1], 'Entry Point', [
          wbInteger(gameProperties, 'Entry Point', itU8, wbEnum(gameProperties, [
           {00} 'Calculate Weapon Damage',
           {01} 'Calculate My Critical Hit Chance',
           {02} 'Calculate My Critical Hit Damage',
           {03} 'Calculate Weapon Attack AP Cost',
           {04} 'Calculate Mine Explode Chance',
           {05} 'Adjust Range Penalty',
           {06} 'Adjust Limb Damage',
           {07} 'Calculate Weapon Range',
           {08} 'Calculate To Hit Chance',
           {09} 'Adjust Experience Points',
           {10} 'Adjust Gained Skill Points',
           {11} 'Adjust Book Skill Points',
           {12} 'Modify Recovered Health',
           {13} 'Calculate Inventory AP Cost',
           {14} 'Get Disposition',
           {15} 'Get Should Attack',
           {16} 'Get Should Assist',
           {17} 'Calculate Buy Price',
           {18} 'Get Bad Karma',
           {19} 'Get Good Karma',
           {20} 'Ignore Locked Terminal',
           {21} 'Add Leveled List On Death',
           {22} 'Get Max Carry Weight',
           {23} 'Modify Addiction Chance',
           {24} 'Modify Addiction Duration',
           {25} 'Modify Positive Chem Duration',
           {26} 'Adjust Drinking Radiation',
           {27} 'Activate',
           {28} 'Mysterious Stranger',
           {29} 'Has Paralyzing Palm',
           {30} 'Hacking Science Bonus',
           {31} 'Ignore Running During Detection',
           {32} 'Ignore Broken Lock',
           {33} 'Has Concentrated Fire',
           {34} 'Calculate Gun Spread',
           {35} 'Player Kill AP Reward',
           {36} 'Modify Enemy Critical Hit Chance',
           {37} 'Reload Speed',
           {38} 'Equip Speed',
           {39} 'Action Point Regen',
           {40} 'Action Point Cost',
           {41} 'Miss Fortune',
           {42} 'Modify Run Speed',
           {43} 'Modify Attack Speed',
           {44} 'Modify Radiation Consumed',
           {45} 'Has Pip Hacker',
           {46} 'Has Meltdown',
           {47} 'See Enemy Health',
           {48} 'Has Jury Rigging',
           {49} 'Modify Threat Range',
           {50} 'Modify Thread',
           {51} 'Has Fast Travel Always',
           {52} 'Knockdown Chance',
           {53} 'Modify Weapon Strength Req',
           {54} 'Modify Aiming Move Speed',
           {55} 'Modify Light Items',
           {56} 'Modify Damage Threshold (defender)',
           {57} 'Modify Chance for Ammo Item',
           {58} 'Modify Damage Threshold (attacker)',
           {59} 'Modify Throwing Velocity',
           {60} 'Chance for Item on Fire',
           {61} 'Has Unarmed Forward Power Attack',
           {62} 'Has Unarmed Back Power Attack',
           {63} 'Has Unarmed Crouched Power Attack',
           {64} 'Has Unarmed Counter Attack',
           {65} 'Has Unarmed Left Power Attack',
           {66} 'Has Unarmed Right Power Attack',
           {67} 'VATS HelperChance',
           {68} 'Modify Item Damage',
           {69} 'Has Improved Detection',
           {70} 'Has Improved Spotting',
           {71} 'Has Improved Item Detection',
           {72} 'Adjust Explosion Radius',
           {73} 'Reserved'
          ]), cpNormal, True, nil, wbPERKEntryPointAfterSet),
          wbInteger(gameProperties, 'Function', itU8, wbPerkDATAFunctionToStr, wbPerkDATAFunctionToInt, cpNormal, False, nil, wbPerkDATAFunctionAfterSet),
          wbInteger(gameProperties, 'Perk Condition Tab Count', itU8, nil, cpIgnore)
        ])
      ], cpNormal, True),
      wbRStructsSK(gameProperties, 'Perk Conditions', 'Perk Condition', [0], [
        wbInteger(gameProperties, PRKC, 'Run On', itS8, wbPRKCToStr, wbPRKCToInt),
        wbCTDAsReq
      ], [], cpNormal, False, nil, nil, wbPERKPRKCDontShow),
      wbRStruct(gameProperties, 'Entry Point Function Parameters', [
        wbInteger(gameProperties, EPFT, 'Type', itU8, wbPerkEPFTToStr, wbPerkEPFTToInt, cpIgnore, False, nil, wbPerkEPFTAfterSet),
        wbUnion(gameProperties, EPFD, 'Data', wbEPFDDecider, [
          wbByteArray(gameProperties, 'Unknown'),
          wbFloat(gameProperties, 'Float'),
          wbStruct(gameProperties, 'Float, Float', [
            wbFloat(gameProperties, 'Float 1'),
            wbFloat(gameProperties, 'Float 2')
          ]),
          wbFormIDCk(gameProperties, 'Leveled Item', [LVLI]),
          wbEmpty(gameProperties, 'None (Script)'),
          wbStruct(gameProperties, 'Actor Value, Float', [
            wbInteger(gameProperties, 'Actor Value', itU32, wbEPFDActorValueToStr, wbEPFDActorValueToInt),
            wbFloat(gameProperties, 'Float')
          ])
        ], cpNormal, False, wbEPFDDontShow),
        wbStringKC(gameProperties, EPF2, 'Button Label', 0, cpNormal, False, wbEPF2DontShow),
        wbInteger(gameProperties, EPF3, 'Script Flags', itU16, wbFlags(gameProperties, [
          'Run Immediately'
        ]), cpNormal, False, False, wbEPF2DontShow),
        wbEmbeddedScriptPerk
      ], [], cpNormal, False, wbPERKPRKCDontShow),
      wbEmpty(gameProperties, PRKF, 'End Marker', cpIgnore, True)
    ], [])
  ]);

  wbBPNDStruct := wbStruct(gameProperties, BPND, '', [
    {00} wbFloat(gameProperties, 'Damage Mult'),
    {04} wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
      'Severable',
      'IK Data',
      'IK Data - Biped Data',
      'Explodable',
      'IK Data - Is Head',
      'IK Data - Headtracking',
      'To Hit Chance - Absolute'
    ])),
    {05} wbInteger(gameProperties, 'Part Type', itU8, wbEnum(gameProperties, [
           'Torso',
           'Head 1',
           'Head 2',
           'Left Arm 1',
           'Left Arm 2',
           'Right Arm 1',
           'Right Arm 2',
           'Left Leg 1',
           'Left Leg 2',
           'Left Leg 3',
           'Right Leg 1',
           'Right Leg 2',
           'Right Leg 3',
           'Brain',
           'Weapon'
         ])),
    {06} wbInteger(gameProperties, 'Health Percent', itU8),
    {07} wbInteger(gameProperties, 'Actor Value', itS8, wbActorValueEnum),
    {08} wbInteger(gameProperties, 'To Hit Chance', itU8),
    {09} wbInteger(gameProperties, 'Explodable - Explosion Chance %', itU8),
    {10} wbInteger(gameProperties, 'Explodable - Debris Count', itU16),
    {12} wbFormIDCk(gameProperties, 'Explodable - Debris', [DEBR, NULL]),
    {16} wbFormIDCk(gameProperties, 'Explodable - Explosion', [EXPL, NULL]),
    {20} wbFloat(gameProperties, 'Tracking Max Angle'),
    {24} wbFloat(gameProperties, 'Explodable - Debris Scale'),
    {28} wbInteger(gameProperties, 'Severable - Debris Count', itS32),
    {32} wbFormIDCk(gameProperties, 'Severable - Debris', [DEBR, NULL]),
    {36} wbFormIDCk(gameProperties, 'Severable - Explosion', [EXPL, NULL]),
    {40} wbFloat(gameProperties, 'Severable - Debris Scale'),
    wbStruct(gameProperties, 'Gore Effects Positioning', [
      wbStruct(gameProperties, 'Translate', [
        {44} wbFloat(gameProperties, 'X'),
        {48} wbFloat(gameProperties, 'Y'),
        {52} wbFloat(gameProperties, 'Z')
      ]),
      wbStruct(gameProperties, 'Rotation', [
        {56} wbFloat(gameProperties, 'X', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize),
        {60} wbFloat(gameProperties, 'Y', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize),
        {64} wbFloat(gameProperties, 'Z', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize)
      ])
    ]),
    {68} wbFormIDCk(gameProperties, 'Severable - Impact DataSet', [IPDS, NULL]),
    {72} wbFormIDCk(gameProperties, 'Explodable - Impact DataSet', [IPDS, NULL]),
    {28} wbInteger(gameProperties, 'Severable - Decal Count', itU8),
    {28} wbInteger(gameProperties, 'Explodable - Decal Count', itU8),
    {76} wbByteArray(gameProperties, 'Unused', 2),
    {80} wbFloat(gameProperties, 'Limb Replacement Scale')
  ], cpNormal, True);

  wbRecord(
  gameProperties,
  BPTD, 'Body Part Data', [
    wbEDIDReq,
    wbMODLReq,
    wbRStructs(gameProperties, 'Body Parts', 'Body Part', [ // When the Part Name is provided
      wbString(gameProperties, BPTN, 'Part Name', 0, cpNormal, True),
      wbString(gameProperties, BPNN, 'Part Node', 0, cpNormal, True),
      wbString(gameProperties, BPNT, 'VATS Target', 0, cpNormal, True),
      wbString(gameProperties, BPNI, 'IK Data - Start Node', 0, cpNormal, True),
      wbBPNDStruct,
      wbString(gameProperties, NAM1, 'Limb Replacement Model', 0, cpNormal, True),
      wbString(gameProperties, NAM4, 'Gore Effects - Target Bone', 0, cpNormal, True),
      wbByteArray(gameProperties, NAM5, 'Texture Files Hashes', 0, cpIgnore)
    ], [], cpNormal, False),
    wbRStructs(gameProperties, 'Unnamed Body Parts', 'Body Part', [ // When the Part Name is not provided
      wbString(gameProperties, BPNN, 'Part Node', 0, cpNormal, True),
      wbString(gameProperties, BPNT, 'VATS Target', 0, cpNormal, True),
      wbString(gameProperties, BPNI, 'IK Data - Start Node', 0, cpNormal, True),
      wbBPNDStruct,
      wbString(gameProperties, NAM1, 'Limb Replacement Model', 0, cpNormal, True),
      wbString(gameProperties, NAM4, 'Gore Effects - Target Bone', 0, cpNormal, True),
      wbByteArray(gameProperties, NAM5, 'Texture Files Hashes', 0, cpIgnore)
    ], [], cpNormal, False),
    wbFormIDCk(gameProperties, RAGA, 'Ragdoll', [RGDL])
  ]);

  wbRecord(
  gameProperties,
  ADDN, 'Addon Node', [
    wbEDIDReq,
    wbOBNDReq,
    wbMODLReq,
    wbInteger(gameProperties, DATA, 'Node Index', itS32, nil, cpNormal, True),
    wbFormIDCk(gameProperties, SNAM, 'Sound', [SOUN]),
    wbStruct(gameProperties, DNAM, 'Data', [
      wbInteger(gameProperties, 'Master Particle System Cap', itU16),
      wbByteArray(gameProperties, 'Unknown', 2)
    ], cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  AVIF, 'ActorValue Information', [
    wbEDIDReq,
    wbFULL,
    wbDESCReq,
    wbICON,
    wbStringKC(gameProperties, ANAM, 'Short Name', 0, cpTranslate)
  ]);

  wbRecord(
  gameProperties,
  RADS, 'Radiation Stage', [
    wbEDIDReq,
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Trigger Threshold', itU32),
      wbFormIDCk(gameProperties, 'Actor Effect', [SPEL])
    ], cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  CAMS, 'Camera Shot', [
    wbEDIDReq,
    wbMODL,
    wbStruct(gameProperties, DATA, 'Data', [
      {00} wbInteger(gameProperties, 'Action', itU32, wbEnum(gameProperties, [
        'Shoot',
        'Fly',
        'Hit',
        'Zoom'
      ])),
      {04} wbInteger(gameProperties, 'Location', itU32, wbEnum(gameProperties, [
        'Attacker',
        'Projectile',
        'Target'
      ])),
      {08} wbInteger(gameProperties, 'Target', itU32, wbEnum(gameProperties, [
        'Attacker',
        'Projectile',
        'Target'
      ])),
      {12} wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
        'Position Follows Location',
        'Rotation Follows Target',
        'Don''t Follow Bone',
        'First Person Camera',
        'No Tracer',
        'Start At Time Zero'
      ])),
      wbStruct(gameProperties, 'Time Multipliers', [
        {16} wbFloat(gameProperties, 'Player'),
        {20} wbFloat(gameProperties, 'Target'),
        {24} wbFloat(gameProperties, 'Global')
      ]),
      {28} wbFloat(gameProperties, 'Max Time'),
      {32} wbFloat(gameProperties, 'Min Time'),
      {36} wbFloat(gameProperties, 'Target % Between Actors')
    ], cpNormal, True, nil, 7),
    wbFormIDCk(gameProperties, MNAM, 'Image Space Modifier', [IMAD])
  ]);

  wbRecord(
  gameProperties,
  CPTH, 'Camera Path', [
    wbEDIDReq,
    wbCTDAs,
    wbArray(gameProperties, ANAM, 'Related Camera Paths', wbFormIDCk(gameProperties, 'Related Camera Path', [CPTH, NULL]), ['Parent', 'Previous Sibling'], cpNormal, True),
    wbInteger(gameProperties, DATA, 'Camera Zoom', itU8, wbEnum(gameProperties, [
      'Default',
      'Disable',
      'Shot List'
    ]), cpNormal, True),
    wbRArray(gameProperties, 'Camera Shots', wbFormIDCk(gameProperties, SNAM, 'Camera Shot', [CAMS]))
  ]);

  wbRecord(
  gameProperties,
  VTYP, 'Voice Type', [
    wbEDIDReq,
    wbInteger(gameProperties, DNAM, 'Flags', itU8, wbFlags(gameProperties, [
      'Allow Default Dialog',
      'Female'
    ]), cpNormal, False)
  ]);

  wbRecord(
  gameProperties,
  IPCT, 'Impact', [
    wbEDIDReq,
    wbMODL,
    wbStruct(gameProperties, DATA, '', [
      wbFloat(gameProperties, 'Effect - Duration'),
      wbInteger(gameProperties, 'Effect - Orientation', itU32, wbEnum(gameProperties, [
        'Surface Normal',
        'Projectile Vector',
        'Projectile Reflection'
      ])),
      wbFloat(gameProperties, 'Angle Threshold'),
      wbFloat(gameProperties, 'Placement Radius'),
      wbInteger(gameProperties, 'Sound Level', itU32, wbSoundLevelEnum),
      wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
        'No Decal Data'
      ]))
    ], cpNormal, True),
    wbDODT,
    wbFormIDCk(gameProperties, DNAM, 'Texture Set', [TXST]),
    wbFormIDCk(gameProperties, SNAM, 'Sound 1', [SOUN]),
    wbFormIDCk(gameProperties, NAM1, 'Sound 2', [SOUN])
  ]);

  wbRecord(
  gameProperties,
  IPDS, 'Impact DataSet', [
    wbEDIDReq,
    wbStruct(gameProperties, DATA, 'Impacts', [
      wbFormIDCk(gameProperties, 'Stone', [IPCT, NULL]),
      wbFormIDCk(gameProperties, 'Dirt', [IPCT, NULL]),
      wbFormIDCk(gameProperties, 'Grass', [IPCT, NULL]),
      wbFormIDCk(gameProperties, 'Glass', [IPCT, NULL]),
      wbFormIDCk(gameProperties, 'Metal', [IPCT, NULL]),
      wbFormIDCk(gameProperties, 'Wood', [IPCT, NULL]),
      wbFormIDCk(gameProperties, 'Organic', [IPCT, NULL]),
      wbFormIDCk(gameProperties, 'Cloth', [IPCT, NULL]),
      wbFormIDCk(gameProperties, 'Water', [IPCT, NULL]),
      wbFormIDCk(gameProperties, 'Hollow Metal', [IPCT, NULL]),
      wbFormIDCk(gameProperties, 'Organic Bug', [IPCT, NULL]),
      wbFormIDCk(gameProperties, 'Organic Glow', [IPCT, NULL])
    ], cpNormal, True, nil, 9)
  ]);

  wbRecord(
  gameProperties,
  ECZN, 'Encounter Zone', [
    wbEDIDReq,
    wbStruct(gameProperties, DATA, '', [
      wbFormIDCkNoReach(gameProperties, 'Owner', [NPC_, FACT, NULL]),
      wbInteger(gameProperties, 'Rank', itS8),
      wbInteger(gameProperties, 'Minimum Level', itS8),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        'Never Resets',
        'Match PC Below Minimum Level'
      ])),
      wbByteArray(gameProperties, 'Unused', 1)
    ], cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  MESG, 'Message', [
    wbEDIDReq,
    wbDESCReq,
    wbFULL,
    wbFormIDCk(gameProperties, INAM, 'Icon', [MICN, NULL], False, cpNormal, True),
    wbByteArray(gameProperties, NAM0, 'Unused', 0, cpIgnore),
    wbByteArray(gameProperties, NAM1, 'Unused', 0, cpIgnore),
    wbByteArray(gameProperties, NAM2, 'Unused', 0, cpIgnore),
    wbByteArray(gameProperties, NAM3, 'Unused', 0, cpIgnore),
    wbByteArray(gameProperties, NAM4, 'Unused', 0, cpIgnore),
    wbByteArray(gameProperties, NAM5, 'Unused', 0, cpIgnore),
    wbByteArray(gameProperties, NAM6, 'Unused', 0, cpIgnore),
    wbByteArray(gameProperties, NAM7, 'Unused', 0, cpIgnore),
    wbByteArray(gameProperties, NAM8, 'Unused', 0, cpIgnore),
    wbByteArray(gameProperties, NAM9, 'Unused', 0, cpIgnore),
    wbInteger(gameProperties, DNAM, 'Flags', itU32, wbFlags(gameProperties, [
      'Message Box',
      'Auto Display'
    ]), cpNormal, True, False, nil, wbMESGDNAMAfterSet),
    wbInteger(gameProperties, TNAM, 'Display Time', itU32, nil, cpNormal, False, False, wbMESGTNAMDontShow),
    wbRStructs(gameProperties, 'Menu Buttons', 'Menu Button', [
      wbStringKC(gameProperties, ITXT, 'Button Text', 0, cpTranslate),
      wbCTDAs
    ], [])
  ], False, nil, cpNormal, False, wbMESGAfterLoad);

  wbRecord(
  gameProperties,
  RGDL, 'Ragdoll', [
    wbEDIDReq,
    wbInteger(gameProperties, NVER, 'Version', itU32, nil, cpNormal, True),
    wbStruct(gameProperties, DATA, 'General Data', [
      wbInteger(gameProperties, 'Dynamic Bone Count', itU32),
      wbByteArray(gameProperties, 'Unused', 4),
      wbStruct(gameProperties, 'Enabled', [
        wbInteger(gameProperties, 'Feedback', itU8, wbEnum(gameProperties, ['No', 'Yes'])),
        wbInteger(gameProperties, 'Foot IK (broken, don''t use)', itU8, wbEnum(gameProperties, ['No', 'Yes'])),
        wbInteger(gameProperties, 'Look IK (broken, don''t use)', itU8, wbEnum(gameProperties, ['No', 'Yes'])),
        wbInteger(gameProperties, 'Grab IK (broken, don''t use)', itU8, wbEnum(gameProperties, ['No', 'Yes'])),
        wbInteger(gameProperties, 'Pose Matching', itU8, wbEnum(gameProperties, ['No', 'Yes']))
      ]),
      wbByteArray(gameProperties, 'Unused', 1)
    ], cpNormal, True),
    wbFormIDCk(gameProperties, XNAM, 'Actor Base', [CREA, NPC_], False, cpNormal, True),
    wbFormIDCk(gameProperties, TNAM, 'Body Part Data', [BPTD], False, cpNormal, True),
    wbStruct(gameProperties, RAFD, 'Feedback Data', [
    {00} wbFloat(gameProperties, 'Dynamic/Keyframe Blend Amount'),
    {04} wbFloat(gameProperties, 'Hierarchy Gain'),
    {08} wbFloat(gameProperties, 'Position Gain'),
    {12} wbFloat(gameProperties, 'Velocity Gain'),
    {16} wbFloat(gameProperties, 'Acceleration Gain'),
    {20} wbFloat(gameProperties, 'Snap Gain'),
    {24} wbFloat(gameProperties, 'Velocity Damping'),
         wbStruct(gameProperties, 'Snap Max Settings', [
           {28} wbFloat(gameProperties, 'Linear Velocity'),
           {32} wbFloat(gameProperties, 'Angular Velocity'),
           {36} wbFloat(gameProperties, 'Linear Distance'),
           {40} wbFloat(gameProperties, 'Angular Distance')
         ]),
         wbStruct(gameProperties, 'Position Max Velocity', [
           {44} wbFloat(gameProperties, 'Linear'),
           {48} wbFloat(gameProperties, 'Angular')
         ]),
         wbStruct(gameProperties, 'Position Max Velocity', [
           {52} wbInteger(gameProperties, 'Projectile', itS32, wbDiv(gameProperties, 1000)),
           {56} wbInteger(gameProperties, 'Melee', itS32, wbDiv(gameProperties, 1000))
         ])
    ], cpNormal, False),
    wbArray(gameProperties, RAFB, 'Feedback Dynamic Bones', wbInteger(gameProperties, 'Bone', itU16), 0, nil, nil, cpNormal, False),
    wbStruct(gameProperties, RAPS, 'Pose Matching Data', [
    {00} wbArray(gameProperties, 'Match Bones', wbInteger(gameProperties, 'Bone', itU16, wbHideFFFF), 3),
    {06} wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
           'Disable On Move'
         ])),
    {07} wbByteArray(gameProperties, 'Unused', 1),
    {08} wbFloat(gameProperties, 'Motors Strength'),
    {12} wbFloat(gameProperties, 'Pose Activation Delay Time'),
    {16} wbFloat(gameProperties, 'Match Error Allowance'),
    {20} wbFloat(gameProperties, 'Displacement To Disable')
    ], cpNormal, True),
    wbString(gameProperties, ANAM, 'Death Pose')
  ]);

  wbRecord(
  gameProperties,
  DOBJ, 'Default Object Manager', [
    wbEDIDReq,
    wbArray(gameProperties, DATA, 'Default Objects', wbFormID(gameProperties, 'Default Object'), [
      'Stimpack',
      'SuperStimpack',
      'RadX',
      'RadAway',
      'Morphine',
      'Perk Paralysis',
      'Player Faction',
      'Mysterious Stranger NPC',
      'Mysterious Stranger Faction',
      'Default Music',
      'Battle Music',
      'Death Music',
      'Success Music',
      'Level Up Music',
      'Player Voice (Male)',
      'Player Voice (Male Child)',
      'Player Voice (Female)',
      'Player Voice (Female Child)',
      'Eat Package Default Food',
      'Every Actor Ability',
      'Drug Wears Off Image Space',
      'Doctor''s Bag',
      'Miss Fortune NPC',
      'Miss Fortune Faction',
      'Meltdown Explosion',
      'Unarmed Forward PA',
      'Unarmed Backward PA',
      'Unarmed Left PA',
      'Unarmed Right PA',
      'Unarmed Crouch PA',
      'Unarmed Counter PA',
      'Spotter Effect',
      'Item Detected Effect',
      'Cateye Mobile Effect (NYI)'
    ], cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  LGTM, 'Lighting Template', [
    wbEDIDReq,
    wbStruct(gameProperties, DATA, 'Lighting', [
      wbStruct(gameProperties, 'Ambient Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Directional Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Fog Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbFloat(gameProperties, 'Fog Near'),
      wbFloat(gameProperties, 'Fog Far'),
      wbInteger(gameProperties, 'Directional Rotation XY', itS32),
      wbInteger(gameProperties, 'Directional Rotation Z', itS32),
      wbFloat(gameProperties, 'Directional Fade'),
      wbFloat(gameProperties, 'Fog Clip Dist'),
      wbFloat(gameProperties, 'Fog Power')
    ], cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  MUSC, 'Music Type', [
    wbEDIDReq,
    wbString(gameProperties, FNAM, 'FileName'),
    wbFloat(gameProperties, ANAM, 'dB (positive = Loop)')
  ]);

  wbRecord(
  gameProperties,
  GRAS, 'Grass', [
    wbEDIDReq,
    wbOBNDReq,
    wbMODLReq,
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Density', itU8),
      wbInteger(gameProperties, 'Min Slope', itU8),
      wbInteger(gameProperties, 'Max Slope', itU8),
      wbByteArray(gameProperties, 'Unused', 1),
      wbInteger(gameProperties, 'Unit from water amount', itU16),
      wbByteArray(gameProperties, 'Unused', 2),
      wbInteger(gameProperties, 'Unit from water type', itU32, wbEnum(gameProperties, [
        'Above - At Least',
        'Above - At Most',
        'Below - At Least',
        'Below - At Most',
        'Either - At Least',
        'Either - At Most',
        'Either - At Most Above',
        'Either - At Most Below'
      ])),
      wbFloat(gameProperties, 'Position Range'),
      wbFloat(gameProperties, 'Height Range'),
      wbFloat(gameProperties, 'Color Range'),
      wbFloat(gameProperties, 'Wave Period'),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        'Vertex Lighting',
        'Uniform Scaling',
        'Fit to Slope'
      ])),
      wbByteArray(gameProperties, 'Unused', 3)
    ], cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  HAIR, 'Hair', [
    wbEDIDReq,
    wbFULLReq,
    wbMODLReq,
    wbString(gameProperties, ICON, 'Texture', 0, cpNormal, True),
    wbInteger(gameProperties, DATA, 'Flags', itU8, wbFlags(gameProperties, [
      'Playable',
      'Not Male',
      'Not Female',
      'Fixed'
    ]), cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  IDLE, 'Idle Animation', [
    wbEDID,
    wbMODLReq,
    wbCTDAs,
    wbArray(gameProperties, ANAM, 'Related Idle Animations', wbFormIDCk(gameProperties, 'Related Idle Animation', [IDLE, NULL]), ['Parent', 'Previous Sibling'], cpNormal, True),
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Animation Group Section', itU8, wbIdleAnam),
      wbStruct(gameProperties, 'Looping', [
        wbInteger(gameProperties, 'Min', itU8),
        wbInteger(gameProperties, 'Max', itU8)
      ]),
      wbByteArray(gameProperties, 'Unused', 1),
      wbInteger(gameProperties, 'Replay Delay', itS16),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        'No attacking'
      ])),
      wbByteArray(gameProperties, 'Unused', 1)
    ], cpNormal, True, nil, 4)
  ]);

  wbRecord(
  gameProperties,
  INFO, 'Dialog response', [
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Type', itU8, wbEnum(gameProperties, [
        {0} 'Topic',
        {1} 'Conversation',
        {2} 'Combat',
        {3} 'Persuasion',
        {4} 'Detection',
        {5} 'Service',
        {6} 'Miscellaneous',
        {7} 'Radio'
      ])),
      wbInteger(gameProperties, 'Next Speaker', itU8, wbEnum(gameProperties, [
        {0} 'Target',
        {1} 'Self',
        {2} 'Either'
      ])),
      wbInteger(gameProperties, 'Flags 1', itU8, wbFlags(gameProperties, [
        {0x01} 'Goodbye',
        {0x02} 'Random',
        {0x04} 'Say Once',
        {0x08} 'Run Immediately',
        {0x10} 'Info Refusal',
        {0x20} 'Random End',
        {0x40} 'Run for Rumors',
        {0x80} 'Speech Challenge'
      ])),
      wbInteger(gameProperties, 'Flags 2', itU8, wbFlags(gameProperties, [
        {0x01} 'Say Once a Day',
        {0x02} 'Always Darken',
        {0x04} 'Unknown 2',
        {0x08} 'Unknown 3',
        {0x10} 'Low Intelligence',
        {0x20} 'High Intelligence'
      ]))
    ], cpNormal, True, nil, 3),
    wbFormIDCkNoReach(gameProperties, QSTI, 'Quest', [QUST], False, cpNormal, True),
    wbFormIDCk(gameProperties, TPIC, 'Topic', [DIAL]),  // The GECK ignores it for ESM
    wbFormIDCkNoReach(gameProperties, PNAM, 'Previous INFO', [INFO, NULL]),
    wbRArray(gameProperties, 'Add Topics', wbFormIDCk(gameProperties, NAME, 'Topic', [DIAL])),
    wbRArray(gameProperties, 'Responses',
      wbRStruct(gameProperties, 'Response', [
        wbStruct(gameProperties, TRDT, 'Response Data', [
          wbInteger(gameProperties, 'Emotion Type', itU32, wbEnum(gameProperties, [
            {0} 'Neutral',
            {1} 'Anger',
            {2} 'Disgust',
            {3} 'Fear',
            {4} 'Sad',
            {5} 'Happy',
            {6} 'Surprise',
            {7} 'Pained'
          ])),
          wbInteger(gameProperties, 'Emotion Value', itS32),
          wbByteArray(gameProperties, 'Unused', 4),
          wbInteger(gameProperties, 'Response number', itU8),
          wbByteArray(gameProperties, 'Unused', 3),
          wbFormIDCk(gameProperties, 'Sound', [SOUN, NULL]),
          wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
            'Use Emotion Animation'
          ])),
          wbByteArray(gameProperties, 'Unused', 3)
        ], cpNormal, False, nil, 5),
        wbStringKC(gameProperties, NAM1, 'Response Text', 0, cpTranslate, True),
        wbString(gameProperties, NAM2, 'Script Notes', 0, cpTranslate, True),
        wbString(gameProperties, NAM3, 'Edits'),
        wbFormIDCk(gameProperties, SNAM, 'Speaker Animation', [IDLE]),
        wbFormIDCk(gameProperties, LNAM, 'Listener Animation', [IDLE])
      ], [])
    ),
    wbCTDAs,
    wbRArray(gameProperties, 'Choices', wbFormIDCk(gameProperties, TCLT, 'Choice', [DIAL])),
    wbRArray(gameProperties, 'Link From', wbFormIDCk(gameProperties, TCLF, 'Topic', [DIAL])),
    wbRArray(gameProperties, 'Follow Up', wbFormIDCk(gameProperties, TCFU, 'Info', [INFO] )),
    wbRStruct(gameProperties, 'Script (Begin)', [
      wbEmbeddedScriptReq
    ], [], cpNormal, True),
    wbRStruct(gameProperties, 'Script (End)', [
      wbEmpty(gameProperties, NEXT, 'Marker'),
      wbEmbeddedScriptReq
    ], [], cpNormal, True),
    wbFormIDCk(gameProperties, SNDD, 'Unused', [SOUN]),
    wbStringKC(gameProperties, RNAM, 'Prompt'),
    wbFormIDCk(gameProperties, ANAM, 'Speaker', [CREA, NPC_]),
    wbFormIDCk(gameProperties, KNAM, 'ActorValue/Perk', [AVIF, PERK]),
    wbInteger(gameProperties, DNAM, 'Speech Challenge', itU32, wbEnum(gameProperties, [
      '---',
      'Very Easy',
      'Easy',
      'Average',
      'Hard',
      'Very Hard'
    ]))
  ], False, wbINFOAddInfo, cpNormal, False, wbINFOAfterLoad);

  wbRecord(
  gameProperties,
  INGR, 'Ingredient', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbICON,
    wbSCRI,
    wbETYPReq,
    wbFloat(gameProperties, DATA, 'Weight', cpNormal, True),
    wbStruct(gameProperties, ENIT, 'Effect Data', [
      wbInteger(gameProperties, 'Value', itS32),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, ['No auto-calculation', 'Food item'])),
      wbByteArray(gameProperties, 'Unused', 3)
    ], cpNormal, True),
    wbEffectsReq
  ]);

  wbRecord(
  gameProperties,
  KEYM, 'Key', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULLReq,
    wbMODL,
    wbICONReq,
    wbSCRI,
    wbDEST,
    wbYNAM,
    wbZNAM,
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Value', itS32),
      wbFloat(gameProperties, 'Weight')
    ], cpNormal, True),
    wbFormIDCk(gameProperties, RNAM, 'Sound - Random/Looping', [SOUN])
  ]);

  wbQuadrantEnum := wbEnum(gameProperties, [
    {0} 'Bottom Left',
    {1} 'Bottom Right',
    {2} 'Top Left',
    {3} 'Top Right'
  ]);

  if wbSimpleRecords then begin

    wbRecord(
    gameProperties,
    LAND, 'Landscape', [
      wbByteArray(gameProperties, DATA, 'Unknown'),
      wbByteArray(gameProperties, VNML, 'Vertex Normals'),
      wbByteArray(gameProperties, VHGT, 'Vertext Height Map'),
      wbByteArray(gameProperties, VCLR, 'Vertex Colours'),

      wbRArrayS(gameProperties, 'Layers', wbRUnion(gameProperties, 'Layer', [
        wbRStructSK(gameProperties, [0],'Base Layer', [
          wbStructSK(gameProperties, BTXT, [1, 3], 'Base Layer Header', [
            wbFormIDCk(gameProperties, 'Texture', [LTEX, NULL]),
            wbInteger(gameProperties, 'Quadrant', itU8, wbQuadrantEnum),
            wbByteArray(gameProperties, 'Unused', 1),
            wbInteger(gameProperties, 'Layer', itS16)
          ])
        ], []),
        wbRStructSK(gameProperties, [0],'Alpha Layer', [
          wbStructSK(gameProperties, ATXT, [1, 3], 'Alpha Layer Header', [
            wbFormIDCk(gameProperties, 'Texture', [LTEX, NULL]),
            wbInteger(gameProperties, 'Quadrant', itU8, wbQuadrantEnum),
            wbByteArray(gameProperties, 'Unused', 1),
            wbInteger(gameProperties, 'Layer', itS16)
          ]),
          wbByteArray(gameProperties, VTXT, 'Alpha Layer Data')
        ], [])
      ], [])),

      wbArray(gameProperties, VTEX, 'Textures', wbFormIDCk(gameProperties, 'Texture', [LTEX, NULL]))
    ]);

  end else begin

    wbRecord(
    gameProperties,
    LAND, 'Landscape', [
      wbByteArray(gameProperties, DATA, 'Unknown'),
      wbArray(gameProperties, VNML, 'Vertex Normals', wbStruct(gameProperties, 'Row', [
        wbArray(gameProperties, 'Columns', wbStruct(gameProperties, 'Column', [
          wbInteger(gameProperties, 'X', itU8),
          wbInteger(gameProperties, 'Y', itU8),
          wbInteger(gameProperties, 'Z', itU8)
        ]), 33)
      ]), 33),
      wbStruct(gameProperties, VHGT, 'Vertext Height Map', [
        wbFloat(gameProperties, 'Offset'),
        wbArray(gameProperties, 'Rows', wbStruct(gameProperties, 'Row', [
          wbArray(gameProperties, 'Columns', wbInteger(gameProperties, 'Column', itU8), 33)
        ]), 33),
        wbByteArray(gameProperties, 'Unused', 3)
      ]),
      wbArray(gameProperties, VCLR, 'Vertex Colours', wbStruct(gameProperties, 'Row', [
        wbArray(gameProperties, 'Columns', wbStruct(gameProperties, 'Column', [
          wbInteger(gameProperties, 'X', itU8),
          wbInteger(gameProperties, 'Y', itU8),
          wbInteger(gameProperties, 'Z', itU8)
        ]), 33)
      ]), 33),

      wbRArrayS(gameProperties, 'Layers', wbRUnion(gameProperties, 'Layer', [
        wbRStructSK(gameProperties, [0],'Base Layer', [
          wbStructSK(gameProperties, BTXT, [1, 3], 'Base Layer Header', [
            wbFormIDCk(gameProperties, 'Texture', [LTEX, NULL]),
            wbInteger(gameProperties, 'Quadrant', itU8, wbQuadrantEnum),
            wbByteArray(gameProperties, 'Unused', 1),
            wbInteger(gameProperties, 'Layer', itS16)
          ])
        ], []),
        wbRStructSK(gameProperties, [0],'Alpha Layer', [
          wbStructSK(gameProperties, ATXT, [1, 3], 'Alpha Layer Header', [
            wbFormIDCk(gameProperties, 'Texture', [LTEX, NULL]),
            wbInteger(gameProperties, 'Quadrant', itU8, wbQuadrantEnum),
            wbByteArray(gameProperties, 'Unused', 1),
            wbInteger(gameProperties, 'Layer', itS16)
          ]),
          wbArrayS(gameProperties, VTXT, 'Alpha Layer Data', wbStructSK(gameProperties, [0], 'Cell', [
            wbInteger(gameProperties, 'Position', itU16, wbAtxtPosition),
            wbByteArray(gameProperties, 'Unused', 2),
            wbFloat(gameProperties, 'Opacity')
          ]))
        ], [])
      ], [])),

      wbArray(gameProperties, VTEX, 'Textures', wbFormIDCk(gameProperties, 'Texture', [LTEX, NULL]))
    ]);

  end;

  wbRecord(
  gameProperties,
  LIGH, 'Light', [
    wbEDIDReq,
    wbOBNDReq,
    wbMODL,
    wbSCRI,
    wbDEST,
    wbFULL,
    wbICON,
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Time', itS32),
      wbInteger(gameProperties, 'Radius', itU32),
      wbStruct(gameProperties, 'Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbInteger(gameProperties, 'Unused', itU8)
      ]),
      wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
        {0x00000001} 'Dynamic',
        {0x00000002} 'Can be Carried',
        {0x00000004} 'Negative',
        {0x00000008} 'Flicker',
        {0x00000010} 'Unused',
        {0x00000020} 'Off By Default',
        {0x00000040} 'Flicker Slow',
        {0x00000080} 'Pulse',
        {0x00000100} 'Pulse Slow',
        {0x00000200} 'Spot Light',
        {0x00000400} 'Spot Shadow'
      ])),
      wbFloat(gameProperties, 'Falloff Exponent'),
      wbFloat(gameProperties, 'FOV'),
      wbInteger(gameProperties, 'Value', itU32),
      wbFloat(gameProperties, 'Weight')
    ], cpNormal, True),
    wbFloat(gameProperties, FNAM, 'Fade value', cpNormal, True),
    wbFormIDCk(gameProperties, SNAM, 'Sound', [SOUN])
  ], False, nil, cpNormal, False, wbLIGHAfterLoad);

  wbRecord(
  gameProperties,
  LSCR, 'Load Screen',
    wbFlags(gameProperties, wbRecordFlagsFlags, wbFlagsList(gameProperties, [
      {0x00000400} 10, 'Displays In Main Menu'
    ])), [
    wbEDIDReq,
    wbICONReq,
    wbDESCReq,
    wbRArrayS(gameProperties, 'Locations', wbStructSK(gameProperties, LNAM, [0, 1], 'Location', [
      wbFormIDCk(gameProperties, 'Direct', [CELL, WRLD, NULL]),
      wbStructSK(gameProperties, [0, 1], 'Indirect', [
        wbFormIDCk(gameProperties, 'World', [NULL, WRLD]),
        wbStructSK(gameProperties, [0,1], 'Grid', [
          wbInteger(gameProperties, 'Y', itS16),
          wbInteger(gameProperties, 'X', itS16)
        ])
      ])
    ])),
    wbFormIDCk(gameProperties, WMI1, 'Load Screen Type', [LSCT])
  ]);

  wbRecord(
  gameProperties,
  LTEX, 'Landscape Texture', [
    wbEDIDReq,
    wbICON,
    wbFormIDCk(gameProperties, TNAM, 'Texture', [TXST], False, cpNormal, True),
    wbStruct(gameProperties, HNAM, 'Havok Data', [
      wbInteger(gameProperties, 'Material Type', itU8, wbEnum(gameProperties, [
        {00} 'STONE',
        {01} 'CLOTH',
        {02} 'DIRT',
        {03} 'GLASS',
        {04} 'GRASS',
        {05} 'METAL',
        {06} 'ORGANIC',
        {07} 'SKIN',
        {08} 'WATER',
        {09} 'WOOD',
        {10} 'HEAVY STONE',
        {11} 'HEAVY METAL',
        {12} 'HEAVY WOOD',
        {13} 'CHAIN',
        {14} 'SNOW',
        {15} 'ELEVATOR',
        {16} 'HOLLOW METAL',
        {17} 'SHEET METAL',
        {18} 'SAND',
        {19} 'BRIKEN CONCRETE',
        {20} 'VEHILCE BODY',
        {21} 'VEHILCE PART SOLID',
        {22} 'VEHILCE PART HOLLOW',
        {23} 'BARREL',
        {24} 'BOTTLE',
        {25} 'SODA CAN',
        {26} 'PISTOL',
        {27} 'RIFLE',
        {28} 'SHOPPING CART',
        {29} 'LUNCHBOX',
        {30} 'BABY RATTLE',
        {31} 'RUBER BALL'
      ])),
      wbInteger(gameProperties, 'Friction', itU8),
      wbInteger(gameProperties, 'Restitution', itU8)
    ], cpNormal, True),
    wbInteger(gameProperties, SNAM, 'Texture Specular Exponent', itU8, nil, cpNormal, True),
    wbRArrayS(gameProperties, 'Grasses', wbFormIDCk(gameProperties, GNAM, 'Grass', [GRAS]))
  ]);

  wbRecord(
  gameProperties,
  LVLC, 'Leveled Creature', [
    wbEDIDReq,
    wbOBNDReq,
    wbInteger(gameProperties, LVLD, 'Chance none', itU8, nil, cpNormal, True),
    wbInteger(gameProperties, LVLF, 'Flags', itU8, wbFlags(gameProperties, [
      {0x01} 'Calculate from all levels <= player''s level',
      {0x02} 'Calculate for each item in count'
    ]), cpNormal, True),
    wbRArrayS(gameProperties, 'Leveled List Entries',
      wbRStructExSK(gameProperties, [0], [1], 'Leveled List Entry', [
        wbStructExSK(gameProperties, LVLO , [0, 2], [3], 'Base Data', [
          wbInteger(gameProperties, 'Level', itS16),
          wbByteArray(gameProperties, 'Unused', 2),
          wbFormIDCk(gameProperties, 'Reference', [CREA, LVLC]),
          wbInteger(gameProperties, 'Count', itS16),
          wbByteArray(gameProperties, 'Unused', 2)
        ]),
        wbCOED
      ], []),
    cpNormal, True),
    wbMODL
  ]);

  wbRecord(
  gameProperties,
  LVLN, 'Leveled NPC', [
    wbEDIDReq,
    wbOBNDReq,
    wbInteger(gameProperties, LVLD, 'Chance none', itU8, nil, cpNormal, True),
    wbInteger(gameProperties, LVLF, 'Flags', itU8, wbFlags(gameProperties, [
      {0x01} 'Calculate from all levels <= player''s level',
      {0x02} 'Calculate for each item in count'
    ]), cpNormal, True),
    wbRArrayS(gameProperties, 'Leveled List Entries',
      wbRStructExSK(gameProperties, [0], [1], 'Leveled List Entry', [
        wbStructExSK(gameProperties, LVLO , [0, 2], [3], 'Base Data', [
          wbInteger(gameProperties, 'Level', itS16),
          wbByteArray(gameProperties, 'Unused', 2),
          wbFormIDCk(gameProperties, 'Reference', [NPC_, LVLN]),
          wbInteger(gameProperties, 'Count', itS16),
          wbByteArray(gameProperties, 'Unused', 2)
        ]),
        wbCOED
      ], []),
    cpNormal, True),
    wbMODL
  ]);

   wbRecord(
   gameProperties,
   LVLI, 'Leveled Item', [
    wbEDIDReq,
    wbOBNDReq,
    wbInteger(gameProperties, LVLD, 'Chance none', itU8, nil, cpNormal, True),
    wbInteger(gameProperties, LVLF, 'Flags', itU8, wbFlags(gameProperties, [
      {0x01} 'Calculate from all levels <= player''s level',
      {0x02} 'Calculate for each item in count',
      {0x04} 'Use All'
    ]), cpNormal, True),
    wbFormIDCk(gameProperties, LVLG, 'Global', [GLOB]),
    wbRArrayS(gameProperties, 'Leveled List Entries',
      wbRStructExSK(gameProperties, [0], [1], 'Leveled List Entry', [
        wbStructExSK(gameProperties, LVLO , [0, 2], [3], 'Base Data', [
          wbInteger(gameProperties, 'Level', itS16),
          wbByteArray(gameProperties, 'Unused', 2),
          wbFormIDCk(gameProperties, 'Reference', [ARMO, AMMO, MISC, WEAP, BOOK, LVLI, KEYM, ALCH, NOTE, IMOD, CMNY, CCRD, CHIP]),
          wbInteger(gameProperties, 'Count', itS16),
          wbByteArray(gameProperties, 'Unused', 2)
        ]),
        wbCOED
      ], [])
    )
  ]);

  wbArchtypeEnum := wbEnum(gameProperties, [
    {00} 'Value Modifier',
    {01} 'Script',
    {02} 'Dispel',
    {03} 'Cure Disease',
    {04} '',
    {05} '',
    {06} '',
    {07} '',
    {08} '',
    {09} '',
    {10} '',
    {11} 'Invisibility',
    {12} 'Chameleon',
    {13} 'Light',
    {14} '',
    {15} '',
    {16} 'Lock',
    {17} 'Open',
    {18} 'Bound Item',
    {19} 'Summon Creature',
    {20} '',
    {21} '',
    {22} '',
    {23} '',
    {24} 'Paralysis',
    {25} '',
    {26} '',
    {27} '',
    {28} '',
    {29} '',
    {30} 'Cure Paralysis',
    {31} 'Cure Addiction',
    {32} 'Cure Poison',
    {33} 'Concussion',
    {34} 'Value And Parts',
    {35} 'Limb Condition',
    {36} 'Turbo'
  ]);

  wbRecord(
  gameProperties,
  MGEF, 'Base Effect', [
    wbEDIDReq,
    wbFULL,
    wbDESCReq,
    wbICON,
    wbMODL,
    wbStruct(gameProperties, DATA, 'Data', [
      wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
        {0x00000001} 'Hostile',
        {0x00000002} 'Recover',
        {0x00000004} 'Detrimental',
        {0x00000008} '',
        {0x00000010} 'Self',
        {0x00000020} 'Touch',
        {0x00000040} 'Target',
        {0x00000080} 'No Duration',
        {0x00000100} 'No Magnitude',
        {0x00000200} 'No Area',
        {0x00000400} 'FX Persist',
        {0x00000800} '',
        {0x00001000} 'Gory Visuals',
        {0x00002000} 'Display Name Only',
        {0x00004000} '',
        {0x00008000} 'Radio Broadcast ??',
        {0x00010000} '',
        {0x00020000} '',
        {0x00040000} '',
        {0x00080000} 'Use skill',
        {0x00100000} 'Use attribute',
        {0x00200000} '',
        {0x00400000} '',
        {0x00800000} '',
        {0x01000000} 'Painless',
        {0x02000000} 'Spray projectile type (or Fog if Bolt is specified as well)',
        {0x04000000} 'Bolt projectile type (or Fog if Spray is specified as well)',
        {0x08000000} 'No Hit Effect',
        {0x10000000} 'No Death Dispel',
        {0x20000000} '????'
      ])),
      {04} wbFloat(gameProperties, 'Base cost (Unused)'),
      {08} wbUnion(gameProperties, 'Assoc. Item', wbMGEFFAssocItemDecider, [
             wbFormID(gameProperties, 'Unused', cpIgnore),
             wbFormID(gameProperties, 'Assoc. Item'),
             wbFormIDCk(gameProperties, 'Assoc. Script', [SCPT, NULL]), //Script
             wbFormIDCk(gameProperties, 'Assoc. Item', [WEAP, ARMO, NULL]), //Bound Item
             wbFormIDCk(gameProperties, 'Assoc. Creature', [CREA]) //Summon Creature
           ], cpNormal, false, nil, wbMGEFFAssocItemAfterSet),
      {12} wbInteger(gameProperties, 'Magic School (Unused)', itS32, wbEnum(gameProperties, [
      ], [
        -1, 'None'
      ])),
      {16} wbInteger(gameProperties, 'Resistance Type', itS32, wbActorValueEnum),
      {20} wbInteger(gameProperties, 'Counter effect count', itU16),
      {22} wbByteArray(gameProperties, 'Unused', 2),
      {24} wbFormIDCk(gameProperties, 'Light', [LIGH, NULL]),
      {28} wbFloat(gameProperties, 'Projectile speed'),
      {32} wbFormIDCk(gameProperties, 'Effect Shader', [EFSH, NULL]),
      {36} wbFormIDCk(gameProperties, 'Object Display Shader', [EFSH, NULL]),
      {40} wbFormIDCk(gameProperties, 'Effect sound', [NULL, SOUN]),
      {44} wbFormIDCk(gameProperties, 'Bolt sound', [NULL, SOUN]),
      {48} wbFormIDCk(gameProperties, 'Hit sound', [NULL, SOUN]),
      {52} wbFormIDCk(gameProperties, 'Area sound', [NULL, SOUN]),
      {56} wbFloat(gameProperties, 'Constant Effect enchantment factor  (Unused)'),
      {60} wbFloat(gameProperties, 'Constant Effect barter factor (Unused)'),
      {64} wbInteger(gameProperties, 'Archtype', itU32, wbArchtypeEnum, cpNormal, False, nil, wbMGEFArchtypeAfterSet),
      {68} wbActorValue
    ], cpNormal, True),
    wbRArrayS(gameProperties, 'Counter Effects', wbFormIDCk(gameProperties, ESCE, 'Effect', [MGEF]), cpNormal, False, nil, wbCounterEffectsAfterSet)
  ], False, nil, cpNormal, False, wbMGEFAfterLoad, wbMGEFAfterSet);

  wbRecord(
  gameProperties,
  MISC, 'Misc. Item', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbICON,
    wbSCRI,
    wbDEST,
    wbYNAM,
    wbZNAM,
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Value', itS32),
      wbFloat(gameProperties, 'Weight')
    ], cpNormal, True),
    wbFormIDCk(gameProperties, RNAM, 'Sound - Random/Looping', [SOUN])
  ]);

  wbRecord(
  gameProperties,
  COBJ, 'Constructible Object', [
    wbEDID,
    wbOBND,
    wbFULL,
    wbMODL,
    wbICON,
    wbSCRI,
    wbYNAM,
    wbZNAM,
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Value', itS32),
      wbFloat(gameProperties, 'Weight')
    ], cpNormal, True)
  ]);

  // floats are reported to change faces after copying
  if True {wbSimpleRecords} then begin
    wbFaceGen := wbRStruct(gameProperties, 'FaceGen Data', [
      wbByteArray(gameProperties, FGGS, 'FaceGen Geometry-Symmetric', 0, cpNormal, True),
      wbByteArray(gameProperties, FGGA, 'FaceGen Geometry-Asymmetric', 0, cpNormal, True),
      wbByteArray(gameProperties, FGTS, 'FaceGen Texture-Symmetric', 0, cpNormal, True)
    ], [], cpNormal, True);

    wbFaceGenNPC := wbRStruct(gameProperties, 'FaceGen Data', [  // Arrays of 4bytes elements
      wbByteArray(gameProperties, FGGS, 'FaceGen Geometry-Symmetric', 0, cpNormal, True),
      wbByteArray(gameProperties, FGGA, 'FaceGen Geometry-Asymmetric', 0, cpNormal, True),
      wbByteArray(gameProperties, FGTS, 'FaceGen Texture-Symmetric', 0, cpNormal, True)
    ], [], cpNormal, True, wbActorTemplateUseModelAnimation);
  end else begin
    wbFaceGen := wbRStruct(gameProperties, 'FaceGen Data', [
      wbArray(gameProperties, FGGS, 'FaceGen Geometry-Symmetric',  wbFloat(gameProperties, 'Value'), [], cpNormal, True),
      wbArray(gameProperties, FGGA, 'FaceGen Geometry-Asymmetric', wbFloat(gameProperties, 'Value'), [], cpNormal, True),
      wbArray(gameProperties, FGTS, 'FaceGen Texture-Symmetric',   wbFloat(gameProperties, 'Value'), [], cpNormal, True)
    ], [], cpNormal, True);

    wbFaceGenNPC := wbRStruct(gameProperties, 'FaceGen Data', [
      wbArray(gameProperties, FGGS, 'FaceGen Geometry-Symmetric',  wbFloat(gameProperties, 'Value'), [], cpNormal, True),
      wbArray(gameProperties, FGGA, 'FaceGen Geometry-Asymmetric', wbFloat(gameProperties, 'Value'), [], cpNormal, True),
      wbArray(gameProperties, FGTS, 'FaceGen Texture-Symmetric',   wbFloat(gameProperties, 'Value'), [], cpNormal, True)
    ], [], cpNormal, True, wbActorTemplateUseModelAnimation);
  end;

  wbRecord(
  gameProperties,
  NPC_, 'Non-Player Character', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULLActor,
    wbMODLActor,
    wbStruct(gameProperties, ACBS, 'Configuration', [
      {00} wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
             {0x000001} 'Female',
             {0x000002} 'Essential',
             {0x000004} 'Is CharGen Face Preset',
             {0x000008} 'Respawn',
             {0x000010} 'Auto-calc stats',
             {0x000020} '',
             {0x000040} '',
             {0x000080} 'PC Level Mult',
             {0x000100} 'Use Template',
             {0x000200} 'No Low Level Processing',
             {0x000400} '',
             {0x000800} 'No Blood Spray',
             {0x001000} 'No Blood Decal',
             {0x002000} '',
             {0x004000} '',
             {0x008000} '',
             {0x010000} '',
             {0x020000} '',
             {0x040000} '',
             {0x080000} '',
             {0x100000} 'No VATS Melee',
           {0x00200000} '',
           {0x00400000} 'Can be all races',
           {0x00800000} 'Autocalc Service',
           {0x01000000} '',
           {0x02000000} '',
           {0x04000000} 'No Knockdowns',
           {0x08000000} 'Not Pushable',
           {0x10000000} 'Unknown 28',
           {0x20000000} '',
           {0x40000000} 'No Rotating To Head-track',
           {0x80000000} ''
           ], [
             {0x000001 Female} wbActorTemplateUseTraits,
             {0x000002 Essential} wbActorTemplateUseBaseData,
             {0x000004 Is CharGen Face Preset} nil,
             {0x000008 Respawn} wbActorTemplateUseBaseData,
             {0x000010 Auto-calc stats} wbActorTemplateUseStats,
             {0x000020 } nil,
             {0x000040 } nil,
             {0x000080 PC Level Mult} wbActorTemplateUseStats,
             {0x000100 Use Template} nil,
             {0x000200 No Low Level Processing} wbActorTemplateUseBaseData,
             {0x000400 } nil,
             {0x000800 No Blood Spray} wbActorTemplateUseModelAnimation,
             {0x001000 No Blood Decal} wbActorTemplateUseModelAnimation,
             {0x002000 } nil,
             {0x004000 } nil,
             {0x008000 } nil,
             {0x010000 } nil,
             {0x020000 } nil,
             {0x040000 } nil,
             {0x080000 } nil,
             {0x100000 No VATS Melee} nil,
           {0x00200000 } nil,
           {0x00400000 Can be all races} nil,
           {0x00800000 } nil,
           {0x01000000 } nil,
           {0x02000000 } nil,
           {0x04000000 No Knockdowns} nil,
           {0x08000000 Not Pushable} wbActorTemplateUseModelAnimation,
           {0x10000000 } nil,
           {0x20000000 } nil,
           {0x40000000 No Rotating To Head-track} wbActorTemplateUseModelAnimation,
           {0x80000000 } nil
           ])),
      {04} wbInteger(gameProperties, 'Fatigue', itU16, nil, cpNormal, True, wbActorTemplateUseStats),
      {06} wbInteger(gameProperties, 'Barter gold', itU16, nil, cpNormal, False, wbActorTemplateUseAIData),
      {08} wbUnion(gameProperties, 'Level', wbCreaLevelDecider, [
             wbInteger(gameProperties, 'Level', itS16, nil, cpNormal, True, wbActorTemplateUseStats),
             wbInteger(gameProperties, 'Level Mult', itS16, wbDiv(gameProperties, 1000), cpNormal, True, wbActorTemplateUseStats)
           ], cpNormal, True, wbActorTemplateUseStats),
      {10} wbInteger(gameProperties, 'Calc min', itU16, nil, cpNormal, True, wbActorTemplateUseStats),
      {12} wbInteger(gameProperties, 'Calc max', itU16, nil, cpNormal, True, wbActorTemplateUseStats),
      {14} wbInteger(gameProperties, 'Speed Multiplier', itU16, nil, cpNormal, True, wbActorTemplateUseStats),
      {16} wbFloat(gameProperties, 'Karma (Alignment)', cpNormal, False, 1, -1, wbActorTemplateUseTraits),
      {20} wbInteger(gameProperties, 'Disposition Base', itS16, nil, cpNormal, False, wbActorTemplateUseTraits),
      {22} wbInteger(gameProperties, 'Template Flags', itU16, wbTemplateFlags)
    ], cpNormal, True),
    wbRArrayS(gameProperties, 'Factions',
      wbStructSK(gameProperties, SNAM, [0], 'Faction', [
        wbFormIDCk(gameProperties, 'Faction', [FACT]),
        wbInteger(gameProperties, 'Rank', itU8),
        wbByteArray(gameProperties, 'Unused', 3)
      ]),
    cpNormal, False, nil, nil, wbActorTemplateUseFactions),
    wbFormIDCk(gameProperties, INAM, 'Death item', [LVLI], False, cpNormal, False, wbActorTemplateUseTraits),
    wbFormIDCk(gameProperties, VTCK, 'Voice', [VTYP], False, cpNormal, True, wbActorTemplateUseTraits),
    wbFormIDCk(gameProperties, TPLT, 'Template', [LVLN, NPC_]),
    wbFormIDCk(gameProperties, RNAM, 'Race', [RACE], False, cpNormal, True, wbActorTemplateUseTraits),
    wbSPLOs,
    wbFormIDCk(gameProperties, EITM, 'Unarmed Attack Effect', [ENCH, SPEL], False, cpNormal, False, wbActorTemplateUseActorEffectList),
    wbInteger(gameProperties, EAMT, 'Unarmed Attack Animation', itU16, wbAttackAnimationEnum, cpNormal, True, False, wbActorTemplateUseActorEffectList),
    wbDESTActor,
    wbSCRIActor,
    wbRArrayS(gameProperties, 'Items', wbCNTO, cpNormal, False, nil, nil, wbActorTemplateUseInventory),
    wbAIDT,
    wbRArray(gameProperties, 'Packages', wbFormIDCk(gameProperties, PKID, 'Package', [PACK]), cpNormal, False, nil, nil, wbActorTemplateUseAIPackages),
    wbArrayS(gameProperties, KFFZ, 'Animations', wbStringLC(gameProperties, 'Animation'), 0, cpNormal, False, nil, nil, wbActorTemplateUseModelAnimation),
    wbFormIDCk(gameProperties, CNAM, 'Class', [CLAS], False, cpNormal, True, wbActorTemplateUseTraits),
    wbStruct(gameProperties, DATA, '', [
      {00} wbInteger(gameProperties, 'Base Health', itS32),
      {04} wbArray(gameProperties, 'Attributes', wbInteger(gameProperties, 'Attribute', itU8), [
            'Strength',
            'Perception',
            'Endurance',
            'Charisma',
            'Intelligence',
            'Agility',
            'Luck'
          ], cpNormal, False, wbActorAutoCalcDontShow),
          wbByteArray(gameProperties, 'Unused'{, 14 - only present in old record versions})
    ], cpNormal, True, wbActorTemplateUseStats),
    wbStruct(gameProperties, DNAM, '', [
      {00} wbArray(gameProperties, 'Skill Values', wbInteger(gameProperties, 'Skill', itU8), [
             'Barter',
             'Big Guns',
             'Energy Weapons',
             'Explosives',
             'Lockpick',
             'Medicine',
             'Melee Weapons',
             'Repair',
             'Science',
             'Guns',
             'Sneak',
             'Speech',
             'Survival',
             'Unarmed'
           ]),
      {14} wbArray(gameProperties, 'Skill Offsets', wbInteger(gameProperties, 'Skill', itU8), [
             'Barter',
             'Big Guns',
             'Energy Weapons',
             'Explosives',
             'Lockpick',
             'Medicine',
             'Melee Weapons',
             'Repair',
             'Science',
             'Guns',
             'Sneak',
             'Speech',
             'Survival',
             'Unarmed'
           ])
    ], cpNormal, False, wbActorTemplateUseStatsAutoCalc),
    wbRArrayS(gameProperties, 'Head Parts',
      wbFormIDCk(gameProperties, PNAM, 'Head Part', [HDPT]),
    cpNormal, False, nil, nil, wbActorTemplateUseModelAnimation),
    wbFormIDCk(gameProperties, HNAM, 'Hair', [HAIR], False, cpNormal, False, wbActorTemplateUseModelAnimation),
    wbFloat(gameProperties, LNAM, 'Hair length', cpNormal, False, 1, -1, wbActorTemplateUseModelAnimation),
    wbFormIDCk(gameProperties, ENAM, 'Eyes', [EYES], False, cpNormal, False, wbActorTemplateUseModelAnimation),
    wbStruct(gameProperties, HCLR, 'Hair color', [
      wbInteger(gameProperties, 'Red', itU8),
      wbInteger(gameProperties, 'Green', itU8),
      wbInteger(gameProperties, 'Blue', itU8),
      wbByteArray(gameProperties, 'Unused', 1)
    ], cpNormal, True, wbActorTemplateUseModelAnimation),
    wbFormIDCk(gameProperties, ZNAM, 'Combat Style', [CSTY], False, cpNormal, False, wbActorTemplateUseTraits),
    wbInteger(gameProperties, NAM4, 'Impact Material Type', itU32, wbImpactMaterialTypeEnum, cpNormal, True, False, wbActorTemplateUseModelAnimation),
    wbFaceGenNPC,
    wbInteger(gameProperties, NAM5, 'Unknown', itU16, nil, cpNormal, True, False, nil, nil, 255),
    wbFloat(gameProperties, NAM6, 'Height', cpNormal, True, 1, -1, wbActorTemplateUseTraits),
    wbFloat(gameProperties, NAM7, 'Weight', cpNormal, True, 1, -1, wbActorTemplateUseTraits)
  ], True, nil, cpNormal, False, wbNPCAfterLoad);

  wbPKDTFlags := wbFlags(gameProperties, [
          {0x00000001} 'Offers Services',
          {0x00000002} 'Must reach location',
          {0x00000004} 'Must complete',
          {0x00000008} 'Lock doors at package start',
          {0x00000010} 'Lock doors at package end',
          {0x00000020} 'Lock doors at location',
          {0x00000040} 'Unlock doors at package start',
          {0x00000080} 'Unlock doors at package end',
          {0x00000100} 'Unlock doors at location',
          {0x00000200} 'Continue if PC near',
          {0x00000400} 'Once per day',
          {0x00000800} '',
          {0x00001000} 'Skip fallout behavior',
          {0x00002000} 'Always run',
          {0x00004000} '',
          {0x00008000} '',
          {0x00010000} '',
          {0x00020000} 'Always sneak',
          {0x00040000} 'Allow swimming',
          {0x00080000} 'Allow falls',
          {0x00100000} 'Head-Tracking off',
          {0x00200000} 'Weapons unequipped',
          {0x00400000} 'Defensive combat',
          {0x00800000} 'Weapon Drawn',
          {0x01000000} 'No idle anims',
          {0x02000000} 'Pretend In Combat',
          {0x04000000} 'Continue During Combat',
          {0x08000000} 'No Combat Alert',
          {0x10000000} 'No Warn/Attack Behaviour',
          {0x20000000} '',
          {0x40000000} '',
          {0x80000000} ''
        ]);

  wbPKDTType := wbEnum(gameProperties, [
           {0} 'Find',
           {1} 'Follow',
           {2} 'Escort',
           {3} 'Eat',
           {4} 'Sleep',
           {5} 'Wander',
           {6} 'Travel',
           {7} 'Accompany',
           {8} 'Use Item At',
           {9} 'Ambush',
          {10} 'Flee Not Combat',
          {11} 'Package Type 11',
          {12} 'Sandbox',
          {13} 'Patrol',
          {14} 'Guard',
          {15} 'Dialogue',
          {16} 'Use Weapon',
          {17} 'Package Type 17',
          {18} 'Combat Controller',
          {19} 'Package Type 19',
          {20} 'Package Type 20',
          {21} 'Alarm',
          {22} 'Flee',
          {23} 'TressPass',
          {24} 'Spectator',
          {25} 'Package Type 25',
          {26} 'Package Type 26',
          {27} 'Package Type 27',
          {28} 'Dialogue 2',
          {29} 'Package Type 29',
          {30} 'Package Type 30',
          {31} 'Package Type 31',
          {32} 'Package Type 32',
          {33} 'Package Type 33',
          {34} 'Package Type 34',
          {35} 'Package Type 35',
          {36} 'Package Type 36',
          {37} 'Package Type 37',
          {38} 'Package Type 38',
          {39} 'Package Type 39',
          {40} 'Package Type 40'
        ]);

  wbObjectTypeEnum := wbEnum(gameProperties, [
          ' NONE',
          'Activators',
          'Armor',
          'Books',
          'Clothing',
          'Containers',
          'Doors',
          'Ingredients',
          'Lights',
          'Misc',
          'Flora',
          'Furniture',
          'Weapons: Any',
          'Ammo',
          'NPCs',
          'Creatures',
          'Keys',
          'Alchemy',
          'Food',
          ' All: Combat Wearable',
          ' All: Wearable',
          'Weapons: Ranged',
          'Weapons: Melee',
          'Weapons: NONE',
          'Actor Effects: Any',
          'Actor Effects: Range Target',
          'Actor Effects: Range Touch',
          'Actor Effects: Range Self',
//          '',
          'Actors: Any'
        ]);


  wbPKDTSpecificFlagsUnused := True;

  wbRecord(
  gameProperties,
  PACK, 'Package', [
    wbEDIDReq,
    wbStruct(gameProperties, PKDT, 'General', [
      wbInteger(gameProperties, 'General Flags', itU32, wbPKDTFlags),
      wbInteger(gameProperties, 'Type', itU8, wbPKDTType),
      wbByteArray(gameProperties, 'Unused', 1),
      wbInteger(gameProperties, 'Fallout Behavior Flags', itU16, wbFlags(gameProperties, [
        {0x00000001}'Hellos To Player',
        {0x00000002}'Random Conversations',
        {0x00000004}'Observe Combat Behavior',
        {0x00000008}'Unknown 4',
        {0x00000010}'Reaction To Player Actions',
        {0x00000020}'Friendly Fire Comments',
        {0x00000040}'Aggro Radius Behavior',
        {0x00000080}'Allow Idle Chatter',
        {0x00000100}'Avoid Radiation'
      ], True)),
      wbUnion(gameProperties, 'Type Specific Flags', wbPKDTSpecificFlagsDecider, [
        wbEmpty(gameProperties, 'Type Specific Flags (missing)', cpIgnore, False, nil, True),
        wbInteger(gameProperties, 'Type Specific Flags - Find', itU16, wbFlags(gameProperties, [
          {0x00000001}'',
          {0x00000002}'',
          {0x00000004}'',
          {0x00000008}'',
          {0x00000010}'',
          {0x00000020}'',
          {0x00000040}'',
          {0x00000080}'',
          {0x00000100}'Find - Allow Buying',
          {0x00000200}'Find - Allow Killing',
          {0x00000400}'Find - Allow Stealing'
        ], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Follow', itU16, wbFlags(gameProperties, [], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Escort', itU16, wbFlags(gameProperties, [
          {0x00000001}'',
          {0x00000002}'',
          {0x00000004}'',
          {0x00000008}'',
          {0x00000010}'',
          {0x00000020}'',
          {0x00000040}'',
          {0x00000080}'',
          {0x00000100}'Escort - Allow Buying',
          {0x00000200}'Escort - Allow Killing',
          {0x00000400}'Escort - Allow Stealing'
        ], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Eat', itU16, wbFlags(gameProperties, [
          {0x00000001}'',
          {0x00000002}'',
          {0x00000004}'',
          {0x00000008}'',
          {0x00000010}'',
          {0x00000020}'',
          {0x00000040}'',
          {0x00000080}'',
          {0x00000100}'Eat - Allow Buying',
          {0x00000200}'Eat - Allow Killing',
          {0x00000400}'Eat - Allow Stealing'
        ], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Sleep', itU16, wbFlags(gameProperties, [], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Wander', itU16, wbFlags(gameProperties, [
          {0x00000001}'Wander - No Eating',
          {0x00000002}'Wander - No Sleeping',
          {0x00000004}'Wander - No Conversation',
          {0x00000008}'Wander - No Idle Markers',
          {0x00000010}'Wander - No Furniture',
          {0x00000020}'Wander - No Wandering'
        ], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Travel', itU16, wbFlags(gameProperties, [], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Accompany', itU16, wbFlags(gameProperties, [], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Use Item At', itU16, wbFlags(gameProperties, [
          {0x00000001}'',
          {0x00000002}'Use Item At - Sit Down',
          {0x00000004}'',
          {0x00000008}'',
          {0x00000010}'',
          {0x00000020}'',
          {0x00000040}'',
          {0x00000080}'',
          {0x00000100}'Use Item At - Allow Buying',
          {0x00000200}'Use Item At - Allow Killing',
          {0x00000400}'Use Item At - Allow Stealing'
        ], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Ambush', itU16, wbFlags(gameProperties, [
          {0x00000001}'Ambush - Hide While Ambushing'
        ], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Flee Not Combat', itU16, wbFlags(gameProperties, [], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - ?', itU16, wbFlags(gameProperties, [], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Sandbox', itU16, wbFlags(gameProperties, [
          {0x00000001}'Sandbox - No Eating',
          {0x00000002}'Sandbox - No Sleeping',
          {0x00000004}'Sandbox - No Conversation',
          {0x00000008}'Sandbox - No Idle Markers',
          {0x00000010}'Sandbox - No Furniture',
          {0x00000020}'Sandbox - No Wandering'
        ], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Patrol', itU16, wbFlags(gameProperties, [], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Guard', itU16, wbFlags(gameProperties, [
          {0x00000001}'',
          {0x00000002}'',
          {0x00000004}'Guard - Remain Near Reference to Guard'
        ], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Dialogue', itU16, wbFlags(gameProperties, [], wbPKDTSpecificFlagsUnused)),
        wbInteger(gameProperties, 'Type Specific Flags - Use Weapon', itU16, wbFlags(gameProperties, [], wbPKDTSpecificFlagsUnused))
      ]),
      wbByteArray(gameProperties, 'Unused', 2)
    ], cpNormal, True, nil, 2),
    wbRStruct(gameProperties, 'Locations', [
      wbStruct(gameProperties, PLDT, 'Location 1', [
        wbInteger(gameProperties, 'Type', itS32, wbEnum(gameProperties, [     // Byte + filler
          {0} 'Near reference',
          {1} 'In cell',
          {2} 'Near current location',
          {3} 'Near editor location',
          {4} 'Object ID',
          {5} 'Object Type',
          {6} 'Near linked reference',
          {7} 'At package location'
        ])),
        wbUnion(gameProperties, 'Location', wbPxDTLocationDecider, [
          wbFormIDCkNoReach(gameProperties, 'Reference', [REFR, PGRE, PMIS, PBEA, ACHR, ACRE, PLYR], True),
          wbFormIDCkNoReach(gameProperties, 'Cell', [CELL]),
          wbByteArray(gameProperties, 'Unused', 4, cpIgnore),
          wbByteArray(gameProperties, 'Unused', 4, cpIgnore),
          wbFormIDCkNoReach(gameProperties, 'Object ID', [ACTI, DOOR, STAT, FURN, CREA, SPEL, NPC_, CONT, ARMO, AMMO, MISC, WEAP, BOOK, KEYM, ALCH, LIGH, CHIP, CMNY, CCRD, IMOD]),
          wbInteger(gameProperties, 'Object Type', itU32, wbObjectTypeEnum),
          wbByteArray(gameProperties, 'Unused', 4, cpIgnore),
          wbByteArray(gameProperties, 'Unused', 4, cpIgnore)
        ]),
        wbInteger(gameProperties, 'Radius', itS32)
      ], cpNormal{, True}),
      wbStruct(gameProperties, PLD2, 'Location 2', [
        wbInteger(gameProperties, 'Type', itS32, wbEnum(gameProperties, [
          {0} 'Near reference',
          {1} 'In cell',
          {2} 'Near current location',
          {3} 'Near editor location',
          {4} 'Object ID',
          {5} 'Object Type',
          {6} 'Near linked reference',
          {7} 'At package location'
        ])),
        wbUnion(gameProperties, 'Location', wbPxDTLocationDecider, [
          wbFormIDCkNoReach(gameProperties, 'Reference', [REFR, PGRE, PMIS, PBEA, ACHR, ACRE, PLYR], True),
          wbFormIDCkNoReach(gameProperties, 'Cell', [CELL]),
          wbByteArray(gameProperties, 'Unused', 4, cpIgnore),
          wbByteArray(gameProperties, 'Unused', 4, cpIgnore),
          wbFormIDCkNoReach(gameProperties, 'Object ID', [ACTI, DOOR, STAT, FURN, CREA, SPEL, NPC_, CONT, ARMO, AMMO, MISC, WEAP, BOOK, KEYM, ALCH, LIGH, CHIP, CMNY, CCRD, IMOD]),
          wbInteger(gameProperties, 'Object Type', itU32, wbObjectTypeEnum),
          wbByteArray(gameProperties, 'Unused', 4, cpIgnore),
          wbByteArray(gameProperties, 'Unused', 4, cpIgnore)
        ]),
        wbInteger(gameProperties, 'Radius', itS32)
      ])
    ], [], cpNormal, False, nil, True),
    wbStruct(gameProperties, PSDT, 'Schedule', [
      wbInteger(gameProperties, 'Month', itS8),
      wbInteger(gameProperties, 'Day of week', itS8, wbEnum(gameProperties, [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Weekdays',
        'Weekends',
        'Monday, Wednesday, Friday',
        'Tuesday, Thursday'
      ], [
        -1, 'Any'
      ])),
      wbInteger(gameProperties, 'Date', itU8),
      wbInteger(gameProperties, 'Time', itS8),
      wbInteger(gameProperties, 'Duration', itS32)
    ], cpNormal, True),
    wbStruct(gameProperties, PTDT, 'Target 1', [
      wbInteger(gameProperties, 'Type', itS32, wbEnum(gameProperties, [
        {0} 'Specific Reference',
        {1} 'Object ID',
        {2} 'Object Type',
        {3} 'Linked Reference'
      ]), cpNormal, False, nil, nil, 2),
      wbUnion(gameProperties, 'Target', wbPxDTLocationDecider, [
        wbFormIDCkNoReach(gameProperties, 'Reference', [ACHR, ACRE, REFR, PGRE, PMIS, PBEA, PLYR], True),
        wbFormIDCkNoReach(gameProperties, 'Object ID', [ACTI, DOOR, STAT, FURN, CREA, SPEL, NPC_, LVLN, LVLC, CONT, ARMO, AMMO, MISC, WEAP, BOOK, KEYM, ALCH, LIGH, FACT, FLST, IDLM, CHIP, CMNY, CCRD, IMOD]),
        wbInteger(gameProperties, 'Object Type', itU32, wbObjectTypeEnum),
        wbByteArray(gameProperties, 'Unused', 4, cpIgnore)
      ]),
      wbInteger(gameProperties, 'Count / Distance', itS32),
      wbFloat(gameProperties, 'Unknown')
    ], cpNormal, False, nil, 3),
    wbCTDAs,
    wbRStruct(gameProperties, 'Idle Animations', [
      wbInteger(gameProperties, IDLF, 'Flags', itU8, wbFlags(gameProperties, [
        'Run in Sequence',
        '',
        'Do Once'
      ]), cpNormal, True),
      wbStruct(gameProperties, IDLC, '', [
        wbInteger(gameProperties,  'Animation Count', itU8),
        wbByteArray(gameProperties, 'Unused', 3)
      ], cpNormal, True, nil, 1),
      wbFloat(gameProperties, IDLT, 'Idle Timer Setting', cpNormal, True),
      wbArray(gameProperties, IDLA, 'Animations', wbFormIDCk(gameProperties, 'Animation', [IDLE]), 0, nil, wbIDLAsAfterSet, cpNormal, True),
      wbByteArray(gameProperties, IDLB, 'Unused', 4, cpIgnore)
    ], [], cpNormal, False, nil, False, nil {cannot be totally removed , wbAnimationsAfterSet}),
    wbFormIDCk(gameProperties, CNAM, 'Combat Style', [CSTY]),
    wbEmpty(gameProperties, PKED, 'Eat Marker'),
    wbInteger(gameProperties, PKE2, 'Escort Distance', itU32),
    wbFloat(gameProperties, PKFD, 'Follow - Start Location - Trigger Radius'),
    wbStruct(gameProperties, PKPT, 'Patrol Flags', [
      wbInteger(gameProperties, 'Repeatable', itU8, wbEnum(gameProperties, ['No', 'Yes']), cpNormal, False, nil, nil, 1),
      wbByteArray(gameProperties, 'Unused', 1)
    ], cpNormal, False, nil, 1),
    wbStruct(gameProperties, PKW3, 'Use Weapon Data', [
      wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
        'Always Hit',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        'Do No Damage',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        'Crouch To Reload',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        'Hold Fire When Blocked'
      ])),
      wbInteger(gameProperties, 'Fire Rate', itU8, wbEnum(gameProperties, [
        'Auto Fire',
        'Volley Fire'
      ])),
      wbInteger(gameProperties, 'Fire Count', itU8, wbEnum(gameProperties, [
        'Number of Bursts',
        'Repeat Fire'
      ])),
      wbInteger(gameProperties, 'Number of Bursts', itU16),
      wbStruct(gameProperties, 'Shoots Per Volleys', [
        wbInteger(gameProperties, 'Min', itU16),
        wbInteger(gameProperties, 'Max', itU16)
      ]),
      wbStruct(gameProperties, 'Pause Between Volleys', [
        wbFloat(gameProperties, 'Min'),
        wbFloat(gameProperties, 'Max')
      ]),
      wbByteArray(gameProperties, 'Unused', 4)
    ]),
    wbStruct(gameProperties, PTD2, 'Target 2', [
      wbInteger(gameProperties, 'Type', itS32, wbEnum(gameProperties, [
        {0} 'Specific reference',
        {1} 'Object ID',
        {2} 'Object Type',
        {3} 'Linked Reference'
      ])),
      wbUnion(gameProperties, 'Target', wbPxDTLocationDecider, [
        wbFormIDCkNoReach(gameProperties, 'Reference', [ACHR, ACRE, REFR, PGRE, PMIS, PBEA, PLYR], True),
        wbFormIDCkNoReach(gameProperties, 'Object ID', [ACTI, DOOR, STAT, FURN, CREA, SPEL, NPC_, LVLN, LVLC, CONT, ARMO, AMMO, MISC, WEAP, BOOK, KEYM, ALCH, LIGH, FACT, FLST, CHIP, CMNY, CCRD, IMOD]),
        wbInteger(gameProperties, 'Object Type', itU32, wbObjectTypeEnum),
        wbByteArray(gameProperties, 'Unused', 4, cpIgnore)
      ]),
      wbInteger(gameProperties, 'Count / Distance', itS32),
      wbFloat(gameProperties, 'Unknown')
    ], cpNormal, False, nil, 3),
    wbEmpty(gameProperties, PUID, 'Use Item Marker'),
    wbEmpty(gameProperties, PKAM, 'Ambush Marker'),
    wbStruct(gameProperties, PKDD, 'Dialogue Data', [
      wbFloat(gameProperties, 'FOV'),
      wbFormIDCk(gameProperties, 'Topic', [DIAL, NULL]),
      wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
        'No Headtracking',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        'Don''t Control Target Movement'
      ])),
      wbByteArray(gameProperties, 'Unused', 4),
      wbInteger(gameProperties, 'Dialogue Type', itU32, wbEnum(gameProperties, [
        'Conversation',
        'Say To'
      ])),
      wbByteArray(gameProperties, 'Unknown', 4)
    ], cpNormal, False, nil, 3),
    wbStruct(gameProperties, PLD2, 'Location 2 (again??)', [
      wbInteger(gameProperties, 'Type', itS32, wbEnum(gameProperties, [
        {0} 'Near reference',
        {1} 'In cell',
        {2} 'Near current location',
        {3} 'Near editor location',
        {4} 'Object ID',
        {5} 'Object Type',
        {6} 'Near linked reference',
        {7} 'At package location'
      ])),
      wbUnion(gameProperties, 'Location', wbPxDTLocationDecider, [
        wbFormIDCkNoReach(gameProperties, 'Reference', [REFR, PGRE, PMIS, PBEA, ACHR, ACRE, PLYR], True),
        wbFormIDCkNoReach(gameProperties, 'Cell', [CELL]),
        wbByteArray(gameProperties, 'Unused', 4, cpIgnore),
        wbByteArray(gameProperties, 'Unused', 4, cpIgnore),
        wbFormIDCkNoReach(gameProperties, 'Object ID', [ACTI, DOOR, STAT, FURN, CREA, SPEL, NPC_, CONT, ARMO, AMMO, MISC, WEAP, BOOK, KEYM, ALCH, LIGH, CHIP, CMNY, CCRD, IMOD]),
        wbInteger(gameProperties, 'Object Type', itU32, wbObjectTypeEnum),
        wbByteArray(gameProperties, 'Unused', 4, cpIgnore),
        wbByteArray(gameProperties, 'Unused', 4, cpIgnore)
      ]),
      wbInteger(gameProperties, 'Radius', itS32)
    ]),
    wbRStruct(gameProperties, 'OnBegin', [
      wbEmpty(gameProperties, POBA, 'OnBegin Marker', cpNormal, True),
      wbFormIDCk(gameProperties, INAM, 'Idle', [IDLE, NULL], False, cpNormal, True),
      wbEmbeddedScriptReq,
      wbFormIDCk(gameProperties, TNAM, 'Topic', [DIAL, NULL], False, cpNormal, True)
    ], [], cpNormal, True),
    wbRStruct(gameProperties, 'OnEnd', [
      wbEmpty(gameProperties, POEA, 'OnEnd Marker', cpNormal, True),
      wbFormIDCk(gameProperties, INAM, 'Idle', [IDLE, NULL], False, cpNormal, True),
      wbEmbeddedScriptReq,
      wbFormIDCk(gameProperties, TNAM, 'Topic', [DIAL, NULL], False, cpNormal, True)
    ], [], cpNormal, True),
    wbRStruct(gameProperties, 'OnChange', [
      wbEmpty(gameProperties, POCA, 'OnChange Marker', cpNormal, True),
      wbFormIDCk(gameProperties, INAM, 'Idle', [IDLE, NULL], False, cpNormal, True),
      wbEmbeddedScriptReq,
      wbFormIDCk(gameProperties, TNAM, 'Topic', [DIAL, NULL], False, cpNormal, True)
    ], [], cpNormal, True)
  ], False, nil, cpNormal, False, wbPACKAfterLoad);

  wbRecord(
  gameProperties,
  QUST, 'Quest', [
    wbEDIDReq,
    wbSCRI,
    wbFULL,
    wbICON,
    wbStruct(gameProperties, DATA, 'General', [
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        {0x01} 'Start game enabled',
        {0x02} '',
        {0x04} 'Allow repeated conversation topics',
        {0x08} 'Allow repeated stages',
        {0x10} 'Unknown 4'
      ])),
      wbInteger(gameProperties, 'Priority', itU8),
      wbByteArray(gameProperties, 'Unused', 2),
      wbFloat(gameProperties, 'Quest Delay')
    ], cpNormal, True, nil, 3),
    wbCTDAs,
    wbRArrayS(gameProperties, 'Stages', wbRStructSK(gameProperties, [0], 'Stage', [
      wbInteger(gameProperties, INDX, 'Stage Index', itS16),
      wbRArray(gameProperties, 'Log Entries', wbRStruct(gameProperties, 'Log Entry', [
        wbInteger(gameProperties, QSDT, 'Stage Flags', itU8, wbFlags(gameProperties, [
          {0x01} 'Complete Quest',
          {0x02} 'Fail Quest'
        ])),
        wbCTDAs,
        wbStringKC(gameProperties, CNAM, 'Log Entry', 0, cpTranslate),
        wbEmbeddedScriptReq,
        wbFormIDCk(gameProperties, NAM0, 'Next Quest', [QUST])
      ], []))
    ], [])),
    wbRArray(gameProperties, 'Objectives', wbRStruct(gameProperties, 'Objective', [
      wbInteger(gameProperties, QOBJ, 'Objective Index', itS32),
      wbStringKC(gameProperties, NNAM, 'Description', 0, cpNormal, True),
      wbRArray(gameProperties, 'Targets', wbRStruct(gameProperties, 'Target', [
        wbStruct(gameProperties, QSTA, 'Target', [
          wbFormIDCkNoReach(gameProperties, 'Target', [REFR, PGRE, PMIS, PBEA, ACRE, ACHR], True),
          wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
            {0x01} 'Compass Marker Ignores Locks'
          ])),
          wbByteArray(gameProperties, 'Unused', 3)
        ]),
        wbCTDAs
      ], []))
    ], []))
  ]);

  wbHeadPartIndexEnum := wbEnum(gameProperties, [
    'Head',
    'Ears',
    'Mouth',
    'Teeth Lower',
    'Teeth Upper',
    'Tongue',
    'Left Eye',
    'Right Eye'
  ]);

  wbBodyPartIndexEnum := wbEnum(gameProperties, [
    'Upper Body',
    'Left Hand',
    'Right Hand',
    'Upper Body Texture'
  ]);

  wbRecord(
  gameProperties,
  RACE, 'Race', [
    wbEDIDReq,
    wbFULLReq,
    wbDESCReq,
    wbXNAMs,
    wbStruct(gameProperties, DATA, '', [
      wbArrayS(gameProperties, 'Skill Boosts', wbStructSK(gameProperties, [0], 'Skill Boost', [
        wbInteger(gameProperties, 'Skill', itS8, wbActorValueEnum),
        wbInteger(gameProperties, 'Boost', itS8)
      ]), 7),
      wbByteArray(gameProperties, 'Unused', 2),
      wbFloat(gameProperties, 'Male Height'),
      wbFloat(gameProperties, 'Female Height'),
      wbFloat(gameProperties, 'Male Weight'),
      wbFloat(gameProperties, 'Female Weight'),
      wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
        'Playable',
        '',
        'Child'
      ]))
    ], cpNormal, True),
    wbFormIDCk(gameProperties, ONAM, 'Older', [RACE]),
    wbFormIDCk(gameProperties, YNAM, 'Younger', [RACE]),
    wbEmpty(gameProperties, NAM2, 'Unknown Marker', cpNormal, True),
    wbArray(gameProperties, VTCK, 'Voices', wbFormIDCk(gameProperties, 'Voice', [VTYP]), ['Male', 'Female'], cpNormal, True),
    wbArray(gameProperties, DNAM, 'Default Hair Styles', wbFormIDCk(gameProperties, 'Default Hair Style', [HAIR, NULL]), ['Male', 'Female'], cpNormal, True),
    wbArray(gameProperties, CNAM, 'Default Hair Colors', wbInteger(gameProperties, 'Default Hair Color', itU8, wbEnum(gameProperties, [
      'Bleached',
      'Brown',
      'Chocolate',
      'Platinum',
      'Cornsilk',
      'Suede',
      'Pecan',
      'Auburn',
      'Ginger',
      'Honey',
      'Gold',
      'Rosewood',
      'Black',
      'Chestnut',
      'Steel',
      'Champagne'
    ])), ['Male', 'Female'], cpNormal, True),
    wbFloat(gameProperties, PNAM, 'FaceGen - Main clamp', cpNormal, True),
    wbFloat(gameProperties, UNAM, 'FaceGen - Face clamp', cpNormal, True),
    wbByteArray(gameProperties, ATTR, 'Unused', 0, cpNormal, True),
    wbRStruct(gameProperties, 'Head Data', [
      wbEmpty(gameProperties, NAM0, 'Head Data Marker', cpNormal, True),
      wbRStruct(gameProperties, 'Male Head Data', [
        wbEmpty(gameProperties, MNAM, 'Male Data Marker', cpNormal, True),
        wbRArrayS(gameProperties, 'Parts', wbRStructSK(gameProperties, [0], 'Part', [
          wbInteger(gameProperties, INDX, 'Index', itU32, wbHeadPartIndexEnum),
          wbMODLReq,
          wbICON
        ], [], cpNormal, False, nil, False, nil, wbHeadPartsAfterSet), cpNormal, True)
      ], [], cpNormal, True),
      wbRStruct(gameProperties, 'Female Head Data', [
        wbEmpty(gameProperties, FNAM, 'Female Data Marker', cpNormal, True),
        wbRArrayS(gameProperties, 'Parts', wbRStructSK(gameProperties, [0], 'Part', [
          wbInteger(gameProperties, INDX, 'Index', itU32, wbHeadPartIndexEnum),
          wbMODLReq,
          wbICON
        ], [], cpNormal, False, nil, False, nil, wbHeadPartsAfterSet), cpNormal, True)
      ], [], cpNormal, True)
    ], [], cpNormal, True),
    wbRStruct(gameProperties, 'Body Data', [
      wbEmpty(gameProperties, NAM1, 'Body Data Marker', cpNormal, True),
      wbRStruct(gameProperties, 'Male Body Data', [
        wbEmpty(gameProperties, MNAM, 'Male Data Marker'),
        wbRArrayS(gameProperties, 'Parts', wbRStructSK(gameProperties, [0], 'Part', [
          wbInteger(gameProperties, INDX, 'Index', itU32, wbBodyPartIndexEnum),
          wbICON,
          wbMODLReq
        ], []), cpNormal, True)
      ], [], cpNormal, True),
      wbRStruct(gameProperties, 'Female Body Data', [
        wbEmpty(gameProperties, FNAM, 'Female Data Marker', cpNormal, True),
        wbRArrayS(gameProperties, 'Parts', wbRStructSK(gameProperties, [0], 'Part', [
          wbInteger(gameProperties, INDX, 'Index', itU32, wbBodyPartIndexEnum),
          wbICON,
          wbMODLReq
        ], []), cpNormal, True)
      ], [], cpNormal, True)
    ], [], cpNormal, True),
    wbArrayS(gameProperties, HNAM, 'Hairs', wbFormIDCk(gameProperties, 'Hair', [HAIR]), 0, cpNormal, True),
    wbArrayS(gameProperties, ENAM, 'Eyes', wbFormIDCk(gameProperties, 'Eye', [EYES]),  0,  cpNormal, True),
    wbRStruct(gameProperties, 'FaceGen Data', [
      wbRStruct(gameProperties, 'Male FaceGen Data', [
        wbEmpty(gameProperties, MNAM, 'Male Data Marker', cpNormal, True),
        wbFaceGen,
        wbInteger(gameProperties, SNAM, 'Unknown', itU16, nil, cpNormal, True)
      ], [], cpNormal, True),
      wbRStruct(gameProperties, 'Female FaceGen Data', [
        wbEmpty(gameProperties, FNAM, 'Female Data Marker', cpNormal, True),
        wbFaceGen,
        wbInteger(gameProperties, SNAM, 'Unknown', itU16, nil, cpNormal, True)	// will effectivly overwrite the SNAM from the male :)
      ], [], cpNormal, True)
    ], [], cpNormal, True)
  ]);

  wbRefRecord(
  gameProperties,
  REFR, 'Placed Object', [
    wbEDID,
    {
    wbStruct(gameProperties, RCLR, 'Linked Reference Color (Old Format?)', [
      wbStruct(gameProperties, 'Link Start Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Link End Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ])
    ], cpIgnore),}
    wbByteArray(gameProperties, RCLR, 'Unused', 0, cpIgnore),
    wbFormIDCk(gameProperties, NAME, 'Base', [TREE, SOUN, ACTI, DOOR, STAT, FURN, CONT, ARMO, AMMO, LVLN, LVLC,
                              MISC, WEAP, BOOK, KEYM, ALCH, LIGH, GRAS, ASPC, IDLM, ARMA, CHIP,
                              MSTT, NOTE, PWAT, SCOL, TACT, TERM, TXST, CCRD, IMOD, CMNY], False, cpNormal, True),
    wbFormIDCk(gameProperties, XEZN, 'Encounter Zone', [ECZN]),

    {--- ?? ---}
    wbXRGD,
    wbXRGB,

    {--- Primitive ---}
    wbStruct(gameProperties, XPRM, 'Primitive', [
      wbStruct(gameProperties, 'Bounds', [
        wbFloat(gameProperties, 'X', cpNormal, True, 2, 4),
        wbFloat(gameProperties, 'Y', cpNormal, True, 2, 4),
        wbFloat(gameProperties, 'Z', cpNormal, True, 2, 4)
      ]),
      wbStruct(gameProperties, 'Color', [
        {84} wbFloat(gameProperties, 'Red', cpNormal, False, 255, 0),
        {88} wbFloat(gameProperties, 'Green', cpNormal, False, 255, 0),
        {92} wbFloat(gameProperties, 'Blue', cpNormal, False, 255, 0)
      ]),
      wbFloat(gameProperties, 'Unknown'),
      wbInteger(gameProperties, 'Type', itU32, wbEnum(gameProperties, [
        'None',
        'Box',
        'Sphere',
        'Portal Box'
      ]))
    ]),
    wbInteger(gameProperties, XTRI, 'Collision Layer', itU32, wbEnum(gameProperties, [
      'Unidentified',
      'Static',
      'AnimStatic',
      'Transparent',
      'Clutter',
      'Weapon',
      'Projectile',
      'Spell',
      'Biped',
      'Trees',
      'Props',
      'Water',
      'Trigger',
      'Terrain',
      'Trap',
      'Non Collidable',
      'Cloud Trap',
      'Ground',
      'Portal',
      'Debris Small',
      'Debris Large',
      'Acustic Space',
      'Actor Zone',
      'Projectile Zone',
      'Gas Trap',
      'Shell Casing',
      'Transparent Small',
      'Invisible Wall',
      'Transparent Small Anim',
      'Dead Bip',
      'Char Controller',
      'Avoid Box',
      'Collision Box',
      'Camera Sphere',
      'Door Detection',
      'Camera Pick',
      'Item Pick',
      'Line Of Sight',
      'Path Pick',
      'Custom Pick 1',
      'Custom Pick 2',
      'Spell Explosion',
      'Dropping Pick'
    ])),
    wbEmpty(gameProperties, XMBP, 'MultiBound Primitive Marker'),

    {--- Bound Contents ---}

    {--- Bound Data ---}
    wbStruct(gameProperties, XMBO, 'Bound Half Extents', [
      wbFloat(gameProperties, 'X'),
      wbFloat(gameProperties, 'Y'),
      wbFloat(gameProperties, 'Z')
    ]),

    {--- Teleport ---}
    wbStruct(gameProperties, XTEL, 'Teleport Destination', [
      wbFormIDCk(gameProperties, 'Door', [REFR], True),
      wbPosRot,
      wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
        'No Alarm'
      ]))
    ]),

    {--- Map Data ---}
    wbRStruct(gameProperties, 'Map Marker', [
      wbEmpty(gameProperties, XMRK, 'Map Marker Data'),
      wbInteger(gameProperties, FNAM, 'Flags', itU8, wbFlags(gameProperties, [
        {0x01} 'Visible',
        {0x02} 'Can Travel To',
        {0x04} '"Show All" Hidden'
      ]), cpNormal, True),
      wbFULLReq,
      wbStruct(gameProperties, TNAM, '', [
        wbInteger(gameProperties, 'Type', itU8, wbEnum(gameProperties, [
          'None',
          'City',
          'Settlement',
          'Encampment',
          'Natural Landmark',
          'Cave',
          'Factory',
          'Monument',
          'Military',
          'Office',
          'Town Ruins',
          'Urban Ruins',
          'Sewer Ruins',
          'Metro',
          'Vault'
        ])),
        wbByteArray(gameProperties, 'Unused', 1)
      ], cpNormal, True),
      wbFormIDCk(gameProperties, WMI1, 'Reputation', [REPU])
    ], []),

    {--- Audio Data ---}
    wbRStruct(gameProperties, 'Audio Data', [
      wbEmpty(gameProperties, MMRK, 'Audio Marker'),
      wbUnknown(gameProperties, FULL),
      wbFormIDCk(gameProperties, CNAM, 'Audio Location', [ALOC]),
      wbInteger(gameProperties, BNAM, 'Flags', itU32, wbFlags(gameProperties, ['Use Controller Values'])),
      wbFloat(gameProperties, MNAM, 'Layer 2 Trigger %', cpNormal, True, 100),
      wbFloat(gameProperties, NNAM, 'Layer 3 Trigger %', cpNormal, True, 100)
    ], []),

    wbInteger(gameProperties, XSRF, 'Special Rendering Flags', itU32, wbFlags(gameProperties, [
      'Unknown 0',
      'Imposter',
      'Use Full Shader in LOD'
    ])),
    wbByteArray(gameProperties, XSRD, 'Special Rendering Data', 4),

    {--- X Target Data ---}
    wbFormIDCk(gameProperties, XTRG, 'Target', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA], True),

    {--- Leveled Actor ----}
    wbXLCM,

    {--- Patrol Data ---}
    wbRStruct(gameProperties, 'Patrol Data', [
      wbFloat(gameProperties, XPRD, 'Idle Time', cpNormal, True),
      wbEmpty(gameProperties, XPPA, 'Patrol Script Marker', cpNormal, True),
      wbFormIDCk(gameProperties, INAM, 'Idle', [IDLE, NULL], False, cpNormal, True),
      wbEmbeddedScriptReq,
      wbFormIDCk(gameProperties, TNAM, 'Topic', [DIAL, NULL], False, cpNormal, True)
    ], []),

    {--- Radio ---}
    wbStruct(gameProperties, XRDO, 'Radio Data', [
      wbFloat(gameProperties, 'Range Radius'),
      wbInteger(gameProperties, 'Broadcast Range Type', itU32, wbEnum(gameProperties, [
        'Radius',
        'Everywhere',
        'Worldspace and Linked Interiors',
        'Linked Interiors',
        'Current Cell Only'
      ])),
      wbFloat(gameProperties, 'Static Percentage'),
      wbFormIDCkNoReach(gameProperties, 'Position Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, NULL])
    ]),

    {--- Ownership ---}
    wbRStruct(gameProperties, 'Ownership', [
      wbXOWN,
      wbInteger(gameProperties, XRNK, 'Faction rank', itS32)
    ], [XCMT, XCMO]),

    {--- Lock ---}
    wbStruct(gameProperties, XLOC, 'Lock Data', [
      wbInteger(gameProperties, 'Level', itU8),
      wbByteArray(gameProperties, 'Unused', 3),
      wbFormIDCkNoReach(gameProperties, 'Key', [KEYM, NULL]),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, ['', '', 'Leveled Lock'])),
      wbByteArray(gameProperties, 'Unused', 3),
      wbByteArray(gameProperties, 'Unknown', 8)
    ], cpNormal, False, nil, 5),

    {--- Extra ---}
    wbInteger(gameProperties, XCNT, 'Count', itS32),
    wbFloat(gameProperties, XRDS, 'Radius'),
    wbFloat(gameProperties, XHLP, 'Health'),
    wbFloat(gameProperties, XRAD, 'Radiation'),
    wbFloat(gameProperties, XCHG, 'Charge'),
    wbRStruct(gameProperties, 'Ammo', [
      wbFormIDCk(gameProperties, XAMT, 'Type', [AMMO], False, cpNormal, True),
      wbInteger(gameProperties, XAMC, 'Count', itS32, nil, cpNormal, True)
    ], []),

    {--- Reflected By / Refracted By ---}
    wbRArrayS(gameProperties, 'Reflected/Refracted By',
      wbStructSK(gameProperties, XPWR, [0], 'Water', [
        wbFormIDCk(gameProperties, 'Reference', [REFR]),
        wbInteger(gameProperties, 'Type', itU32, wbFlags(gameProperties, [
          'Reflection',
          'Refraction'
        ]))
      ])
    ),

    {--- Lit Water ---}
    wbRArrayS(gameProperties, 'Lit Water',
      wbFormIDCk(gameProperties, XLTW, 'Water', [REFR])
    ),

    {--- Decals ---}
    wbRArrayS(gameProperties, 'Linked Decals',
      wbStructSK(gameProperties, XDCR, [0], 'Decal', [
        wbFormIDCk(gameProperties, 'Reference', [REFR]),
        wbUnknown(gameProperties)
      ])
    ),

    {--- Linked Ref ---}
    wbFormIDCk(gameProperties, XLKR, 'Linked Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, PLYR]),
    wbStruct(gameProperties, XCLP, 'Linked Reference Color', [
      wbStruct(gameProperties, 'Link Start Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ]),
      wbStruct(gameProperties, 'Link End Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8),
        wbByteArray(gameProperties, 'Unused', 1)
      ])
    ]),

    {--- Activate Parents ---}
    wbRStruct(gameProperties, 'Activate Parents', [
      wbInteger(gameProperties, XAPD, 'Flags', itU8, wbFlags(gameProperties, [
        'Parent Activate Only'
      ], True)),
      wbRArrayS(gameProperties, 'Activate Parent Refs',
        wbStructSK(gameProperties, XAPR, [0], 'Activate Parent Ref', [
          wbFormIDCk(gameProperties, 'Reference', [REFR, ACRE, ACHR, PGRE, PMIS, PBEA, PLYR]),
          wbFloat(gameProperties, 'Delay')
        ])
      )
    ], []),

    wbStringKC(gameProperties, XATO, 'Activation Prompt'),

    {--- Enable Parent ---}
    wbXESP,

    {--- Emittance ---}
    wbFormIDCk(gameProperties, XEMI, 'Emittance', [LIGH, REGN]),

    {--- MultiBound ---}
    wbFormIDCk(gameProperties, XMBR, 'MultiBound Reference', [REFR]),

    {--- Flags ---}
    wbInteger(gameProperties, XACT, 'Action Flag', itU32, wbFlags(gameProperties, [
      'Use Default',
      'Activate',
      'Open',
      'Open by Default'
    ])),
    wbEmpty(gameProperties, ONAM, 'Open by Default'),
    wbEmpty(gameProperties, XIBS, 'Ignored By Sandbox'),

    {--- Generated Data ---}
    wbStruct(gameProperties, XNDP, 'Navigation Door Link', [
      wbFormIDCk(gameProperties, 'Navigation Mesh', [NAVM]),
      wbInteger(gameProperties, 'Teleport Marker Triangle', itS16, wbREFRNavmeshTriangleToStr, wbStringToInt),
      wbByteArray(gameProperties, 'Unused', 2)
    ]),

    wbArray(gameProperties, XPOD, 'Portal Data', wbFormIDCk(gameProperties, 'Room', [REFR, NULL]), 2),
    wbStruct(gameProperties, XPTL, 'Portal Data', [
      wbStruct(gameProperties, 'Size', [
        wbFloat(gameProperties, 'Width', cpNormal, False, 2),
        wbFloat(gameProperties, 'Height', cpNormal, False, 2)
      ]),
      wbStruct(gameProperties, 'Position', [
        wbFloat(gameProperties, 'X'),
        wbFloat(gameProperties, 'Y'),
        wbFloat(gameProperties, 'Z')
      ]),
      wbStruct(gameProperties, 'Rotation (Quaternion?)', [
        wbFloat(gameProperties, 'q1'),
        wbFloat(gameProperties, 'q2'),
        wbFloat(gameProperties, 'q3'),
        wbFloat(gameProperties, 'q4')
      ])
    ]),

    wbInteger(gameProperties, XSED, 'SpeedTree Seed', itU8),

    wbRStruct(gameProperties, 'Room Data', [
      wbStruct(gameProperties, XRMR, 'Header', [
        wbInteger(gameProperties, 'Linked Rooms Count', itU16),
        wbByteArray(gameProperties, 'Unknown', 2)
      ]),
      wbRArrayS(gameProperties, 'Linked Rooms',
        wbFormIDCk(gameProperties, XLRM, 'Linked Room', [REFR])
      )
    ], []),

    wbStruct(gameProperties, XOCP, 'Occlusion Plane Data', [
      wbStruct(gameProperties, 'Size', [
        wbFloat(gameProperties, 'Width', cpNormal, False, 2),
        wbFloat(gameProperties, 'Height', cpNormal, False, 2)
      ]),
      wbStruct(gameProperties, 'Position', [
        wbFloat(gameProperties, 'X'),
        wbFloat(gameProperties, 'Y'),
        wbFloat(gameProperties, 'Z')
      ]),
      wbStruct(gameProperties, 'Rotation (Quaternion?)', [
        wbFloat(gameProperties, 'q1'),
        wbFloat(gameProperties, 'q2'),
        wbFloat(gameProperties, 'q3'),
        wbFloat(gameProperties, 'q4')
      ])
    ]),
    wbArray(gameProperties, XORD, 'Linked Occlusion Planes', wbFormIDCk(gameProperties, 'Plane', [REFR, NULL]), [
      'Right',
      'Left',
      'Bottom',
      'Top'
    ]),

    wbXLOD,

    {--- 3D Data ---}
    wbXSCL,
    wbDATAPosRot
  ], True, wbPlacedAddInfo, cpNormal, False, wbREFRAfterLoad);


  wbRecord(
  gameProperties,
  REGN, 'Region', [
    wbEDID,
    wbICON,
    wbStruct(gameProperties, RCLR, 'Map Color', [
      wbInteger(gameProperties, 'Red', itU8),
      wbInteger(gameProperties, 'Green', itU8),
      wbInteger(gameProperties, 'Blue', itU8),
      wbByteArray(gameProperties, 'Unused', 1)
    ], cpNormal, True),
    wbFormIDCkNoReach(gameProperties, WNAM, 'Worldspace', [WRLD]),

    wbRArray(gameProperties, 'Region Areas', wbRStruct(gameProperties, 'Region Area', [
      wbInteger(gameProperties, RPLI, 'Edge Fall-off', itU32),
      wbArray(gameProperties, RPLD, 'Region Point List Data', wbStruct(gameProperties, 'Point', [
        wbFloat(gameProperties, 'X'),
        wbFloat(gameProperties, 'Y')
      ]), 0, wbRPLDAfterLoad)
    ], [])),

    wbRArrayS(gameProperties, 'Region Data Entries', wbRStructSK(gameProperties, [0], 'Region Data Entry', [
      {always starts with an RDAT}
      wbStructSK(gameProperties, RDAT, [0], 'Data Header', [
        wbInteger(gameProperties, 'Type', itU32, wbEnum(gameProperties, [
          {0}'',
          {1}'',
          {2}'Objects',
          {3}'Weather',
          {4}'Map',
          {5}'Land',
          {6}'Grass',
          {7}'Sound',
          {8}'Imposter',
          {9}''
        ])),
        wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
          'Override'
        ])),
        wbInteger(gameProperties, 'Priority', itU8),
        wbByteArray(gameProperties, 'Unused')
      ], cpNormal, True),

      {followed by one of these: }

      {--- Objects ---}
      wbArray(gameProperties, RDOT, 'Objects', wbStruct(gameProperties, 'Object', [
        wbFormIDCk(gameProperties, 'Object', [TREE, STAT, LTEX]),
        wbInteger(gameProperties, 'Parent Index', itU16, wbHideFFFF),
        wbByteArray(gameProperties, 'Unused', 2),
        wbFloat(gameProperties, 'Density'),
        wbInteger(gameProperties, 'Clustering', itU8),
        wbInteger(gameProperties, 'Min Slope', itU8),
        wbInteger(gameProperties, 'Max Slope', itU8),
        wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
          {0}'Conform to slope',
          {1}'Paint Vertices',
          {2}'Size Variance +/-',
          {3}'X +/-',
          {4}'Y +/-',
          {5}'Z +/-',
          {6}'Tree',
          {7}'Huge Rock'
        ])),
        wbInteger(gameProperties, 'Radius wrt Parent', itU16),
        wbInteger(gameProperties, 'Radius', itU16),
        wbFloat(gameProperties, 'Min Height'),
        wbFloat(gameProperties, 'Max Height'),
        wbFloat(gameProperties, 'Sink'),
        wbFloat(gameProperties, 'Sink Variance'),
        wbFloat(gameProperties, 'Size Variance'),
        wbStruct(gameProperties, 'Angle Variance', [
          wbInteger(gameProperties, 'X', itU16),
          wbInteger(gameProperties, 'Y', itU16),
          wbInteger(gameProperties, 'Z', itU16)
        ]),
        wbByteArray(gameProperties, 'Unused', 2),
        wbByteArray(gameProperties, 'Unknown', 4)
      ]), 0, nil, nil, cpNormal, False, wbREGNObjectsDontShow),

      {--- Map ---}
      wbString(gameProperties, RDMP, 'Map Name', 0, cpTranslate, False, wbREGNMapDontShow),

      {--- Grass ---}
      wbArrayS(gameProperties, RDGS, 'Grasses', wbStructSK(gameProperties, [0], 'Grass', [
        wbFormIDCk(gameProperties, 'Grass', [GRAS]),
        wbByteArray(gameProperties, 'Unknown',4)
      ]), 0, cpNormal, False, nil, nil, wbREGNGrassDontShow),

      {--- Sound ---}
      wbInteger(gameProperties, RDMD, 'Music Type', itU32, wbMusicEnum, cpIgnore, False, False, wbNeverShow),
      wbFormIDCk(gameProperties, RDMO, 'Music', [MUSC], False, cpNormal, False, wbREGNSoundDontShow),
      wbFormIDCk(gameProperties, RDSI, 'Incidental MediaSet', [MSET], False, cpNormal, False, wbREGNSoundDontShow),
      wbRArray(gameProperties, 'Battle MediaSets', wbFormIDCk(gameProperties, RDSB, 'Battle MediaSet', [MSET]), cpNormal, False, nil, nil, wbREGNSoundDontShow),
      wbArrayS(gameProperties, RDSD, 'Sounds', wbStructSK(gameProperties, [0], 'Sound', [
        wbFormIDCk(gameProperties, 'Sound', [SOUN]),
        wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
          'Pleasant',
          'Cloudy',
          'Rainy',
          'Snowy'
        ])),
        wbInteger(gameProperties, 'Chance', itU32, wbScaledInt4ToStr, wbScaledInt4ToInt)
      ]), 0, cpNormal, False, nil, nil, wbREGNSoundDontShow),

      {--- Weather ---}
      wbArrayS(gameProperties, RDWT, 'Weather Types', wbStructSK(gameProperties, [0], 'Weather Type', [
        wbFormIDCk(gameProperties, 'Weather', [WTHR]),
        wbInteger(gameProperties, 'Chance', itU32),
        wbFormIDCk(gameProperties, 'Global', [GLOB, NULL])
      ]), 0, cpNormal, False, nil, nil, wbREGNWeatherDontShow),

      {--- Imposter ---}
      wbArrayS(gameProperties, RDID, 'Imposters', wbFormIDCk(gameProperties, 'Imposter', [REFR]), 0, cpNormal, False, nil, nil, wbREGNImposterDontShow)
    ], []))
  ], True);

  wbRecord(
  gameProperties,
  SOUN, 'Sound', [
    wbEDIDReq,
    wbOBNDReq,
    wbString(gameProperties, FNAM, 'Sound FileName'),
    wbInteger(gameProperties, RNAM, 'Random Chance %', itU8),
    wbRUnion(gameProperties, 'Sound Data', [
      wbStruct(gameProperties, SNDD, 'Sound Data', [
        wbInteger(gameProperties, 'Minimum Attentuation Distance', itU8, wbMul(gameProperties, 5)),
        wbInteger(gameProperties, 'Maximum Attentuation Distance', itU8, wbMul(gameProperties, 100)),
        wbInteger(gameProperties, 'Frequency Adjustment %', itS8),
        wbByteArray(gameProperties, 'Unused', 1),
        wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
          {0x0001} 'Random Frequency Shift',
          {0x0002} 'Play At Random',
          {0x0004} 'Environment Ignored',
          {0x0008} 'Random Location',
          {0x0010} 'Loop',
          {0x0020} 'Menu Sound',
          {0x0040} '2D',
          {0x0080} '360 LFE',
          {0x0100} 'Dialogue Sound',
          {0x0200} 'Envelope Fast',
          {0x0400} 'Envelope Slow',
          {0x0800} '2D Radius',
          {0x1000} 'Mute When Submerged',
          {0x2000} 'Start at Random Position'
        ])),
        wbInteger(gameProperties, 'Static attentuation cdB', itS16),
        wbInteger(gameProperties, 'Stop time ', itU8, wbAlocTime),
        wbInteger(gameProperties, 'Start time ', itU8, wbAlocTime),
        wbArray(gameProperties, 'Attenuation Curve', wbInteger(gameProperties, 'Point', itS16), 5),
        wbInteger(gameProperties, 'Reverb Attenuation Control', itS16),
        wbInteger(gameProperties, 'Priority', itS32),
        wbStruct(gameProperties, 'Loop Points', [
          wbInteger(gameProperties, 'Begin', itS32),
          wbInteger(gameProperties, 'End', itS32)
        ])

      ], cpNormal, True),
      wbStruct(gameProperties, SNDX, 'Sound Data', [
        wbInteger(gameProperties, 'Minimum attentuation distance', itU8, wbMul(gameProperties, 5)),
        wbInteger(gameProperties, 'Maximum attentuation distance', itU8, wbMul(gameProperties, 100)),
        wbInteger(gameProperties, 'Frequency adjustment %', itS8),
        wbByteArray(gameProperties, 'Unused', 1),
        wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
          {0x0001} 'Random Frequency Shift',
          {0x0002} 'Play At Random',
          {0x0004} 'Environment Ignored',
          {0x0008} 'Random Location',
          {0x0010} 'Loop',
          {0x0020} 'Menu Sound',
          {0x0040} '2D',
          {0x0080} '360 LFE',
          {0x0100} 'Dialogue Sound',
          {0x0200} 'Envelope Fast',
          {0x0400} 'Envelope Slow',
          {0x0800} '2D Radius',
          {0x1000} 'Mute When Submerged'
        ])),
        wbInteger(gameProperties, 'Static attentuation cdB', itS16),
        wbInteger(gameProperties, 'Stop time ', itU8),
        wbInteger(gameProperties, 'Start time ', itU8)
      ], cpNormal, True)
    ], [], cpNormal, True),
    wbArray(gameProperties, ANAM, 'Attenuation Curve', wbInteger(gameProperties, 'Point', itS16), 5, nil, nil, cpNormal, False, wbNeverShow),
    wbInteger(gameProperties, GNAM, 'Reverb Attenuation Control', itS16, nil, cpNormal, False, False, wbNeverShow),
    wbInteger(gameProperties, HNAM, 'Priority', itS32, nil, cpNormal, False, False, wbNeverShow)
  ], False, nil, cpNormal, False, wbSOUNAfterLoad);

  wbRecord(
  gameProperties,
  SPEL, 'Actor Effect', [
    wbEDIDReq,
    wbFULL,
    wbStruct(gameProperties, SPIT, '', [
      wbInteger(gameProperties, 'Type', itU32, wbEnum(gameProperties, [
        {0} 'Actor Effect',
        {1} 'Disease',
        {2} 'Power',
        {3} 'Lesser Power',
        {4} 'Ability',
        {5} 'Poison',
        {6} '',
        {7} '',
        {8} '',
        {9} '',
       {10} 'Addiction'
      ])),
      wbInteger(gameProperties, 'Cost (Unused)', itU32),
      wbInteger(gameProperties, 'Level (Unused)', itU32, wbEnum(gameProperties, [
        {0} 'Unused'
      ])),
      wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        {0x00000001} 'No Auto-Calc',
        {0x00000002} 'Immune to Silence 1?',
        {0x00000004} 'PC Start Effect',
        {0x00000008} 'Immune to Silence 2?',
        {0x00000010} 'Area Effect Ignores LOS',
        {0x00000020} 'Script Effect Always Applies',
        {0x00000040} 'Disable Absorb/Reflect',
        {0x00000080} 'Force Touch Explode'
      ])),
      wbByteArray(gameProperties, 'Unused', 3)
    ], cpNormal, True),
    wbEffectsReq
  ]);

  wbRecord(
  gameProperties,
  STAT, 'Static', [
    wbEDIDReq,
    wbOBNDReq,
    wbMODL,
    wbInteger(gameProperties, BRUS, 'Passthrough Sound', itS8, wbEnum(gameProperties, [
      'BushA',
      'BushB',
      'BushC',
      'BushD',
      'BushE',
      'BushF',
      'BushG',
      'BushH',
      'BushI',
      'BushJ'
    ], [
      -1, 'NONE'
    ])),
    wbFormIDCk(gameProperties, RNAM, 'Sound - Looping/Random', [SOUN])
  ]);

  wbRecord(
  gameProperties,
  TES4, 'Main File Header', [
    wbStruct(gameProperties, HEDR, 'Header', [
      wbFloat(gameProperties, 'Version'),
      wbInteger(gameProperties, 'Number of Records', itU32),
      wbInteger(gameProperties, 'Next Object ID', itU32, wbNextObjectIDToString, wbNextObjectIDToInt)
    ], cpNormal, True),
    wbByteArray(gameProperties, OFST, 'Unknown', 0, cpIgnore),
    wbByteArray(gameProperties, DELE, 'Unknown', 0, cpIgnore),
    wbString(gameProperties, CNAM, 'Author', 0, cpTranslate, True),
    wbString(gameProperties, SNAM, 'Description', 0, cpTranslate),
    wbRArray(gameProperties, 'Master Files', wbRStruct(gameProperties, 'Master File', [
      wbStringForward(gameProperties, MAST, 'FileName', 0, cpNormal, True),
      wbByteArray(gameProperties, DATA, 'Unused', 8, cpIgnore, True)
    ], [ONAM])).IncludeFlag(dfInternalEditOnly, not wbAllowMasterFilesEdit),
    wbArray(gameProperties, ONAM, 'Overriden Forms', wbFormIDCk(gameProperties, 'Form', [REFR, ACHR, ACRE, PMIS, PBEA, PGRE, LAND, NAVM]), 0, nil, nil, cpNormal, False, wbTES4ONAMDontShow),
    wbByteArray(gameProperties, SCRN, 'Screenshot')
  ], True, nil, cpNormal, True, wbRemoveOFST);

  wbRecord(
  gameProperties,
  PLYR, 'Player Reference', [
    wbEDID,
    wbFormID(gameProperties, PLYR, 'Player', cpNormal, True).SetDefaultNativeValue($7)
  ]).IncludeFlag(dfInternalEditOnly);

  wbRecord(
  gameProperties,
  TREE, 'Tree', [
    wbEDIDReq,
    wbOBNDReq,
    wbMODLReq,
    wbICONReq,
    wbDEST,
    wbArrayS(gameProperties, SNAM, 'SpeedTree Seeds', wbInteger(gameProperties, 'SpeedTree Seed', itU32), 0, cpNormal, True),
    wbStruct(gameProperties, CNAM, 'Tree Data', [
      wbFloat(gameProperties, 'Leaf Curvature'),
      wbFloat(gameProperties, 'Minimum Leaf Angle'),
      wbFloat(gameProperties, 'Maximum Leaf Angle'),
      wbFloat(gameProperties, 'Branch Dimming Value'),
      wbFloat(gameProperties, 'Leaf Dimming Value'),
      wbInteger(gameProperties, 'Shadow Radius', itS32),
      wbFloat(gameProperties, 'Rock Speed'),
      wbFloat(gameProperties, 'Rustle Speed')
    ], cpNormal, True),
    wbStruct(gameProperties, BNAM, 'Billboard Dimensions', [
      wbFloat(gameProperties, 'Width'),
      wbFloat(gameProperties, 'Height')
    ], cpNormal, True)
  ]);
end;

procedure DefineFNVf(var gameProperties: TGameProperties);
begin
  wbRecord(
  gameProperties,
  WATR, 'Water', [
    wbEDIDReq,
    wbFULL,
    wbString(gameProperties, NNAM, 'Noise Map', 0, cpNormal, True),
    wbInteger(gameProperties, ANAM, 'Opacity', itU8, nil, cpNormal, True),
    wbInteger(gameProperties, FNAM, 'Flags', itU8, wbFlags(gameProperties, [
      {0}'Causes Damage',
      {1}'Reflective'
    ]), cpNormal, True),
    wbString(gameProperties, MNAM, 'Material ID', 0, cpNormal, True),
    wbFormIDCk(gameProperties, SNAM, 'Sound', [SOUN]),
    wbFormIDCk(gameProperties, XNAM, 'Actor Effect', [SPEL]),
    wbInteger(gameProperties, DATA, 'Damage', itU16, nil, cpNormal, True, True),
    wbRUnion(gameProperties, 'Visual Data', [
      wbStruct(gameProperties, DNAM, 'Visual Data', [
        wbFloat(gameProperties, 'Unknown'),
        wbFloat(gameProperties, 'Unknown'),
        wbFloat(gameProperties, 'Unknown'),
        wbFloat(gameProperties, 'Unknown'),
        wbFloat(gameProperties, 'Water Properties - Sun Power'),
        wbFloat(gameProperties, 'Water Properties - Reflectivity Amount'),
        wbFloat(gameProperties, 'Water Properties - Fresnel Amount'),
        wbByteArray(gameProperties, 'Unused', 4),
        wbFloat(gameProperties, 'Fog Properties - Above Water - Fog Distance - Near Plane'),
        wbFloat(gameProperties, 'Fog Properties - Above Water - Fog Distance - Far Plane'),
        wbStruct(gameProperties, 'Shallow Color', [
          wbInteger(gameProperties, 'Red', itU8),
          wbInteger(gameProperties, 'Green', itU8),
          wbInteger(gameProperties, 'Blue', itU8),
          wbByteArray(gameProperties, 'Unused', 1)
        ]),
        wbStruct(gameProperties, 'Deep Color', [
          wbInteger(gameProperties, 'Red', itU8),
          wbInteger(gameProperties, 'Green', itU8),
          wbInteger(gameProperties, 'Blue', itU8),
          wbByteArray(gameProperties, 'Unused', 1)
        ]),
        wbStruct(gameProperties, 'Reflection Color', [
          wbInteger(gameProperties, 'Red', itU8),
          wbInteger(gameProperties, 'Green', itU8),
          wbInteger(gameProperties, 'Blue', itU8),
          wbByteArray(gameProperties, 'Unused', 1)
        ]),
        wbByteArray(gameProperties, 'Unused', 4),
        wbFloat(gameProperties, 'Rain Simulator - Force'),
        wbFloat(gameProperties, 'Rain Simulator - Velocity'),
        wbFloat(gameProperties, 'Rain Simulator - Falloff'),
        wbFloat(gameProperties, 'Rain Simulator - Dampner'),
        wbFloat(gameProperties, 'Displacement Simulator - Starting Size'),
        wbFloat(gameProperties, 'Displacement Simulator - Force'),
        wbFloat(gameProperties, 'Displacement Simulator - Velocity'),
        wbFloat(gameProperties, 'Displacement Simulator - Falloff'),
        wbFloat(gameProperties, 'Displacement Simulator - Dampner'),
        wbFloat(gameProperties, 'Rain Simulator - Starting Size'),
        wbFloat(gameProperties, 'Noise Properties - Normals - Noise Scale'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer One - Wind Direction'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Two - Wind Direction'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Three - Wind Direction'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer One - Wind Speed'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Two - Wind Speed'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Three - Wind Speed'),
        wbFloat(gameProperties, 'Noise Properties - Normals - Depth Falloff Start'),
        wbFloat(gameProperties, 'Noise Properties - Normals - Depth Falloff End'),
        wbFloat(gameProperties, 'Fog Properties - Above Water - Fog Amount'),
        wbFloat(gameProperties, 'Noise Properties - Normals - UV Scale'),
        wbFloat(gameProperties, 'Fog Properties - Under Water - Fog Amount'),
        wbFloat(gameProperties, 'Fog Properties - Under Water - Fog Distance - Near Plane'),
        wbFloat(gameProperties, 'Fog Properties - Under Water - Fog Distance - Far Plane'),
        wbFloat(gameProperties, 'Water Properties - Distortion Amount'),
        wbFloat(gameProperties, 'Water Properties - Shininess'),
        wbFloat(gameProperties, 'Water Properties - Reflection HDR Multiplier'),
        wbFloat(gameProperties, 'Water Properties - Light Radius'),
        wbFloat(gameProperties, 'Water Properties - Light Brightness'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer One - UV Scale'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Two - UV Scale'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Three - UV Scale'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer One - Amplitude Scale'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Two - Amplitude Scale'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Three - Amplitude Scale')
      ], cpNormal, True, nil, 46),
      wbStruct(gameProperties, DATA, 'Visual Data', [
        wbFloat(gameProperties, 'Unknown'),
        wbFloat(gameProperties, 'Unknown'),
        wbFloat(gameProperties, 'Unknown'),
        wbFloat(gameProperties, 'Unknown'),
        wbFloat(gameProperties, 'Water Properties - Sun Power'),
        wbFloat(gameProperties, 'Water Properties - Reflectivity Amount'),
        wbFloat(gameProperties, 'Water Properties - Fresnel Amount'),
        wbByteArray(gameProperties, 'Unused', 4),
        wbFloat(gameProperties, 'Fog Properties - Above Water - Fog Distance - Near Plane'),
        wbFloat(gameProperties, 'Fog Properties - Above Water - Fog Distance - Far Plane'),
        wbStruct(gameProperties, 'Shallow Color', [
          wbInteger(gameProperties, 'Red', itU8),
          wbInteger(gameProperties, 'Green', itU8),
          wbInteger(gameProperties, 'Blue', itU8),
          wbByteArray(gameProperties, 'Unused', 1)
        ]),
        wbStruct(gameProperties, 'Deep Color', [
          wbInteger(gameProperties, 'Red', itU8),
          wbInteger(gameProperties, 'Green', itU8),
          wbInteger(gameProperties, 'Blue', itU8),
          wbByteArray(gameProperties, 'Unused', 1)
        ]),
        wbStruct(gameProperties, 'Reflection Color', [
          wbInteger(gameProperties, 'Red', itU8),
          wbInteger(gameProperties, 'Green', itU8),
          wbInteger(gameProperties, 'Blue', itU8),
          wbByteArray(gameProperties, 'Unused', 1)
        ]),
        wbByteArray(gameProperties, 'Unused', 4),
        wbFloat(gameProperties, 'Rain Simulator - Force'),
        wbFloat(gameProperties, 'Rain Simulator - Velocity'),
        wbFloat(gameProperties, 'Rain Simulator - Falloff'),
        wbFloat(gameProperties, 'Rain Simulator - Dampner'),
        wbFloat(gameProperties, 'Displacement Simulator - Starting Size'),
        wbFloat(gameProperties, 'Displacement Simulator - Force'),
        wbFloat(gameProperties, 'Displacement Simulator - Velocity'),
        wbFloat(gameProperties, 'Displacement Simulator - Falloff'),
        wbFloat(gameProperties, 'Displacement Simulator - Dampner'),
        wbFloat(gameProperties, 'Rain Simulator - Starting Size'),
        wbFloat(gameProperties, 'Noise Properties - Normals - Noise Scale'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer One - Wind Direction'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Two - Wind Direction'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Three - Wind Direction'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer One - Wind Speed'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Two - Wind Speed'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Three - Wind Speed'),
        wbFloat(gameProperties, 'Noise Properties - Normals - Depth Falloff Start'),
        wbFloat(gameProperties, 'Noise Properties - Normals - Depth Falloff End'),
        wbFloat(gameProperties, 'Fog Properties - Above Water - Fog Amount'),
        wbFloat(gameProperties, 'Noise Properties - Normals - UV Scale'),
        wbFloat(gameProperties, 'Fog Properties - Under Water - Fog Amount'),
        wbFloat(gameProperties, 'Fog Properties - Under Water - Fog Distance - Near Plane'),
        wbFloat(gameProperties, 'Fog Properties - Under Water - Fog Distance - Far Plane'),
        wbFloat(gameProperties, 'Water Properties - Distortion Amount'),
        wbFloat(gameProperties, 'Water Properties - Shininess'),
        wbFloat(gameProperties, 'Water Properties - Reflection HDR Multiplier'),
        wbFloat(gameProperties, 'Water Properties - Light Radius'),
        wbFloat(gameProperties, 'Water Properties - Light Brightness'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer One - UV Scale'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Two - UV Scale'),
        wbFloat(gameProperties, 'Noise Properties - Noise Layer Three - UV Scale'),
        wbEmpty(gameProperties, 'Noise Properties - Noise Layer One - Amplitude Scale'),
        wbEmpty(gameProperties, 'Noise Properties - Noise Layer Two - Amplitude Scale'),
        wbEmpty(gameProperties, 'Noise Properties - Noise Layer Three - Amplitude Scale'),
        wbInteger(gameProperties, 'Damage (Old Format)', itU16)
      ], cpNormal, True)
    ], [], cpNormal, True),
    wbStruct(gameProperties, GNAM, 'Related Waters (Unused)', [
      wbFormIDCk(gameProperties, 'Daytime', [WATR, NULL]),
      wbFormIDCk(gameProperties, 'Nighttime', [WATR, NULL]),
      wbFormIDCk(gameProperties, 'Underwater', [WATR, NULL])
    ], cpNormal, True)
  ], False, nil, cpNormal, False, wbWATRAfterLoad);

  wbRecord(
  gameProperties,
  WEAP, 'Weapon', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbICON,
    wbSCRI,
    wbEITM,
    wbInteger(gameProperties, EAMT, 'Enchantment Charge Amount', itS16),
    wbFormIDCkNoReach(gameProperties, NAM0, 'Ammo', [AMMO, FLST]),
    wbDEST,
    wbREPL,
    wbETYPReq,
    wbBIPL,
    wbYNAM,
    wbZNAM,
    wbRStruct(gameProperties, 'Shell Casing Model', [
      wbString(gameProperties, MOD2, 'Model FileName'),
      wbByteArray(gameProperties, MO2T, 'Texture Files Hashes', 0, cpIgnore),
      wbMO2S
    ], []),
    wbRStruct(gameProperties, 'Scope Model', [
      wbString(gameProperties, MOD3, 'Model FileName'),
      wbByteArray(gameProperties, MO3T, 'Texture Files Hashes', 0, cpIgnore),
      wbMO3S
    ], []),
    wbFormIDCk(gameProperties, EFSD, 'Scope Effect', [EFSH]),
    wbRStruct(gameProperties, 'World Model', [
      wbString(gameProperties, MOD4, 'Model FileName'),
      wbByteArray(gameProperties, MO4T, 'Texture Files Hashes', 0, cpIgnore),
      wbMO4S
    ], []),
    wbString(gameProperties, MWD1, 'Model - Mod 1'),
    wbString(gameProperties, MWD2, 'Model - Mod 2'),
    wbString(gameProperties, MWD3, 'Model - Mod 1 and 2'),
    wbString(gameProperties, MWD4, 'Model - Mod 3'),
    wbString(gameProperties, MWD5, 'Model - Mod 1 and 3'),
    wbString(gameProperties, MWD6, 'Model - Mod 2 and 3'),
    wbString(gameProperties, MWD7, 'Model - Mod 1, 2 and 3'),
    {wbRStruct(gameProperties,  'Model with Mods', [
      wbString(gameProperties, MWD1, 'Mod 1'),
      wbString(gameProperties, MWD2, 'Mod 2'),
      wbString(gameProperties, MWD3, 'Mod 1 and 2'),
      wbString(gameProperties, MWD4, 'Mod 3'),
      wbString(gameProperties, MWD5, 'Mod 1 and 3'),
      wbString(gameProperties, MWD6, 'Mod 2 and 3'),
      wbString(gameProperties, MWD7, 'Mod 1, 2 and 3')
    ], [], cpNormal, False, nil, True),}

    wbString(gameProperties, VANM, 'VATS Attack Name', 0, cpTranslate),
    wbString(gameProperties, NNAM, 'Embedded Weapon Node'),

    wbFormIDCk(gameProperties, INAM, 'Impact DataSet', [IPDS]),
    wbFormIDCk(gameProperties, WNAM, '1st Person Model', [STAT]),
    wbFormIDCk(gameProperties, WNM1, '1st Person Model - Mod 1', [STAT]),
    wbFormIDCk(gameProperties, WNM2, '1st Person Model - Mod 2', [STAT]),
    wbFormIDCk(gameProperties, WNM3, '1st Person Model - Mod 1 and 2', [STAT]),
    wbFormIDCk(gameProperties, WNM4, '1st Person Model - Mod 3', [STAT]),
    wbFormIDCk(gameProperties, WNM5, '1st Person Model - Mod 1 and 3', [STAT]),
    wbFormIDCk(gameProperties, WNM6, '1st Person Model - Mod 2 and 3', [STAT]),
    wbFormIDCk(gameProperties, WNM7, '1st Person Model - Mod 1, 2 and 3', [STAT]),
    {wbRStruct(gameProperties, '1st Person Models with Mods', [
      wbFormIDCk(gameProperties, WNM1, 'Mod 1', [STAT]),
      wbFormIDCk(gameProperties, WNM2, 'Mod 2', [STAT]),
      wbFormIDCk(gameProperties, WNM3, 'Mod 1 and 2', [STAT]),
      wbFormIDCk(gameProperties, WNM4, 'Mod 3', [STAT]),
      wbFormIDCk(gameProperties, WNM5, 'Mod 1 and 3', [STAT]),
      wbFormIDCk(gameProperties, WNM6, 'Mod 2 and 3', [STAT]),
      wbFormIDCk(gameProperties, WNM7, 'Mod 1, 2 and 3', [STAT])
    ], [], cpNormal, False, nil, True),}
    wbFormIDCk(gameProperties, WMI1, 'Weapon Mod 1', [IMOD]),
    wbFormIDCk(gameProperties, WMI2, 'Weapon Mod 2', [IMOD]),
    wbFormIDCk(gameProperties, WMI3, 'Weapon Mod 3', [IMOD]),
    {wbRStruct(gameProperties, 'Weapon Mods', [
      wbFormIDCk(gameProperties, WMI1, 'Mod 1', [IMOD]),
      wbFormIDCk(gameProperties, WMI2, 'Mod 2', [IMOD]),
      wbFormIDCk(gameProperties, WMI3, 'Mod 3', [IMOD])
    ], [], cpNormal, False, nil, True),}
    wbRStruct(gameProperties, 'Sound - Gun', [
      wbFormIDCk(gameProperties, SNAM, 'Shoot 3D', [SOUN]),
      wbFormIDCk(gameProperties, SNAM, 'Shoot Dist', [SOUN])
    ], []),
    //wbFormIDCk(gameProperties, SNAM, 'Sound - Gun - Shoot 3D', [SOUN]),
    //wbFormIDCk(gameProperties, SNAM, 'Sound - Gun - Shoot Dist', [SOUN]),
    wbFormIDCk(gameProperties, XNAM, 'Sound - Gun - Shoot 2D', [SOUN]),
    wbFormIDCk(gameProperties, NAM7, 'Sound - Gun - Shoot 3D Looping', [SOUN]),
    wbFormIDCk(gameProperties, TNAM, 'Sound - Melee - Swing / Gun - No Ammo', [SOUN]),
    wbFormIDCk(gameProperties, NAM6, 'Sound - Block', [SOUN]),
    wbFormIDCk(gameProperties, UNAM, 'Sound - Idle', [SOUN]),
    wbFormIDCk(gameProperties, NAM9, 'Sound - Equip', [SOUN]),
    wbFormIDCk(gameProperties, NAM8, 'Sound - Unequip', [SOUN]),
    wbRStruct(gameProperties, 'Sound - Mod 1', [
      wbFormIDCk(gameProperties, WMS1, 'Shoot 3D', [SOUN]),
      wbFormIDCk(gameProperties, WMS1, 'Shoot Dist', [SOUN])
    ], []),
    //wbFormIDCk(gameProperties, WMS1, 'Sound - Mod 1 - Shoot 3D', [SOUN]),
    //wbFormIDCk(gameProperties, WMS1, 'Sound - Mod 1 - Shoot Dist', [SOUN]),
    wbFormIDCk(gameProperties, WMS2, 'Sound - Mod 1 - Shoot 2D', [SOUN]),
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Value', itS32),
      wbInteger(gameProperties, 'Health', itS32),
      wbFloat(gameProperties, 'Weight'),
      wbInteger(gameProperties, 'Base Damage', itS16),
      wbInteger(gameProperties, 'Clip Size', itU8)
    ], cpNormal, True),
    wbStruct(gameProperties, DNAM, '', [
      {00} wbInteger(gameProperties, 'Animation Type', itU32, wbWeaponAnimTypeEnum),
      {04} wbFloat(gameProperties, 'Animation Multiplier'),
      {08} wbFloat(gameProperties, 'Reach'),
      {12} wbInteger(gameProperties, 'Flags 1', itU8, wbFlags(gameProperties, [
        'Ignores Normal Weapon Resistance',
        'Is Automatic',
        'Has Scope',
        'Can''t Drop',
        'Hide Backpack',
        'Embedded Weapon',
        'Don''t Use 1st Person IS Animations',
        'Non-Playable'
      ])),
      {13} wbInteger(gameProperties, 'Grip Animation', itU8, wbEnum(gameProperties, [
      ], [
        230, 'HandGrip1',
        231, 'HandGrip2',
        232, 'HandGrip3',
        233, 'HandGrip4',
        234, 'HandGrip5',
        235, 'HandGrip6',
        255, 'DEFAULT'
      ])),
      {14} wbInteger(gameProperties, 'Ammo Use', itU8),
      {15} wbInteger(gameProperties, 'Reload Animation', itU8, wbReloadAnimEnum),
      {16} wbFloat(gameProperties, 'Min Spread'),
      {20} wbFloat(gameProperties, 'Spread'),
      {24} wbFloat(gameProperties, 'Unknown'),
      {28} wbFloat(gameProperties, 'Sight FOV'),
      {32} wbFloat(gameProperties),
      {36} wbFormIDCk(gameProperties, 'Projectile', [PROJ, NULL]),
      {40} wbInteger(gameProperties, 'Base VATS To-Hit Chance', itU8),
      {41} wbInteger(gameProperties, 'Attack Animation', itU8, wbEnum(gameProperties, [
           ], [
             26, 'AttackLeft',
             32, 'AttackRight',
             38, 'Attack3',
             44, 'Attack4',
             50, 'Attack5',
             56, 'Attack6',
             62, 'Attack7',
             68, 'Attack8',
            144, 'Attack9',
             74, 'AttackLoop',
             80, 'AttackSpin',
             86, 'AttackSpin2',
            114, 'AttackThrow',
            120, 'AttackThrow2',
            126, 'AttackThrow3',
            132, 'AttackThrow4',
            138, 'AttackThrow5',
            150, 'AttackThrow6',
            156, 'AttackThrow7',
            162, 'AttackThrow8',
            102, 'PlaceMine',
            108, 'PlaceMine2',
            255, 'DEFAULT'
           ])),
      {42} wbInteger(gameProperties, 'Projectile Count', itU8),
      {43} wbInteger(gameProperties, 'Embedded Weapon - Actor Value', itU8, wbEnum(gameProperties, [
        {00} 'Perception',
        {01} 'Endurance',
        {02} 'Left Attack',
        {03} 'Right Attack',
        {04} 'Left Mobility',
        {05} 'Right Mobilty',
        {06} 'Brain'
      ])),
      {44} wbFloat(gameProperties, 'Min Range'),
      {48} wbFloat(gameProperties, 'Max Range'),
      {52} wbInteger(gameProperties, 'On Hit', itU32, wbEnum(gameProperties, [
        'Normal formula behavior',
        'Dismember Only',
        'Explode Only',
        'No Dismember/Explode'
      ])),
      {56} wbInteger(gameProperties, 'Flags 2', itU32, wbFlags(gameProperties, [
        {0x00000001}'Player Only',
        {0x00000002}'NPCs Use Ammo',
        {0x00000004}'No Jam After Reload',
        {0x00000008}'Override - Action Points',
        {0x00000010}'Minor Crime',
        {0x00000020}'Range - Fixed',
        {0x00000040}'Not Used In Normal Combat',
        {0x00000080}'Override - Damage to Weapon Mult',
        {0x00000100}'Don''t Use 3rd Person IS Animations',
        {0x00000200}'Short Burst',
        {0x00000400}'Rumble Alternate',
        {0x00000800}'Long Burst',
        {0x00001000}'Scope has NightVision',
        {0x00002000}'Scope from Mod'
      ])),
      {60} wbFloat(gameProperties, 'Animation Attack Multiplier'),
      {64} wbFloat(gameProperties, 'Fire Rate'),
      {68} wbFloat(gameProperties, 'Override - Action Points'),
      {72} wbFloat(gameProperties, 'Rumble - Left Motor Strength'),
      {76} wbFloat(gameProperties, 'Rumble - Right Motor Strength'),
      {80} wbFloat(gameProperties, 'Rumble - Duration'),
      {84} wbFloat(gameProperties, 'Override - Damage to Weapon Mult'),
      {88} wbFloat(gameProperties, 'Attack Shots/Sec'),
      {92} wbFloat(gameProperties, 'Reload Time'),
      {96} wbFloat(gameProperties, 'Jam Time'),
     {100} wbFloat(gameProperties, 'Aim Arc'),
     {104} wbInteger(gameProperties, 'Skill', itS32, wbActorValueEnum),
     {108} wbInteger(gameProperties, 'Rumble - Pattern', itU32, wbEnum(gameProperties, [
       'Constant',
       'Square',
       'Triangle',
       'Sawtooth'
     ])),
     {112} wbFloat(gameProperties, 'Rumble - Wavelength'),
     {116} wbFloat(gameProperties, 'Limb Dmg Mult'),
     {120} wbInteger(gameProperties, 'Resist Type', itS32, wbActorValueEnum),
     {124} wbFloat(gameProperties, 'Sight Usage'),
     {128} wbFloat(gameProperties, 'Semi-Automatic Fire Delay Min'),
     {132} wbFloat(gameProperties, 'Semi-Automatic Fire Delay Max'),
     wbFloat(gameProperties),
     wbInteger(gameProperties, 'Effect - Mod 1', itU32, wbModEffectEnum),
     wbInteger(gameProperties, 'Effect - Mod 2', itU32, wbModEffectEnum),
     wbInteger(gameProperties, 'Effect - Mod 3', itU32, wbModEffectEnum),
     wbFloat(gameProperties, 'Value A - Mod 1'),
     wbFloat(gameProperties, 'Value A - Mod 2'),
     wbFloat(gameProperties, 'Value A - Mod 3'),
     wbInteger(gameProperties, 'Power Attack Animation Override', itU32, wbEnum(gameProperties, [
     ], [
        0, '0?',
       97, 'AttackCustom1Power',
       98, 'AttackCustom2Power',
       99, 'AttackCustom3Power',
      100, 'AttackCustom4Power',
      101, 'AttackCustom5Power',
      255, 'DEFAULT'
     ])),
     wbInteger(gameProperties, 'Strength Req', itU32),
     wbByteArray(gameProperties, 'Unknown', 1),
     wbInteger(gameProperties, 'Reload Animation - Mod', itU8, wbReloadAnimEnum),
     wbByteArray(gameProperties, 'Unknown', 2),
     wbFloat(gameProperties, 'Regen Rate'),
     wbFloat(gameProperties, 'Kill Impulse'),
     wbFloat(gameProperties, 'Value B - Mod 1'),
     wbFloat(gameProperties, 'Value B - Mod 2'),
     wbFloat(gameProperties, 'Value B - Mod 3'),
     wbFloat(gameProperties, 'Impulse Dist'),
     wbInteger(gameProperties, 'Skill Req', itU32)
    ], cpNormal, True, nil, 36),

   wbStruct(gameProperties, CRDT, 'Critical Data', [
      {00} wbInteger(gameProperties, 'Critical Damage', itU16),
      {09} wbByteArray(gameProperties, 'Unused', 2),
      {04} wbFloat(gameProperties, 'Crit % Mult'),
      {08} wbInteger(gameProperties, 'Flags', itU8, wbFlags(gameProperties, [
        'On Death'
      ])),
      {09} wbByteArray(gameProperties, 'Unused', 3),
      {12} wbFormIDCk(gameProperties, 'Effect', [SPEL, NULL])
    ], cpNormal, True),
    wbStruct(gameProperties, VATS, 'VATS', [
     wbFormIDCk(gameProperties, 'Effect',[SPEL, NULL]),
     wbFloat(gameProperties, 'Skill'),
     wbFloat(gameProperties, 'Dam. Mult'),
     wbFloat(gameProperties, 'AP'),
     wbInteger(gameProperties, 'Silent', itU8, wbEnum(gameProperties, ['No', 'Yes'])),
     wbInteger(gameProperties, 'Mod Required', itU8, wbEnum(gameProperties, ['No', 'Yes'])),
     wbByteArray(gameProperties, 'Unused', 2)
    ]),
    wbInteger(gameProperties, VNAM, 'Sound Level', itU32, wbSoundLevelEnum, cpNormal, True)
  ], True, nil, cpNormal, False, wbWEAPAfterLoad);

  if wbSimpleRecords then
    wbRecord(
    gameProperties,
    WRLD, 'Worldspace', [
      wbEDIDReq,
      wbFULL,
      wbFormIDCk(gameProperties, XEZN, 'Encounter Zone', [ECZN]),
      wbRStruct(gameProperties, 'Parent', [
        wbFormIDCk(gameProperties, WNAM, 'Worldspace', [WRLD]),
        wbInteger(gameProperties, PNAM, 'Flags', itU16, wbFlags(gameProperties, [
          {0x00000001}'Use Land Data',
          {0x00000002}'Use LOD Data',
          {0x00000004}'Use Map Data',
          {0x00000008}'Use Water Data',
          {0x00000010}'Use Climate Data',
          {0x00000020}'Use Image Space Data'
          ], True), cpNormal, True)
      ], []),
      wbFormIDCk(gameProperties, CNAM, 'Climate', [CLMT]),
      wbFormIDCk(gameProperties, NAM2, 'Water', [WATR]),
      wbFormIDCk(gameProperties, NAM3, 'LOD Water Type', [WATR]),
      wbFloat(gameProperties, NAM4, 'LOD Water Height'),
      wbStruct(gameProperties, DNAM, 'Land Data', [
        wbFloat(gameProperties, 'Default Land Height'),
        wbFloat(gameProperties, 'Default Water Height')
      ]),
      wbICON,
      wbStruct(gameProperties, MNAM, 'Map Data', [
        wbStruct(gameProperties, 'Usable Dimensions', [
          wbInteger(gameProperties, 'X', itS32),
          wbInteger(gameProperties, 'Y', itS32)
        ]),
        wbStruct(gameProperties, 'Cell Coordinates', [
          wbStruct(gameProperties, 'NW Cell', [
            wbInteger(gameProperties, 'X', itS16),
            wbInteger(gameProperties, 'Y', itS16)
          ]),
          wbStruct(gameProperties, 'SE Cell', [
            wbInteger(gameProperties, 'X', itS16),
            wbInteger(gameProperties, 'Y', itS16)
          ])
        ])
      ]),
      wbStruct(gameProperties, ONAM, 'World Map Offset Data', [
        wbFloat(gameProperties, 'World Map Scale'),
        wbFloat(gameProperties, 'Cell X Offset'),
        wbFloat(gameProperties, 'Cell Y Offset')
      ], cpNormal, True),
      wbFormIDCk(gameProperties, INAM, 'Image Space', [IMGS]),
      wbInteger(gameProperties, DATA, 'Flags', itU8, wbFlags(gameProperties, [  // LoadForm supports a DWord here, but only first byte would be used.
        {0x01} 'Small World',
        {0x02} 'Can''t Fast Travel',
        {0x04} '',
        {0x08} '',
        {0x10} 'No LOD Water',
        {0x20} 'No LOD Noise',
        {0x40} 'Don''t Allow NPC Fall Damage',
        {0x80} 'Needs Water Adjustment'
      ]), cpNormal, True),
      wbRStruct(gameProperties, 'Object Bounds', [
        wbStruct(gameProperties, NAM0, 'Min', [
          wbFloat(gameProperties, 'X', cpNormal, False, 1/4096),
          wbFloat(gameProperties, 'Y', cpNormal, False, 1/4096)
        ], cpIgnore, True),
        wbStruct(gameProperties, NAM9, 'Max', [
          wbFloat(gameProperties, 'X', cpNormal, False, 1/4096),
          wbFloat(gameProperties, 'Y', cpNormal, False, 1/4096)
        ], cpIgnore, True)
      ], []),
      wbFormIDCk(gameProperties, ZNAM, 'Music', [MUSC]),
      wbString(gameProperties, NNAM, 'Canopy Shadow', 0, cpNormal, True),
      wbString(gameProperties, XNAM, 'Water Noise Texture', 0, cpNormal, True),
      wbRArrayS(gameProperties, 'Swapped Impacts', wbStructExSK(gameProperties, IMPS, [0, 1], [2], 'Swapped Impact', [
        wbInteger(gameProperties, 'Material Type', itU32, wbImpactMaterialTypeEnum),
        wbFormIDCkNoReach(gameProperties, 'Old', [IPCT]),
        wbFormIDCk(gameProperties, 'New', [IPCT, NULL])
      ])),
      wbArray(gameProperties, IMPF, 'Footstep Materials', wbString(gameProperties, 'Unknown', 30), [
        'ConcSolid',
        'ConcBroken',
        'MetalSolid',
        'MetalHollow',
        'MetalSheet',
        'Wood',
        'Sand',
        'Dirt',
        'Grass',
        'Water'
      ]),
      wbByteArray(gameProperties, OFST, 'Offset Data')
    ], False, nil, cpNormal, False, wbRemoveOFST)
  else
    wbRecord(
    gameProperties,
    WRLD, 'Worldspace', [
      wbEDIDReq,
      wbFULL,
      wbFormIDCk(gameProperties, XEZN, 'Encounter Zone', [ECZN]),
      wbRStruct(gameProperties, 'Parent', [
        wbFormIDCk(gameProperties, WNAM, 'Worldspace', [WRLD]),
        wbInteger(gameProperties, PNAM, 'Flags', itU16, wbFlags(gameProperties, [
          {0x00000001}'Use Land Data',
          {0x00000002}'Use LOD Data',
          {0x00000004}'Use Map Data',
          {0x00000008}'Use Water Data',
          {0x00000010}'Use Climate Data',
          {0x00000020}'Use Image Space Data'  // in order to use this "Image Space" needs to be NULL.
                                              //  Other parent flags are checked before the form value.
          ], True), cpNormal, True)
      ], []),
      wbFormIDCk(gameProperties, CNAM, 'Climate', [CLMT]),
      wbFormIDCk(gameProperties, NAM2, 'Water', [WATR]),
      wbFormIDCk(gameProperties, NAM3, 'LOD Water Type', [WATR]),
      wbFloat(gameProperties, NAM4, 'LOD Water Height'),
      wbStruct(gameProperties, DNAM, 'Land Data', [
        wbFloat(gameProperties, 'Default Land Height'),
        wbFloat(gameProperties, 'Default Water Height')
      ]),
      wbICON,
      wbStruct(gameProperties, MNAM, 'Map Data', [
        wbStruct(gameProperties, 'Usable Dimensions', [
          wbInteger(gameProperties, 'X', itS32),
          wbInteger(gameProperties, 'Y', itS32)
        ]),
        wbStruct(gameProperties, 'Cell Coordinates', [
          wbStruct(gameProperties, 'NW Cell', [
            wbInteger(gameProperties, 'X', itS16),
            wbInteger(gameProperties, 'Y', itS16)
          ]),
          wbStruct(gameProperties, 'SE Cell', [
            wbInteger(gameProperties, 'X', itS16),
            wbInteger(gameProperties, 'Y', itS16)
          ])
        ])
      ]),
      wbStruct(gameProperties, ONAM, 'World Map Offset Data', [
        wbFloat(gameProperties, 'World Map Scale'),
        wbFloat(gameProperties, 'Cell X Offset'),
        wbFloat(gameProperties, 'Cell Y Offset')
      ], cpNormal, True),
      wbFormIDCk(gameProperties, INAM, 'Image Space', [IMGS]),
      wbInteger(gameProperties, DATA, 'Flags', itU8, wbFlags(gameProperties, [  // LoadForm supports a DWord here, but only first byte would be used.
        {0x01} 'Small World',
        {0x02} 'Can''t Fast Travel',
        {0x04} '',
        {0x08} '',
        {0x10} 'No LOD Water',
        {0x20} 'No LOD Noise',
        {0x40} 'Don''t Allow NPC Fall Damage',
        {0x80} 'Needs Water Adjustment'
      ]), cpNormal, True),
      wbRStruct(gameProperties, 'Object Bounds', [
        wbStruct(gameProperties, NAM0, 'Min', [
          wbFloat(gameProperties, 'X', cpNormal, False, 1/4096),
          wbFloat(gameProperties, 'Y', cpNormal, False, 1/4096)
        ], cpIgnore, True),
        wbStruct(gameProperties, NAM9, 'Max', [
          wbFloat(gameProperties, 'X', cpNormal, False, 1/4096),
          wbFloat(gameProperties, 'Y', cpNormal, False, 1/4096)
        ], cpIgnore, True)
      ], []),
      wbFormIDCk(gameProperties, ZNAM, 'Music', [MUSC]),
      wbString(gameProperties, NNAM, 'Canopy Shadow', 0, cpNormal, True),
      wbString(gameProperties, XNAM, 'Water Noise Texture', 0, cpNormal, True),
      wbRArrayS(gameProperties, 'Swapped Impacts', wbStructExSK(gameProperties, IMPS, [0, 1], [2], 'Swapped Impact', [
        wbInteger(gameProperties, 'Material Type', itU32, wbImpactMaterialTypeEnum),
        wbFormIDCkNoReach(gameProperties, 'Old', [IPCT]),
        wbFormIDCk(gameProperties, 'New', [IPCT, NULL])
      ])),
      wbArray(gameProperties, IMPF, 'Footstep Materials', wbString(gameProperties, 'Unknown', 30), [
        'ConcSolid',
        'ConcBroken',
        'MetalSolid',
        'MetalHollow',
        'MetalSheet',
        'Wood',
        'Sand',
        'Dirt',
        'Grass',
        'Water'
      ]),
      wbArray(gameProperties, OFST, 'Offset Data', wbArray(gameProperties, 'Rows', wbInteger(gameProperties, 'Offset', itU32), wbOffsetDataColsCounter), 0) // cannot be saved by GECK
    ], False, nil, cpNormal, False, wbRemoveOFST);

  wbRecord(
  gameProperties,
  WTHR, 'Weather', [
    wbEDIDReq,
    wbFormIDCk(gameProperties, _0_IAD, 'Sunrise Image Space Modifier', [IMAD]),
    wbFormIDCk(gameProperties, _1_IAD, 'Day Image Space Modifier', [IMAD]),
    wbFormIDCk(gameProperties, _2_IAD, 'Sunset Image Space Modifier', [IMAD]),
    wbFormIDCk(gameProperties, _3_IAD, 'Night Image Space Modifier', [IMAD]),
    wbFormIDCk(gameProperties, _4_IAD, 'High Noon Image Space Modifier', [IMAD]),
    wbFormIDCk(gameProperties, _5_IAD, 'Midnight Image Space Modifier', [IMAD]),
    wbString(gameProperties, DNAM, 'Cloud Textures - Layer 0', 0, cpNormal, True),
    wbString(gameProperties, CNAM, 'Cloud Textures - Layer 1', 0, cpNormal, True),
    wbString(gameProperties, ANAM, 'Cloud Textures - Layer 2', 0, cpNormal, True),
    wbString(gameProperties, BNAM, 'Cloud Textures - Layer 3', 0, cpNormal, True),
    wbMODL,
    wbByteArray(gameProperties, LNAM, 'Unknown', 4, cpNormal, True),
    wbArray(gameProperties, ONAM, 'Cloud Speed', wbInteger(gameProperties, 'Layer', itU8{, wbDiv(2550)}), 4, nil, nil, cpNormal, True),
    wbArray(gameProperties, PNAM, 'Cloud Layer Colors',
      wbArray(gameProperties, 'Layer',
        wbStruct(gameProperties, 'Color', [
          wbInteger(gameProperties, 'Red', itU8),
          wbInteger(gameProperties, 'Green', itU8),
          wbInteger(gameProperties, 'Blue', itU8),
          wbByteArray(gameProperties, 'Unused', 1)
        ]),
        ['Sunrise', 'Day', 'Sunset', 'Night', 'High Noon', 'Midnight']
      ),
    4),
    wbArray(gameProperties, NAM0, 'Colors by Types/Times',
      wbArray(gameProperties, 'Type',
        wbStruct(gameProperties, 'Time', [
          wbInteger(gameProperties, 'Red', itU8),
          wbInteger(gameProperties, 'Green', itU8),
          wbInteger(gameProperties, 'Blue', itU8),
          wbByteArray(gameProperties, 'Unused', 1)
        ]),
        ['Sunrise', 'Day', 'Sunset', 'Night', 'High Noon', 'Midnight']
      ),
      ['Sky-Upper','Fog','Unused','Ambient','Sunlight','Sun','Stars','Sky-Lower','Horizon','Unused']
    , cpNormal, True),
    wbStruct(gameProperties, FNAM, 'Fog Distance', [
      wbFloat(gameProperties, 'Day - Near'),
      wbFloat(gameProperties, 'Day - Far'),
      wbFloat(gameProperties, 'Night - Near'),
      wbFloat(gameProperties, 'Night - Far'),
      wbFloat(gameProperties, 'Day - Power'),
      wbFloat(gameProperties, 'Night - Fower')
    ], cpNormal, True),
    wbByteArray(gameProperties, INAM, 'Unused', 304, cpIgnore, True),
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Wind Speed', itU8),
      wbInteger(gameProperties, 'Cloud Speed (Lower)', itU8),
      wbInteger(gameProperties, 'Cloud Speed (Upper)', itU8),
      wbInteger(gameProperties, 'Trans Delta', itU8),
      wbInteger(gameProperties, 'Sun Glare', itU8),
      wbInteger(gameProperties, 'Sun Damage', itU8),
      wbInteger(gameProperties, 'Precipitation - Begin Fade In', itU8),
      wbInteger(gameProperties, 'Precipitation - End Fade Out', itU8),
      wbInteger(gameProperties, 'Thunder/Lightning - Begin Fade In', itU8),
      wbInteger(gameProperties, 'Thunder/Lightning - End Fade Out', itU8),
      wbInteger(gameProperties, 'Thunder/Lightning - Frequency', itU8),
      wbInteger(gameProperties, 'Weather Classification', itU8, wbWthrDataClassification),
      wbStruct(gameProperties, 'Lightning Color', [
        wbInteger(gameProperties, 'Red', itU8),
        wbInteger(gameProperties, 'Green', itU8),
        wbInteger(gameProperties, 'Blue', itU8)
      ])
    ], cpNormal, True),
    wbRArray(gameProperties, 'Sounds', wbStruct(gameProperties, SNAM, 'Sound', [
      wbFormIDCk(gameProperties, 'Sound', [SOUN]),
      wbInteger(gameProperties, 'Type', itU32, wbEnum(gameProperties, [
       {0}'Default',
       {1}'Precip',
       {2}'Wind',
       {3}'Thunder'
      ]))
    ]))
  ]);

  wbRecord(
  gameProperties,
  IMOD, 'Item Mod', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbICON,
    wbSCRI,
    wbDESC,
    wbDEST,
    wbYNAM,
    wbZNAM,
    wbStruct(gameProperties, DATA, 'Data', [
      wbInteger(gameProperties, 'Value', itU32),
      wbFloat(gameProperties, 'Weight')
    ])
  ]);

  wbRecord(
  gameProperties,
  ALOC, 'Media Location Controller', [
    wbEDIDReq,
    wbFULL,
    wbByteArray(gameProperties, NAM1, 'Flags and Enums, messily combined'),
    wbUnknown(gameProperties, NAM2),
    wbUnknown(gameProperties, NAM3),
    wbFloat(gameProperties, NAM4, 'Location Delay'),
    wbInteger(gameProperties, NAM5, 'Day Start', itU32, wbAlocTime),
    wbInteger(gameProperties, NAM6, 'Night Start', itU32, wbAlocTime),
    wbFloat(gameProperties, NAM7, 'Retrigger Delay'),
    wbRArrayS(gameProperties, 'Neutral Sets',
      wbFormIDCk(gameProperties, HNAM, 'Media Set', [MSET])
    ),
    wbRArrayS(gameProperties, 'Ally Sets',
      wbFormIDCk(gameProperties, ZNAM, 'Media Set', [MSET])
    ),
    wbRArrayS(gameProperties, 'Friend Sets',
      wbFormIDCk(gameProperties, XNAM, 'Media Set', [MSET])
    ),
    wbRArrayS(gameProperties, 'Enemy Sets',
      wbFormIDCk(gameProperties, YNAM, 'Media Set', [MSET])
    ),
    wbRArrayS(gameProperties, 'Location Sets',
      wbFormIDCk(gameProperties, LNAM, 'Media Set', [MSET])
    ),
    wbRArrayS(gameProperties, 'Battle Sets',
      wbFormIDCk(gameProperties, GNAM, 'Media Set', [MSET])
    ),
    wbFormIDCk(gameProperties, RNAM, 'Conditional Faction', [FACT]),
    wbUnknown(gameProperties, FNAM)
  ]);

  wbRecord(
  gameProperties,
  MSET, 'Media Set', [
    wbEDIDReq,
    wbFULL,
    wbInteger(gameProperties, NAM1, 'Type', itU32, wbEnum(gameProperties, [
      'Battle Set',
      'Location Set',
      'Dungeon Set',
      'Incidental Set'
    ], [
      -1, 'No Set'
    ])),
    wbString(gameProperties, NAM2, 'Loop (B) / Battle (D) / Day Outer (L)'),
    wbString(gameProperties, NAM3, 'Explore (D) / Day Middle (L)'),
    wbString(gameProperties, NAM4, 'Suspense (D) / Day Inner (L)'),
    wbString(gameProperties, NAM5, 'Night Outer (L)'),
    wbString(gameProperties, NAM6, 'Night Middle (L)'),
    wbString(gameProperties, NAM7, 'Night Inner (L)'),
    wbFloat(gameProperties, NAM8, 'Loop dB (B) / Battle dB (D) / Day Outer dB (L)'),
    wbFloat(gameProperties, NAM9, 'Explore dB (D) / Day Middle dB (L)'),
    wbFloat(gameProperties, NAM0, 'Suspense dB (D) / Day Inner dB (L)'),
    wbFloat(gameProperties, ANAM, 'Night Outer dB (L)'),
    wbFloat(gameProperties, BNAM, 'Night Middle dB (L)'),
    wbFloat(gameProperties, CNAM, 'Night Inner dB (L)'),
    wbFloat(gameProperties, JNAM, 'Day Outer Boundary % (L)'),
    wbFloat(gameProperties, KNAM, 'Day Middle Boundary % (L)'),
    wbFloat(gameProperties, LNAM, 'Day Inner Boundary % (L)'),
    wbFloat(gameProperties, MNAM, 'Night Outer Boundary % (L)'),
    wbFloat(gameProperties, NNAM, 'Night Middle Boundary % (L)'),
    wbFloat(gameProperties, ONAM, 'Night Inner Boundary % (L)'),
    wbInteger(gameProperties, PNAM, 'Enable Flags', itU8, wbFlags(gameProperties, [
      {0x01} 'Day Outer',
      {0x02} 'Day Middle',
      {0x04} 'Day Inner',
      {0x08} 'Night Outer',
      {0x10} 'Night Middle',
      {0x20} 'Night Inner'
    ])),
    wbFloat(gameProperties, DNAM, 'Wait Time (B) / Minimum Time On (D,L) / Daytime Min (I)'),
    wbFloat(gameProperties, ENAM, 'Loop Fade Out (B) / Looping/Random Crossfade Overlap (D,L) / Nighttime Min (I)'),
    wbFloat(gameProperties, FNAM, 'Recovery Time (B) / Layer Crossfade Time (D,L) / Daytime Max (I)'),
    wbFloat(gameProperties, GNAM, 'Nighttime Max (I)'),
    wbFormIDCk(gameProperties, HNAM, 'Intro (B,D) / Daytime (I)', [SOUN]),
    wbFormIDCk(gameProperties, INAM, 'Outro (B,D) / Nighttime (I)', [SOUN]),
    wbUnknown(gameProperties, DATA)
  ]);

  wbRecord(
  gameProperties,
  AMEF, 'Ammo Effect', [
    wbEDIDReq,
    wbFULL,
    wbStruct(gameProperties, DATA, 'Data', [
      wbInteger(gameProperties, 'Type', itU32, wbEnum(gameProperties, [
        'Damage Mod',
        'DR Mod',
        'DT Mod',
        'Spread Mod',
        'Weapon Condition Mod',
        'Fatigue Mod'
      ])),
      wbInteger(gameProperties, 'Operation', itU32, wbEnum(gameProperties, [
        'Add',
        'Multiply',
        'Subtract'
      ])),
      wbFloat(gameProperties, 'Value')
    ])
  ]);

  wbRecord(
  gameProperties,
  CCRD, 'Caravan Card', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbICON,
    wbSCRI,
    wbYNAM,
    wbZNAM,
    wbRStruct(gameProperties, 'High Res Image', [
      wbString(gameProperties, TX00, 'Face'),
      wbString(gameProperties, TX01, 'Back')
    ], []),
    wbRStruct(gameProperties, 'Card', [
      wbInteger(gameProperties, INTV, 'Suit', itU32, wbEnum(gameProperties, [
        '',
        'Hearts',
        'Spades',
        'Diamonds',
        'Clubs',
        'Joker'
      ])),
      wbInteger(gameProperties, INTV, 'Value', itU32, wbEnum(gameProperties, [
        '',
        'Ace',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '10',
        '',
        'Jack',
        'Queen',
        'King',
        'Joker'
      ]))
    ], []),
    wbInteger(gameProperties, DATA, 'Value', itU32)
  ]);

  wbRecord(
  gameProperties,
  CDCK, 'Caravan Deck', [
    wbEDIDReq,
    wbFULL,
    wbRArrayS(gameProperties, 'Cards',
      wbFormIDCk(gameProperties, CARD, 'Card', [CCRD])
    ),
    wbInteger(gameProperties, DATA, 'Count (broken)', itU32)
  ]);

  wbRecord(
  gameProperties,
  CHAL, 'Challenge', [
    wbEDIDReq,
    wbFULL,
    wbICON,
    wbSCRI,
    wbDESC,
    wbStruct(gameProperties, DATA, 'Data', [
      wbInteger(gameProperties, 'Type', itU32, wbEnum(gameProperties, [
        {00} 'Kill from a Form List',
        {01} 'Kill a specific FormID',
        {02} 'Kill any in a category',
        {03} 'Hit an Enemy',
        {04} 'Discover a Map Marker',
        {05} 'Use an Item',
        {06} 'Acquire an Item',
        {07} 'Use a Skill',
        {08} 'Do Damage',
        {09} 'Use an Item from a List',
        {10} 'Acquire an Item from a List',
        {11} 'Miscellaneous Stat',
        {12} 'Craft Using an Item',
        {13} 'Scripted Challenge'
      ])),
      wbInteger(gameProperties, 'Threshold', itU32),
      wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
        'Start Disabled',
        'Recurring',
        'Show Zero Progress'
      ])),
      wbInteger(gameProperties, 'Interval', itU32),
      wbByteArray(gameProperties, '(depends on type)', 2),
      wbByteArray(gameProperties, '(depends on type)', 2),
      wbByteArray(gameProperties, '(depends on type)', 4)
    ]),
    wbFormID(gameProperties, SNAM, '(depends on type)'),
    wbFormID(gameProperties, XNAM, '(depends on type)')
  ]);

  wbRecord(
  gameProperties,
  CHIP, 'Casino Chip', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbICON,
    wbDEST,
    wbYNAM,
    wbZNAM
  ]);

  wbRecord(
  gameProperties,
  CMNY, 'Caravan Money', [
    wbEDIDReq,
    wbOBNDReq,
    wbFULL,
    wbMODL,
    wbICON,
    wbYNAM,
    wbZNAM,
    wbInteger(gameProperties, DATA, 'Absolute Value', itU32)
  ]);

  wbRecord(
  gameProperties,
  CSNO, 'Casino', [
    wbEDIDReq,
    wbFULL,
    wbStruct(gameProperties, DATA, 'Data', [
      wbFloat(gameProperties, 'Decks % Before Shuffle'),
      wbFloat(gameProperties, 'BlackJack Payout Ratio'),
      wbArray(gameProperties, 'Slot Reel Stops', wbInteger(gameProperties, 'Reel', itU32),[
        'Symbol 1',
        'Symbol 2',
        'Symbol 3',
        'Symbol 4',
        'Symbol 5',
        'Symbol 6',
        'Symbol W'
      ]),
      wbInteger(gameProperties, 'Number of Decks', itU32),
      wbInteger(gameProperties, 'Max Winnings', itU32),
      wbFormIDCk(gameProperties, 'Currency', [CHIP]),
      wbFormIDCk(gameProperties, 'Casino Winnings Quest', [QUST]),
      wbInteger(gameProperties, 'Flags', itU32, wbFlags(gameProperties, [
        'Dealer Stay on Soft 17'
      ]))
    ]),
    wbRStruct(gameProperties, 'Casino Chip Models', [
      wbString(gameProperties, MODL, '$1 Chip'),
      wbString(gameProperties, MODL, '$5 Chip'),
      wbString(gameProperties, MODL, '$10 Chip'),
      wbString(gameProperties, MODL, '$25 Chip'),
      wbString(gameProperties, MODL, '$100 Chip'),
      wbString(gameProperties, MODL, '$500 Chip'),
      wbString(gameProperties, MODL, 'Roulette Chip')
    ], []),
    wbString(gameProperties, MODL, 'Slot Machine Model'),
    wbString(gameProperties, MOD2, 'Slot Machine Model (again?)'),
    wbString(gameProperties, MOD3, 'BlackJack Table Model'),
    wbString(gameProperties, MODT, 'BlackJack Table Model related'),
    wbString(gameProperties, MOD4, 'Roulette Table Model'),
    wbRStruct(gameProperties, 'Slot Reel Textures', [
      wbString(gameProperties, ICON, 'Symbol 1'),
      wbString(gameProperties, ICON, 'Symbol 2'),
      wbString(gameProperties, ICON, 'Symbol 3'),
      wbString(gameProperties, ICON, 'Symbol 4'),
      wbString(gameProperties, ICON, 'Symbol 5'),
      wbString(gameProperties, ICON, 'Symbol 6'),
      wbString(gameProperties, ICON, 'Symbol W')
    ], []),
      wbRStruct(gameProperties, 'BlackJack Decks', [
      wbString(gameProperties, ICO2, 'Deck 1'),
      wbString(gameProperties, ICO2, 'Deck 2'),
      wbString(gameProperties, ICO2, 'Deck 3'),
      wbString(gameProperties, ICO2, 'Deck 4')
    ], [])
  ]);

  wbRecord(
  gameProperties,
  DEHY, 'Dehydration Stage', [
    wbEDIDReq,
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Trigger Threshold', itU32),
      wbFormIDCk(gameProperties, 'Actor Effect', [SPEL])
    ], cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  HUNG, 'Hunger Stage', [
    wbEDIDReq,
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Trigger Threshold', itU32),
      wbFormIDCk(gameProperties, 'Actor Effect', [SPEL])
    ], cpNormal, True)
  ]);

  wbRecord(
  gameProperties,
  LSCT, 'Load Screen Type', [
    wbEDIDReq,
    wbStruct(gameProperties, DATA, 'Data', [
      wbInteger(gameProperties, 'Type', itU32, wbEnum(gameProperties, [
        'None',
        'XP Progress',
        'Objective',
        'Tip',
        'Stats'
      ])),
      wbStruct(gameProperties, 'Data 1', [
        wbInteger(gameProperties, 'X', itU32),
        wbInteger(gameProperties, 'Y', itU32),
        wbInteger(gameProperties, 'Width', itU32),
        wbInteger(gameProperties, 'Height', itU32),
        wbFloat(gameProperties, 'Orientation', cpNormal, True, wbRotationFactor, wbRotationScale, nil, RadiansNormalize),
        wbInteger(gameProperties, 'Font', itU32, wbEnum(gameProperties, [
          '',
          '2',
          '3',
          '4',
          '5',
          '6',
          '7',
          '8'
        ])),
        wbStruct(gameProperties, 'Font Color', [
          wbFloat(gameProperties, 'R'),
          wbFloat(gameProperties, 'G'),
          wbFloat(gameProperties, 'B')
        ]),
        wbInteger(gameProperties, 'Font', itU32, wbEnum(gameProperties, [
          '',
          'Left',
          'Center',
          '',
          'Right'
        ]))
      ]),
      wbByteArray(gameProperties, 'Unknown', 20),
      wbStruct(gameProperties, 'Data 2', [
        wbInteger(gameProperties, 'Font', itU32, wbEnum(gameProperties, [
          '',
          '2',
          '3',
          '4',
          '5',
          '6',
          '7',
          '8'
        ])),
        wbStruct(gameProperties, 'Font Color', [
          wbFloat(gameProperties, 'R'),
          wbFloat(gameProperties, 'G'),
          wbFloat(gameProperties, 'B')
        ]),
        wbByteArray(gameProperties, '', 4),
        wbInteger(gameProperties, 'Stats', itU32, wbEnum(gameProperties, [
          '',
          '2',
          '3',
          '4',
          '5',
          '6',
          '7',
          '8'
        ]))
      ])
    ])
  ]);

  wbRecord(
  gameProperties,
  RCCT, 'Recipe Category', [
    wbEDIDReq,
    wbFULL,
    wbInteger(gameProperties, DATA, 'Flags', itU8, wbFlags(gameProperties, [
      'Subcategory?',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ]))
  ]);

  wbRecord(
  gameProperties,
  RCPE, 'Recipe', [
    wbEDIDReq,
    wbFULL,
    wbCTDAs,
    wbStruct(gameProperties, DATA, 'Data', [
      wbInteger(gameProperties, 'Skill', itS32, wbActorValueEnum),
      wbInteger(gameProperties, 'Level', itU32),
      wbFormIDCk(gameProperties, 'Category', [RCCT, NULL]),   // Some of DeadMoney are NULL
      wbFormIDCk(gameProperties, 'Sub-Category', [RCCT])
    ]),
    wbRStructs(gameProperties, 'Ingredients', 'Ingredient', [
      wbFormIDCk(gameProperties, RCIL, 'Item', [ARMO, AMMO, MISC, WEAP, BOOK, KEYM, ALCH, NOTE, IMOD, CMNY, CCRD, CHIP, LIGH], False, cpNormal, True),
      wbInteger(gameProperties, RCQY, 'Quantity', itU32, nil, cpNormal, True)
    ], []),
    wbRStructs(gameProperties, 'Outputs', 'Output', [
      wbFormIDCk(gameProperties, RCOD, 'Item', [ARMO, AMMO, MISC, WEAP, BOOK, KEYM, ALCH, NOTE, IMOD, CMNY, CCRD, CHIP, LIGH], False, cpNormal, True),
      wbInteger(gameProperties, RCQY, 'Quantity', itU32, nil, cpNormal, True)
    ], [])
  ]);

  wbRecord(
  gameProperties,
  REPU, 'Reputation', [
    wbEDIDReq,
    wbFULL,
    wbICON,
    wbFloat(gameProperties, DATA, 'Value')
  ]);

  wbRecord(
  gameProperties,
  SLPD, 'Sleep Deprivation Stage', [
    wbEDIDReq,
    wbStruct(gameProperties, DATA, '', [
      wbInteger(gameProperties, 'Trigger Threshold', itU32),
      wbFormIDCk(gameProperties, 'Actor Effect', [SPEL])
    ], cpNormal, True)
  ]);

  wbAddGroupOrder(GMST);
  wbAddGroupOrder(TXST);
  wbAddGroupOrder(MICN);
  wbAddGroupOrder(GLOB);
  wbAddGroupOrder(CLAS);
  wbAddGroupOrder(FACT);
  wbAddGroupOrder(HDPT);
  wbAddGroupOrder(HAIR);
  wbAddGroupOrder(EYES);
  wbAddGroupOrder(RACE);
  wbAddGroupOrder(SOUN);
  wbAddGroupOrder(ASPC);
  wbAddGroupOrder(MGEF);
  wbAddGroupOrder(SCPT);
  wbAddGroupOrder(LTEX);
  wbAddGroupOrder(ENCH);
  wbAddGroupOrder(SPEL);
  wbAddGroupOrder(ACTI);
  wbAddGroupOrder(TACT);
  wbAddGroupOrder(TERM);
  wbAddGroupOrder(ARMO);
  wbAddGroupOrder(BOOK);
  wbAddGroupOrder(CONT);
  wbAddGroupOrder(DOOR);
  wbAddGroupOrder(INGR);
  wbAddGroupOrder(LIGH);
  wbAddGroupOrder(MISC);
  wbAddGroupOrder(STAT);
  wbAddGroupOrder(SCOL);
  wbAddGroupOrder(MSTT);
  wbAddGroupOrder(PWAT);
  wbAddGroupOrder(GRAS);
  wbAddGroupOrder(TREE);
  wbAddGroupOrder(FURN);
  wbAddGroupOrder(WEAP);
  wbAddGroupOrder(AMMO);
  wbAddGroupOrder(NPC_);
  wbAddGroupOrder(PLYR);
  wbAddGroupOrder(CREA);
  wbAddGroupOrder(LVLC);
  wbAddGroupOrder(LVLN);
  wbAddGroupOrder(KEYM);
  wbAddGroupOrder(ALCH);
  wbAddGroupOrder(IDLM);
  wbAddGroupOrder(NOTE);
  wbAddGroupOrder(COBJ);
  wbAddGroupOrder(PROJ);
  wbAddGroupOrder(LVLI);
  wbAddGroupOrder(WTHR);
  wbAddGroupOrder(CLMT);
  wbAddGroupOrder(REGN);
  wbAddGroupOrder(NAVI);
  wbAddGroupOrder(DIAL);
  wbAddGroupOrder(QUST);
  wbAddGroupOrder(IDLE);
  wbAddGroupOrder(PACK);
  wbAddGroupOrder(CSTY);
  wbAddGroupOrder(LSCR);
  wbAddGroupOrder(ANIO);
  wbAddGroupOrder(WATR);
  wbAddGroupOrder(EFSH);
  wbAddGroupOrder(EXPL);
  wbAddGroupOrder(DEBR);
  wbAddGroupOrder(IMGS);
  wbAddGroupOrder(IMAD);
  wbAddGroupOrder(FLST);
  wbAddGroupOrder(PERK);
  wbAddGroupOrder(BPTD);
  wbAddGroupOrder(ADDN);
  wbAddGroupOrder(AVIF);
  wbAddGroupOrder(RADS);
  wbAddGroupOrder(CAMS);
  wbAddGroupOrder(CPTH);
  wbAddGroupOrder(VTYP);
  wbAddGroupOrder(IPCT);
  wbAddGroupOrder(IPDS);
  wbAddGroupOrder(ARMA);
  wbAddGroupOrder(ECZN);
  wbAddGroupOrder(MESG);
  wbAddGroupOrder(RGDL);
  wbAddGroupOrder(DOBJ);
  wbAddGroupOrder(LGTM);
  wbAddGroupOrder(MUSC);
  wbAddGroupOrder(IMOD);
  wbAddGroupOrder(REPU);
  wbAddGroupOrder(RCPE);
  wbAddGroupOrder(RCCT);
  wbAddGroupOrder(CHIP);
  wbAddGroupOrder(CSNO);
  wbAddGroupOrder(LSCT);
  wbAddGroupOrder(MSET);
  wbAddGroupOrder(ALOC);
  wbAddGroupOrder(CHAL);
  wbAddGroupOrder(AMEF);
  wbAddGroupOrder(CCRD);
  wbAddGroupOrder(CMNY);
  wbAddGroupOrder(CDCK);
  wbAddGroupOrder(DEHY);
  wbAddGroupOrder(HUNG);
  wbAddGroupOrder(SLPD);
  // Forced at the end.
  wbAddGroupOrder(CELL);
  wbAddGroupOrder(WRLD);
end;

procedure DefineFNV(var gameProperties: TGameProperties);
begin
  wbNexusModsUrl := 'https://www.nexusmods.com/newvegas/mods/34703';
  if wbToolMode = tmLODgen then
    wbNexusModsUrl := 'https://www.nexusmods.com/newvegas/mods/58562';
  DefineFNVa(gameProperties);
  DefineFNVb(gameProperties);
  DefineFNVc(gameProperties);
  DefineFNVd(gameProperties);
  DefineFNVe(gameProperties);
  DefineFNVf(gameProperties);
end;

end.
