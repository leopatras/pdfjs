IMPORT util
IMPORT os
MAIN
  DEFINE w, err, creator, author STRING
  DEFINE version FLOAT
  DEFINE args DYNAMIC ARRAY OF STRING
  CALL check_prerequisites()
  OPEN FORM f FROM "pdfjs"
  DISPLAY FORM f
  INPUT BY NAME w WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED, ACCEPT = FALSE)
    BEFORE INPUT
      CALL DIALOG.setActionHidden("error", 1)
      CALL displayPDF("hello.pdf")
    ON ACTION radstation ATTRIBUTE(TEXT = "Show radstation.pdf")
      CALL displayPDF("radstation.pdf")
    ON ACTION hello ATTRIBUTE(TEXT = "Show hello.pdf")
      CALL displayPDF("hello.pdf")
    ON ACTION showcreator ATTRIBUTE(TEXT = "Retrieve creator")
      CALL ui.interface.frontcall(
        "webcomponent", "call", ["formonly.w", "getCreator"], [creator])
      MESSAGE "creator:", creator
    ON ACTION showauthor ATTRIBUTE(TEXT = "Retrieve author")
      CALL ui.interface.frontcall(
        "webcomponent", "call", ["formonly.w", "getAuthor"], [author])
      MESSAGE "author:", author
    ON ACTION error
      CALL ui.interface.frontcall(
        "webcomponent", "call", ["formonly.w", "getError"], [err])
      ERROR SFMT("Failed at js side with:%1", err)
    ON ACTION showenv ATTRIBUTE(TEXT = "Show FGL env")
      ERROR "public_dir:",
        fgl_getenv("FGL_PUBLIC_DIR"),
        ",\npublic_url_prefix:",
        fgl_getenv("FGL_PUBLIC_URL_PREFIX"),
        ",\npublic_image:",
        fgl_getenv("FGL_PUBLIC_IMAGEPATH"),
        ",\npwd:",
        os.Path.pwd(),
        ",\nFGL_PRIVATE_DIR:",
        fgl_getenv("FGL_PRIVATE_DIR")
      DISPLAY "public_dir:",
        fgl_getenv("FGL_PUBLIC_DIR"),
        ",\npublic_url_prefix:",
        fgl_getenv("FGL_PUBLIC_URL_PREFIX"),
        ",\npublic_image:",
        fgl_getenv("FGL_PUBLIC_IMAGEPATH"),
        ",\npwd:",
        os.Path.pwd(),
        ",\nFGL_PRIVATE_DIR:",
        fgl_getenv("FGL_PRIVATE_DIR")
      RUN "echo `env | grep FGL`"
  END INPUT
END MAIN

FUNCTION copyToPublic(fname)
  DEFINE fname, pubdir, pubimgpath, pubname STRING
  DEFINE remoteName STRING
  DEFINE sepIdx INT
  DEFINE use_public BOOLEAN
  --GAS sets this variables, to they are only available in GAS mode
  LET use_public = fgl_getenv("USE_PUBLIC") IS NOT NULL
  DISPLAY "use public:", use_public
  DISPLAY fname TO file
  LET pubdir = fgl_getenv("FGL_PUBLIC_DIR")
  IF pubdir IS NOT NULL AND os.Path.exists(pubdir) THEN
    LET pubimgpath = fgl_getenv("FGL_PUBLIC_IMAGEPATH")
    --just use the first sub dir in the path if we have more than one
    --the default is "common"
    IF (sepIdx := pubimgpath.getIndexOf(os.Path.pathSeparator(), 1)) > 0 THEN
      LET pubimgpath = pubimgpath.subString(1, sepIdx - 1)
    END IF
    LET pubdir = os.Path.join(pubdir, pubimgpath)
    LET pubname = os.Path.join(pubdir, os.Path.baseName(fname))
    --copy our image to the GAS public dir
    --which means anybody knowing the file name can access it
    --if our file name is hello.pdf the http name is then http://localhost:xxx/ua/i/common/hello.pdf?t=xxxxxxx
    IF use_public THEN
      DISPLAY "use pubdir:", pubdir
      DISPLAY pubname TO file
      IF NOT os.Path.copy(fname, pubname) THEN
        ERROR "Cant copy: ", fname, " to :", pubname
        DISPLAY "Cant copy: ", fname, " to public:", pubname
        RETURN NULL
      END IF
      LET fname = os.Path.baseName(fname)
    ELSE
      --remove any potential leftovers
      CALL os.Path.delete(pubname) RETURNING status
    END IF
  END IF
  LET remoteName = ui.Interface.filenameToURI(fname)
  DISPLAY "remoteName:",remoteName
  RETURN remoteName
END FUNCTION

FUNCTION displayPDF(fname)
  DEFINE fname, remoteName STRING
  LET remoteName = copyToPublic(fname)
  DISPLAY remoteName TO url
  CALL ui.interface.frontcall(
    "webcomponent", "call", ["formonly.w", "displayPDF", remoteName], [])
END FUNCTION

FUNCTION check_prerequisites()
  DEFINE code INT
  RUN "curl --help" RETURNING code
  IF code THEN
    DISPLAY "SKIP test for platforms not having curl"
    EXIT PROGRAM 1
  END IF
  RUN "patch --help" RETURNING code
  IF code THEN
    DISPLAY "SKIP test for platforms not having patch"
    EXIT PROGRAM 1
  END IF
  RUN "make download_and_patch" RETURNING code
  IF code THEN
    DISPLAY "SKIP test: download and patch failed"
    EXIT PROGRAM 1
  END IF
END FUNCTION
