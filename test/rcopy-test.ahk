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
	}

    @Test_SetDefaults()
	{
        this.AssertEquals(RCopy.options.subdirs, [])
        this.AssertEquals(RCopy.options.rename_as, "")
        this.AssertEquals(RCopy.options.source, "")
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
