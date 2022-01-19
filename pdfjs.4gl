IMPORT util
IMPORT os
CONSTANT TMK = "compressed.tracemonkey-pldi-09.pdf"
CONSTANT CP2PUBLIC = FALSE
MAIN
  DEFINE w, err, creator, author, gasloc, origin, url STRING
  DEFINE version FLOAT
  DEFINE args DYNAMIC ARRAY OF STRING
  CALL check_prerequisites()
  OPEN FORM f FROM "pdfjs"
  DISPLAY FORM f
  #we display web.html in a *URL based* component
  #because of GDC-4402
  IF (gasloc
      := fgl_getenv("FGL_VMPROXY_WEB_COMPONENT_LOCATION")) IS NOT NULL THEN
    LET url = gasloc, "/web/web.html"
    DISPLAY "url:", url
  ELSE
    --direct mode:
    --we use the hidden component based webcomponent to retrieve the URL
    --for the URL based component
    --this is admittedly a very ugly hack and surrounds GDC-4402
    DISPLAY "direct mode:need hack"
    CALL ui.interface.frontcall(
        "webcomponent", "call", ["formonly.w2", "getUrl"], [url])
  END IF
  DISPLAY "url of url based compo:", url
  MESSAGE "url of url based compo:", url
  DISPLAY url TO w
  MENU
    BEFORE MENU
      CALL DIALOG.setActionHidden("error", 1)
      CALL displayPDF("hello.pdf")
    ON ACTION cancel
      EXIT MENU
    ON ACTION radstation ATTRIBUTE(TEXT = "Show radstation.pdf")
      CALL displayPDF("radstation.pdf")
    ON ACTION hello ATTRIBUTE(TEXT = "Show hello.pdf")
      CALL displayPDF("hello.pdf")
    ON ACTION pages2 ATTRIBUTE(TEXT = "Show 2pages.pdf")
      CALL displayPDF("2pages.pdf")
    ON ACTION tmk ATTRIBUTE(TEXT = "Show Trace monkey")
      CALL displayPDF(TMK)
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
  END MENU
END MAIN

FUNCTION displayPDF(fname)
  DEFINE fname, remoteName STRING
  DISPLAY fname TO file
  CASE
    WHEN fname.equals(TMK)
      LET remoteName = TMK
    WHEN CP2PUBLIC
      LET remoteName = copyToPublic(fname)
    OTHERWISE
      LET remoteName = ui.Interface.filenameToURI(fname)
  END CASE
  DISPLAY remoteName TO url
  CALL ui.interface.frontcall(
      "webcomponent", "call", ["formonly.w", "displayPDF", remoteName], [])
END FUNCTION

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

FUNCTION check_tool(tool)
  DEFINE tool STRING
  DEFINE code INT
  LET tool = tool, " 2>/dev/null"
  RUN tool RETURNING code
  IF code THEN
    DISPLAY "SKIP program for platforms not having:'", tool, "'"
    EXIT PROGRAM 1
  END IF
END FUNCTION

FUNCTION check_prerequisites()
  DEFINE code INT
  CALL check_tool("patch --help")
  CALL check_tool("node --help")
  CALL check_tool("npm help")
  RUN "make build_and_patch" RETURNING code
  IF code THEN
    DISPLAY "SKIP program: make_build_patch failed"
    EXIT PROGRAM 1
  END IF
END FUNCTION
