// ignore_for_file: constant_identifier_names

class IconIds {
  static const String train = 'train';
  static const String car = 'car';
  static const String bus = 'bus';
  static const String bike = 'bike';
  static const String footprints = 'footprints';
}

final List<Map<String, dynamic>> rawRoutesData = [
  {
    "name": "Cycle: St Chads View to Leeds Station",
    "polyline": "srogInltHrAF@{ANcAPe@Vi@`@[b@E`@DXVPZJXNr@H|@DhA?JfADxAFhAJrC`@C}BAmC?{EJsJ?]AOHSlAhBVZh@x@xA~A`A~@TNPc@P[VWRo@z@cCjAiDdEsL`@eAf@]pAs@lCwAXMt@Wn@IxA?TDt@V`Ad@f@TbARf@Dd@?bAMZIv@c@z@e@rA_AbAm@`Ac@d@Un@SvAa@n@OfAMd@Eh@CfB?xCBd@Bh@?`A@rB@LA@CHIRKZ@B?RDj@TfA^t@^jAb@jAh@`Az@n@j@`Av@d@`@DLZVlBjB^l@LVDf@Cb@AN?fDDAb@BDoADuABkABiBDaCH_ANcA`AyD|@eDnBeHb@{Ab@oAdAkClB_FzAgDv@iAbCkCfCgDp@kAt@cAl@{@d@kAtAoEd@oBJSTe@Vw@?g@n@iCvBsK^_BXw@Rg@Ra@Xe@bAiAj@q@Vo@`@aA`@{AD_@Fq@Bq@C{AGk@c@{B]mBGk@Cm@BoCVeL?yBEoAAs@IWKI[CGKIqAKBEkAEw@UiC?A",
    "color": "#00FF00"
  },
  {
    "name": "Drive (Uber): St Chads View to Leeds Station",
    "polyline": "srogInltH_ACDdAFr@Lp@Nv@|@pCt@jA\\Xb@Tb@Lb@@fAArACh@AFiDVoHdBNbBRt@L^IbC_@pBc@bAi@xBoAj@a@_AkCMSe@iA[u@OSOOPc@P[VWRo@z@cCbDmJlBoF`@eAf@]pAs@lCwAXMt@Wn@IxA?TDt@V`Ad@f@TbARf@Dd@?bAMZIv@c@z@e@rA_AbAm@`Ac@d@Un@SvAa@n@OfAMd@Eh@CfB?xCBd@Bh@?`A@rB@LA@CHIRKZ@B?RDj@TfA^t@^jAb@j@TFY`@iA`FuM|@_ClAeE\\mAb@sApAyCz@_Cr@aChA}Et@mCj@mBj@_B|AaEr@wBr@eC\\qB\\{BZeDDq@Ju@HYJQrCuBHIf@i@Za@L_@Le@FwAZuHLwAFs@DKBq@FaAJgBFoAZMHE`Aq@~AiAT[V_@FM[gB{@aFMs@A[@i@ViFBiBQs@G}@Wa@Ke@Ok@",
    "color": "#0000FF"
  },
  {
    "name": "Bus (Line 24): St Chads View to Leeds Station",
    "polyline": "srogIdltH{@CI@wCULmBF[f@kDDk@@o@?q@Eu@OiAb@WDZj@[jC}A`CwArAqAbBkBxCaDdCaCtCwCbCqBb@[TYZg@FSXaAVy@L]^_AZg@TWZQf@Ub@]^c@T_@d@sAVaALcALiBz@oI`A_Gb@uE|@sHb@iCxAsHxBsJ|@eCBYb@w@lAcB`@m@`AuAxHwKtCgEbBgCM[Aa@p@M`@KVET[Zc@JSPi@z@yDt@sC`@kAv@cBRWT}@Hg@Pe@`@uA^wAjBsDzBwEt@uA`AwB\\m@b@k@PQ\\Q`@S`@Op@MfAI|BE|@Id@M^S\\WVU\\m@^m@NQn@m@b@[hAm@jB}@NG?D?ENIRKXMfBw@l@Eb@Nb@@`ARr@Ll@HCVGl@Ad@EhACvEfDE|@B^F@QX@RLf@ALE\\?hB?XZJTBN@LELCDHHNHf@x@z@vANTNC?D",
    "color": "#30227d"
  },
  {
    "name": "Train (Northern): St Chads View to Leeds Station via Headingley",
    "polyline": "srogItltHw@ALjBTjA@^Pp@Tn@Rp@b@t@b@d@TNZN`@Jb@@fAAvBGH@@`ADv@F`BETEHNfAD`B@z@AfC?|@@v@DNV`@MZOXAP?VD`@n@nCHVh@dBVrAL`BlAQJ@\\Ad@Ar@Bl@Dh@Jb@HHNILb@T|@b@FB~@Ef@LbAHN@j@R?X?TFF^kAB@ToBXqB|@}Gt@{Ed@uC\\aChBwHnBqHhAqEfDaMrByH~@eDj@_Bz@sBf@gApAwBtAmB\\_@|BuB`As@bBcAr@YxBm@lAWrAM`AE`B@nAJdAR|Ab@^LzEbBvFpBxAh@hB`@tAN|ADvAAnAOrCu@xCuArB{AdAeA~AkBtAwBXi@rAsDnByGhBiG|DwM`DqK~AoFdA{DvDkM`AeDv@sDh@qCP_BHkADaBA}AOcCUaBYqAyAoEyAmEq@oCcBoK{BcOmEmFcAb@|CV",
    "color": "#262262"
  },
  {
    "name": "Train: Leeds Station to Loughborough",
    "polyline": "}zigI`lmHyA{@`Fi@`@rD~A|JxAhQlEhO|AzOcDna@lTry@xGdMjFrC~OxErLrBnWc@vPkB|Fy@bNwJxMcPtU_Ihp@iUzOQtRuEph@wV|MaDfPgMrO}^dEgYtM{v@bWiy@d`@g~AjLqVfI_IdVeGdNhBzNrIp[jTlZdM~RlBfPgDdVkThx@mk@t^_WrHqLrDoUq@mVnBzGzUd`@xNvPjIrO|Ozg@dc@tbBfKr]nObTpQvL`i@|]bRvJ|Ep@pPUbKkDtQwDrYfErMfEz_BxYfTwAzOmHx_@og@lN{RjQeOd_@uSzR_WbUi]jQgMjPaG`RcIfLcNtKs[pDi_@\\aYpF{t@hIie@~KiV`n@ad@lKmExM_BzMuRhHwe@CsfAdEyd@nGoPvKyL~RwLbMoCfJ^lO|@jKiCzQiT`Pu^lc@cbA`Yyn@tLqKxNwAfO|GnNvTbUd^dL|J`OvSjOt_@lZ`u@fUv_@fW~n@nO`Vzr@xh@|ZjRhHz@fKoAjWeJxOoH``@qf@zFmDtM{BhScDfIwFlPiZlNuq@zNcb@tg@{cA|KeOnMwHnMmV`g@qPlJdEdWfd@p`@rp@bV`b@zNxQl_@r[lWb^rS`T~QhTtTpb@rJpGpOn@bSiCxSjBfKhH`LpQpXld@n^dh@nVl_@dObQ`[lc@zq@~hAd[|e@zSdVfMdBpJe@nMmItJcSrU_y@pp@mwBhKeRpVoTdPqZzHc\\n[sqAxXsn@tUu`@|VmPxQeB`e@dN`OCrHqBzGoDpRyQ`VqYzMe[zKoQvLaKvUeHn_@aDlUZd_@dFze@lHhVvA`b@eBhSiEbWmJj[uS|o@yg@`bAc_@z[oJlMaCfLHx]|JfcAv_Axw@ls@bPvEbVh@|[k@lc@l@hd@fL~WnIde@zA~TcEdQiHbMmE~^qFnWf@hVbEvbAl^p_@lFvP`FtU|MnNfNpPhX|Yz{@`q@`_ChRdn@vPpX|HpGhN~D|e@rD|Yw@jb@cLxz@~Cx]{C~UjAxlAhMrY`GzXnFpX~Bv\\iGxj@}VbKiFfg@m_@|k@io@nb@wX~a@mLpRiAhb@zCtr@bXrWdGlRr@zVgB|QwExc@mT~b@sFvD_CtFsR`Lkl@gAqf@gVyjAcEwm@RuTvQw}AlQahAt]{jAjIqYzKo~@tDolAjOo`CtKg~@x[}eBpPau@lIy`A^k[xD}e@nP{k@fTeVlUqIpRyGje@{Hpb@gB`cApCvY_Fxz@a`@bi@wQbTuN~^m_@zXqWvUc^jRa^rb@{k@x^}^vTkTbl@wt@zc@{w@tKyS",
    "color": "#880038"
  },
  {
    "name": "Bus (Line 1): Loughborough to East Leake",
    "polyline": "ckcaIlrhFMXWj@FJINo@zACZ@HLb@Jh@@FOTgAv@w@b@KFm@r@m@bAi@jA}@fCQv@K`AErB?d@CdA{@Ie@Cu@?gBK_BKkBO_@?s@G_CLmETa@F_@Lg@TSDYDw@@iCK_DO}COKCo@OSQ]a@Y_@eAcDc@yAyAcFcAcD{@iCOYWWkA_Ag@m@Wm@k@gCMy@Ig@KSME_@Ag@HiCn@m@PwAdAk@v@QXq@xAg@dBOt@]fBYxAS`@E?E@QAo@UkCoBeEiBu@e@SQq@m@sCcCqAqAeBiCcF}JcCkF_AmB}AyCeAmAk@i@_@YeBs@kBe@iCs@}CmAqBg@uBYs@Gs@Cs@E}@e@i@e@UWuBmCoEcG]_@u@o@_@YcBeAcB_AiE_CcBeAa@_@}AcBu@w@c@OGgMWKq@]YOkAm@_GwCoRyJuAbFeAjD_CvHuEpOgElNeCpIoAu@GCAH",
    "color": "#002663"
  },
  {
    "name": "Drive (Uber): Loughborough to East Leake",
    "polyline": "agcaIdthFCJp@Pw@bAuD~CWXmA|@u@`@[Z_AzAi@jAo@fBW~@QjAG`C?d@CdA{@Ie@Cu@?gBK_BKkBO_@?s@G_CLmETa@F_@Lg@TSDYDw@@iCK_DO}COKCo@OSQ]a@Y_@eAcDc@yAyAcFcAcD{@iCOWWYkA_Ag@m@Wm@[kAO{@My@Ig@KSME_@Ag@HsD|@uAdA_@`@_@l@u@~Ai@hB}@tEG\\S`@G@G?[Em@[SQkBsAk@YWMaCaAu@e@{@w@IIsCaCqAqAeBiCs@sA{D_I}CyG}@eBy@}AeAmAk@i@_@YeBs@c@KkCs@eAYa@Q{B{@c@MmAY_AOiBQs@Cs@E}@e@i@e@w@}@kFgHuAcBiA_AgAu@wAy@iCuAqBgA_BaAiAgAmBwBMIYGGgMg@Q{@g@kAm@kCsAyGgDaHmDgDgBi@pBaAdDoA`EeDtK_M|a@]jAa@UaAk@aIgFwEyCk@_@]c@QOA@ADIDG?GEGIA]@E@Ey@m@uByCy@eAy@y@QO",
    "color": "#0000FF"
  },
  {
    "name": "Cycle: Loughborough to East Leake",
    "polyline": "ckcaIlrhFMXWj@FJRZCD_@x@Q^Cb@DTLd@MJWXmA|@u@`@[Z_AzAi@jAo@fBW~@QjAG`C?d@CdA{@Ie@Cu@?gBK_BKkBO_@?s@G_CLmETa@F_@Lg@TSDYDw@@iCK_DO}COKCo@OSQ]a@Y_@eAcDc@yAyAcF_CmHOWWYkA_Ag@m@Wm@[kAO{@My@Ig@KSME_@Ag@HsD|@uAdA_@`@_@l@u@~Ai@hB}@tEG\\S`@G@G?[Em@[SQkBsAk@YWMaCaAu@e@{@w@IIsCaCqAqAeBiCs@sA{D_I}CyG}@eBy@}AeAmAk@i@_@YeBs@c@KkCs@eAYa@Q{B{@c@MmAY_AOiBQs@Cs@E}@e@i@e@w@}@kFgHuAcBiA_AgAu@wAy@{F}C_BaAiAgAmBwBMIYGGgMg@Q{@g@kAm@_GwCuGgDyIqEuAbFwCnJs@~B_AzCITIKOOYOk@GkAKQEBOD}D@wBE_@CIGIICgAC_A@WJm@`@_@`@]LWDOCIBIPCfAEtAAHeAMsC_@Y`B[lBGVQFMH_BtCg@jAa@dBo@zBUb@YNm@R_@V@@@D@D@L?LELGFI@GCKU@[w@q@wB{CqA}Aq@o@",
    "color": "#00FF00"
  },
  {
    "name": "Direct Drive: St Chads View to East Leake",
    "polyline": "srogInltHS~EpCvFjBd@fAAdCoD|B_HxDVrL}D_BeLjGyPvDsI~EkCnFi@pHlBbXgJtSLhEbBvHcP~GaSlO{f@hB{NhDaDdB|@jCdJjGxNjFpGpFdArHrEzPeAfM_@dIjIxT?dCeRIgI{Oah@uIgg@pAk`@zK{\\~IaIpLcGfWxMrKk@`FwGlC_PGwg@jByx@bHuXfJ}HrSyA~Wj@~[x@vSnK`LbDxLG|b@aQjU_L~UqD`\\nG|QlOdMnSvh@nnAzc@ftA|Xtc@xm@ra@hThFbPTzdAmOfQoCr[kLxSaRfY{i@l[me@zh@ck@lLiD`JFpYhI~WtPbOrN~[jYxYlC~MjAtNbG`i@bj@z[`RxWvDd]m@|XwEjXeQtf@ks@jX_SxXgFbUlDfK|F|V~N~Y`EvT}BzKcE`c@{]tKyOlTcf@dIiWdGmPvNmR`~@cs@z^i`@vNsVzi@}o@nPoJdU}@hP`FlVrE`SuGnTgWbf@ke@dSq^tO{Pj\\uO~PcG|a@aX`h@ug@jsA_~@fPyFv_@mCnWgGhWuRlRcSrVu`@rg@wjAxOuQhXcVn`@sd@rg@gk@zf@{t@ri@sdBfGyf@hBcu@oJq_AiAalAhF_uFzE{f@bFeSpL{WxReSd_@mOxWq@tb@jKfWdJr_@|Et`@bBdy@nRps@jUbQShPcFvc@k]`\\yMh\\sDb\\bBpVbFl]~HdSdKze@d\\b{Bzr@~z@d_@lXjM~R`S`d@z`ArUf]ba@b^pVrKjM~@|o@vA`i@cFlh@yUth@iXrj@wKxd@Oh]~G`W~A|Qy@zp@}@va@lFp[h@b^eBvXtArr@vQpj@|OlYvCvi@_DrTqEr[`A|j@|VvYxAlUsFh\\}WzRwIbQmMjPc\\xM_g@lLeU|f@sh@tn@gs@tc@gu@`k@ekAbf@al@r[}d@fKiJzS{Jrb@wC|\\yKl[eUb`@uPnm@qLvo@yKtNoGl[a]pPqSd\\yPlV}A~SlDh\\rQrZjb@~Sbg@x[n]v]hNnYdWl^bq@|Xb^l^tYtUrKde@zPhUvUdO`\\~Ln_@vOhVvPhL`TnDll@sBvXq@la@bCfYKdNoDrReD`ZpBdUvKfHrGrSlUv^jVhOtCbUk@rj@iTto@uX|\\uNb^{QhL}G|KSjQ}HjDcAbCeGjK_TnGgRh@k[yAgWoA}^GuSfNm[|C_QjIsJ`C{g@OiRqBwRn@cRdJyc@fDuJpCkKl@gT~Hgc@d@{GqBi@}OiFSwQuEgk@lIA|BRjAqNj@sVjCe_@w@on@g@sUnCyWTwNzA_D~DzA",
    "color": "#0000FF"
  }
];

final Map<String, dynamic> routesMap = {
  'uber': 'Drive (Uber): St Chads View to Leeds Station',
  'bus': 'Bus (Line 24): St Chads View to Leeds Station',
  'cycle': 'Cycle: St Chads View to Leeds Station',
  'train_walk_headingley': 'Train (Northern): St Chads View to Leeds Station via Headingley',
  'train_main': 'Train: Leeds Station to Loughborough',
  'last_uber': 'Drive (Uber): Loughborough to East Leake',
  'last_bus': 'Bus (Line 1): Loughborough to East Leake',
  'last_cycle': 'Cycle: Loughborough to East Leake'
};

final Map<String, dynamic> directDriveData = {
  'time': 110,
  'cost': 39.15,
  'distance': 87.0
};

final Map<String, dynamic> segmentOptionsData = {
  'firstMile': [
    {
      'id': 'uber',
      'label': 'Uber',
      'detail': 'St Chads → Leeds Station',
      'time': 14,
      'cost': 8.97,
      'distance': 3.0,
      'riskScore': 0,
      'iconId': IconIds.car,
      'color': 'text-black',
      'bgColor': 'bg-zinc-100',
      'lineColor': '#000000',
      'desc': 'Fastest door-to-door.',
      'waitTime': 4,
      'segments': [
        { 'mode': 'taxi', 'label': 'Uber', 'lineColor': '#000000', 'iconId': IconIds.car, 'time': 14, 'to': 'Leeds Station' }
      ]
    },
    {
      'id': 'bus',
      'label': 'Bus (Line 24)',
      'detail': '5min walk + 16min bus',
      'time': 23,
      'cost': 2.00,
      'distance': 3.0,
      'riskScore': 0,
      'iconId': IconIds.bus,
      'color': 'text-brand-dark',
      'bgColor': 'bg-brand-light',
      'lineColor': '#30227d',
      'recommended': true,
      'desc': 'Best balance.',
      'nextBusIn': 12,
      'segments': [
        { 'mode': 'bus', 'label': 'Bus', 'lineColor': '#30227d', 'iconId': IconIds.bus, 'time': 23, 'to': 'Leeds Station' }
      ]
    },
    {
      'id': 'drive_park',
      'label': 'Drive & Park',
      'detail': 'Drive to Station',
      'time': 15,
      'cost': 24.89,
      'distance': 3.0,
      'riskScore': 0,
      'iconId': IconIds.car,
      'color': 'text-zinc-800',
      'bgColor': 'bg-zinc-100',
      'lineColor': '#3f3f46',
      'desc': 'Flexibility.',
      'segments': [
        { 'mode': 'car', 'label': 'Drive', 'lineColor': '#3f3f46', 'iconId': IconIds.car, 'time': 15, 'to': 'Leeds Station' }
      ]
    },
    {
      'id': 'train_walk_headingley',
      'label': 'Headingley (Walk)',
      'detail': '18m Walk + 10m Train',
      'time': 28,
      'cost': 3.40,
      'distance': 3.0,
      'riskScore': 2,
      'iconId': IconIds.footprints,
      'color': 'text-slate-600',
      'bgColor': 'bg-slate-100',
      'lineColor': '#262262',
      'desc': 'Walking transfer.',
      'segments': [
        { 'mode': 'walk', 'label': 'Walk', 'lineColor': '#475569', 'iconId': IconIds.footprints, 'time': 18, 'to': 'Headingley Station' },
        { 'mode': 'train', 'label': 'Northern', 'lineColor': '#262262', 'iconId': IconIds.train, 'time': 10, 'to': 'Leeds Station' }
      ]
    },
    {
      'id': 'train_uber_headingley',
      'label': 'Uber + Northern',
      'detail': '5m Uber + 10m Train',
      'time': 15,
      'cost': 9.32,
      'distance': 3.0,
      'riskScore': 1,
      'iconId': IconIds.car,
      'color': 'text-slate-600',
      'bgColor': 'bg-slate-100',
      'lineColor': '#262262',
      'desc': 'Fast transfer.',
      'waitTime': 3,
      'segments': [
        { 'mode': 'taxi', 'label': 'Uber', 'lineColor': '#000000', 'iconId': IconIds.car, 'time': 5, 'to': 'Headingley Station' },
        { 'mode': 'train', 'label': 'Northern', 'lineColor': '#262262', 'iconId': IconIds.train, 'time': 10, 'to': 'Leeds Station' }
      ]
    },
    {
      'id': 'cycle',
      'label': 'Personal Bike',
      'detail': 'Cycle to Station',
      'time': 17,
      'cost': 0.00,
      'distance': 3.0,
      'riskScore': 1,
      'iconId': IconIds.bike,
      'color': 'text-blue-600',
      'bgColor': 'bg-blue-100',
      'lineColor': '#00FF00',
      'desc': 'Zero emissions.',
      'segments': [
        { 'mode': 'bike', 'label': 'Bike', 'lineColor': '#00FF00', 'iconId': IconIds.bike, 'time': 17, 'to': 'Leeds Station' }
      ]
    }
  ],
  'mainLeg': {
    'id': 'train_main',
    'label': 'CrossCountry',
    'detail': 'Leeds → Loughborough',
    'time': 102,
    'cost': 25.70,
    'distance': 80.0,
    'riskScore': 1,
    'iconId': IconIds.train,
    'color': 'text-[#713e8d]',
    'bgColor': 'bg-indigo-100',
    'lineColor': '#880038',
    'platform': 4,
    'segments': [
      { 'mode': 'train', 'label': 'CrossCountry', 'lineColor': '#880038', 'iconId': IconIds.train, 'time': 102, 'to': 'Loughborough Station' }
    ]
  },
  'lastMile': [
    {
      'id': 'uber',
      'label': 'Uber',
      'detail': 'Loughborough → East Leake',
      'time': 10,
      'cost': 14.89,
      'distance': 5.0,
      'riskScore': 0,
      'iconId': IconIds.car,
      'color': 'text-black',
      'bgColor': 'bg-zinc-100',
      'lineColor': '#000000',
      'desc': 'Reliable final leg.',
      'segments': [
        { 'mode': 'taxi', 'label': 'Uber', 'lineColor': '#000000', 'iconId': IconIds.car, 'time': 10, 'to': 'East Leake' }
      ]
    },
    {
      'id': 'bus',
      'label': 'Bus (Line 1)',
      'detail': 'Walk 4min + Bus 10min',
      'time': 14,
      'cost': 3.00,
      'distance': 5.0,
      'riskScore': 2,
      'iconId': IconIds.bus,
      'color': 'text-brand-dark',
      'bgColor': 'bg-brand-light',
      'lineColor': '#002663',
      'recommended': true,
      'desc': 'Short walk required.',
      'segments': [
        { 'mode': 'bus', 'label': 'Bus', 'lineColor': '#002663', 'iconId': IconIds.bus, 'time': 14, 'to': 'East Leake' }
      ]
    },
    {
      'id': 'cycle',
      'label': 'Personal Bike',
      'detail': 'Cycle to Dest',
      'time': 24,
      'cost': 0.00,
      'distance': 5.0,
      'riskScore': 1,
      'iconId': IconIds.bike,
      'color': 'text-blue-600',
      'bgColor': 'bg-blue-100',
      'lineColor': '#00FF00',
      'desc': 'Scenic route.',
      'segments': [
        { 'mode': 'bike', 'label': 'Bike', 'lineColor': '#00FF00', 'iconId': IconIds.bike, 'time': 24, 'to': 'East Leake' }
      ]
    }
  ]
};
