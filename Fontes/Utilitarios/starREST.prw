User Function startRest()
  //O nome do job REST e ambiente de execução dele, podem ser obtidos no arquivo
  //de configuração do _appServer_.
  //Detalhes da função em https://tdn.totvs.com/display/tec/StartJob

Local lret := .F.
  lret := startjob("U_BOLHBPDF",getenvserver(),.T., {'01','02'})
  if !lret
    return -1
  endif
    
Return
