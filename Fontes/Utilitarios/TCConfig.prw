#INCLUDE 'TOTVS.CH'
#INCLUDE 'TOPCONN.CH'

/* No exemplo abaixo listamos em um array todas as configurações disponíveis*/
user function teste()
  Local nI, cConfig, aConfig
   
  TCLink()
   
  cConfig := TCConfig( 'ALL_CONFIG_OPTIONS' )
   
  aConfig := StrTokArr( cConfig, ';' )
  For nI := 1 to len( aConfigs )
    conout( aConfigs[nI] )
  Next
   
  TCUnlink()
return
