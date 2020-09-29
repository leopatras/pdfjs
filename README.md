# This Genero demo uses the pdfjs javascript library

Prerequisites (server side)
  * gnu make 
  * patch
  * curl
  * bash

Running in GDC
```
  FGLSERVER=<yourgdc> make run
```

Running in GDC via GAS
```
  GDC=<yourgdcexecutable> make webrun
```
This assumes FGLASDIR is set and the GAS/GDC/fglrun are on the same machine

Running in GDC via GAS and expose the PDF as public resource
```
  USE_PUBLIC=1 GDC=<yourgdcexecutable> make webrun
```
