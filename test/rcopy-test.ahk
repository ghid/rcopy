; ahk: console
#include <logging>
#include <testcase>
#include <string>
#include <object>
#include <arrays>
#include <flimsydata>

class RCopyTest extends TestCase
{

	@BeforeClass_Setup() {
		if (!FileExist(A_Scriptdir "\Testdata")) {
            OutputDebug *** Create Testdata ***
			FileCreateDir %A_ScriptDir%\Testdata\DCIM\100OLYMP\
			SetWorkingDir %A_ScriptDir%\Testdata\DCIM\100OLYMP\
			fd := new FlimsyData.Simple(1450)
			; Create test files
			loop 20 {
                date := fd.GetDate(2001,20190113)
                time := fd.GetTime()
                m := SubStr(date, 5, 2)
                m := (m = 10 ? "A"
                    : m = 11 ? "B"
                    : m = 12 ? "C"
                    : m+0)
                d := SubStr(date, 7, 2)
                x := SubStr("0000" A_Index, -3)
                fn := fd.GetPattern("%[P,_]") m d x
                ts := date time
                FileAppend,, %fn%.orf
                FileSetTime %ts%, %fn%.orf, C
                FileSetTime %ts%, %fn%.orf, M
                FileAppend,, %fn%.jpg
                FileSetTime %ts%, %fn%.jpg, C
                FileSetTime %ts%, %fn%.jpg, M
			}
            FileAppend,, a_culprit.txt
		}
	}

	@BeforeRedirStdOut()
    {
		Ansi.StdOut := FileOpen(A_Temp "\rcopy-test.txt", "w")
	}

    @BeforeReInit()
    {
        RCopy.options := RCopy.set_defaults()
        RCopy.context_vars := RCopy.set_context_vars()
    }

	@AfterRedirStdOut()
    {
		Ansi.StdOut.Close()
		Ansi.StdOut := Ansi.__InitStdOut()
		FileDelete %A_Temp%\rcopy-test.txt
	}

	@Test_Class()
	{
		this.AssertTrue(RCopy.HasKey("options"))
		this.AssertTrue(RCopy.HasKey("context_vars"))
        this.AssertTrue(RCopy.options.HasKey("file_types"))
		this.AssertTrue(IsFunc(RCopy.set_defaults))
		this.AssertTrue(IsFunc(RCopy.set_context_vars))
		this.AssertTrue(IsFunc(RCopy.SetupSourcePath))
		this.AssertTrue(IsFunc(RCopy.SetupTargetPath))
		this.AssertTrue(IsFunc(RCopy.CopyAndRename))
		this.AssertTrue(IsFunc(RCopy.FillFileContext))
		this.AssertTrue(IsFunc(RCopy.IncreaseSequenceContext))
	}

    @Test_SetDefaults()
	{
        this.AssertEquals(RCopy.options.rename_as, "")
        this.AssertEquals(RCopy.options.source, "")
        this.AssertEquals(RCopy.options.start_with, 1)
        this.AssertEquals(RCopy.options.dry_run, false)
        this.AssertEquals(RCopy.options.help_context_vars, false)
        this.AssertEquals(RCopy.options.help_file_types, false)
        this.AssertEquals(RCopy.options.help, false)
    }

    @Test_SetContextVars()
    {
        this.AssertTrue(RCopy.context_vars.HasKey("%y%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%yy%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%m%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%d%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%#%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%%"))
    }

    @Test_SetupSourcePath()
    {
        this.AssertException(RCopy, "SetupSourcePath", "", "Specify source", "")
        RCopy.SetupSourcePath("c:\work\temp")
        this.AssertEquals(RCopy.options.source, "c:\work\temp\*.*")
        RCopy.SetupSourcePath("*.jpg")
        this.AssertEquals(RCopy.options.source, "*.jpg")
        RCopy.SetupSourcePath("x*.jpg")
        this.AssertEquals(RCopy.options.source, "x*.jpg")
        RCopy.SetupSourcePath(".")
        this.AssertEquals(RCopy.options.source, ".")
        RCopy.SetupSourcePath("*.*")
        this.AssertEquals(RCopy.options.source, "*.*")
        RCopy.SetupSourcePath("*.")
        this.AssertEquals(RCopy.options.source, "*.")
        RCopy.SetupSourcePath(".\*")
        this.AssertEquals(RCopy.options.source, ".\*")
        RCopy.SetupSourcePath("c:\work\t*")
        this.AssertEquals(RCopy.options.source, "c:\work\t*")
        RCopy.SetupSourcePath("c:\work\t*.jpg")
        this.AssertEquals(RCopy.options.source, "c:\work\t*.jpg")
    }

    @Test_FillFileContext()
    {
        RCopy.FillFileContext("test.jpg", 20190114090807, 2)
        this.AssertEquals(RCopy.context_vars["%d%"].value, "14")
        this.AssertEquals(RCopy.context_vars["%m%"].value, "01")
        this.AssertEquals(RCopy.context_vars["%y%"].value, "2019")
        this.AssertEquals(RCopy.context_vars["%yy%"].value, "19")
        this.AssertEquals(RCopy.context_vars["%#%"].value, "2")
    }

    @Test_IncreaseSequenceContext()
    {
        this.AssertEquals(RCopy.context_vars["%#%"].value, 1)
        RCopy.IncreaseSequenceContext()
        this.AssertEquals(RCopy.context_vars["%#%"].value, 2)
        RCopy.IncreaseSequenceContext()
        this.AssertEquals(RCopy.context_vars["%#%"].value, 3)
    }

    @Test_UseContext()
    {
        this.AssertEquals(RCopy.UseContext("My_Image-%y%-%m%-%d%_%00x%")
            , "My_Image-YYYY-MM-DD_001")

        RCopy.FillFileContext("test.jpg", 20190114094815, 13)
        this.AssertEquals(RCopy.UseContext("%y%"), "2019")
        this.AssertEquals(RCopy.UseContext("%yy%"), "19")
        this.AssertEquals(RCopy.UseContext("%m%"), "01")
        this.AssertEquals(RCopy.UseContext("%m%"), "01")
        this.AssertEquals(RCopy.UseContext("%d%"), "14")
        this.AssertEquals(RCopy.UseContext("%x%"), "13", TestCase.AS_STRING)
        this.AssertEquals(RCopy.UseContext("%0x%"), "13", TestCase.AS_STRING)
        this.AssertEquals(RCopy.UseContext("%00x%"), "013", TestCase.AS_STRING)
        this.AssertEquals(RCopy.UseContext("%000x%"), "0013", TestCase.AS_STRING)
    }

    @Test_SetupTargetPath()
    {
        RCopy.options.dest := "c:\temp"
        this.AssertEquals(RCopy.SetupTargetPath(), "c:\temp\")
    }

    @Test_SetupTargetPath2()
    {
        RCopy.options.dest := "c:\temp\%y%\%m%\%d%"
        RCopy.FillFileContext("test.jpg", 20190114113819, 1)
        this.AssertEquals(RCopy.SetupTargetPath(), "c:\temp\2019\01\14\")
    }

    @Test_FtExpr()
    {
        this.AssertEquals(RCopy.FtExpr()
            , "i)^(.*\.jpe?g|.*\.tiff?|.*\.orf|.*\.dng)$")
    }
}

exitapp RCopyTest.RunTests()

#include %A_ScriptDir%\..\rcopy.ahk
