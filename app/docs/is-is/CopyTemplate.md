---
title: Quality.Template.Copy
audience: developer, admin
keywords: gæði, skoðunarsniðmát, afrita, tvöfalda
locale: is-is
---

```json
{"type":"Quality.Template.Copy","data":{"sourceTemplateCode":"INCOMING","targetTemplateCode":"INCOMING-V2","targetDescription":"Móttaka vara, útgáfa 2","expectedCount":1}}
```

Afritar eitt gæðaskoðunarsniðmát, með öllum línum þess og niðurstöðuskilyrðum þeirra, í nýjan sniðmátskóða í einu kalli. Það keyrir Microsoft-skýrsluna `Qlty. Inspection Copy Template` (20402) á leið stakrar afritunar (Stofna úr vörunúmerum óvirkt), svo afritið er það staðlaða: hver lína heldur línunúmeri, prófun og gildum, og bæði nýi hausinn og línur hans sýna upprunann í `Copied From Template Code`.

| Lykill | Áskilinn | Gildi |
| --- | --- | --- |
| `sourceTemplateCode` | Já | Kóði sniðmáts sem er til, í mesta lagi 20 stafir |
| `targetTemplateCode` | Já | Nýr kóði, í mesta lagi 20 stafir; má ekki vera til og verður að vera annar en upprunakóðinn |
| `targetDescription` | Nei | Í mesta lagi 100 stafir; sjálfgefið er lýsing upprunans (áskilið ef upprunann vantar lýsingu) |
| `expectedCount` | Sjá neðar | Eina nýja sniðmátið, þ.e. `1` |

Svarið skilar `templateCode`, `description`, `copiedFromTemplateCode` og `linesCopied` (fjölda lína í nýja sniðmátinu).

Höfnun, alltaf áður en nokkru er breytt og með `parameter`, `expected` og `nextStep`: kóða vantar (`MissingParameter`), óþekktur uppruni (`RecordNotFound`), mark sem er þegar til (`PreconditionFailed`), of langur kóði eða lýsing, gildi sem er ekki texti eða uppruni sama og mark (`InvalidParameter`), og óþekktur lykill (`UnknownParameter`).

Þessi tegund stofnar aðeins sniðmát. Hún bætir aldrei línum við sniðmát sem er til og breytir hvorki né eyðir sniðmáti eða línu. Til að sameina við sniðmát sem er til skaltu nota aðgerðina Afrita sniðmát í Business Central sjálf/ur.

`expectedCount` telur eina nýja sniðmátið. Öðru gildi en `1` er hafnað (`ConfirmationMismatch`) og engu er breytt. Þegar Krefjast staðfestingar fyrir óafturkræf skilaboð er virkt í Bifröst-uppsetningu skilar kall án `expectedCount` villunni `ConfirmationRequired` með væntum fjölda og breytir engu.

Áhrif: stofnar einn sniðmátshaus, línur hans og niðurstöðuskilyrði þeirra. Ekki ídempotent: öðru kalli með sama mark er hafnað því markið er þá til. Ekkert `Commit` er á staðlaðri leið; höfnun eða villa bakfærir alla afritunina. Með `Omit Commit` ber kallandi ábyrgð á bakfærslu.

Úthlutaðu `BIFROST QM Full ori` ásamt Foundation-vinnsluhlutverki. Les- og grunnsöfnin geta ekki keyrt þessa aðgerð. Kallandi þarf einnig innbyggða heimild til að stofna í töflum sniðmátshauss, sniðmátslína og niðurstöðuskilyrða (Microsoft `QltyMgmt - Admin`, sem Full-safnið inniheldur). Engin ytri þjónusta er kölluð.

Afritun úr vörum (fjöldaafritun) er ekki studd: sú leið skýrslunnar biður um staðfestingu.
