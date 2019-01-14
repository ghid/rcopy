; ahk: console
#include <logging>
#include <testcase>
#include <string>
#include <object>
#include <arrays>

class RCopyTest extends TestCase
{

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
		this.AssertTrue(IsFunc(RCopy.set_defaults))
		this.AssertTrue(IsFunc(RCopy.set_context_vars))
		this.AssertTrue(IsFunc(RCopy.SetupSourcePath))
		this.AssertTrue(IsFunc(RCopy.SetupTargetPath))
		this.AssertTrue(IsFunc(RCopy.CopyAndRename))
		this.AssertTrue(IsFunc(RCopy.FillFileContext))
		this.AssertTrue(IsFunc(RCopy.FillGlobalContext))
		this.AssertTrue(IsFunc(RCopy.IncreaseSequenceContext))
	}

    @Test_SetDefaults()
	{
        this.AssertEquals(RCopy.options.subdirs, [])
        this.AssertEquals(RCopy.options.rename_as, "")
        this.AssertEquals(RCopy.options.source, "")
        this.AssertEquals(RCopy.options.dry_run, false)
        this.AssertEquals(RCopy.options.help_context_vars, false)
        this.AssertEquals(RCopy.options.help, false)
    }

    @Test_SetContextVars()
    {
        this.AssertTrue(RCopy.context_vars.HasKey("%y%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%yy%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%m%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%d%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%s%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%s_%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%s1%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%s1_%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%x%"))
        this.AssertTrue(RCopy.context_vars.HasKey("%%"))
    }

    @Test_SetupSourcePath()
    {
        this.AssertException(RCopy, "SetupSourcePath", "", "Specify source-dir\\pattern", "")
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

    @Test_FillGlobalContext()
    {
        RCopy.FillGlobalContext()
        this.AssertEquals(RCopy.context_vars["%s%"].value, "Image")
        this.AssertEquals(RCopy.context_vars["%s_%"].value, "Image")
        this.AssertEquals(RCopy.context_vars["%s1%"].value, "Image")
        this.AssertEquals(RCopy.context_vars["%s1_%"].value, "Image")
    }

    @Test_FillGlobalContext_1_SubDir()
    {
        RCopy.options.subdirs := ["My Subdir"]
        RCopy.FillGlobalContext()
        this.AssertEquals(RCopy.context_vars["%s%"].value, "My Subdir")
        this.AssertEquals(RCopy.context_vars["%s_%"].value, "My_Subdir")
        this.AssertEquals(RCopy.context_vars["%s1%"].value, "My Subdir")
        this.AssertEquals(RCopy.context_vars["%s1_%"].value, "My_Subdir")
    }

    @Test_FillGlobalContext_2_SubDirs()
    {
        RCopy.options.subdirs := ["My Customer", "2018", "Winter Campaign"]
        RCopy.FillGlobalContext()
        this.AssertEquals(RCopy.context_vars["%s%"].value, "Winter Campaign")
        this.AssertEquals(RCopy.context_vars["%s_%"].value, "Winter_Campaign")
        this.AssertEquals(RCopy.context_vars["%s1%"].value, "My Customer")
        this.AssertEquals(RCopy.context_vars["%s1_%"].value, "My_Customer")
    }

    @Test_FillFileContext()
    {
        RCopy.FillFileContext("test.jpg", 20190114090807, 2)
        this.AssertEquals(RCopy.context_vars["%d%"].value, "14")
        this.AssertEquals(RCopy.context_vars["%m%"].value, "01")
        this.AssertEquals(RCopy.context_vars["%y%"].value, "2019")
        this.AssertEquals(RCopy.context_vars["%yy%"].value, "19")
        this.AssertEquals(RCopy.context_vars["%x%"].value, "2")
    }

    @Test_IncreaseSequenceContext()
    {
        this.AssertEquals(RCopy.context_vars["%x%"].value, 1)
        RCopy.IncreaseSequenceContext()
        this.AssertEquals(RCopy.context_vars["%x%"].value, 2)
        RCopy.IncreaseSequenceContext()
        this.AssertEquals(RCopy.context_vars["%x%"].value, 3)
    }

    @Test_UseContext()
    {
        this.AssertEquals(RCopy.UseContext("My_%s_%-%y%-%m%-%d%_%00x%")
            , "My_Image-YYYY-MM-DD_001")

        RCopy.options.subdirs := ["My Project", "My Campaign"]
        RCopy.FillGlobalContext()
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
        this.AssertEquals(RCopy.UseContext("%s%"), "My Campaign")
        this.AssertEquals(RCopy.UseContext("%s_%"), "My_Campaign")
        this.AssertEquals(RCopy.UseContext("%s1%"), "My Project")
        this.AssertEquals(RCopy.UseContext("%s1_%"), "My_Project")
    }

    @Test_SetupTargetPath()
    {
        RCopy.options.dest := "c:\temp"
        this.AssertEquals(RCopy.SetupTargetPath(), "c:\temp\")

        RCopy.options.subdirs := ["My Project"]
        this.AssertEquals(RCopy.SetupTargetPath(), "c:\temp\My Project\")

        RCopy.options.subdirs := ["My Project\"]
        this.AssertEquals(RCopy.SetupTargetPath(), "c:\temp\My Project\")

        RCopy.options.subdirs := ["%y%", "%m%", "My Project"]
        RCopy.FillFileContext("test.jpg", 20190114113819, 1)
        this.AssertEquals(RCopy.SetupTargetPath(), "c:\temp\2019\01\My Project\")
    }

    @Test_SetupTargetPath2()
    {
        RCopy.options.dest := "c:\temp\%y%\%m%\%d%"
        RCopy.FillFileContext("test.jpg", 20190114113819, 1)
        this.AssertEquals(RCopy.SetupTargetPath(), "c:\temp\2019\01\14\")
    }
/*
	@Test_Operations() {
		this.AssertEquals(Operations("add"), "add")
		this.AssertEquals(Operations("sub"), "sub")
		this.AssertException("", "Operations", "", "", "mult")
	}

	@Test_Add()
	{
		RCopy.options := {n1: 0, n2: 0}
		this.AssertEquals(RCopy.add(), "0+0=0")
		RCopy.options := {n1: 1, n2: 1}
		this.AssertEquals(RCopy.add(), "1+1=2")
		RCopy.options := {n1: 1.1, n2: 1.2}
		this.AssertEquals(RCopy.add(), "1.1+1.2=2.300000")
		RCopy.options := {n1: "blah", n2: 99}
		this.AssertException(RCopy, "add",,"Add: n1 is not a number: blah")
		RCopy.options := {n1: 42, n2: "blubb"}
		this.AssertException(RCopy, "add",,"Add: n2 is not a number: blubb")
	}

	@Test_CLI_Usage()
	{
		text =
(
usage: RCopy: -o <add|sub> --n1=<value-1> --n2=<value-2>

    -o, --operation <operation>
                          Define which operation to be performed:
                          . add: perform addition
                          . sub: perform substraction

    --n1 <value-1>        The first value for the calculation
    --n2 <value-2>        The second value for the calculation


Specify an operation
usage: RCopy: -o <add|sub> --n1=<value-1> --n2=<value-2>

    -o, --operation <operation>
                          Define which operation to be performed:
                          . add: perform addition
                          . sub: perform substraction

    --n1 <value-1>        The first value for the calculation
    --n2 <value-2>        The second value for the calculation



)
		this.AssertEquals(RCopy.Run(["-h"]), "")
		this.AssertEquals(RCopy.Run([]), 0)
		Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\cui-test.txt"), text)
	}

	@Test_CLI_Add() {
		this.AssertEquals(RCopy.Run(["-o", "add", "--n1", 1, "--n2", 1]), 1)
		Ansi.Flush()
		this.AssertEquals(TestCase.FileContent(A_Temp "\cui-test.txt"), "1+1=2`n")
	}
*/
}

exitapp RCopyTest.RunTests()

#include %A_ScriptDir%\..\rcopy.ahk
; vim:tw=100:ts=4:sts=4:sw=4:et:ft=autohotkey:nobomb
