; ahk: console
class RCopy
{

	static options := RCopy.set_defaults()
    static context_vars := RCopy.set_context_vars()

	set_defaults() ; IDEA: Rename to InitDefaults()
    {
		return { subdirs: []
            , dest: RegExReplace(A_MyDocuments
                , "\\Documents$"
                , "\Pictures\Camera Roll")
            , rename_as: ""
            , source: ""
            , help_context_vars: false
            , help: false }
	}

    set_context_vars() ; IDEA: Rename to InitCtxVars()
    {
        return { "%y%": { value: "YYYY"
                , desc: "4-digit year of creation date of the source file" }
            , "%yy%":  { value: "YY"
                , desc: "2-digit year of creation date of the source file" }
            , "%m%":   { value: "MM"
                , desc: "2-digit month of creation date of the source file" }
            , "%d%":   { value: "DD"
                , desc: "2-digit day of creation date of the source file" }
            , "%s%":   { value: "Image"
                , desc: "Value of the deepest given subdir if available; "
                . "otherwise ""Image""" }
            , "%s_%":  { value: "Image"
                , desc: "Same as ""%s%"" but spaces will be replaces by ""_""" }
            , "%s1%":  { value: "Image"
                , desc: "Value of the first given subdir if available; "
                . "otherwise ""Image""" }
            , "%s1_%": { value: "Image"
                , desc: "Same as ""%s1"" but spaces will be replaced by ""_""" }
            , "%x%":   { value: 1
                , desc: "Sequence number which will be increased by every file "
                . "processed (use e.g. %00x% to create 3 digits with leadings "
                . "zeroes)" }
            , "%%":    { value: "%"
                , desc: "Insert a single `%` character" } }
    }

    SetupSourcePath(source_path)
    {
        _log := new Logger("class." A_ThisFunc)

        TestCase.Assert(source_path <> "", "Specify source-dir\pattern", "error")

        if (RegExMatch(source_path, "(\.|\*|\*\.|\*\.\*|\.\\\*)$"))
        {
            RCopy.options.source := source_path
        }
        else
        {
            is_dir := InStr(FileExist(source_path), "D") > 0
            if (is_dir)
            {
                RCopy.options.source := source_path "\*.*"
            }
            else
            {
                SplitPath source_path, name, dir
                RCopy.options.source := (dir <> "" ? dir "\" : "")
                    . (name <> "" ? name : "*.*")
            }
        }

        return _log.Exit()
    }

    CopyAndRename()
    {
        _log := new Logger("class." A_ThisFunc)

        RCopy.FillGlobalContext()

        Ansi.WriteLine("Copy from: " RCopy.options.source)
        Ansi.WriteLine("       to: " RCopy.options.dest)
        Ansi.WriteLine(, true)

        loop files, % RCopy.options.source
        {
            RCopy.FillFileContext(A_LoopFilePath, A_LoopFileTimeCreated, A_Index)
            pattern := RCopy.UseContext(RCopy.options.rename_as)
                . "." A_LoopFileExt
            _log.Logs(Logger.Finest, "pattern", pattern)
            Ansi.WriteLine(A_LoopFileName " ... " pattern, true)
            RCopy.IncreaseSequenceContext()
        }

        return _log.Exit()
    }

    UseContext(name)
    {
        _log := new Logger("class." A_ThisFunc)
        _log.Logs(Logger.Input, "name", name)

        p := 1
        loop
        {
            if (p := RegExMatch(name, "%(d|m|yy?|s_?)%", $, p))
            {
                if (_log.Logs(Logger.Finest))
                {
                    _log.Finest("p", p)
                    _log.Finest("$", $)
                }
                name := name.ReplaceAt(p, StrLen($), RCopy.context_vars[$].value)
                p += StrLen($)
            }
        } until (p = 0)

        p := 1
        loop
        {
            if (p := RegExMatch(name, "%0*x%", $, p))
            {
                if (_log.Logs(Logger.Finest))
                {
                    _log.Finest("p", p)
                    _log.Finest("$", $)
                }
                name := name.ReplaceAt(p, StrLen($)
                    , (RCopy.context_vars["%x%"].value).Pad(String.PAD_NUMBER
                    , StrLen($)-2))
                p += StrLen($)
            }
        } until (p = 0)

        name := StrReplace(name, "%%", "%")

        return _log.Exit(name)
    }

    IncreaseSequenceContext()
    {
        _log := new Logger("class." A_ThisFunc)

        RCopy.context_vars["%x%"].value += 1

        return _log.Exit()
    }

    FillFileContext(filename, create_timstamp, index)
    {
        _log := new Logger("class." A_ThisFunc)

        if (_log.Logs(Logger.Input))
        {
            _log.Input("filename", filename)
            _log.Input("create_timstamp", create_timstamp)
            _log.Input("index", index)
        }

        FormatTime year, %create_timstamp%, yyyy
        FormatTime year2, %create_timstamp%, yy
        FormatTime month, %create_timstamp%, MM
        FormatTime day, %create_timstamp%, dd

        RCopy.context_vars["%y%"].value := year
        RCopy.context_vars["%yy%"].value := year2
        RCopy.context_vars["%m%"].value := month
        RCopy.context_vars["%d%"].value := day
        RCopy.context_vars["%x%"].value := index

        if (_log.Logs(Logger.Finest))
        {
            _log.Finest("day", day)
            _log.Finest("month", month)
            _log.Finest("year", year)
            _log.Finest("year2", year2)
            _log.Finest("RCopy.context_vars[""%d%""].value"
                , RCopy.context_vars["%d%"].value)
            _log.Finest("RCopy.context_vars[""%m%""].value"
                , RCopy.context_vars["%m%"].value)
            _log.Finest("RCopy.context_vars[""%y%""].value"
                , RCopy.context_vars["%y%"].value)
            _log.Finest("RCopy.context_vars[""%yy%""].value"
                , RCopy.context_vars["%yy%"].value)
            _log.Finest("RCopy.context_vars[""%x%""].value"
                , RCopy.context_vars["%x%"].value)
        }

        return _log.Exit()
    }

    FillGlobalContext()
    {
        _log := new Logger("class." A_ThisFunc)

        n_subdirs := RCopy.options.subdirs.MaxIndex()
        _log.Logs(Logger.Finest, "n_subdirs", n_subdirs)
        if (n_subdirs)
        {
            s := RCopy.options.subdirs[n_subdirs]
            _log.Logs(Logger.Finest, "s", s)
            RCopy.context_vars["%s%"].value := s
            RCopy.context_vars["%s_%"].value := RegExReplace(s, "\s", "_")
            if (_log.Logs(Logger.Finest))
            {
                _log.Finest("RCopy.context_vars[""%s%""].value"
                    , RCopy.context_vars["%s%"].value)
                _log.Finest("RCopy.context_vars[""%s_%""].value"
                    , RCopy.context_vars["%s_%"].value)
            }

            s1 := RCopy.options.subdirs[1]
            _log.Logs(Logger.Finest, "s1", s1)
            RCopy.context_vars["%s1%"].value := s1
            RCopy.context_vars["%s1_%"].value := RegExReplace(s1, "\s", "_")
            if (_log.Logs(Logger.Finest))
            {
                _log.Finest("RCopy.context_vars[""%s1%""].value"
                    , RCopy.context_vars["%s1%"].value)
                _log.Finest("RCopy.context_vars[""%s1_%""].value"
                    , RCopy.context_vars["%s1_%"].value)
            }
        }

        return _log.Exit()
    }

    ListContextVars() ; IDEA: Rename to ListCtxVars()
    {
        _log := new Logger("class." A_ThisFunc)

        dt := new DataTable()
        dt.DefineColumn(new DataTable.Column(10))
        dt.DefineColumn(new DataTable.Column.Wrapped(60))
        for pattern, context_var in RCopy.context_vars
        {
            dt.AddData([ pattern, context_var.desc ])
        }
        Ansi.WriteLine("`n" dt.GetTableAsString(), true)

        return _log.Exit()
    }

	cli()
    {
		_log := new Logger("class." A_ThisFunc)

        op := new OptParser("RCopy: [options] <source-dir\pattern>",, "RCOPY_OPTS")
        op.Add(new OptParser.Group("Available options"))
        op.Add(new OptParser.String("s", "subdir", RCopy.options, "subdirs"
            , "dir"
            , "Copy into a sub-directory. Context variables may be used. "
            . "If the directory doesn't exist, it will be created"
            , OptParser.OPT_ARG | OptParser.OPT_MULTIPLE))
        op.Add(new OptParser.String("d", "dest", RCopy.options, "dest", "dir"
            , "Destination directory"
            , OptParser.OPT_ARG, RCopy.options.dest, RCopy.options.dest))
        op.Add(new OptParser.Line("", "(Default: " RCopy.options.dest ")"))
        op.Add(new OptParser.String("r", "rename-as", RCopy.options, "rename_as"
            , "pattern"))
        op.Add(new OptParser.Boolean(0, "help-context-vars", RCopy.options
            , "help_context_vars"
            , "Show available context variables"))
        op.Add(new OptParser.Line("--[no]env", "Ignore environment variable "
            . op.stEnvVarName))
		op.Add(new OptParser.Boolean("h", "help", RCopy.options, "help"
            , "Display usage", OptParser.OPT_HIDDEN))

		return _log.Exit(op)
	}

	run(args)
    {
		_log := new Logger("class." A_ThisFunc)

		if (_log.Logs(Logger.Input))
        {
			_log.Input("args", args)
            _log.Logs(Logger.Finest, "args:`n" LoggingHelper.Dump(args))
		}

		try
        {
			rc := 1
			op := RCopy.cli()
			args := op.Parse(args)
			if (_log.Logs(Logger.Finest))
            {
				_log.Finest("rc", rc)
				_log.Finest("RCopy.options:`n" LoggingHelper.Dump(RCopy.options))
                _log.Finest("args:`n" LoggingHelper.Dump(args))
			}

			if (RCopy.options.help)
            {
				Ansi.WriteLine(op.Usage())
				rc := ""
            }
            else if (RCopy.options.help_context_vars)
            {
                RCopy.ListContextVars()
                rc := ""
			}
            else
            {
                n_args := args.MaxIndex()
                _log.Logs(Logger.Finest, "n_args", n_args)

                if (n_args > 1)
                {
                    throw _log.Exit(Exception("Too many arguments"))
                }
                RCopy.SetupSourcePath(args[1])

                if (_log.Logs(Logger.Finest))
                {
                    _log.Finest("rc", rc)
                    _log.Finest("RCopy.options:`n"
                        . LoggingHelper.Dump(RCopy.options))
                }

                RCopy.CopyAndRename()
            }
		}
        catch e
        {
			_log.Fatal(e.message)
			Ansi.WriteLine(e.message)
			Ansi.WriteLine(op.Usage())
			rc := 0
		}

		return _log.Exit(rc)
	}
}

#NoEnv                                      ; NOTEST-BEGIN
#include <logging>
#include <system>
#include <ansi>
#include <datatable>
#include <string>
#include <optparser>
#include <testcase>

Main:
_main := new Logger("app.RCopy.label.main")
exitapp _main.Exit(RCopy.run(System.vArgs))	; NOTEST-END
; vim:tw=100:ts=4:sts=4:sw=4:et:ft=autohotkey:nobomb
